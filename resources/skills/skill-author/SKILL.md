---
name: skill-author
description: "Author, standardize, and package new AI agent skills for the dotfiles ecosystem. Use when asked to create a new skill, write a SKILL.md, or convert guidelines into an agent skill package."
---

# Skill Author

Standardizes the authoring, packaging, and validation of canonical agent skills within the dotfiles repository.

## Core Rules

1. **Strict YAML Frontmatter Schema**:
   Every skill must begin with standard YAML frontmatter:
   ```yaml
   ---
   name: <kebab-case-name>
   description: "<Clear, disambiguated triggering condition and role summary>"
   ---
   ```
2. **Disambiguated Trigger Boundaries**:
   - Write descriptions that trigger ONLY on appropriate user intents.
   - Guardrail skills must begin with `Internal guardrail:` to prevent aggressive auto-triggering on generic user prompts.
3. **Progressive Disclosure & Token Economy**:
   - Keep `SKILL.md` dense and actionable (under 400 words).
   - Place detailed templates, schemas, and extended guides in `references/*.md`.
   - Place deterministic automation scripts in `scripts/*.sh`.
4. **Registry & Profile Registration**:
   - Register new skills in `resources/skills/_registry.json` with computed content hash, version, and dependencies.
   - Assign new skills to appropriate profiles in `resources/skills/_profiles.json`.
   - Run `ai-skills sync` to propagate symlinks to all configured agents.
