class Devopstools < Formula
  desc "Bundle installer for DevOps tools"
  homepage "https://github.com/saimeda32/homebrew-devopstools"
  url "https://github.com/saimeda32/homebrew-devopstools/archive/refs/heads/main.tar.gz"
  sha256 "0496898de8205001b7b04277a836dd9acbdec8c43bdd79232e58fd39c9263f8b"
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
