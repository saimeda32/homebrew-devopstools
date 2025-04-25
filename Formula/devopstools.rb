class Devopstools < Formula
  desc "Bundle installer for DevOps tools"
  homepage "https://github.com/saimeda32/homebrew-devopstools"
  url "https://github.com/saimeda32/homebrew-devopstools/archive/refs/heads/main.tar.gz"
  sha256 "145f9126a06dd62796561bae9f8d90933c49a2ff5438d20692544c443f37e73c"
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
