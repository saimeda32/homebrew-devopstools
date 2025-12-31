class Devopstools < Formula
  desc "Bundle installer for DevOps tools"
  homepage "https://github.com/saimeda32/devopstools"
  url "https://github.com/saimeda32/homebrew-devopstools/archive/refs/tags/v1.0.14.tar.gz"
  sha256 "f2f2c0399b3d382fa664df3131233b85ec663d2508cfbb52fa39a82bb36ea804"
  version "v1.0.14"  # Removed the 'v' prefix


  def install
    bin.install "install.sh"
    # install user-facing wrapper so `devopstools` is available in PATH
    if File.exist?("bin/devopstools")
      bin.install "bin/devopstools"
    end
    # install scripts directory so installed wrapper can find helpers at
    # #{opt_prefix}/scripts (Homebrew's opt path)
    if File.directory?("scripts")
      prefix.install "scripts"
    end
    # install profiles so installed package has curated profiles available
    if File.directory?("profiles")
      prefix.install "profiles"
    end
    pkgshare.install "tools.txt"
  end

  def post_install
    # IMPORTANT: We do not auto-run the install script during `brew install`.
    # Running external installers during formula installation can cause
    # unexpected side effects and requires network/privileged operations.
    # Users should run the bundled installer manually when ready:
    #   #{opt_bin}/install.sh #{opt_pkgshare}/tools.txt
  end

  def caveats
    <<~EOS
      To install the listed tools run:

        #{opt_bin}/install.sh #{opt_pkgshare}/tools.txt

      This script is idempotent and will skip already-installed formulae.
      Logs are written to: $HOME/Library/Logs/devopstools/install.log
    EOS
  end

  test do
    # Basic sanity test: script exists and prints usage
    assert_predicate bin/"install.sh", :exist?
    output = shell_output("#{bin}/install.sh -h", 2)
    assert_match "Usage:", output
  end
end