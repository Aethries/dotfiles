---
name: nextjs-app-router
description: "Next.js App Router engineering: React Server Components (RSC), Server Actions, hydration boundaries, Route Handlers, ISR/cache revalidation, and Turbopack. Use when building or debugging Next.js 14/15 web applications."
---

# Next.js App Router Engineering

Standards for modern Next.js 14/15 fullstack applications using React Server Components, Server Actions, and streaming.

## Core Rules

1. **Server vs. Client Components**:
   - Default all components to Server Components (RSC). Do not add `'use client'` unless client state (`useState`, `useEffect`), event listeners (`onClick`), or browser APIs (`window`, `localStorage`) are needed.
   - Push `'use client'` to the leaf nodes of the component tree to preserve server streaming benefits.
   - Never pass functions as props from Server Components to Client Components; pass serializable data or use Server Actions.

2. **Data Fetching & Cache Semantics**:
   - Fetch data directly inside async Server Components (`await db.query(...)` or `fetch(...)`).
   - Use `revalidatePath()` or `revalidateTag()` inside Server Actions for targeted cache invalidation.
   - For static content, configure explicit route segment config (`export const dynamic = 'force-static'`).

3. **Server Actions & Mutations**:
   - Place Server Actions in dedicated action files marked with `'use server'` at top.
   - Always validate incoming payload arguments with Zod / Valibot inside the action.
   - Return structured result envelopes (`{ success: true, data }` or `{ success: false, error: string }`) instead of throwing unhandled exceptions across the network boundary.

4. **Loading & Error UI**:
   - Implement `loading.tsx` with Suspense skeletons to avoid layout shift (CLS).
   - Implement `error.tsx` (must be `'use client'`) to catch and recover from runtime render exceptions.
