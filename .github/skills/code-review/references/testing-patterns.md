# Testing Review Patterns

Use this reference when evaluating test quality during a code review. Good tests are as important as the code they cover — they serve as living documentation and a safety net for future changes.

## Common Anti-Patterns

### Assertion-Free Tests
**Pattern**: Tests that execute code but never assert anything meaningful. They pass as long as no exception is thrown.
**Why it's bad**: Gives false confidence — the test "passes" even if the output is completely wrong.
**Fix**: Every test should assert at least one observable outcome (return value, state change, side effect, or thrown exception).

### Testing Implementation Instead of Behavior
**Pattern**: Tests that assert on internal details (private method calls, exact SQL strings, internal state) rather than observable behavior.
**Why it's bad**: Tests break on every refactor even when behavior is preserved, discouraging improvement.
**Fix**: Test through public interfaces. Assert on what the code does, not how it does it.

### Excessive Mocking
**Pattern**: Tests that mock every dependency, including simple value objects, data structures, or stable libraries.
**Why it's bad**: Tests become coupled to the exact shape of the implementation. Mock behavior diverges from real behavior over time.
**Fix**: Only mock at true system boundaries (external APIs, databases, file systems, clocks). Use real objects for internal collaborators when practical.

### Copy-Paste Test Code
**Pattern**: Near-identical test methods with small variations copy-pasted instead of parameterized.
**Why it's bad**: Maintenance burden — fixing a test setup bug requires editing N copies.
**Fix**: Use parameterized/data-driven tests (`@pytest.mark.parametrize`, `[Theory]` in xUnit, table-driven tests in Go, `test.each` in Jest).

### Flaky Tests
**Pattern**: Tests that sometimes pass and sometimes fail without code changes. Common causes: timing dependencies, shared mutable state, test ordering dependencies, non-deterministic data.
**How to spot**: Look for `sleep()`, `Thread.sleep()`, shared static state, reliance on real time/dates, or tests that modify global configuration.
**Fix**: Use deterministic clocks/timers, isolate test state, use proper synchronization for async tests.

### Giant Test Setup (Arrange)
**Pattern**: 50+ lines of setup before the actual test action, often constructing deeply nested object graphs.
**Why it's bad**: Hard to understand what's actually being tested. Signals that the code under test may have too many dependencies.
**Fix**: Use builder patterns or factory methods for test data. Consider whether the production code needs refactoring to reduce coupling.

### Testing Only the Happy Path
**Pattern**: Tests only cover the success scenario. No tests for invalid inputs, error conditions, edge cases, or boundary values.
**Fix**: Add tests for: null/empty inputs, boundary values (0, -1, MAX_INT), error responses, timeout/retry behavior, concurrent access scenarios.

## What Good Tests Look Like

### Clear Structure
Each test should follow Arrange → Act → Assert (or Given → When → Then) with clear visual separation. The test name should describe the scenario being tested, not the method name.

### One Concept Per Test
A test should verify one logical concept. Multiple assertions are fine if they all verify different aspects of the same behavior — but testing two unrelated behaviors in one test makes failures ambiguous.

### Readable Without Context
Someone reading the test should understand the expected behavior without reading the production code. Good test names describe: the scenario, the action, and the expected outcome.

### Fast and Independent
Tests should not depend on each other's execution order or shared state. Each test sets up its own preconditions and cleans up after itself.

## Language-Specific Test Patterns

### JavaScript/TypeScript (Jest/Vitest)
- Use `describe` blocks to group related tests
- Prefer `toEqual` for deep comparison, `toBe` for primitives
- Use `beforeEach` for shared setup, not shared mutable variables
- For async tests: always `await` or return the promise; use `expect.assertions(N)` for tests with catch blocks

### Python (pytest)
- Use fixtures for reusable setup; prefer function-scoped fixtures
- Use `@pytest.mark.parametrize` for data-driven tests
- Use `pytest.raises` context manager for exception testing
- Avoid `unittest.TestCase` when using pytest — it limits fixture usage

### C# (xUnit/NUnit)
- Use `[Theory]` with `[InlineData]` or `[MemberData]` for parameterized tests
- Use `FluentAssertions` or similar for readable assertions
- Do not emit "Arrange", "Act", "Assert" section comments
- Follow the project's existing test naming convention

### Go
- Use table-driven tests with subtests (`t.Run`)
- Use `testify/assert` or standard `if` checks — be consistent within the project
- Use `t.Helper()` in test helper functions for better error reporting
- Use `t.Parallel()` where tests are independent

### Java (JUnit 5)
- Use `@ParameterizedTest` with `@ValueSource`, `@CsvSource`, or `@MethodSource` for data-driven tests
- Use `assertThrows` for exception testing instead of try-catch with `fail()`
- Use `@BeforeEach` / `@AfterEach` for per-test setup/teardown, `@BeforeAll` / `@AfterAll` for expensive shared resources
- Use `@Nested` classes to group related tests and share setup
- Use `@DisplayName` for readable test names when method names aren't sufficient
- Prefer AssertJ fluent assertions for complex assertions (e.g., `assertThat(list).hasSize(3).contains("a")`)

### Rust
- Use `#[cfg(test)] mod tests` for unit tests in the same file
- Use `#[should_panic(expected = "...")]` for expected panic tests
- Use `assert_eq!`, `assert_ne!`, and `assert!(condition, "message")` with descriptive messages
- Use `Result<(), Box<dyn Error>>` return type in tests for `?` operator support

## Test Double Strategy

Choose the right test double for the situation:

- **Fake**: A working implementation with shortcuts (e.g., in-memory database). Best for integration tests where you need realistic behavior without external dependencies.
- **Stub**: Returns canned responses. Use when you just need a dependency to return specific data for a test scenario.
- **Mock**: Verifies interactions (was this method called with these arguments?). Use sparingly — only when the interaction itself is the behavior under test (e.g., verifying an email was sent).
- **Spy**: Wraps a real object and records calls. Use when you need real behavior but also want to verify interactions.

**Rule of thumb**: Prefer fakes over mocks for most tests. Mocks test *how* code works; fakes test *what* code does. Fakes lead to less brittle tests.

## Integration & E2E Test Anti-Patterns

### Relying on External Services in CI
**Pattern**: Tests that hit real third-party APIs (payment providers, email services) in CI pipelines.
**Why it's bad**: Flaky failures from network issues, rate limits, or service downtime. Also risks real side effects (charges, emails sent).
**Fix**: Use fakes or recorded responses (VCR pattern / WireMock / nock) for CI. Reserve real-service tests for a separate, low-frequency integration suite.

### No Test Data Cleanup
**Pattern**: Integration tests that create records in a shared database but never clean them up.
**Why it's bad**: Tests pollute each other's state, causing ordering-dependent failures.
**Fix**: Use per-test transactions that roll back, or dedicated test databases that are reset between runs.
