---
name: skill-author
description: "Author, standardize, and package new AI agent skills for the dotfiles ecosystem. Use when asked to create a new skill, write a SKILL.md, or convert guidelines into an agent skill package."
---

# Skill Author

Standardizes the authoring, packaging, and validation of canonical agent skills within the dotfiles repository.

## Core Rules

1. **Scope Decision & Discovery First**:
   - Before authoring any skill, search canonical and trusted sources: `ai-skills search <term>`.
   - Strictly follow the triage ladder: **Reuse existing** > **Extend existing** > **Create new**.
   - Verify semantic uniqueness via `curate.sh dedup` (Jaccard threshold <0.70) to prevent domain/capability bloat.
2. **Enhance Raw Requirements & English Rewrite**:
   - Transform ambiguous user notes or raw prompt instructions into crisp, professional, English-first rules.
   - Disambiguate trigger boundaries: clearly state WHEN to activate and WHEN NOT to activate.
   - Guardrail skills must begin with `Internal guardrail:` to prevent spurious auto-triggering on generic user prompts.
3. **Strict YAML Frontmatter Schema**:
   Every skill must begin with standard YAML frontmatter:
   ```yaml
   ---
   name: <kebab-case-name>
   description: "<Clear, disambiguated triggering condition and role summary>"
   ---
   ```
4. **Progressive Disclosure & Token Economy**:
   - Keep `SKILL.md` dense and actionable (under 400 words).
   - Place detailed checklists, schemas, and extended guides in `references/*.md`.
   - Place deterministic automation scripts in `scripts/*.sh`.
5. **Registry, Profile Registration & Installation**:
   - Compute hash and register in `resources/skills/_registry.json` with capabilities, triggers, and provenance.
   - Assign to appropriate profile in `resources/skills/_profiles.json`.
   - Propagate globally (`ai-skills sync`) or install into project (`ai-skills add <name> --project`).
