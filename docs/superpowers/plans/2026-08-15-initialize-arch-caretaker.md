# Initialize Arch Caretaker Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Create a user-owned Git repository that safely scaffolds the Arch Caretaker configuration project.

**Architecture:** The repository holds declarative configuration and documentation only. Its top-level folders separate status bar, shell, desktop, terminal, package, and local backup concerns. `backup/` is a local-only staging folder whose contents are never tracked.

**Tech Stack:** Git, POSIX shell filesystem commands, Markdown.

**Spec:** `docs/superpowers/specs/2026-08-15-arch-caretaker-design.md`

## Global Constraints

- Repository path is `/home/kael/codex-proj/arch-workbench/arch-caretaker`.
- The repository runs as user `kael`; no system path is modified.
- `backup/` content is ignored by Git.
- No package, service, or desktop configuration is changed by this initialization.
- The repository is the source of truth for future user-level configuration; deployment will use explicit symbolic links and component reload commands.

---

### Task 1: Scaffold The Repository

**Files:**
- Create: `README.md`
- Create: `.gitignore`
- Create: `statusbar/.gitkeep`
- Create: `shell/.gitkeep`
- Create: `desktop/.gitkeep`
- Create: `terminal/.gitkeep`
- Create: `packages/.gitkeep`
- Create: `backup/.gitkeep`

**Interfaces:**
- Consumes: the approved directory layout in `docs/superpowers/specs/2026-08-15-arch-caretaker-design.md`.
- Produces: an initialized Git repository with empty, trackable configuration folders and an ignored local-backup folder.

- [ ] **Step 1: Initialize Git and create the top-level folders**

Run:

```bash
git init
mkdir -p statusbar shell desktop terminal packages backup
```

Expected: `.git/` and all six folders exist under the repository root.

- [ ] **Step 2: Add repository documentation and ignore rules**

Create `README.md` containing:

```markdown
# Arch Caretaker

User-owned, reproducible configuration for this Arch Linux desktop.

## Areas

- `statusbar/`: status-bar configuration and helper scripts
- `shell/`: shell configuration and prompt tooling
- `desktop/`: desktop-session and window-manager configuration
- `terminal/`: terminal emulator configuration
- `packages/`: package manifests and installation notes
- `backup/`: ignored local backup staging area

System changes are opt-in and require explicit confirmation.
User-level deployment uses explicit symbolic links followed by a component reload.
```

Create `.gitignore` containing:

```gitignore
# Backups can contain credentials and machine-private data.
backup/*
!backup/.gitkeep
```

- [ ] **Step 3: Keep the empty configuration folders in version control**

Create an empty `.gitkeep` file in each top-level folder, including `backup/`.

- [ ] **Step 4: Verify the repository state and backup exclusion**

Run:

```bash
git status --short
git check-ignore -v backup/example-secret.txt
```

Expected: all files except a hypothetical `backup/example-secret.txt` appear as untracked; `git check-ignore` reports the `backup/*` rule.

- [ ] **Step 5: Commit the safe initial scaffold**

Run:

```bash
git add README.md .gitignore statusbar shell desktop terminal packages backup docs
git commit -m "chore: initialize arch caretaker"
```

Expected: `git status --short` has no output.
