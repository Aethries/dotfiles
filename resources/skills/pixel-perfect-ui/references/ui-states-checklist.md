# UI States & Fidelity Checklist

Verify every UI component and view against this checklist prior to delivery.

---

## 1. Design Token Fidelity
- [ ] Colors use defined design tokens / CSS variables (no raw hex codes like `#3b82f6`).
- [ ] Spacing (padding, margin, gap) follows the project scale (`4px`, `8px`, `12px`, `16px`, `24px`, etc.).
- [ ] Typography uses design system font family, weight, and size definitions.
- [ ] Border radii and box shadows match Figma or styleguide tokens.

## 2. Exhaustive UI States
- [ ] **Empty State**: Friendly illustration/icon, clear explanation, and primary action button when list/data is empty.
- [ ] **Loading State**: Skeleton placeholders match the dimensions of resolved content to eliminate Cumulative Layout Shift (CLS).
- [ ] **Error State**: Non-blocking banner or card with user-friendly error message and retry button.
- [ ] **Partial / Overflow**: Long texts are clamped (`line-clamp-1` or `line-clamp-2`), with tooltips enabled where truncation hides critical information.
- [ ] **Interactive States**: Hover, active, disabled, and loading states visually distinct.

## 3. Responsiveness & Cross-Device
- [ ] Tested on 320px (small mobile), 768px (tablet), 1024px (laptop), 1440px (desktop).
- [ ] No unintentional horizontal overflow (`overflow-x: hidden` is not used as a band-aid for broken layout).
- [ ] Touch targets are at least 44x44px on mobile devices.

## 4. Accessibility (a11y)
- [ ] Color contrast ratio meets WCAG AA standards (at least 4.5:1 for normal text).
- [ ] Keyboard navigable (Tab, Enter, Space, Escape on modals).
- [ ] Visible focus indicators (`:focus-visible`) never removed via `outline: none` without a custom replacement.
- [ ] Form inputs have associated `<label>` or `aria-label`.
