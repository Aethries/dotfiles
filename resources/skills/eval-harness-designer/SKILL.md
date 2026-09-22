---
name: eval-harness-designer
description: "LLM & agent evaluation harness design: benchmark datasets, tool-calling accuracy verification, hallucination scoring, regression test suites, and deterministic grading metrics. Use when evaluating prompt changes or agent performance."
---

# LLM & Agent Evaluation Harness Design

Engineering standards for automated, reproducible evaluation and regression testing of AI agents and prompts.

## Core Rules

1. **Ground Truth Benchmark Datasets**:
   - Maintain a curated JSONL dataset of representative user prompts, required tool calls, and expected outputs.
   - Categorize test cases by complexity: P0 (basic single-turn actions), P1 (multi-step tool chains), and P2 (adversarial / negative prompts).

2. **Deterministic vs Semantic Grading**:
   - Prefer deterministic assertions: verify exact JSON schema compliance, regex matches, HTTP status codes, and database mutations.
   - For open-ended natural language answers, use LLM-as-a-Judge with strict rubrics and binary scoring (0 or 1) rather than vague 1–5 scales.

3. **Evaluation Metrics**:
   - Track **Tool Call Accuracy**: did the agent invoke the correct tool with the correct arguments?
   - Track **Pass@K** and **Token Efficiency**: measure tokens burned per successful task completion.
   - Track **Latency & Cost**: quantify dollar and runtime cost per query run.

4. **CI/CD Integration**:
   - Run a fast smoke eval suite on every prompt or system message modification before merging.
   - Halt releases if accuracy drops below baseline thresholds.
