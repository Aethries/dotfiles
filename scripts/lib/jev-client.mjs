const DEFAULT_ENDPOINT = "http://localhost:20128/v1/systemone";
const DEFAULT_MODEL = "oc/jev-1.13-free";
const DEFAULT_TIMEOUT_MS = 20_000;
const MAX_REQUEST_BYTES = 120_000;
const MAX_RESPONSE_BYTES = 1_000_000;
const LOOPBACK_HOSTS = new Set(["127.0.0.1", "localhost", "::1"]);

const isRecord = (value) => value !== null && typeof value === "object" && !Array.isArray(value);

function fail(message) {
  throw new Error(`JEV ${message}`);
}

function validateEndpoint(rawEndpoint, allowRemote) {
  let endpoint;
  try {
    endpoint = new URL(rawEndpoint);
  } catch {
    fail(`endpoint is not a valid URL: ${rawEndpoint}`);
  }

  if (!endpoint || !["http:", "https:"].includes(endpoint.protocol)) {
    fail("endpoint must use http or https");
  }
  if (endpoint.username || endpoint.password) {
    fail("endpoint must not contain embedded credentials");
  }
  if (!allowRemote && !LOOPBACK_HOSTS.has(endpoint.hostname)) {
    fail("endpoint must be loopback-only; set JEV_ALLOW_REMOTE=1 only for an intentional remote deployment");
  }
  if (endpoint.pathname !== "/v1/systemone") {
    fail("endpoint path must be /v1/systemone");
  }
  return endpoint.toString();
}

function parseTimeout(rawTimeout) {
  if (rawTimeout === undefined || rawTimeout === "") {
    return DEFAULT_TIMEOUT_MS;
  }
  const timeout = Number(rawTimeout);
  if (!Number.isInteger(timeout) || timeout < 1_000 || timeout > 60_000) {
    fail("timeout must be an integer between 1000 and 60000 milliseconds");
  }
  return timeout;
}

export function getJevConfig(env = process.env) {
  const endpoint = validateEndpoint(
    env.JEV_ENDPOINT?.trim() || DEFAULT_ENDPOINT,
    env.JEV_ALLOW_REMOTE === "1",
  );
  const model = env.JEV_MODEL?.trim() || DEFAULT_MODEL;
  if (!/^[A-Za-z0-9._/-]{1,160}$/.test(model)) {
    fail("model contains unsupported characters");
  }
  return {
    endpoint,
    model,
    timeoutMs: parseTimeout(env.JEV_TIMEOUT_MS),
  };
}

function assertState(state) {
  if (!(typeof state === "string" || Array.isArray(state) || isRecord(state))) {
    fail("state must be a string, object, or array");
  }
}

function assertQuestions(questions) {
  if (!isRecord(questions) || Object.keys(questions).length === 0) {
    fail("questions must be a non-empty object");
  }
  if (Object.keys(questions).length > 16) {
    fail("questions must contain at most 16 entries");
  }

  for (const [id, question] of Object.entries(questions)) {
    if (!/^[A-Za-z][A-Za-z0-9_-]{0,63}$/.test(id)) {
      fail(`question id is invalid: ${id}`);
    }
    if (!isRecord(question) || !["noul", "choice", "score"].includes(question.type)) {
      fail(`question ${id} must use type noul, choice, or score`);
    }
    if (question.instructions === undefined) {
      fail(`question ${id} is missing instructions`);
    }
    if (question.type === "choice" && !isRecord(question.criteria)) {
      fail(`choice question ${id} must define criteria`);
    }
    if (question.type === "score" && !Array.isArray(question.criteria)) {
      fail(`score question ${id} must define criteria`);
    }
  }
}

async function readBoundedBody(response) {
  const contentLength = Number(response.headers.get("content-length"));
  if (Number.isFinite(contentLength) && contentLength > MAX_RESPONSE_BYTES) {
    fail("response exceeded the 1 MB safety limit");
  }
  if (!response.body) {
    return response.text();
  }

  const reader = response.body.getReader();
  const chunks = [];
  let total = 0;
  try {
    while (true) {
      const { done, value } = await reader.read();
      if (done) break;
      total += value.byteLength;
      if (total > MAX_RESPONSE_BYTES) {
        await reader.cancel();
        fail("response exceeded the 1 MB safety limit");
      }
      chunks.push(value);
    }
  } finally {
    reader.releaseLock();
  }
  return Buffer.concat(chunks).toString("utf8");
}

function validateResponse(payload) {
  if (!isRecord(payload) || !isRecord(payload.answers)) {
    fail("response did not contain a typed answers object");
  }
  return payload;
}

export async function evaluateJev({ state, questions, model, env = process.env }) {
  assertState(state);
  assertQuestions(questions);

  const config = getJevConfig(env);
  const body = JSON.stringify({
    state,
    model: model || config.model,
    questions,
  });
  if (Buffer.byteLength(body, "utf8") > MAX_REQUEST_BYTES) {
    fail("request exceeded the 120 KB safety limit");
  }

  let response;
  try {
    response = await fetch(config.endpoint, {
      method: "POST",
      headers: {
        Accept: "application/json",
        "Content-Type": "application/json",
      },
      body,
      signal: AbortSignal.timeout(config.timeoutMs),
    });
  } catch (error) {
    const reason = error?.name === "TimeoutError" || error?.name === "AbortError"
      ? `request timed out after ${config.timeoutMs} ms`
      : "local endpoint was unreachable";
    fail(reason);
  }

  const responseBody = await readBoundedBody(response);
  if (!response.ok) {
    fail(`endpoint returned HTTP ${response.status}`);
  }

  let payload;
  try {
    payload = JSON.parse(responseBody);
  } catch {
    fail("endpoint returned invalid JSON");
  }
  return validateResponse(payload);
}

function rounded(value) {
  return typeof value === "number" && Number.isFinite(value)
    ? Math.round(value * 1000) / 1000
    : value;
}

export function compactAnswers(answers) {
  return Object.fromEntries(
    Object.entries(answers).map(([id, answer]) => {
      if (!isRecord(answer)) return [id, { type: "unknown" }];
      const compact = { type: answer.type || "unknown" };
      if (answer.type === "noul") compact.noul = rounded(answer.noul);
      if (answer.type === "choice") {
        compact.choice = answer.choice;
        compact.confidence = rounded(answer.confidence);
      }
      if (answer.type === "score") {
        compact.score = rounded(answer.score);
        compact.confidence = rounded(answer.confidence);
      }
      return [id, compact];
    }),
  );
}

export function formatPreflightContext(payload, endpoint = getJevConfig().endpoint) {
  const model = typeof payload.model === "string" ? payload.model : "configured Jev model";
  const answers = compactAnswers(payload.answers);
  return [
    `JEV preflight completed via local ${endpoint} using ${model}; no API key was sent.`,
    `Typed results: ${JSON.stringify(answers)}.`,
    "Treat these results as advisory structured context, keep the original user request, and continue applying the repository safety and approval rules.",
  ].join(" ");
}

export const JEV_DEFAULTS = Object.freeze({
  endpoint: DEFAULT_ENDPOINT,
  model: DEFAULT_MODEL,
  timeoutMs: DEFAULT_TIMEOUT_MS,
});
