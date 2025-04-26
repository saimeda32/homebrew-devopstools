class Devopstools < Formula
  desc "Bundle installer for DevOps tools"
  homepage "https://github.com/saimeda32/devopstools"
  url "https://github.com/saimeda32/devopstools/archive/refs/tags/v1.0.0.tar.gz"
  sha256 "PLACEHOLDER_SHA256"
  version "1.0.0"

  def install
    bin.install "install.sh"
    pkgshare.install "tools.txt"
  end

  def post_install
    system "#{bin}/install.sh", "#{pkgshare}/tools.txt"
  end

  def caveats
    <<~EOS
      ✅ DevOps tools installation completed using your customized script.
      🛠️ Tools are skipped if already installed.
      🎉 Check the terminal output for the installation summary.
    EOS
  end
end