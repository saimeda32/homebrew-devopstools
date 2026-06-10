class Devopstools < Formula
  desc "AI-ready DevOps installer with 11 role-based profiles and interactive setup"
  homepage "https://github.com/saimeda32/homebrew-devopstools"
  url "https://github.com/saimeda32/homebrew-devopstools/archive/refs/heads/main.tar.gz"
  version "2026.06"
  sha256 :no_check  # Using main branch; users can verify with: brew audit --download --strict devopstools

  def install
    # Install interactive entry point and core scripts
    bin.install "start.sh" => "devopstools-setup"
    bin.install "install.sh"
    bin.install "bin/devopstools"

    # Install helper scripts for profile management and QA
    libexec.install Dir["scripts/*"] if File.directory?("scripts")

    # Install all role-based profiles
    if File.directory?("profiles")
      prefix.install "profiles"
    end

    # Install tools inventory and documentation
    pkgshare.install "tools.txt"
    pkgshare.install Dir["*.md"] if Dir["*.md"].any?
  end

  def post_install
    # Note: We don't auto-run the installer during 'brew install' as it requires
    # user interaction and can trigger network operations and privilege escalation.
    # Users should run the setup wizard when ready.
  end

  def caveats
    <<~EOS
      ✅ Homebrew DevOps Tools installed!

      🚀 Quick Start (Interactive Mode):

        devopstools-setup

      This launches a friendly menu to:
        • Select profiles (base, frontend, backend, devops, ai, etc.)
        • Skip tools you don't want
        • Preview before installing
        • Confirm and go!

      📖 For more options:

        install.sh -h

      Advanced Examples:

        # Install specific profiles
        install.sh --profiles base,frontend --dry-run

        # Skip tools and merge profiles
        install.sh --profiles devops,security --skip-tools docker --yes

      💾 Logs saved to: $HOME/Library/Logs/devopstools/install.log

      🎯 Available Profiles:
        base, frontend, backend, devops, ai, fullstack,
        security, observability, infra-modern, web3, devx

      📚 Learn more:
        https://github.com/saimeda32/homebrew-devopstools
    EOS
  end

  test do
    # Verify core scripts exist and are executable
    assert_predicate bin/"devopstools-setup", :exist?
    assert_predicate bin/"install.sh", :exist?
    
    # Basic sanity check on help output
    output = shell_output("#{bin}/install.sh -h", 2)
    assert_match "Usage:", output
  end
end