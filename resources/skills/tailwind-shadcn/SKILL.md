---
name: tailwind-shadcn
description: "TailwindCSS v4 & Shadcn UI component design: CSS design tokens, Radix UI headless accessible primitives, cn/clsx/tailwind-merge class composition, and variant-driven props (CVA). Use when building modern web UI components."
---

# TailwindCSS & Shadcn UI Component Standards

Standards for building accessible, token-driven, composable web components with TailwindCSS and Radix/Shadcn primitives.

## Core Rules

1. **Utility & Variant Merging**:
   - Merge className props with `cn()` (`clsx` + `tailwind-merge`):
     ```tsx
     import { clsx, type ClassValue } from "clsx";
     import { twMerge } from "tailwind-merge";
     export function cn(...inputs: ClassValue[]) { return twMerge(clsx(inputs)); }
     ```
   - Use `class-variance-authority` (CVA) for multi-variant components (`variant: default | destructive | outline`, `size: sm | md | lg`).
   - Ban `@apply` in CSS files; express styling through utilities and design token variables.

2. **Accessibility & Radix Primitives**:
   - Wrap headless Radix UI primitives (`@radix-ui/react-*`) for complex interactions (Dialog, DropdownMenu, Popover, Tooltip, Select).
   - Never override ARIA attributes or break keyboard navigation (Tab, Escape, Enter, Arrow keys).
   - Ensure proper focus rings (`focus-visible:ring-2 focus-visible:ring-offset-2`).

3. **Design Tokens & Dark Mode**:
   - Consume CSS variables defined in theme layer (`bg-background text-foreground border-border`).
   - Never hardcode arbitrary hex colors (`#1a2b3c`); map all colors to HSL/OKLCH design tokens.
