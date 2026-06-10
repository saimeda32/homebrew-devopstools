# 🚀 Quick Start Guide

Welcome! This guide will get you up and running in **2 minutes**.

## Installation (One-Time Setup)

### Option A: Direct from Repository (Recommended for Testing)
```bash
git clone git@github.com:saimeda32/homebrew-devopstools.git
cd homebrew-devopstools
```

### Option B: Via Homebrew Tap (After Release)
```bash
brew tap saimeda32/devopstools
brew install devopstools
```

---

## 🎯 Getting Started (Choose One)

### **For Complete Beginners: Interactive Mode** ⭐

```bash
./scripts/interactive-select.sh
```

This opens a friendly menu:
```
========================================
  DevOps Tools Installer
========================================

Select profiles to install (space-separated):

  [1] base              Minimal tools for all developers
  [2] frontend          Frontend development
  [3] backend           Backend development
  [4] devops            DevOps essentials
  [5] ai                AI/LLM development
  [6] fullstack         Full-stack web development
  [7] security          Security tools & scanning
  [8] observability     Monitoring & logging
  [9] infra-modern      Modern infrastructure
  [10] web3             Blockchain development
  [11] devx             Developer experience

Examples: 1 2 3 (space-separated)
Or just 1 for base, or press Enter to skip
Your selection: 
```

**Then it asks:**
1. ✅ Which profiles to install
2. ✅ Which tools to skip (optional)
3. ✅ Preview mode or actual install

---

### **For Experienced Developers: Command Line**

#### See what would install (preview):
```bash
./install.sh --profiles base,frontend --dry-run
```

#### Actually install a profile:
```bash
./install.sh --profiles base,frontend --yes
```

#### Install and skip specific tools:
```bash
./install.sh --profiles backend --skip-tools npm:prettier --yes
```

#### Combine multiple profiles:
```bash
./install.sh --profiles base,ai,security --yes
```

---

## 📋 Choose Your Profile

| Profile | For | Example Use |
|---------|-----|------------|
| **base** | Everyone | All developers get foundational tools |
| **frontend** | React/Vue/Next.js devs | Node.js, pnpm, yarn, bun, expo-cli |
| **backend** | Python/API devs | Python 3.13, poetry, pytest, ruff |
| **devops** | Infrastructure teams | Terraform, K8s, AWS CLI, Docker |
| **ai** | ML/LLM engineers | Ollama, LangChain, Jupyter, Python |
| **fullstack** | Full-stack devs | Everything: frontend + backend + docker |
| **security** | Security ops | Trivy, tfsec, vault, grype, snyk |
| **observability** | DevOps teams | Prometheus, Grafana, Loki |
| **infra-modern** | Modern infrastructure | Pulumi, GitOps, K8s, ArgoCD |
| **web3** | Blockchain devs | Foundry, Solidity tools |
| **devx** | Anyone | Shell enhancements: fzf, ripgrep, bat |

---

## 🧪 Safe by Default

### Dry-Run Mode (Preview First)
```bash
./install.sh --profiles base,frontend --dry-run
```
Shows what would install **without making any changes**

### Skip Tools
```bash
./install.sh --profiles frontend --skip-tools docker,npm:prettier --yes
```
Skip tools you already have or don't want

### Check What's Already Installed
The installer automatically:
- ✓ Skips tools you already have
- ✓ Shows what it's doing (detailed logging)
- ✓ Never overwrites your config
- ✓ Creates backups of modified files

---

## 📚 Common Scenarios

### Scenario 1: Brand New Dev Machine
```bash
./install.sh --profiles base,devx --yes
```
Gets you: git, curl, fzf, ripgrep, bat, GitHub CLI + shell enhancements

### Scenario 2: Full-Stack JavaScript Developer
```bash
./install.sh --profiles base,fullstack --yes
```
Gets you: Node.js, Python, Docker, pnpm, yarn, bun, + all dev tools

### Scenario 3: AI/ML Engineer Setup
```bash
./install.sh --profiles base,ai,fullstack --skip-tools docker --yes
```
Gets you: Python 3.13, Ollama, LangChain, Jupyter, Node.js, testing tools

### Scenario 4: DevOps Engineer
```bash
./install.sh --profiles base,devops,security,observability --yes
```
Gets you: Terraform, K8s, security scanners, monitoring stack

### Scenario 5: Preview Before Installing
```bash
./install.sh --profiles base,frontend --dry-run
```
See everything that would be installed, then decide

---

## 🆘 Troubleshooting

### ❌ "brew not available"
**Solution:** Install Homebrew first
```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
```

### ❌ "Permission denied" errors
**Solution:** Let the installer fix it
```bash
./install.sh --profiles base --yes  # Automatically fixes permissions
```

### ❌ Specific tool failed to install
**Solution:** Skip it and continue
```bash
./install.sh --profiles backend --skip-tools npm:prettier --yes
```

### ❌ Want to see the log
**Solution:** Check the detailed log
```bash
tail -f ~/Library/Logs/devopstools/install.log
```

### ❌ Want to run it again (idempotent)
**Solution:** Just run it again - it's safe!
```bash
./install.sh --profiles base,frontend --yes
# Skips already-installed tools, installs missing ones
```

---

## ⚡ Pro Tips

1. **Always dry-run first**
   ```bash
   ./install.sh --profiles YOUR_PROFILE --dry-run
   ```

2. **Mix and match profiles**
   ```bash
   ./install.sh --profiles base,frontend,ai,security --yes
   ```

3. **Skip what you don't want**
   ```bash
   ./install.sh --profiles fullstack --skip-tools docker,npm:serve --yes
   ```

4. **Run multiple times (idempotent)**
   - Safe to run anytime
   - Skips already-installed tools
   - Won't break existing setup

5. **View detailed logs**
   ```bash
   less ~/Library/Logs/devopstools/install.log
   ```

---

## 📖 Next Steps

- Read [README.md](README.md) for full documentation
- Run `./install.sh -h` for help
- Run `./scripts/interactive-select.sh -h` for interactive mode help
- Check [CONTRIBUTING.md](CONTRIBUTING.md) to add tools

---

## ❓ Questions?

- 📧 Open an [Issue](https://github.com/saimeda32/homebrew-devopstools/issues)
- 💬 Start a [Discussion](https://github.com/saimeda32/homebrew-devopstools/discussions)
- 🐛 Report a [Bug](https://github.com/saimeda32/homebrew-devopstools/issues/new?labels=bug)

---

**You're all set! Pick a profile above and run:**

```bash
./install.sh --profiles base --dry-run    # Preview
./install.sh --profiles base --yes        # Install
```

Or just run:
```bash
./scripts/interactive-select.sh           # Interactive mode
```

Enjoy! 🚀
