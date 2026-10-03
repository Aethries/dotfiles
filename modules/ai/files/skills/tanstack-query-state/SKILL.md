---
name: tanstack-query-state
description: "TanStack Query (React Query) v5 server-state management: query key factories, optimistic mutations, prefetching, cache invalidation, and infinite scroll pagination. Use when managing asynchronous server state in web frontends."
---

# TanStack Query (React Query) Standards

Standards for managing server state, asynchronous caching, and optimistic UI mutations with TanStack Query v5.

## Core Rules

1. **Strict Query Key Factories**:
   - Centralize all query keys into typed query key factories to avoid typo-induced cache desynchronization:
     ```typescript
     export const userKeys = {
       all: ['users'] as const,
       lists: () => [...userKeys.all, 'list'] as const,
       list: (filters: UserFilters) => [...userKeys.lists(), filters] as const,
       details: () => [...userKeys.all, 'detail'] as const,
       detail: (id: string) => [...userKeys.details(), id] as const,
     };
     ```

2. **Optimistic Updates & Rollbacks**:
   - For interactive mutations (likes, toggles, inline edits), update the cache optimistically inside `onMutate`:
     - Cancel outgoing queries (`queryClient.cancelQueries(...)`).
     - Snapshot current cache data for rollback.
     - Set new cache state (`queryClient.setQueryData(...)`).
     - Return context with snapshot.
   - Roll back to snapshot inside `onError(err, vars, context)`.
   - Invalidate query key inside `onSettled` to sync with authoritative server state.

3. **Stale Time vs GC Time**:
   - Avoid aggressive refetching on window focus for static or slow-changing data; set a sensible `staleTime` (e.g. 1–5 minutes).
   - Ensure `gcTime` (formerly `cacheTime`) is greater than or equal to `staleTime` so cached data remains available during background refetches.

4. **Prefetching**:
   - Prefetch expected next pages or detail views on link hover (`queryClient.prefetchQuery(...)`) to eliminate perceptible loading delays.
