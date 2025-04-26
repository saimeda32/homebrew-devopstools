class Devopstools < Formula
  desc "Bundle installer for DevOps tools"
  homepage "https://github.com/saimeda32/devopstools"
  url "https://github.com/saimeda32/homebrew-devopstools/archive/refs/tags/v1.0.5.tar.gz"
  sha256 "12809a23fae4ca10c49212d78b07cc497015398fe24e9c83acf03f926cfbb0c9"
  version "1.0.8"  # Removed the 'v' prefix


  def install
    bin.install "install.sh"
    pkgshare.install "tools.txt"
  end

  def post_install
    # Run your installation script with tools.txt
    system "#{bin}/install.sh", "#{pkgshare}/tools.txt"
    
    # ✅ Optional: Print the install.log file automatically after installation
    log_file = "#{pkgshare}/install.log"
    if File.exist?(log_file)
      puts "📋 Installation Log:"
      puts File.read(log_file)
    else
      puts "⚠️ Installation log not found at #{log_file}."
    end
  end

  def caveats
    <<~EOS
      ✅ DevOps tools installation completed using your customized script.
      🛠️ Tools are skipped if already installed.
      📝 Detailed installation log is saved in the Cellar at:
         #{HOMEBREW_CELLAR}/devopstools/#{version}/share/devopstools/install.log
      🎉 Check the log for the full summary!
    EOS
  end
end