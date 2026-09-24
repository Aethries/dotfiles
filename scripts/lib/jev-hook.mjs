import { compactAnswers, evaluateJev, formatPreflightContext, getJevConfig } from "./jev-client.mjs";

const MAX_INPUT_BYTES = 1_000_000;

export const PREFLIGHT_QUESTIONS = Object.freeze({
  request_kind: {
    type: "choice",
    instructions: "What is the primary kind of request in `prompt`? Choose the single best category.",
    criteria: {
      explanation: "The user mainly asks for an explanation, instructions, or a factual answer.",
      diagnosis: "The user mainly asks to investigate an existing problem or unexpected behavior.",
      implementation: "The user asks to create, edit, configure, refactor, or otherwise change files or systems.",
      verification: "The user mainly asks to test, audit, review, validate, or report current state.",
      clarification: "The request is too incomplete to classify without first asking the user for missing information.",
    },
  },
  is_actionable: {
    type: "noul",
    instructions: "Can an agent begin handling `prompt` using the information provided, without inventing a material requirement?",
    criteria: {
      true: "The goal and scope are sufficiently clear for a safe next step, including asking a narrowly scoped clarification if needed.",
      false: "A material choice, target, authority, or expected behavior is missing and cannot be safely inferred.",
    },
  },
});

async function readStdin() {
  const chunks = [];
  let total = 0;
  for await (const chunk of process.stdin) {
    total += Buffer.byteLength(chunk, "utf8");
    if (total > MAX_INPUT_BYTES) {
      throw new Error("hook input exceeded the 1 MB safety limit");
    }
    chunks.push(chunk);
  }
  return chunks.join("");
}

export async function readHookInput() {
  const raw = await readStdin();
  let input;
  try {
    input = JSON.parse(raw);
  } catch {
    throw new Error("hook input was not valid JSON");
  }
  if (input === null || typeof input !== "object" || Array.isArray(input)) {
    throw new Error("hook input must be a JSON object");
  }
  if (typeof input.prompt !== "string" || input.prompt.trim() === "") {
    throw new Error("hook input did not contain a non-empty prompt");
  }
  return input;
}

export async function runPreflight(input) {
  const config = getJevConfig();
  const result = await evaluateJev({
    env: process.env,
    model: config.model,
    state: {
      prompt: input.prompt,
      cwd: typeof input.cwd === "string" ? input.cwd : process.cwd(),
      agent: "coding-agent",
      hook_event: typeof input.hook_event_name === "string" ? input.hook_event_name : "UserPromptSubmit",
    },
    questions: PREFLIGHT_QUESTIONS,
  });
  return {
    model: result.model || config.model,
    answers: compactAnswers(result.answers),
    context: formatPreflightContext(result, config.endpoint),
    hookEventName: typeof input.hook_event_name === "string"
      ? input.hook_event_name
      : "UserPromptSubmit",
  };
}
