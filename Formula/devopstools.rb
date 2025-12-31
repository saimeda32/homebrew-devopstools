class Devopstools < Formula
  desc "Bundle installer for DevOps tools"
  homepage "https://github.com/saimeda32/devopstools"
  url "https://github.com/saimeda32/homebrew-devopstools/archive/refs/tags/v1.0.17.tar.gz"
  sha256 "6c50e267bd065e979eda68f3c1f135dbe60e26565b5b264996030c23b726bb5c"
  version "v1.0.17"  # Removed the 'v' prefix


  def install
    # keep bin lean: install wrapper and top-level installer
    bin.install "bin/devopstools"
    bin.install "install.sh"

    # place helper scripts and curated profiles in libexec so the wrapper
    # can reliably call them from the opt/libexec path
    libexec.install Dir["scripts/*"] if File.directory?("scripts")
    # install profiles into the package prefix so scripts that expect
    # REPO_ROOT/profiles will find them when the package is installed
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