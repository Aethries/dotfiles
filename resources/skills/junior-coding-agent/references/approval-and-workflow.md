# Approval and Workflow Reference

Use this file when a task touches Git, GitHub, configs, dependencies, package management, CI, Docker, or project workflow.

## Permission model

A normal coding request such as "fix this bug" or "fix lint in this file" gives permission to:
- read the repository;
- read GitHub context;
- edit source files inside the task scope;
- edit directly related tests;
- run existing safe checks such as lint, typecheck, tests, and build.

It does not give permission to:
- change branches;
- commit or push;
- open or merge a PR;
- create, close, edit, relabel, or move GitHub issues;
- change Project fields or milestones;
- change config or project rules;
- install/remove/upgrade packages;
- change package manager or lockfile;
- run destructive commands;
- expand the task into unrelated cleanup.

The user's explicit request can grant any of these permissions. Do not ask again for an action already clearly approved in the same task.

## Default branch rule

If code must change while on the default branch, stop before editing and ask to create or switch to a task branch.

Suggested names:
- issue bug: `fix/<issue-number>-<short-slug>`
- issue feature: `feat/<issue-number>-<short-slug>`
- no issue bug: `fix/<short-slug>`
- no issue feature: `feat/<short-slug>`
- maintenance: `chore/<short-slug>`

Do not create a branch only to look busy. Use an existing clearly related task branch when safe.

## GitHub context rule

Use `gh` read commands freely when the repository is on GitHub.

For a named bug or feature with no issue number:
1. Search open issues using a few clear keywords.
2. Prefer exact or strongly related matches.
3. Read the issue before assuming it is the same task.
4. If one issue clearly matches, use it as context.
5. If several different issues match, ask the user which one matters.
6. If none match, do not create one without approval.

## Issue and PR lifecycle

When approved to implement an issue:
1. Read the issue and its relevant Project/milestone context.
2. Work only within its scope.
3. Verify the code.
4. Ask for commit approval unless commit was already requested.
5. Ask for push/PR approval unless already requested.
6. When creating the PR, add `Closes #N` only if the implementation fully resolves issue N.
7. Use `Refs #N` for partial work.
8. Do not merge without separate approval.
9. Let GitHub close the issue through the merged PR when `Closes #N` is used.

Do not manually close an implementation issue before its resolving PR is merged unless the user asks.

## Protected config rule

For a normal source-code task, do not edit these files just to make checks pass:
- linter configuration;
- formatter configuration;
- `.editorconfig`;
- `tsconfig*`;
- Dockerfiles and Compose files;
- CI workflows;
- bundler/build config;
- test-runner global config;
- package-manager config;
- dependency manifests and lockfiles;
- environment config/schema.

If one of these files is the real root cause, explain the evidence and ask permission before editing it.

## Dirty working tree rule

If there are unrelated uncommitted changes:
- do not reset them;
- do not stash them automatically;
- do not stage them;
- do not include them in a commit;
- avoid editing the same files if that could overwrite the user's work;
- ask the user when safe isolation is not possible.

## Verification rule

Use the repository's existing commands. Do not invent a new package manager command or modify scripts to make verification easier.

Typical order:
1. focused test/check for the changed area;
2. lint/typecheck for the changed project;
3. broader tests/build when the task can affect them;
4. inspect `git diff` and `git status`.

A failed check is information. Do not hide it by weakening project rules.
