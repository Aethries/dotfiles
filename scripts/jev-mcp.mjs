import { createInterface } from "node:readline";
import { compactAnswers, evaluateJev } from "./lib/jev-client.mjs";
import { PREFLIGHT_QUESTIONS } from "./lib/jev-hook.mjs";

const PROTOCOL_VERSION = "2024-11-05";
const SERVER_VERSION = "0.1.0";

function writeMessage(message) {
  process.stdout.write(`${JSON.stringify(message)}\n`);
}

function errorResponse(id, code, message) {
  return {
    jsonrpc: "2.0",
    id: id ?? null,
    error: { code, message },
  };
}

function toolError(message) {
  return {
    isError: true,
    content: [{
      type: "text",
      text: `JEV preflight failed: ${message}. Verify that 9Router is listening on local port 20128; no API key is required.`,
    }],
  };
}

const tools = [{
  name: "jev_preflight",
  description: "Evaluate a user request with local TypeSafe Jev before the normal chat model handles it. This sends no API key and fails if the local JEV endpoint is unavailable.",
  inputSchema: {
    type: "object",
    properties: {
      prompt: {
        type: "string",
        minLength: 1,
        description: "The complete user request to classify and assess for actionability.",
      },
      cwd: {
        type: "string",
        description: "Optional current repository directory to include as context.",
      },
      context: {
        type: "string",
        description: "Optional short, non-secret context that helps classify the request.",
      },
    },
    required: ["prompt"],
    additionalProperties: false,
  },
}];

async function callTool(name, args) {
  if (name !== "jev_preflight") {
    return toolError(`unknown tool '${name}'`);
  }
  if (args === null || typeof args !== "object" || Array.isArray(args)) {
    return toolError("arguments must be an object");
  }
  if (typeof args.prompt !== "string" || args.prompt.trim() === "") {
    return toolError("prompt must be a non-empty string");
  }

  try {
    const result = await evaluateJev({
      state: {
        prompt: args.prompt,
        cwd: typeof args.cwd === "string" ? args.cwd : process.cwd(),
        context: typeof args.context === "string" ? args.context : undefined,
        agent: "mcp-client",
      },
      questions: PREFLIGHT_QUESTIONS,
    });
    const output = {
      model: result.model,
      answers: compactAnswers(result.answers),
      usage: result.usage,
    };
    return {
      content: [{ type: "text", text: JSON.stringify(output) }],
      structuredContent: output,
    };
  } catch (error) {
    return toolError(error instanceof Error ? error.message : "unknown local endpoint error");
  }
}

async function handleMessage(message) {
  if (message === null || typeof message !== "object" || Array.isArray(message)) {
    return errorResponse(null, -32600, "JSON-RPC message must be an object");
  }
  const { id, method, params } = message;
  if (typeof method !== "string") {
    return errorResponse(id, -32600, "JSON-RPC method is required");
  }
  if (id === undefined && method.startsWith("notifications/")) {
    return null;
  }

  switch (method) {
    case "initialize":
      return {
        jsonrpc: "2.0",
        id,
        result: {
          protocolVersion: typeof params?.protocolVersion === "string"
            ? params.protocolVersion
            : PROTOCOL_VERSION,
          capabilities: { tools: {} },
          serverInfo: { name: "jev-local", version: SERVER_VERSION },
        },
      };
    case "notifications/initialized":
      return null;
    case "ping":
      return { jsonrpc: "2.0", id, result: {} };
    case "tools/list":
      return { jsonrpc: "2.0", id, result: { tools } };
    case "tools/call": {
      const result = await callTool(params?.name, params?.arguments);
      return { jsonrpc: "2.0", id, result };
    }
    default:
      return errorResponse(id, -32601, `Method not found: ${method}`);
  }
}

const input = createInterface({ input: process.stdin, crlfDelay: Infinity });
for await (const line of input) {
  if (!line.trim()) continue;
  let message;
  try {
    message = JSON.parse(line);
  } catch {
    writeMessage(errorResponse(null, -32700, "Request was not valid JSON"));
    continue;
  }
  try {
    const response = await handleMessage(message);
    if (response) writeMessage(response);
  } catch (error) {
    const messageText = error instanceof Error ? error.message : "unknown MCP server error";
    process.stderr.write(`jev-local MCP error: ${messageText}\n`);
    if (message.id !== undefined) writeMessage(errorResponse(message.id, -32603, messageText));
  }
}
