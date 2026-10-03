import { readHookInput, runPreflight } from "./lib/jev-hook.mjs";

try {
  const result = await runPreflight(await readHookInput());
  process.stdout.write(`${JSON.stringify({
    hookSpecificOutput: {
      hookEventName: result.hookEventName,
      additionalContext: result.context,
    },
  })}\n`);
} catch (error) {
  const message = error instanceof Error ? error.message : "unknown preflight failure";
  process.stderr.write(`JEV preflight blocked this request: ${message}\n`);
  process.exitCode = 2;
}
