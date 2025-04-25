class Devopstools < Formula
  desc "Bundle installer for DevOps tools"
  homepage "https://github.com/saimeda32/homebrew-devopstools"
  url "https://github.com/saimeda32/homebrew-devopstools/archive/refs/heads/main.tar.gz"
  sha256 "28f8b34aa6a426207de4d7d17f26bd879e47e54201cb424bde7254a3957eff7b"
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
