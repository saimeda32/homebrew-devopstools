# 🍺 Homebrew DevOps Tools

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)
[![Homebrew Tap](https://img.shields.io/badge/homebrew-tap-blue)](https://brew.sh/)
[![PRs Welcome](https://img.shields.io/badge/PRs-welcome-brightgreen.svg)](#contributing--prs)

Enterprise-grade, AI-ready installer and profile manager for macOS developer workstations. Provision complete dev environments in minutes with role-based profiles, intelligent tool detection, and zero-risk dry-run previews.

> ✅ **Safe to rerun anytime** — Gracefully skips already-installed tools  
> ⚡ **AI/LLM Ready** — Ollama, LangChain, Jupyter included  
> 🛡️ **Security-First** — Trivy, Grype, tfsec pre-configured  
> 🤖 **Idempotent & Reliable** — Works with Homebrew, npm, pipx, and taps  
> 🎯 **Role-Based Profiles** — Choose what you need, skip what you don't  
> 💻 **Modern Toolchain** — Python 3.12/3.13, uv, bun, deno support  

---

## ✨ What's New (2026 Update)

### Phase 1: AI/LLM Integration
- **Ollama** for local LLM inference
- **LangChain** for LLM application development
- **JupyterLab** for interactive notebooks
- **Improved Python tooling** with uv, ruff

### Phase 2: Modern Runtimes
- **uv** — Ultra-fast Python package manager
- **bun** — Lightning-fast JavaScript runtime
- **deno** — TypeScript runtime with batteries included
- **Python 3.12 & 3.13** alongside 3.11

### Phase 3: Security & Compliance
- **Trivy** — Comprehensive vulnerability scanner
- **Grype** — Software supply chain security
- **tfsec** — Terraform security
- **cosign** — Container signing

### Phase 4: Observability & Monitoring
- **Prometheus** — Metrics collection
- **Grafana** — Visualization dashboards
- **Loki** — Log aggregation

### Phase 5: Modern Infrastructure
- **Pulumi** — Infrastructure as Code
- **ArgoCD** — GitOps automation
- **Kustomize** — Kubernetes customization

### Phase 6: Container Alternatives
- **colima** — Docker Desktop alternative
- **podman** — Container runtime without daemon

### Phase 7: Web3 & Blockchain
- **Foundry** — Solidity development toolkit

---

## 📦 Available Profiles

Select from 11 curated profiles or create your own combinations:

| Profile | Purpose | Key Tools |
|---------|---------|-----------|
| **base** | All developers | git, curl, jq, fzf, ripgrep, bat |
| **frontend** | React/Vue/Next.js | node, pnpm, yarn, bun, expo-cli |
| **backend** | Python/API dev | python@3.13, uv, poetry, ruff, pytest |
| **devops** | Infrastructure | Terraform, K8s, AWS CLI, Docker |
| **ai** | ML/LLM dev | Ollama, LangChain, Jupyter, uv |
| **fullstack** | Everything | frontend + backend + containers |
| **security** | Sec ops | trivy, grype, tfsec, vault, snyk |
| **observability** | Monitoring | prometheus, grafana, loki |
| **infra-modern** | Modern IaC | Pulumi, GitOps, K8s, Cloud CLIs |
| **web3** | Blockchain dev | foundry, solidity tools |
| **devx** | DX improvements | starship, fzf, bat, ripgrep, prettier |

---

## 🚀 Quick Start

### For Everyone: One-Line Interactive Setup ⭐

```bash
git clone git@github-sai:saimeda32/homebrew-devopstools.git
cd homebrew-devopstools
./start.sh
```

That's it! This opens a friendly menu where you:
1. Select profiles (or mix-and-match with numbers)
2. Choose tools to skip (optional)
3. Preview or install immediately

### Interactive Mode (Advanced)

```bash
# Full control with options
./scripts/interactive-select.sh

# Pre-select profiles
./scripts/interactive-select.sh --profiles base,frontend

# Preview before installing
./scripts/interactive-select.sh --profiles backend --dry-run
```

### Command-Line Mode (Automation/CI)

```bash
# Dry-run preview (no changes)
./install.sh --profiles base,frontend --dry-run

# Install base + frontend (actual install)
./install.sh --profiles base,frontend --yes --no-dry-run

# Install and skip specific tools
./install.sh --profiles backend,ai --skip-tools npm:prettier,docker --yes

# Non-interactive automation (CI/CD)
./install.sh --profiles base,devops --yes --non-interactive --no-dry-run
```

### Via Homebrew (After Installation)

```bash
# Add the tap
brew tap saimeda32/devopstools

# Install the wrapper
brew install devopstools

# Run interactively
devopstools-select

# Or use direct commands
devopstools --profiles base,frontend --dry-run
```

---

## 🎯 Usage Examples

### Example 1: Set Up Frontend Developer
```bash
./install.sh --profiles base,frontend --skip-tools docker --yes
```
Installs: base utilities + Node.js, pnpm, yarn, bun, React tools (skips Docker)

### Example 2: AI/ML Engineer Setup
```bash
./install.sh --profiles base,ai,security --skip-tools npm:prettier --yes
```
Installs: Python 3.13, Ollama, LangChain, Jupyter, security tools (skips prettier)

### Example 3: DevOps Engineer Full Stack
```bash
./install.sh --profiles base,devops,security,observability,infra-modern --yes
```
Installs: Terraform, K8s, security scanners, monitoring stack, modern IaC

### Example 4: Full-Stack with Selective Skips
```bash
./install.sh \
  --profiles fullstack,ai \
  --skip-tools npm:create-react-app,pipx:ipython \
  --dry-run
```
Preview before installing (no actual changes)

---

## ⚙️ Advanced Options

### Tool Skipping (Graceful Exclusion)

Skip already-deployed tools or deprecated packages:

```bash
# Skip single tool
--skip-tools docker

# Skip multiple (comma-separated)
--skip-tools docker,npm:prettier,yarn

# Skip by package type
--skip-tools npm:serve          # Skip npm package
--skip-tools pipx:poetry        # Skip pipx package
--skip-tools tap:hashicorp/tap  # Skip tap
```

**Smart Detection:**
- Checks if tool is already installed
- Handles npm, pipx, and Homebrew packages
- Works with partial matches (e.g., `python` skips all Python installs)

### Dry-Run Mode

Preview what will be installed without making changes:

```bash
./install.sh --profiles base,frontend --dry-run
```

Output shows:
- ✓ Tools already installed (skipped)
- → Tools that would be installed
- ✖ Any failures or blockers

### Non-Interactive Mode

For automation and CI/CD pipelines:

```bash
./install.sh \
  --profiles base,devops \
  --non-interactive \
  --yes \
  --no-dry-run
```

No prompts, runs to completion, suitable for GitHub Actions/GitLab CI.

---

## 📋 How It Works

### Detection & Graceful Skipping

The installer intelligently detects already-installed tools:

```
Tool Type          Detection Method              Example
─────────────────  ──────────────────────────    ──────────────
Homebrew formulae  brew list --formula            git, docker, node
npm packages       npm list -g --depth=0          prettier, expo-cli
pipx packages      pipx list                      poetry, black
Taps               brew tap (list)                derailed/k9s
Special            command -v (in PATH)           tfswitch
```

If a tool is found, it's **automatically skipped** with a ✓ checkmark.

### Profile Merging

Multiple profiles are merged intelligently:

```bash
# Input
--profiles backend,ai

# Merged tools (deduplicated & sorted)
python@3.13
uv
poetry
pytest
ollama
langchain
jupyterlab
git
curl
yq
```

### Installation Order

1. **Homebrew** installations first (dependencies)
2. **Taps** added before formulas that need them
3. **Node** installed if npm packages needed
4. **Python3** installed if pipx packages needed
5. **npm/pipx** packages installed last

---

## 🛠️ Configuration

### Modify `tools.txt`

The `tools.txt` file is the canonical inventory. When adding a new tool:

```bash
# 1. Add to tools.txt (with category)
## My New Category
my-new-tool

# 2. Include in relevant profiles
profiles/backend.txt
profiles/ai.txt

# 3. Test in dry-run
./install.sh --profiles backend --dry-run

# 4. Commit and push
git add tools.txt profiles/backend.txt
git commit -m "Add my-new-tool"
```

### Tool Format Support

```bash
git                          # Homebrew formula
python@3.13                  # Specific version
tap: hashicorp/tap          # Tap registration
hashicorp/tap/consul        # Tap-qualified formula
npm:prettier                # npm global package
pipx:poetry                 # pipx package
```

### Add Custom Profile

```bash
# Create new profile
cat > profiles/custom.txt <<EOF
# My Custom Profile
git
python@3.13
npm:prettier
docker
docker-compose
EOF

# Test it
./install.sh --profiles custom --dry-run

# Use it
./install.sh --profiles custom --yes
```

---

## 📊 QA & Validation

Run comprehensive QA suite:

```bash
./scripts/qa-validate.sh
```

This validates:
- ✓ All profiles exist and are readable
- ✓ tools.txt syntax and contents
- ✓ Profile contents and tool types
- ✓ Script syntax and executability
- ✓ Tool format validation
- ✓ Dry-run mode functionality
- ✓ Profile merging logic
- ✓ Tool skipping mechanism
- ✓ Installation detection logic
- ✓ New features (AI, security, modern runtimes)

---

## 🔍 Troubleshooting

### Issue: "brew not available"
**Solution:** Install Homebrew first
```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
```

### Issue: "Permission denied" on Homebrew directories
**Solution:** Fix permissions
```bash
sudo chown -R "$(whoami)" /opt/homebrew
# Or run installer with --yes flag to auto-fix
./install.sh --profiles base --yes
```

### Issue: npm/pipx packages fail to install
**Solution:** Check prerequisites
```bash
# For npm packages
which npm && npm list -g --depth=0

# For pipx packages
which python3 && python3 -m pipx list
```

### Issue: Specific tool won't install
**Solution:** Check logs
```bash
tail -f ~/Library/Logs/devopstools/install.log
```

### Issue: Want to skip already-installed tool
**Solution:** Use --skip-tools
```bash
./install.sh --profiles backend --skip-tools npm:prettier --yes
```

---

## 🔒 Safety Features

### Dry-Run by Default (Interactive Mode)
When using interactive selector, it asks before installing:
```
Ready to proceed? [y/N]
> 
```

### Idempotent Design
Safe to run multiple times:
- Already-installed tools are skipped ✓
- No duplicate installations
- Configuration files not overwritten
- Non-destructive zsh management

### Comprehensive Logging
All operations logged to:
```
~/Library/Logs/devopstools/install.log
```

### Rollback Support
Backups created by `manage_zshrc.sh`:
```
~/.zshrc.bak.<timestamp>
```

---

## 👥 Team & Organization Usage

### Enforce Baseline (CI/CD)

```yaml
# GitHub Actions example
- name: Install DevOps Tools
  run: |
    brew tap saimeda32/devopstools
    devopstools --profiles base,devops \
      --yes --non-interactive --no-dry-run
```

### Role-Based Provisioning

**Frontend Team:**
```bash
devopstools --profiles base,frontend,security
```

**Backend Team:**
```bash
devopstools --profiles base,backend,devops,security
```

**ML Team:**
```bash
devopstools --profiles base,ai,fullstack,security
```

**DevOps Team:**
```bash
devopstools --profiles base,devops,security,observability,infra-modern
```

---

## 📝 Contributing & PRs

We welcome contributions! Follow this workflow:

```bash
# 1. Fork and clone
git clone git@github.com:YOUR_USERNAME/homebrew-devopstools.git
cd homebrew-devopstools

# 2. Create feature branch
git checkout -b feature/add-new-tool

# 3. Make changes
# - Add to tools.txt
# - Add to relevant profiles
# - Test with --dry-run

# 4. Run QA validation
./scripts/qa-validate.sh

# 5. Commit and push
git add -A
git commit -m "Add new-tool for ML workflows"
git push -u origin feature/add-new-tool

# 6. Create PR
gh pr create --fill
```

### Contribution Guidelines
- ✅ Test new tools with `--dry-run` before PR
- ✅ Add to both `tools.txt` AND relevant `profiles/*.txt`
- ✅ Run `./scripts/qa-validate.sh` to pass QA
- ✅ Include rationale for new tools in PR description
- ✅ Keep profiles focused (use multiple small profiles, not one giant one)

---

## 📄 License

MIT License - See [LICENSE](LICENSE) for details.

---

## 🤝 Support

- 📧 Issues: [GitHub Issues](https://github.com/saimeda32/homebrew-devopstools/issues)
- 💬 Discussions: [GitHub Discussions](https://github.com/saimeda32/homebrew-devopstools/discussions)
- 🐛 Bug Reports: Use issue template

---

## 🎓 Learn More

- [Homebrew](https://brew.sh/)
- [DevOps Tools Index](https://github.com/saimeda32/homebrew-devopstools/wiki)
- [Contributing Guide](CONTRIBUTING.md)

---

**Made with ❤️ for developers. Fork, contribute, and level up your team's setup!**
