# Common Anti-Patterns by Language

When reviewing code, use this reference for language-specific pitfalls and idiomatic improvements. Read the section matching the language of the code under review.

## JavaScript / TypeScript

### Common Anti-Patterns
- **`==` instead of `===`**: Loose equality causes surprising coercions (`"0" == false` is `true`). Always use strict equality.
- **Missing `await`**: Forgetting `await` on async calls leads to working with Promise objects instead of values. The code may appear to work but silently drops errors.
- **Modifying state directly in React**: `state.items.push(x)` won't trigger re-render. Must create new references: `setItems([...items, x])`.
- **useEffect with missing dependencies**: Stale closures cause bugs that are hard to trace. ESLint's exhaustive-deps rule catches these.
- **`for...in` on arrays**: Iterates over all enumerable properties (including prototype), not just indices. Use `for...of`, `.forEach()`, or `.map()`.
- **Floating point comparison**: `0.1 + 0.2 !== 0.3`. Use epsilon comparison or integer arithmetic for money.
- **Catching errors without handling**: `catch (e) {}` silently swallows failures. At minimum, log the error.
- **Memory leaks from uncleared intervals/listeners**: `setInterval` and `addEventListener` need corresponding cleanup, especially in component unmount lifecycle.

### Idiomatic Patterns
- Prefer `const` by default, `let` when reassignment is needed, never `var`
- Use optional chaining (`?.`) and nullish coalescing (`??`) instead of verbose null checks
- Prefer `Array.prototype` methods (map, filter, reduce) over manual loops for data transformations
- Use template literals over string concatenation for readability
- In TypeScript, prefer narrowing (type guards) over type assertions (`as`)

## Python

### Common Anti-Patterns
- **Mutable default arguments**: `def f(items=[])` shares the same list across all calls. Use `def f(items=None): items = items or []`.
- **Bare `except:`**: Catches `SystemExit`, `KeyboardInterrupt`, and `GeneratorExit`. At minimum use `except Exception:`.
- **Using `type()` for type checking**: `isinstance()` handles inheritance correctly.
- **String concatenation in loops**: Building strings with `+=` in a loop is O(n^2). Use `"".join(parts)` or `io.StringIO`.
- **Not using context managers**: `open()` without `with` risks file handle leaks on exceptions.
- **`from module import *`**: Pollutes namespace, makes it impossible to trace where names come from.
- **Checking `== True` or `== None`**: Use `if x:` for truthiness, `if x is None:` for identity.

### Idiomatic Patterns
- Use f-strings for string formatting (Python 3.6+)
- Use dataclasses or NamedTuple instead of plain dicts for structured data
- Use `pathlib.Path` instead of `os.path` string manipulation
- Use list/dict/set comprehensions when they improve readability
- Use `enumerate()` instead of manual counter variables
- Use type hints for function signatures

## Go

### Common Anti-Patterns
- **Ignoring errors**: `result, _ := doSomething()` silently drops errors. Always handle or explicitly document why it's safe to ignore.
- **Goroutine leaks**: Launching goroutines without ensuring they can terminate (no context, no done channel, no timeout).
- **Data races with shared state**: Accessing shared variables from multiple goroutines without sync primitives. Use `go run -race` to detect.
- **Defer in loops**: `defer` runs at function end, not loop end. Resources opened in loops accumulate until the function returns.
- **Nil map writes**: Writing to an uninitialized map panics. Always `make(map[K]V)` first.
- **Interface pollution**: Defining interfaces with many methods upfront. Go idiom is small interfaces, defined by consumers.

### Idiomatic Patterns
- Accept interfaces, return structs
- Use `context.Context` for cancellation and deadlines
- Errors are values — wrap with `fmt.Errorf("...: %w", err)` for context
- Use table-driven tests
- Keep packages focused and name them by what they provide, not what they contain

## Java

### Common Anti-Patterns
- **Catching `Exception` or `Throwable` broadly**: Hides specific error types and makes debugging harder. Catch the narrowest applicable exception.
- **Null references without checks**: Use `Optional<T>` for values that may be absent, or validate inputs at boundaries.
- **String comparison with `==`**: Compares references, not values. Use `.equals()`.
- **Resource leaks (pre-try-with-resources)**: Always use try-with-resources for `AutoCloseable` objects.
- **Synchronized on non-final fields**: The lock reference can change, defeating the synchronization.
- **Mutable collections exposed from methods**: Return `Collections.unmodifiableList()` or defensive copies.

### Idiomatic Patterns
- Use records (Java 16+) for data carrier classes
- Prefer `var` for local variables when the type is obvious from the right-hand side
- Use Stream API for collection transformations, but don't over-chain to the point of unreadability
- Use sealed interfaces (Java 17+) for exhaustive type hierarchies

## Rust

### Common Anti-Patterns
- **Excessive `.unwrap()` or `.expect()`**: Panics in production code. Use `?` operator for error propagation, or pattern matching for explicit handling.
- **Cloning to satisfy the borrow checker**: Often indicates a design issue. Consider restructuring ownership instead.
- **Large `unsafe` blocks**: Minimize `unsafe` scope. Each `unsafe` block should have a safety comment explaining why the invariants hold.
- **Not using iterators**: Manual indexing instead of iterator chains loses safety guarantees and composability.

### Idiomatic Patterns
- Use `Result<T, E>` and `?` for error handling
- Prefer `&str` over `String` in function parameters
- Use `impl Trait` for return types when the concrete type is an implementation detail
- Use `derive` macros for common traits
