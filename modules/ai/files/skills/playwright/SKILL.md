---
name: playwright
description: "Playwright E2E testing: resilient user-facing locators, auto-waiting, page fixture management, network request interception/mocking, and trace viewer debugging. Use when authoring or debugging browser end-to-end tests."
---

# Playwright E2E Testing Standards

Standards for authoring robust, non-flaky end-to-end browser tests with Playwright.

## Core Rules

1. **User-Centric Locators**:
   - Prioritize accessibility-driven user-facing locators:
     ```typescript
     page.getByRole('button', { name: /submit/i })
     page.getByLabel(/username/i)
     page.getByPlaceholder(/search/i)
     page.getByText(/success/i)
     ```
   - Fall back to `page.getByTestId('custom-id')` only when ARIA roles are ambiguous.
   - Strictly ban brittle CSS selectors and absolute XPath paths (e.g. `div > div:nth-child(3) > button`).

2. **Auto-Waiting & Assertions**:
   - Use web-first assertions with built-in auto-waiting (`await expect(locator).toBeVisible()`, `await expect(locator).toHaveText(...)`).
   - Ban arbitrary sleeps (`await page.waitForTimeout(...)`). Wait for actual network conditions (`page.waitForResponse(...)`) or element states instead.

3. **Isolation & Fixtures**:
   - Each test must run in complete isolation. Never depend on state left by a preceding test.
   - Use custom test fixtures (`test.extend<{ authenticatedPage: Page }>`) to share setup logic cleanly.
   - Reset test databases or use isolated user sessions per test worker.

4. **Debugging & Traces**:
   - Enable `trace: 'on-first-retry'` in `playwright.config.ts` to capture execution snapshots, DOM snapshots, and network traces on failure.
