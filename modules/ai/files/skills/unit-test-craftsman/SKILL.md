---
name: unit-test-craftsman
description: "Unit testing craftsmanship: AAA pattern (Arrange-Act-Assert), boundary value analysis, test doubles (mocks, stubs, fakes, spies), parameterized testing, and zero test leakage across Vitest, Jest, and native test runners."
---

# Unit Test Craftsmanship

Engineering standards for fast, deterministic, maintainable unit tests across JavaScript/TypeScript, Go, Python, and Rust.

## Core Rules

1. **AAA Pattern & Single Responsibility**:
   - Structure every test case with clear Arrange, Act, and Assert blocks separated by newlines:
     ```typescript
     // Arrange
     const calculator = new TaxCalculator({ rate: 0.1 });
     // Act
     const result = calculator.calculate(100);
     // Assert
     expect(result).toBe(10);
     ```
   - Each test verifies exactly one logical behavior or boundary outcome.

2. **Boundary Value Analysis & Equivalence Partitioning**:
   - Test beyond the happy path: null/undefined, empty collections, zero, negative numbers, maximum boundaries (`Number.MAX_SAFE_INTEGER`), and unicode strings.
   - Use parameterized/table-driven tests (`test.each` or Go slice of test cases) to cover input combinations without code duplication.

3. **Test Doubles Discipline**:
   - **Stub**: Provides hardcoded indirect inputs.
   - **Mock**: Verifies indirect outputs and call expectations.
   - **Fake**: Working implementation with shortcuts (e.g., in-memory repository). Prefer fakes over brittle deep mocks.
   - Ban mocking standard library primitives or types you do not own. Wrap third-party SDKs in adapters before mocking.

4. **Zero Test Pollution**:
   - Reset all mocks and fake timers in `afterEach()` (`vi.clearAllMocks()`, `jest.restoreAllMocks()`).
   - Never write to shared static state or real filesystem paths during unit tests.
