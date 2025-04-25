class Devopstools < Formula
  desc "Bundle installer for DevOps tools"
  homepage "https://github.com/yourname/homebrew-devopstools"
  version "1.0.0"

  def install
    system "curl", "-sL", "https://raw.githubusercontent.com/yourname/homebrew-devopstools/main/install.sh", "|", "bash"
  end
end
