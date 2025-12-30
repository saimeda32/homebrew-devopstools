Developer / maintainer workflow (important)

If you modify the formula (Formula/devopstools.rb) or add the wrapper bin/devopstools, you must commit and push those changes to the remote repository so the tap and Homebrew users can access them. Local edits alone will not affect other machines.

Commit and push example:

  git checkout -b feat/install-wrapper
  git add Formula/devopstools.rb bin/devopstools README.md INSTALL.md
  git commit -m "Install devopstools wrapper via formula"
  git push --set-upstream origin feat/install-wrapper

Test locally by building the formula from source (use the path to your clone):

  # remove any existing install
  brew uninstall --force saimeda32/devopstools/devopstools || true
  # install the formula from your local clone
  brew install --build-from-source /path/to/your/clone/Formula/devopstools.rb

  # verify wrapper is installed and executable
  ls -la /opt/homebrew/bin/devopstools || ls -la /usr/local/bin/devopstools || true

After opening a PR and merging, users can update via:

  brew reinstall saimeda32/devopstools/devopstools

Notes:
- Homebrew will install any files placed in the formula `bin` into a location on the system PATH for all users. That is the correct way to provide a system-wide `devopstools` command—avoid per-user symlinks.
- We intentionally avoid auto-running the installer during `post_install`. Use the installed `devopstools` wrapper or call the installed script at /opt/homebrew/opt/devopstools/bin/install.sh to bootstrap tools.
