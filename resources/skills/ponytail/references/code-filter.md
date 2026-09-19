# Ponytail 6-Step Code Filter Reference

## The 6 Rungs

1. **Rung 1: YAGNI Check**
   - Question: "Will the product break today if this does not exist?"
   - If no, delete or refuse to build.

2. **Rung 2: Standard Library / Native Primitives**
   - Question: "Does the runtime (Node.js/browser APIs, Python stdlib, Bash builtins, POSIX tools) have built-in utilities?"
   - Examples:
     - JavaScript/TypeScript: `crypto.randomUUID()`, `structuredClone()`, `URL`, `fetch`, native `Array`/`Object` methods.
     - Python: `pathlib`, `dataclasses`, `functools`, `itertools`.
     - Shell: Parameter expansion `${var#prefix}` instead of piping to `sed`/`awk`/`cut`.

3. **Rung 3: Native Platform Features**
   - Question: "Can the platform handle this without custom application logic?"
   - Examples:
     - CSS `:hover`, `:focus-visible`, `<dialog>` element over custom JS modal state.
     - Database unique index, check constraints, foreign keys over application-level duplicate checks.
     - Systemd timer/service over custom background daemons or loops.

4. **Rung 4: Existing Installed Dependencies**
   - Question: "Does an existing dependency already in the project have a helper?"
   - Rule: Never add a new third-party dependency if 5-10 lines of native code or an existing utility can do the job safely.

5. **Rung 5: The One-Liner**
   - Question: "Can this be written cleanly in one readable line?"
   - Prefer simple, idiomatic single expressions when clear.

6. **Rung 6: Minimum Working Code**
   - Build only the path that satisfies the active acceptance criteria.
   - Skip hypothetical edge cases until an actual requirement asks for them.

## Ponytail Comment Convention

```typescript
// ponytail: in-memory cache ceiling = 100 entries. Upgrade to Redis when multi-replica deployed.
const cache = new Map<string, string>();
```

Pattern: `[code] → skipped: [X], add when [Y].`
