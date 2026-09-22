---
name: git-advanced-workflow
description: "Advanced Git workflows: Git worktrees for concurrent branch development, interactive rebase surgery, automated git bisect scripts, sparse checkouts, and clean linear commit hygiene. Use when performing complex Git operations or managing large repositories."
---

# Advanced Git Workflows & Repository Hygiene

Engineering standards for friction-free local branch management, history manipulation, and repository navigation.

## Core Rules

1. **Git Worktrees for Parallel Work**:
   - Never stash or discard uncommitted changes to switch branches. Use Git worktrees to maintain multiple working directories linked to the same `.git` repository:
     ```bash
     git worktree add ../feature-branch feature-branch
     git worktree list
     git worktree remove ../feature-branch
     ```

2. **Interactive Rebase Surgery (`git rebase -i`)**:
   - Keep pull request commit histories clean and atomic:
     - Squash trivial typo/fixup commits (`fixup!` commits with `git rebase -i --autosquash`).
     - Reorder or split monolithic commits into cohesive logical steps.
   - Never rebase commits that have already been merged into primary release branches (`main`, `master`).

3. **Automated Bisecting**:
   - Automate regression root-cause identification using `git bisect run`:
     ```bash
     git bisect start HEAD v1.0.0
     git bisect run ./scripts/run-test.sh
     git bisect reset
     ```

4. **Sparse Checkout & Shallow Clones**:
   - For massive monorepos, use sparse checkouts (`git sparse-checkout set <subfolder>`) and partial clones (`--filter=blob:none`) to eliminate unnecessary disk bloat and network transfer overhead.
