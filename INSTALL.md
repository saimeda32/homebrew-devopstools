# Installation Guide

## For Users: Using the Homebrew Tap

### One-Time Setup (adds the tap)

```bash
brew tap saimeda32/homebrew-devopstools
```

### Install the Tools Manager

```bash
brew install devopstools
```

### Launch Interactive Setup

```bash
devopstools-setup
```

This opens a friendly numbered menu where you:
1. Select profiles (e.g., `1` for base, `2` for frontend)
2. Optionally skip specific tools
3. Preview what will be installed
4. Confirm to proceed

### Advanced Usage

```bash
# Direct installation with profiles
devopstools --profiles base,frontend --dry-run

# Install with tool skipping
devopstools --profiles backend,ai --skip-tools docker,npm:prettier --yes

# Use the core installer directly
install.sh --help
```

---

## For Maintainers: Updating the Tap

### Before You Start

- Commit any changes to files: `Formula/devopstools.rb`, `bin/devopstools`, `start.sh`, `scripts/`, `profiles/`, etc.
- Push to `main` branch (the formula pulls from main)

### Example Workflow

```bash
# Make changes
vim Formula/devopstools.rb
# or
vim start.sh
# or
vim profiles/ai.txt

# Commit and push
git add .
git commit -m "feat: Add support for..."
git push origin main
```

### Testing Changes Locally

```bash
# Remove any existing install
brew uninstall --force devopstools || true

# Install formula from your local clone
brew install --build-from-source /path/to/your/clone/Formula/devopstools.rb

# Verify installation
which devopstools-setup
devopstools-setup --help
install.sh --help
```

### After Merging PR

Users can update with:

```bash
brew reinstall devopstools
```

---

## How the Tap Works

1. **Tap Repository**: `https://github.com/saimeda32/homebrew-devopstools`
   - This IS the tap (it's a Homebrew-compatible formula repository)

2. **Formula Location**: `Formula/devopstools.rb`
   - Homebrew finds and installs from here

3. **Installation Files**:
   - `bin/devopstools` → installed to `/opt/homebrew/bin/devopstools`
   - `bin/devopstools-setup` (via `start.sh`) → installed to `/opt/homebrew/bin/devopstools-setup`
   - `install.sh` → installed to `/opt/homebrew/bin/install.sh`
   - `scripts/` → copied to `/opt/homebrew/opt/devopstools/libexec/`
   - `profiles/` → copied to `/opt/homebrew/opt/devopstools/profiles/`
   - `tools.txt` → copied to `/opt/homebrew/opt/devopstools/share/devopstools/`

4. **User Entry Points**:
   - `devopstools-setup` — Interactive menu (recommended for new users)
   - `devopstools` — Direct command (for advanced automation)
   - `install.sh` — Core installer with full options

---

## Troubleshooting

### "Formula not found" error

Ensure you've added the tap:
```bash
brew tap saimeda32/homebrew-devopstools
brew install devopstools
```

### Updated formula not showing

Tap caches formulas. Force refresh:
```bash
brew untap saimeda32/homebrew-devopstools
brew tap saimeda32/homebrew-devopstools
brew install devopstools
```

### Command not found

After installation, make sure Homebrew's bin is in PATH:
```bash
export PATH="/opt/homebrew/bin:$PATH"
which devopstools-setup
```

### Verify formula is working

```bash
brew info devopstools
brew cat saimeda32/homebrew-devopstools/devopstools
```

---

## Notes

- The formula uses `sha256 :no_check` for main branch (always latest)
- We do NOT auto-run installers during `brew install` (safer, respects user choice)
- All scripts are idempotent—safe to run multiple times
- Logs are saved to `$HOME/Library/Logs/devopstools/install.log`
