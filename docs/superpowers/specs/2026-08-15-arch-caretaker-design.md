# Arch Caretaker Design

## Purpose

`arch-caretaker` is a user-owned, reproducible configuration repository for the ongoing maintenance and improvement of this Arch Linux desktop.

## Location And Ownership

- Workspace: `/home/kael/codex-proj/arch-workbench/`
- Repository: `/home/kael/codex-proj/arch-workbench/arch-caretaker/`
- Owner: the `kael` user
- Version control: `arch-caretaker` is an independent Git repository.

The repository is never placed in a system-owned path. It contains declarative configuration, scripts, documentation, and package manifests rather than copies of entire system directories.

## Initial Layout

```text
arch-caretaker/
|-- statusbar/  # Status-bar configuration and helper scripts
|-- shell/      # Shell configuration and prompt tooling
|-- desktop/    # Desktop-session and window-manager configuration
|-- terminal/   # Terminal emulator configuration
|-- packages/   # Package manifests and installation notes
|-- backup/     # Local-only, ignored backup staging area
`-- docs/       # Design, plans, and operational documentation
```

## Safety Rules

- `backup/` contents are ignored by Git. Sensitive credentials, browser data, private keys, and full system snapshots do not enter the repository.
- Each deployment script must state its target paths and whether it needs elevated privileges before it changes anything.
- System-wide changes are opt-in: no command changes `/etc`, package state, services, boot configuration, or desktop settings without an explicit user confirmation for that operation.
- Every reversible configuration change records its restore procedure in the relevant subproject documentation.
- Packages are represented as manifests or documented commands; installation is not implicit.

## Deployment Model

The repository is the source of truth for managed configuration. User-level components may be deployed by symbolic links from their live configuration paths under `/home/kael/.config/` to a component directory in this repository. A deployment command must name the link target and run the component's documented reload action. No link is created by initial setup.

System-wide configuration remains separate from this model. It requires a component-specific deployment script, a stated target path, a backup or restore procedure, and explicit user confirmation.

## Initial Deliverable

The initial setup creates the repository, its top-level directories, a `README.md`, and a `.gitignore` that protects `backup/`. It does not alter any active system configuration.
