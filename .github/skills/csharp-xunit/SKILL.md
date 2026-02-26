---
name: csharp-xunit
description: "Write effective XUnit unit tests for C#/.NET projects, including data-driven tests with Theory/InlineData/MemberData/ClassData, mocking, assertions, and test organization. Use when: (1) Creating or updating XUnit test projects, (2) Writing Fact or Theory-based unit tests, (3) Implementing data-driven tests with InlineData, MemberData, or ClassData, (4) Setting up test fixtures with IClassFixture or ICollectionFixture, (5) Organizing test structure with Arrange-Act-Assert pattern, or (6) Configuring mocking and test isolation in .NET test projects."
---

# XUnit Best Practices

Provide guidance for writing effective C#/.NET unit tests with XUnit, covering standard tests, data-driven testing, assertions, mocking, and test organization.

## Project Setup

- Use a separate test project named `[ProjectName].Tests`
- Reference `Microsoft.NET.Test.Sdk`, `xunit`, and `xunit.runner.visualstudio` packages
- Name test classes to match classes under test (e.g., `CalculatorTests` for `Calculator`)
- Run tests with `dotnet test`

## Test Structure

- No test class attributes required (unlike MSTest/NUnit)
- Use `[Fact]` for simple single-scenario tests
- Follow Arrange-Act-Assert (AAA) pattern
- Name tests: `MethodName_Scenario_ExpectedBehavior`
- Use constructor for setup, `IDisposable.Dispose()` for teardown
- Use `IClassFixture<T>` for shared context within a test class
- Use `ICollectionFixture<T>` for shared context across multiple test classes

## Standard Tests

- Keep each test focused on a single behavior
- Make tests independent and idempotent (runnable in any order)
- Include only assertions needed to verify the test case
- Avoid test interdependencies

```csharp
public class CalculatorTests
{
    private readonly Calculator _sut = new();

    [Fact]
    public void Add_TwoPositiveNumbers_ReturnsSum()
    {
        // Arrange
        int a = 2, b = 3;

        // Act
        var result = _sut.Add(a, b);

        // Assert
        Assert.Equal(5, result);
    }
}
```

## Data-Driven Tests

Use `[Theory]` combined with data source attributes for parameterized tests.

### InlineData

```csharp
[Theory]
[InlineData(2, 3, 5)]
[InlineData(-1, 1, 0)]
[InlineData(0, 0, 0)]
public void Add_WithVariousInputs_ReturnsExpectedSum(int a, int b, int expected)
{
    var result = _sut.Add(a, b);
    Assert.Equal(expected, result);
}
```

### MemberData

```csharp
public static IEnumerable<object[]> AddTestData =>
    new List<object[]>
    {
        new object[] { 1, 2, 3 },
        new object[] { -4, -6, -10 },
    };

[Theory]
[MemberData(nameof(AddTestData))]
public void Add_WithMemberData_ReturnsExpectedSum(int a, int b, int expected)
{
    Assert.Equal(expected, _sut.Add(a, b));
}
```

### ClassData

```csharp
public class AddTestDataClass : IEnumerable<object[]>
{
    public IEnumerator<object[]> GetEnumerator()
    {
        yield return new object[] { 1, 2, 3 };
        yield return new object[] { -4, -6, -10 };
    }

    IEnumerator IEnumerable.GetEnumerator() => GetEnumerator();
}

[Theory]
[ClassData(typeof(AddTestDataClass))]
public void Add_WithClassData_ReturnsExpectedSum(int a, int b, int expected)
{
    Assert.Equal(expected, _sut.Add(a, b));
}
```

## Assertions

| Purpose | Assertion |
|---------|-----------|
| Value equality | `Assert.Equal(expected, actual)` |
| Reference equality | `Assert.Same(expected, actual)` |
| Boolean | `Assert.True(condition)` / `Assert.False(condition)` |
| Collections | `Assert.Contains(item, collection)` / `Assert.DoesNotContain(item, collection)` |
| Regex | `Assert.Matches(pattern, actual)` / `Assert.DoesNotMatch(pattern, actual)` |
| Exceptions | `Assert.Throws<T>(() => ...)` / `await Assert.ThrowsAsync<T>(async () => ...)` |

Consider FluentAssertions library for more readable assertions.

## Mocking and Isolation

- Use Moq or NSubstitute for dependency mocking
- Define dependencies as interfaces to facilitate mocking
- Inject mocks via constructor

```csharp
public class OrderServiceTests
{
    private readonly Mock<IOrderRepository> _repoMock = new();
    private readonly OrderService _sut;

    public OrderServiceTests()
    {
        _sut = new OrderService(_repoMock.Object);
    }

    [Fact]
    public async Task GetOrder_ExistingId_ReturnsOrder()
    {
        var expected = new Order { Id = 1 };
        _repoMock.Setup(r => r.GetByIdAsync(1)).ReturnsAsync(expected);

        var result = await _sut.GetOrderAsync(1);

        Assert.Same(expected, result);
    }
}
```

## Test Organization

- Group tests by feature or component
- Use `[Trait("Category", "CategoryName")]` for categorization
- Use `ITestOutputHelper` for test diagnostics
- Skip tests conditionally: `[Fact(Skip = "reason")]`
- Use collection fixtures to group tests with shared dependencies
