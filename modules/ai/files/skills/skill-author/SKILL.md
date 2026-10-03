---
name: skill-author
description: "Author, standardize, and package new AI agent skills for the dotfiles ecosystem. Use when asked to create a new skill, write a SKILL.md, or convert guidelines into an agent skill package."
---

# Skill Author

Standardizes the authoring, packaging, and validation of canonical agent skills within the dotfiles repository.

## Core Rules

1. **Required Triage & Discovery Workflow**:
   - **Understand Raw Requirement**: Analyze user needs and identify required capabilities.
   - **Decide Scope**: Determine whether skill belongs in Global agent config, Dotfiles canonical library, or Project-local `.agents/skills`.
   - **Local Search First**: Query local skills via `ai-skills search <term>`.
   - **Discover Trusted Sources**: If not found locally, query trusted catalogs: `ai-skills discover <term>`.
   - **Resolve Original Upstream**: Verify first-party vendor or official upstream repository (catalog != upstream).
   - **Inspect & Security Review**: Audit candidate files for security and malicious patterns via `curate.sh audit`.
   - **Metadata Overlap & Semantic Review**: Perform deep semantic comparison against existing skills. Classify relationship: `KEEP_BOTH`, `PARTIAL_OVERLAP`, `DUPLICATE`, `SUPERSEDES`, or `CONFLICT`.
   - **Select Action**: Determine action from **REUSE** (stop and reuse existing), **EXTEND**, **COMPANION**, **CREATE**, or **REPLACE**.
   - **Stop on Duplicate**: When existing skill suffices, explicitly state: "Do not create a new skill. Reuse existing <name>."
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
