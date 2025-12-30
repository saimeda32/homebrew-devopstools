# 🍺 Homebrew DevOps Tools Tap

A small Homebrew Tap that bundles a curated list of DevOps tools and provides a reusable installer script.

This repository aims to be community-friendly: idempotent installs, clear logging, CI checks, and explicit manual runs to avoid surprises during formula installation.

## Quick Start

1. Tap the repo:

```bash
brew tap yourname/devopstools
```

2. Install the formula (this only installs the helper script and asset files):

```bash
brew install yourname/devopstools/devopstools
```

3. Run the bundled installer (recommended: dry-run first):

```bash
# Dry-run to validate what would change
./install.sh --dry-run tools.txt

# Run for real (use --yes to allow the script to attempt permission fixes)
./install.sh --yes tools.txt
```

Logs are written to:

- macOS: $HOME/Library/Logs/devopstools/install.log

## Enterprise Workstation Model

This repository encodes the corporate workstation standard. It defines layered tooling and enforces policies so engineers do not need tribal knowledge.

Layers (enforced):
- Layer 1 — Control Planes: Terraform is managed ONLY via `tfswitch`. `terraform` must never be installed directly.
- Layer 2 — Runtimes: `python@3.x` and `node` are installed via Homebrew only.
- Layer 3 — Global CLIs: Python CLIs use `pipx`, JavaScript CLIs use `npm` (only when brew is inappropriate).
- Layer 4 — Infra & Cloud tooling: Installed via Homebrew bottles where possible.
- Layer 5 — System productivity: Safe universal tools via brew.

Why `tfswitch` instead of `terraform`:
- Using `tfswitch` enforces version gating, reproducibility, and avoids multiple projects installing conflicting Terraform binaries.
- By policy, `terraform` is intentionally gated behind `tfswitch` and this repo will refuse direct `terraform` installs.

Policy enforcement:
- The installer and validator will fail or flag policy violations (for example direct `terraform` entries).
- The repo provides `profiles/` for role-based tool bundles and `install.sh --profile <name>` to install them.

Adding new tools:
- Evaluate tool compatibility with the layering model.
- Prefer Homebrew bottles; if the tooling is a Python CLI, add it as `pipx:tool` in the profile or `tools.txt`.
- For npm tooling, add `npm:package` entries; the installer will use `npm` to install globally but only after installing `node` via Homebrew when necessary.

Corporate mac constraints:
- App Store is not used. All userland tools must be provided via Homebrew or package managers handled by this repo.
- Installs are non-interactive and idempotent.


## Files

- `install.sh` — Idempotent installer script for Homebrew formulae.
- `tools.txt` — One Homebrew formula per line. Comments with `#` are allowed.
- `Formula/devopstools.rb` — Homebrew formula that installs the helper script.

## CI

GitHub Actions provides two checks:

- `lint`: runs `shellcheck` on `install.sh`.
- `test-dry-run`: executes the script in `--dry-run` mode on macOS.

## Contributing

- Add or update formula names in `tools.txt` (one per line).
- Keep changes minimal and provide rationale in PR descriptions.
- CI will validate formatting and run the dry-run.

## License

MIT — see the LICENSE file.

---

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
