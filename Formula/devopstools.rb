class Devopstools < Formula
  desc "Bundle installer for DevOps tools"
  homepage "https://github.com/saimeda32/homebrew-devopstools"
  url "https://github.com/saimeda32/homebrew-devopstools/archive/refs/heads/main.tar.gz"
  sha256 "edf24b5c805dd524bfdfed9dccd069321605434029e54853f60f3e8433cc7f14"
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
