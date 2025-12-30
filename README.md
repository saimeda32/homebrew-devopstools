# homebrew-devopstools

Enterprise-ready installer and profile manager for developer workstations

This repository provides a safe, auditable, and idempotent framework to
provision macOS developer workstations using Homebrew as the primary
package manager. It enforces policy (e.g. Terraform via tfswitch only),
provides role-based profiles, and includes non-destructive zsh configuration
management for teams.

Quick concepts
- `tools.txt`: canonical inventory and policy surface (source-of-truth).
- `profiles/*.txt`: curated subsets of `tools.txt` for team/workstation roles.
- `install.sh`: idempotent installer that understands `tap:`, `npm:`, `pipx:`
	and enforces enterprise policies.
- `scripts/manage_zshrc.sh`: idempotent, non-destructive zshrc manager.
- `scripts/apply_profiles.sh` & `bin/devopstools`: interactive and scripted
	helpers to merge profiles and invoke the installer.

Safety-first defaults
- Dry-run by default for user-facing helpers; nothing is changed unless
	`--no-dry-run` / explicit consent is provided.
- Backups: any file modified by `manage_zshrc.sh` is backed up
	as `<file>.bak.<epoch>` before changes are applied.
- Plugin installs and network operations are opt-in and non-interactive to
	support locked-down networks and CI.

Usage examples

- Preview installing the `frontend` profile (no changes):
```bash
devopstools --profiles frontend --dry-run --non-interactive
```

- Merge `base` + `frontend` and run installer interactively (prompts before
    proceeding):
```bash
devopstools --profiles base,frontend
```

- Merge and install non-interactively (automation):
```bash
devopstools --profiles base,frontend --no-dry-run --yes --non-interactive
```

Zsh management
- `scripts/manage_zshrc.sh` will:
	- read defaults from `.devopstools/reference_zshrc` (this repo)
	- insert/update a managed block in `~/.zshrc` without overwriting user
		customizations outside the block
	- back up the original `~/.zshrc` before modification
	- defer plugin installation unless `--install-plugins` is passed

Profiles and `tools.txt`
- Keep `tools.txt` as the canonical validated inventory for CI and policy
	(run `scripts/validate_tools.sh tools.txt` in CI).
- Profiles are lightweight curated lists. When adding a new tool, add it to
	`tools.txt` first, then include it in the relevant profile(s).

CI recommendations
- Run `scripts/validate_tools.sh tools.txt` on PRs to detect policy gaps.
-- Optionally run `devopstools --profiles base --dry-run` or
-- `devopstools --profiles frontend --dry-run` in macOS runners to detect runtime install errors.

Contributing & PRs
- Make changes on a branch and open a PR against `main`. Example commands:
```bash
git checkout -b feature/your-change
git add -A
git commit -m "Describe your change"
git push -u origin feature/your-change
# use gh if installed
gh pr create --fill --base main --head feature/your-change
```

If you prefer I can prepare a branch and push it for you. Note: pushing from
this environment requires git remote permissions; if push fails, run the
the commands above locally.

License
See LICENSE in the repository.

If you want, I can also:

- Add unit/integration tests that verify each tool resolves in Homebrew (I added a validate script already).
- Provide a way to pin tool versions or use Homebrew bundles.
- Add an automated release process for the tap.

Run `make validate` to check that listed tools are resolvable on a machine with Homebrew.
# 🍺 Homebrew DevOps Tools Tap

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)
[![Homebrew Tap](https://img.shields.io/badge/homebrew-tap-blue)](https://brew.sh/)
[![PRs Welcome](https://img.shields.io/badge/PRs-welcome-brightgreen.svg)](https://github.com/yourname/homebrew-devopstools/pulls)

A Homebrew Tap to easily install a bundle of essential DevOps and Platform Engineering tools with built-in validations.  
The installer automatically checks for existing installations, skips tools that are already installed, and continues safely without failing the entire process.

> ✅ Safe to rerun anytime.  
> ⚡ Simple to maintain.  
> 🤝 Consistent tooling across your team.

---

## 🚀 Features

- Installs common DevOps tools via Homebrew
- Skips tools already installed (idempotent)
- Continues installation even if one tool fails
- Easily updatable via `tools.txt`
- Supports external taps and formulae

---

## 📥 Installation

### 1️⃣ Tap the repository:
```bash
brew tap yourname/devopstools
