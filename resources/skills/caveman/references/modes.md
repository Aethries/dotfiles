# Caveman Compression Modes

## 1. Lite Mode
- Strips filler greetings, conversational fluff, and concluding pleasantries.
- Keeps grammatically complete sentences but removes unnecessary explanations.

## 2. Full Mode (Default)
- Telegraphic phrasing.
- Drops articles (a, an, the) and non-essential conjunctions.
- Uses pattern: `[thing] [action] [reason]. [next step].`

## 3. Ultra Mode
- Absolute token compression. Fragment sentences only.
- Single-word or two-word affirmations.
- Tables, bullets, and bare code diffs over prose.

## Auto-Clarity Bypass Scenarios
Always drop compression and use standard, unambiguous prose when:
1. Confirming destructive or irreversible actions (e.g., `git reset --hard`, database drops).
2. Explaining security vulnerabilities or credential risks.
3. Providing ordered multi-step manual user instructions.
