class Devopstools < Formula
  desc "Bundle installer for DevOps tools"
  homepage "https://github.com/saimeda32/homebrew-devopstools"
  url "https://github.com/saimeda32/homebrew-devopstools/archive/refs/heads/main.tar.gz"
  sha256 "4b8aa0547c0bafafca86046e58db1675b86e4d24b7b47eced589b26f0637d68e"
  version "1.0.0"

  def install
    system "curl", "-sL", "https://raw.githubusercontent.com/saimeda32/homebrew-devopstools/main/install.sh", "|", "bash"
  end
end
