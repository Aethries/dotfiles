#!/usr/bin/env python3
"""
AI Developer Tooling & Agentic Workflow Provisioner.
Interactive grouped multi-select checkbox UI for Skills and MCP servers.
Supports toggling entire scopes/groups at once or individual items.
"""

import argparse
import curses
import json
import os
import re
import shutil
import subprocess
import sys
from pathlib import Path

# Terminal Colors
BLUE = "\033[1;34m"
GREEN = "\033[1;32m"
YELLOW = "\033[1;33m"
RED = "\033[1;31m"
CYAN = "\033[1;36m"
BOLD = "\033[1m"
RESET = "\033[0m"


def log(msg: str):
    print(f"\n{BLUE}==>{RESET} {BOLD}{msg}{RESET}")


def success(msg: str):
    print(f"{GREEN}✓{RESET} {msg}")


def warn(msg: str):
    print(f"{YELLOW}!{RESET} {msg}")


def error(msg: str, fatal: bool = True):
    print(f"{RED}✗{RESET} {msg}", file=sys.stderr)
    if fatal:
        sys.exit(1)


# Path Constants
SCRIPT_DIR = Path(__file__).resolve().parent
DOTFILES_DIR = SCRIPT_DIR.parent
AI_MODULE_DIR = DOTFILES_DIR / "modules" / "ai"
SKILLS_SRC_DIR = AI_MODULE_DIR / "files" / "skills"
HOME = Path.home()

# Catalog of Supported MCP Servers
MCP_CATALOG = {
    "codegraph": {
        "name": "CodeGraph (Tree-sitter AST & blast radius)",
        "anti": {
            "command": "uvx",
            "args": ["code-review-graph", "mcp"],
            "env": {},
        },
        "codex": {
            "command": "uvx",
            "args": ["code-review-graph", "mcp"],
        },
    },
    "codebase-memory": {
        "name": "Codebase Memory (AST symbols & relationships)",
        "anti": {
            "command": "uvx",
            "args": ["codebase-memory-mcp"],
            "env": {},
        },
        "codex": {
            "command": "uvx",
            "args": ["codebase-memory-mcp"],
        },
    },

    "context7": {
        "name": "Context7 (Upstash documentation lookup)",
        "anti": {
            "command": "npx",
            "args": ["-y", "@upstash/context7-mcp"],
        },
        "codex": {
            "command": "npx",
            "args": ["-y", "@upstash/context7-mcp"],
        },
    },
    "jira": {
        "name": "Jira Issue Tracker",
        "anti": {
            "command": "npx",
            "args": ["-y", "mcp-remote", "https://mcp.atlassian.com/v2/mcp"],
        },
        "codex": {
            "command": "npx",
            "args": ["-y", "jira-mcp"],
        },
    },
    "atlassian": {
        "name": "Atlassian MCP (Remote SSE)",
        "anti": {
            "url": "https://mcp.atlassian.com/v2/mcp",
        },
        "codex": {
            "url": "https://mcp.atlassian.com/v2/mcp",
        },
    },
    "jev-local": {
        "name": "JEV Local Advisory Preflight",
        "anti": {
            "command": "jev-mcp",
            "env": {
                "JEV_ENDPOINT": "http://localhost:20128/v1/systemone",
                "JEV_MODEL": "oc/jev-1.13-free",
            },
        },
        "codex": {
            "command": "jev-mcp",
            "startup_timeout_sec": 30.0,
            "env": {
                "JEV_ENDPOINT": "http://localhost:20128/v1/systemone",
                "JEV_MODEL": "oc/jev-1.13-free",
            },
        },
    },
    "9remote": {
        "name": "9Remote Gateway Proxy",
        "anti": {
            "url": "http://127.0.0.1:2208/mcp",
            "headers": {
                "Authorization": "Bearer a1a25b899f3364b59d26d16d9d5622f5c22af0e357563e377865723c2b039584"
            },
        },
        "codex": {
            "url": "http://127.0.0.1:2208/mcp",
            "http_headers": {
                "Authorization": "Bearer a1a25b899f3364b59d26d16d9d5622f5c22af0e357563e377865723c2b039584"
            },
            "env_http_headers": {
                "x-9remote-session": "NINE_REMOTE_SESSION_ID"
            },
        },
    },
}

MCP_CATEGORIES = [
    (
        "🔍 AST & Code Knowledge Graphs",
        ["codegraph", "codebase-memory"],
    ),
    (
        "🧠 Context & Persistent Memory",
        ["context7"],
    ),
    (
        "🌐 Gateways & Integrations",
        ["jira", "atlassian", "jev-local", "9remote"],
    ),
]

SKILL_CATEGORIES = [
    (
        "🎯 Core & Agent Workflow",
        [
            "ponytail", "caveman", "senior-implementer", "clean-code",
            "systematic-debugging", "verify-changes", "rtk", "plan-writing",
            "tdd-workflow", "lint-and-validate",
            "behavioral-modes", "brainstorming", "simplify-code", "skillify",
            "release-notes", "documentation-templates", "agent-squad-orchestrator",
            "parallel-agents", "coordinator-mode", "junior-coding-agent",
            "flow-learning-codebase", "app-builder"
        ],
    ),
    (
        "🏛️ Architecture & System Design",
        [
            "architecture-designer", "architecture-guardrails", "architecture",
            "domain-driven-design", "microservices-decomposition",
            "system-design-guardrails", "diagram-author", "migration-strategist",
            "tech-debt-strategist", "technical-planner", "technical-researcher",
            "feature-spec-writer", "prd-author", "agile-sprint-planner",
            "event-driven-architect", "transactional-outbox-pattern",
            "caching-strategy-architect"
        ],
    ),
    (
        "🔍 AST Knowledge Graph & Memory",
        [
            "codegraph", "codebase-memory", "code-review-graph",
            "context-compression", "memory-system", "rag-pipeline-architect"
        ],
    ),
    (
        "🎨 Frontend, UI & Design",
        [
            "ui-ux-pro-max", "frontend-design", "frontend-architecture",
            "design-spec", "design-system", "design", "pixel-perfect-ui",
            "tailwind-shadcn", "tailwind-patterns", "tanstack-query-state",
            "nextjs-app-router", "nextjs-react-expert", "web-design-guidelines",
            "slides", "banner-design", "brand", "mobile-design", "ui-styling"
        ],
    ),
    (
        "⚡ Backend, APIs & Distributed",
        [
            "nestjs", "nestjs-cqrs-microservices", "fastapi", "golang",
            "rust", "rust-pro", "python-patterns", "nodejs-best-practices",
            "trpc-fullstack", "grpc-protobuf-engineer", "api-contract-designer",
            "api-patterns", "centrifugo", "bullmq", "redis",
            "redis-distributed-patterns", "typesafe-ai"
        ],
    ),
    (
        "💾 Database & Data Modeling",
        [
            "database-design", "data-model-architect", "database-query-optimizer",
            "postgresql", "prisma"
        ],
    ),
    (
        "☁️ Cloud, DevOps & Infrastructure",
        [
            "docker", "docker-multiarch-builder", "kubernetes",
            "helm-chart-architect", "gitops-terraform", "cloud-infra",
            "aws-cloud-architect", "gcp-cloud-architect", "azure-cloud-architect",
            "github-actions", "cicd-security-hardening", "linux-server-admin",
            "vps-hardening", "nixos", "opentelemetry-tracing",
            "reliability-engineer", "incident-investigator"
        ],
    ),
    (
        "🛡️ Security & Auditing",
        [
            "security-guardrails", "api-security-auditor",
            "prompt-injection-defense", "vulnerability-scanner", "red-team-tactics"
        ],
    ),
    (
        "🧪 Testing & Verification",
        [
            "qa-test-flow-engineer", "unit-test-craftsman", "playwright",
            "webapp-testing", "testing-patterns", "eval-harness-designer",
            "engineering-review", "quality-gate", "source-quality",
            "project-source-quality"
        ],
    ),
    (
        "🛠️ System, Shell & Tooling",
        [
            "shell-scripting", "bash-linux", "powershell-windows",
            "neovim-lua", "git-advanced-workflow", "chrome-extension",
            "chrome-extension-advanced", "godot-gdscript", "game-development",
            "mcp-server-author", "mcp-builder", "skill-author",
            "detect-stack", "project-context", "batch-operations",
            "geo-fundamentals", "seo-fundamentals", "server-management",
            "i18n-localization", "performance-profiling", "intelligent-routing"
        ],
    ),
    (
        "🧬 Life Sciences & GCP Data",
        [
            "uniprot-database", "pdb-database", "pubchem-database", "pubmed-database",
            "reactome-database", "quickgo-database", "string-database",
            "jaspar-database", "unibind-database", "dbsnp-database",
            "clinvar-database", "ensembl-database", "gtex-database",
            "human-protein-atlas-database", "interpro-database", "openfda-database",
            "opentargets-database", "chembl-database", "clinical-trials-database",
            "encode-ccres-database", "literature-search-arxiv",
            "literature-search-biorxiv", "literature-search-europepmc",
            "alphafold-database-fetch-and-analyze",
            "alphagenome-variant-impact-score", "foldseek-structural-search",
            "ncbi-sequence-fetch", "predictingthepast", "pymol",
            "ucsc-conservation-and-tfbs", "uv", "credentials", "bigquery-ai-ml",
            "bigquery-bigframes", "bigquery-graph", "bigquery-sql", "dbt-bigquery",
            "data-autocleaning", "enforcing-resource-attribution",
            "gcp-composer-troubleshooting", "gcp-data-pipelines",
            "gcp-managed-airflow-migrations", "gcp-managed-airflow-recommendations",
            "google-cloud-auth-verification"
        ],
    ),
]


def get_all_available_skills() -> dict[str, str]:
    if not SKILLS_SRC_DIR.exists():
        return {}
    skills = {}
    for item in sorted(SKILLS_SRC_DIR.iterdir()):
        if item.is_dir() and (item / "SKILL.md").exists():
            desc = ""
            with open(item / "SKILL.md", encoding="utf-8", errors="ignore") as f:
                for line in f:
                    if line.startswith("description:"):
                        desc = line.split(":", 1)[1].strip().strip("\"'")
                        break
            skills[item.name] = desc
    return skills


def build_grouped_skills_data() -> list[dict]:
    avail_skills = get_all_available_skills()
    accounted = set()
    groups = []

    for title, skill_list in SKILL_CATEGORIES:
        items = []
        for s in skill_list:
            if s in avail_skills:
                items.append({
                    "id": s,
                    "name": s,
                    "desc": avail_skills[s],
                })
                accounted.add(s)
        if items:
            groups.append({
                "title": title,
                "items": items,
            })

    # Catch-all for any unlisted skills
    unaccounted = [s for s in sorted(avail_skills.keys()) if s not in accounted]
    if unaccounted:
        items = [{
            "id": s,
            "name": s,
            "desc": avail_skills[s],
        } for s in unaccounted]
        groups.append({
            "title": "📁 Other Skills",
            "items": items,
        })

    return groups


def build_grouped_mcps_data() -> list[dict]:
    groups = []
    for title, mcp_list in MCP_CATEGORIES:
        items = []
        for m in mcp_list:
            if m in MCP_CATALOG:
                items.append({
                    "id": m,
                    "name": m,
                    "desc": MCP_CATALOG[m]["name"],
                })
        if items:
            groups.append({
                "title": title,
                "items": items,
            })
    return groups


def safe_symlink(source: Path, target: Path) -> bool:
    if not source.exists() and not source.is_symlink():
        err(f"Source does not exist: {source}")
        return False
    target.parent.mkdir(parents=True, exist_ok=True)
    if target.is_symlink():
        try:
            if target.resolve() == source.resolve():
                return True
        except Exception:
            pass
        target.unlink()
    elif target.exists():
        backup = target.with_name(f"{target.name}.backup")
        if backup.exists() or backup.is_symlink():
            import time
            ts = time.strftime("%Y%m%d%H%M%S")
            backup = target.with_name(f"{target.name}.backup.{ts}")
            counter = 1
            while backup.exists() or backup.is_symlink():
                backup = target.with_name(f"{target.name}.backup.{ts}_{counter}")
                counter += 1
        target.rename(backup)
        warn(f"Moved existing {target} to {backup}")

    try:
        target.symlink_to(source)
        return True
    except Exception as e:
        err(f"Failed to symlink {source} -> {target}: {e}")
        if 'backup' in locals() and backup.exists():
            backup.rename(target)
        return False


def prompt_menu(title: str, options: list[tuple[str, str]], default_idx: int = 0) -> str:
    print(f"\n{CYAN}{BOLD}{title}{RESET}")
    for idx, (key, label) in enumerate(options, 1):
        def_mark = f" {GREEN}(default){RESET}" if (idx - 1) == default_idx else ""
        print(f"  [{idx}] {label}{def_mark}")

    while True:
        choice = input(f"Select option [1-{len(options)}] (default: {default_idx + 1}): ").strip()
        if not choice:
            return options[default_idx][0]
        if choice.isdigit():
            c = int(choice)
            if 1 <= c <= len(options):
                return options[c - 1][0]
        print(f"{RED}Invalid selection. Please choose 1-{len(options)}.{RESET}")


# ------------------------------------------------------------------------------
# Interactive Grouped Checkbox TUI (Curses & Text Fallback)
# ------------------------------------------------------------------------------

def curses_checkbox_ui(stdscr, title: str, groups: list[dict], selected_set: set[str]) -> set[str]:
    curses.curs_set(0)
    stdscr.clear()

    # Color initialization
    curses.start_color()
    curses.use_default_colors()
    curses.init_pair(1, curses.COLOR_CYAN, -1)     # Group header
    curses.init_pair(2, curses.COLOR_GREEN, -1)    # Checkbox checked
    curses.init_pair(3, curses.COLOR_WHITE, -1)    # Item text
    curses.init_pair(4, curses.COLOR_BLACK, curses.COLOR_CYAN)  # Highlighted bar
    curses.init_pair(5, curses.COLOR_YELLOW, -1)   # Partial group checkbox

    # Flatten entries: list of tuples (type, group_idx, item_idx_or_None)
    def build_rows():
        rows = []
        for g_idx, g in enumerate(groups):
            rows.append(("group", g_idx, None))
            for i_idx, _ in enumerate(g["items"]):
                rows.append(("item", g_idx, i_idx))
        return rows

    rows = build_rows()
    cursor_idx = 0
    scroll_offset = 0

    while True:
        h, w = stdscr.getmaxyx()
        stdscr.erase()

        # Header info (top 2 lines)
        header_text = f" {title} "
        stdscr.addstr(0, 0, header_text.ljust(w - 1)[: w - 1], curses.A_REVERSE | curses.A_BOLD)
        help_bar = " [SPACE]: Toggle | [a]: Toggle Scope/Group | [A]: Toggle All | [ENTER]: Confirm | [q]: Quit"
        stdscr.addstr(1, 0, help_bar.ljust(w - 1)[: w - 1], curses.A_DIM)

        usable_height = h - 3  # reserve top 2 lines and bottom status bar

        # Adjust scroll offset
        if cursor_idx < scroll_offset:
            scroll_offset = cursor_idx
        elif cursor_idx >= scroll_offset + usable_height:
            scroll_offset = cursor_idx - usable_height + 1

        # Render list items
        for line_no in range(usable_height):
            r_idx = scroll_offset + line_no
            if r_idx >= len(rows):
                break

            r_type, g_idx, i_idx = rows[r_idx]
            g = groups[g_idx]
            is_active = (r_idx == cursor_idx)

            y = line_no + 2
            x = 0

            if r_type == "group":
                # Compute group selection state
                g_items = g["items"]
                sel_count = sum(1 for item in g_items if item["id"] in selected_set)
                total_count = len(g_items)

                if sel_count == total_count and total_count > 0:
                    box_str = "[x]"
                    box_color = curses.color_pair(2) | curses.A_BOLD
                elif sel_count > 0:
                    box_str = "[-]"
                    box_color = curses.color_pair(5) | curses.A_BOLD
                else:
                    box_str = "[ ]"
                    box_color = curses.A_DIM

                title_line = f" {box_str} {g['title']} ({sel_count}/{total_count})"
                if is_active:
                    stdscr.addstr(y, 0, title_line.ljust(w - 1)[: w - 1], curses.color_pair(4) | curses.A_BOLD)
                else:
                    stdscr.addstr(y, 0, " ")
                    stdscr.addstr(box_str, box_color)
                    stdscr.addstr(f" {g['title']} ({sel_count}/{total_count})"[: w - 6], curses.color_pair(1) | curses.A_BOLD)

            else:  # item
                item = g["items"][i_idx]
                is_sel = item["id"] in selected_set
                box_str = "[x]" if is_sel else "[ ]"
                box_color = curses.color_pair(2) | curses.A_BOLD if is_sel else curses.A_DIM

                desc_short = f" - {item['desc']}" if item["desc"] else ""
                item_line = f"     {box_str} {item['name']}{desc_short}"

                if is_active:
                    stdscr.addstr(y, 0, item_line.ljust(w - 1)[: w - 1], curses.color_pair(4))
                else:
                    stdscr.addstr(y, 0, "     ")
                    stdscr.addstr(box_str, box_color)
                    stdscr.addstr(f" {item['name']}{desc_short}"[: w - 9], curses.color_pair(3))

        # Bottom status bar
        total_selected = len(selected_set)
        total_available = sum(len(g["items"]) for g in groups)
        status_text = f" Total Selected: {total_selected}/{total_available} | Press [ENTER] when done "
        stdscr.addstr(h - 1, 0, status_text.ljust(w - 1)[: w - 1], curses.A_REVERSE)

        stdscr.refresh()

        key = stdscr.getch()

        if key in (curses.KEY_UP, ord("k")):
            if cursor_idx > 0:
                cursor_idx -= 1
        elif key in (curses.KEY_DOWN, ord("j")):
            if cursor_idx < len(rows) - 1:
                cursor_idx += 1
        elif key in (curses.KEY_PPAGE,):
            cursor_idx = max(0, cursor_idx - usable_height)
        elif key in (curses.KEY_NPAGE,):
            cursor_idx = min(len(rows) - 1, cursor_idx + usable_height)
        elif key == ord(" "):  # Space: toggle current item or group
            r_type, g_idx, i_idx = rows[cursor_idx]
            g = groups[g_idx]
            if r_type == "group":
                # Toggle entire group
                g_items = g["items"]
                all_sel = all(it["id"] in selected_set for it in g_items)
                if all_sel:
                    for it in g_items:
                        selected_set.discard(it["id"])
                else:
                    for it in g_items:
                        selected_set.add(it["id"])
            else:
                item_id = g["items"][i_idx]["id"]
                if item_id in selected_set:
                    selected_set.discard(item_id)
                else:
                    selected_set.add(item_id)
        elif key == ord("a"):  # Toggle whole group under cursor
            r_type, g_idx, _ = rows[cursor_idx]
            g = groups[g_idx]
            g_items = g["items"]
            all_sel = all(it["id"] in selected_set for it in g_items)
            if all_sel:
                for it in g_items:
                    selected_set.discard(it["id"])
            else:
                for it in g_items:
                    selected_set.add(it["id"])
        elif key == ord("A"):  # Toggle EVERYTHING
            total_items = [it["id"] for g in groups for it in g["items"]]
            if len(selected_set) == len(total_items):
                selected_set.clear()
            else:
                selected_set.update(total_items)
        elif key in (10, 13, curses.KEY_ENTER):  # Enter: confirm
            break
        elif key in (ord("q"), ord("Q"), 27):  # Quit / cancel
            print("\nOperation cancelled by user.")
            sys.exit(0)

    return selected_set


def fallback_text_checkbox_ui(title: str, groups: list[dict], selected_set: set[str]) -> set[str]:
    print(f"\n{BOLD}{CYAN}=== {title} ==={RESET}")
    print("Controls:")
    print("  • Enter scope number (e.g. '1', '4') to toggle that whole scope")
    print("  • Enter item index (e.g. '1.3', '4.2') or exact ID to toggle single item")
    print("  • Enter 'all' or 'none' to select/deselect everything")
    print("  • Enter 'done' (or press Enter) to confirm selection\n")

    id_to_group = {}
    index_to_item = {}

    for g_idx, g in enumerate(groups, 1):
        for i_idx, item in enumerate(g["items"], 1):
            id_to_group[item["id"]] = g
            index_to_item[f"{g_idx}.{i_idx}"] = item["id"]

    while True:
        print(f"\n{BOLD}{title}:{RESET}")
        for g_idx, g in enumerate(groups, 1):
            g_items = g["items"]
            sel_count = sum(1 for it in g_items if it["id"] in selected_set)
            total = len(g_items)
            box = "[x]" if sel_count == total and total > 0 else ("[-]" if sel_count > 0 else "[ ]")
            print(f"  {BOLD}[{g_idx}] {box} {g['title']} ({sel_count}/{total}){RESET}")
            for i_idx, it in enumerate(g_items, 1):
                ibox = f"{GREEN}[x]{RESET}" if it["id"] in selected_set else "[ ]"
                desc_short = f" ({it['desc'][:50]}...)" if it["desc"] else ""
                print(f"      {g_idx}.{i_idx} {ibox} {it['name']}{desc_short}")

        total_sel = len(selected_set)
        total_avail = sum(len(g["items"]) for g in groups)
        prompt = input(f"\n[Selected {total_sel}/{total_avail}] Action (scope#/item#/all/none/done) [default: done]: ").strip()

        if not prompt or prompt.lower() in ("done", "d", "ok", "confirm"):
            break
        elif prompt.lower() == "all":
            selected_set = {it["id"] for g in groups for it in g["items"]}
        elif prompt.lower() == "none":
            selected_set.clear()
        elif prompt.isdigit():  # Scope number
            g_num = int(prompt)
            if 1 <= g_num <= len(groups):
                g = groups[g_num - 1]
                all_sel = all(it["id"] in selected_set for it in g["items"])
                if all_sel:
                    for it in g["items"]:
                        selected_set.discard(it["id"])
                else:
                    for it in g["items"]:
                        selected_set.add(it["id"])
            else:
                warn("Scope number out of range.")
        elif prompt in index_to_item:
            target_id = index_to_item[prompt]
            if target_id in selected_set:
                selected_set.discard(target_id)
            else:
                selected_set.add(target_id)
        elif prompt in id_to_group:
            if prompt in selected_set:
                selected_set.discard(prompt)
            else:
                selected_set.add(prompt)
        else:
            # Check comma separated
            tokens = [t.strip() for t in prompt.split(",") if t.strip()]
            for t in tokens:
                if t in index_to_item:
                    selected_set.symmetric_difference_update({index_to_item[t]})
                elif t in id_to_group:
                    selected_set.symmetric_difference_update({t})
                elif t.isdigit() and 1 <= int(t) <= len(groups):
                    g = groups[int(t) - 1]
                    for it in g["items"]:
                        selected_set.add(it["id"])

    return selected_set


def run_grouped_selection(title: str, groups: list[dict], default_all: bool = True) -> list[str]:
    all_ids = {it["id"] for g in groups for it in g["items"]}
    selected_set = set(all_ids) if default_all else set()

    # Try curses interactive interface first if TTY is attached
    if sys.stdin.isatty() and os.environ.get("TERM", "") != "dumb":
        try:
            res = curses.wrapper(curses_checkbox_ui, title, groups, selected_set)
            return sorted(list(res))
        except Exception:
            # Fall back to text prompt if terminal doesn't support curses properly
            pass

    res = fallback_text_checkbox_ui(title, groups, selected_set)
    return sorted(list(res))


# ------------------------------------------------------------------------------
# Deployment Logic
# ------------------------------------------------------------------------------

def deploy_skills(scope: str, agent: str, skills: list[str], project_dir: Path):
    if not skills:
        warn("No skills selected to link.")
        return

    destinations: list[Path] = []
    if scope == "global":
        if agent in ("both", "anti"):
            destinations.extend([
                HOME / ".gemini" / "config" / "skills",
                HOME / ".gemini" / "antigravity-cli" / "skills",
                HOME / ".gemini" / "antigravity" / "skills",
            ])
        if agent in ("both", "codex"):
            destinations.append(HOME / ".codex" / "skills")
    else:  # project
        destinations.append(project_dir / ".agents" / "skills")

    for dest in destinations:
        dest.mkdir(parents=True, exist_ok=True)
        # Prune dangling symlinks
        for item in dest.iterdir():
            if item.is_symlink() and not item.exists():
                item.unlink()

        for skill in skills:
            src = SKILLS_SRC_DIR / skill
            if src.exists():
                safe_symlink(src, dest / skill)

    success(f"Linked {len(skills)} skills into {len(destinations)} destination(s)")


def merge_codex_toml(existing_toml: str, new_mcp_content: str, managed_keys: set[str]) -> str:
    """
    Merge new managed MCP server configurations into existing Codex config.toml.
    Preserves:
    - Top-level settings (model, approval policies, etc.)
    - Non-MCP sections ([tui], [desktop], [features], [projects], etc.)
    - Custom / non-managed [mcp_servers."..."] sections
    """
    if not existing_toml.strip():
        return f"# Codex Configuration\n{new_mcp_content}\n"

    lines = existing_toml.splitlines(keepends=True)
    sections: list[tuple[str | None, str]] = []
    current_header: str | None = None
    current_chunk: list[str] = []

    for line in lines:
        m = re.match(r"^\s*\[([a-zA-Z0-9_.\"-]+)\]", line)
        if m:
            sections.append((current_header, "".join(current_chunk)))
            current_header = m.group(1)
            current_chunk = [line]
        else:
            current_chunk.append(line)
    sections.append((current_header, "".join(current_chunk)))

    re_mcp = re.compile(r'^mcp_servers\."([^"]+)"')
    kept_sections: list[tuple[str | None, str]] = []
    first_mcp_index = -1

    for header, content in sections:
        if header is None:
            kept_sections.append((header, content))
            continue
        m_mcp = re_mcp.match(header)
        if m_mcp:
            server_key = m_mcp.group(1)
            if server_key in managed_keys:
                if first_mcp_index == -1:
                    first_mcp_index = len(kept_sections)
                continue
            else:
                if first_mcp_index == -1:
                    first_mcp_index = len(kept_sections)
                kept_sections.append((header, content))
        else:
            kept_sections.append((header, content))

    clean_new_mcp = ("\n" + new_mcp_content.strip() + "\n\n") if new_mcp_content.strip() else ""
    insert_at = first_mcp_index if first_mcp_index != -1 else min(1, len(kept_sections))

    result_parts: list[str] = []
    for i, (_, content) in enumerate(kept_sections):
        if i == insert_at and clean_new_mcp:
            result_parts.append(clean_new_mcp)
        result_parts.append(content)
    if insert_at >= len(kept_sections) and clean_new_mcp:
        result_parts.append(clean_new_mcp)

    return "".join(result_parts).rstrip() + "\n"


def deploy_mcps(scope: str, agent: str, mcps: list[str], project_dir: Path):
    if not mcps:
        warn("No MCP servers selected.")
        return

    # 1. Antigravity MCP Config
    if agent in ("both", "anti"):
        anti_servers = {}
        for m in mcps:
            cfg = MCP_CATALOG.get(m, {}).get("anti")
            if cfg:
                anti_servers[m] = cfg

        if scope == "global":
            anti_payload = {"mcpServers": anti_servers}
            anti_paths = [
                HOME / ".gemini" / "antigravity" / "mcp_config.json",
                HOME / ".gemini" / "antigravity-cli" / "mcp_config.json",
                HOME / ".gemini" / "config" / "mcp_config.json",
            ]
            module_anti_file = DOTFILES_DIR / "modules" / "antigravity" / "files" / "mcp_config.json"
            module_anti_file.parent.mkdir(parents=True, exist_ok=True)
            with open(module_anti_file, "w") as f:
                json.dump(anti_payload, f, indent=2)

            for p in anti_paths:
                safe_symlink(module_anti_file, p)
            success(f"Updated Antigravity MCP config ({len(anti_servers)} servers)")
        else:
            proj_gemini = project_dir / ".gemini" / "mcp_config.json"
            proj_gemini.parent.mkdir(parents=True, exist_ok=True)
            existing_anti = {}
            if proj_gemini.exists():
                try:
                    with open(proj_gemini, "r") as f:
                        existing_anti = json.load(f)
                except Exception:
                    existing_anti = {}
            if "mcpServers" not in existing_anti or not isinstance(existing_anti.get("mcpServers"), dict):
                existing_anti["mcpServers"] = {}
            existing_anti["mcpServers"].update(anti_servers)
            with open(proj_gemini, "w") as f:
                json.dump(existing_anti, f, indent=2)
            success(f"Configured project Antigravity MCP: {proj_gemini}")

    # 2. Codex MCP Config
    if agent in ("both", "codex"):
        codex_lines = []
        for m in mcps:
            cfg = MCP_CATALOG.get(m, {}).get("codex")
            if not cfg:
                continue
            toml_key = m.replace("-", "_")
            codex_lines.append(f'\n[mcp_servers."{toml_key}"]')
            if "command" in cfg:
                codex_lines.append(f'command = "{cfg["command"]}"')
            if "args" in cfg:
                args_str = json.dumps(cfg["args"])
                codex_lines.append(f"args = {args_str}")
            if "url" in cfg:
                codex_lines.append(f'url = "{cfg["url"]}"')
            if "startup_timeout_sec" in cfg:
                codex_lines.append(f'startup_timeout_sec = {cfg["startup_timeout_sec"]}')
            if "env" in cfg:
                codex_lines.append(f'[mcp_servers."{toml_key}".env]')
                for ek, ev in cfg["env"].items():
                    codex_lines.append(f'{ek} = "{ev}"')
            if "http_headers" in cfg:
                codex_lines.append(f'[mcp_servers."{toml_key}".http_headers]')
                for hk, hv in cfg["http_headers"].items():
                    codex_lines.append(f'{hk} = "{hv}"')
            if "env_http_headers" in cfg:
                codex_lines.append(f'[mcp_servers."{toml_key}".env_http_headers]')
                for ehk, ehv in cfg["env_http_headers"].items():
                    codex_lines.append(f'"{ehk}" = "{ehv}"')

        mcp_toml_content = "\n".join(codex_lines)
        managed_toml_keys = {m.replace("-", "_") for m in mcps}

        if scope == "global":
            codex_config_file = DOTFILES_DIR / "modules" / "codex" / "files" / "config.toml"
            if codex_config_file.exists():
                existing = codex_config_file.read_text()
                new_config = merge_codex_toml(existing, mcp_toml_content, managed_toml_keys)
                codex_config_file.write_text(new_config)
                safe_symlink(codex_config_file, HOME / ".codex" / "config.toml")
                success(f"Updated Codex config with {len(mcps)} MCP servers")
        else:
            proj_codex = project_dir / ".codex" / "config.toml"
            proj_codex.parent.mkdir(parents=True, exist_ok=True)
            existing = proj_codex.read_text() if proj_codex.exists() else ""
            new_config = merge_codex_toml(existing, mcp_toml_content, managed_toml_keys)
            proj_codex.write_text(new_config)
            success(f"Configured project Codex MCP: {proj_codex}")


def deploy_utilities():
    local_bin = HOME / ".local" / "bin"
    local_bin.mkdir(parents=True, exist_ok=True)

    rtk_src = DOTFILES_DIR / "modules" / "shell" / "files" / "bin" / "rtk"
    if rtk_src.exists():
        rtk_src.chmod(0o755)
        safe_symlink(rtk_src, local_bin / "rtk")

    jev_src = DOTFILES_DIR / "scripts" / "jev-mcp.sh"
    if jev_src.exists():
        jev_src.chmod(0o755)
        safe_symlink(jev_src, local_bin / "jev-mcp")

    success("Linked RTK Ultra & JEV MCP utilities to ~/.local/bin")


# ------------------------------------------------------------------------------
# Main Entry Point
# ------------------------------------------------------------------------------

def main():
    parser = argparse.ArgumentParser(
        description="AI Developer Tooling & Agentic Workflow Provisioner"
    )
    parser.add_argument(
        "--scope",
        choices=["global", "project"],
        help="Target scope: global workstation or current project",
    )
    parser.add_argument(
        "--agent",
        choices=["both", "anti", "codex"],
        help="Target agent: both, anti (Antigravity), or codex",
    )
    parser.add_argument(
        "--skills",
        help="Skills to install: 'all', 'core', 'none', or comma-separated list",
    )
    parser.add_argument(
        "--mcps",
        help="MCP servers to install: 'all', 'none', or comma-separated list",
    )
    parser.add_argument(
        "--project-dir",
        default=str(Path.cwd()),
        help="Target project directory for project scope",
    )
    parser.add_argument(
        "-y",
        "--yes",
        "--all",
        action="store_true",
        help="Automated unattended mode: global, both agents, all skills, all MCPs",
    )

    args = parser.parse_args()
    project_dir = Path(args.project_dir).resolve()

    grouped_skills = build_grouped_skills_data()
    grouped_mcps = build_grouped_mcps_data()

    all_skill_ids = [it["id"] for g in grouped_skills for it in g["items"]]
    all_mcp_ids = [it["id"] for g in grouped_mcps for it in g["items"]]

    # Parameter Resolution
    if args.yes:
        scope = "global"
        agent = "both"
        selected_skills = all_skill_ids
        selected_mcps = all_mcp_ids
    elif any([args.scope, args.agent, args.skills, args.mcps]):
        scope = args.scope or "global"
        agent = args.agent or "both"

        if not args.skills or args.skills == "all":
            selected_skills = all_skill_ids
        elif args.skills == "none":
            selected_skills = []
        else:
            wanted = [x.strip() for x in args.skills.split(",") if x.strip()]
            selected_skills = [s for s in wanted if s in all_skill_ids]

        if not args.mcps or args.mcps == "all":
            selected_mcps = all_mcp_ids
        elif args.mcps == "none":
            selected_mcps = []
        else:
            wanted = [x.strip() for x in args.mcps.split(",") if x.strip()]
            selected_mcps = [m for m in wanted if m in all_mcp_ids]
    else:
        # Step 1: Scope
        scope = prompt_menu(
            "1. Select Target Scope",
            [
                ("global", "Global Workstation (~/.gemini, ~/.codex, ~/.local/bin)"),
                ("project", f"Project Local ({os.getcwd()})"),
            ],
            default_idx=0,
        )

        # Step 2: Agent
        agent = prompt_menu(
            "2. Select Target AI Agents",
            [
                ("both", "Both Antigravity & Codex"),
                ("anti", "Google Antigravity only"),
                ("codex", "OpenAI Codex only"),
            ],
            default_idx=0,
        )

        # Step 3: Interactive Grouped Checkbox for Skills
        selected_skills = run_grouped_selection(
            "Select AI Skills by Scope (SPACE: toggle item, a: toggle scope, ENTER: confirm)",
            grouped_skills,
            default_all=True,
        )

        # Step 4: Interactive Grouped Checkbox for MCP Servers
        selected_mcps = run_grouped_selection(
            "Select MCP Servers by Scope (SPACE: toggle item, a: toggle scope, ENTER: confirm)",
            grouped_mcps,
            default_all=True,
        )

    log(f"Executing AI Provisioning [Scope: {scope.upper()} | Agent: {agent.upper()}]")
    print(f"  • Selected Skills: {len(selected_skills)} skills")
    print(f"  • Selected MCPs:   {', '.join(selected_mcps) if selected_mcps else 'none'}")
    if scope == "project":
        print(f"  • Target Project:  {project_dir}")

    # 1. Deploy Skills
    log("1. Deploying AI Skills")
    deploy_skills(scope, agent, selected_skills, project_dir)

    # 2. Deploy MCP Servers
    log("2. Configuring MCP Servers")
    deploy_mcps(scope, agent, selected_mcps, project_dir)

    # 3. Setup utilities & settings
    if scope == "global":
        log("3. Linking AI Utilities & Theme Synchronization")
        deploy_utilities()

        if agent in ("both", "anti"):
            anti_setup = DOTFILES_DIR / "modules" / "antigravity" / "setup.sh"
            if anti_setup.exists():
                subprocess.run(["bash", str(anti_setup)], check=True)

        if agent in ("both", "codex"):
            codex_setup = DOTFILES_DIR / "modules" / "codex" / "setup.sh"
            if codex_setup.exists():
                subprocess.run(["bash", str(codex_setup)], check=True)

    success(f"AI Tooling setup completed successfully! ({scope.upper()} mode)")


if __name__ == "__main__":
    main()
