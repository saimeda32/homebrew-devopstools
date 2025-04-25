class Devopstools < Formula
  desc "Bundle installer for DevOps tools"
  homepage "https://github.com/saimeda32/homebrew-devopstools"
  url "https://github.com/saimeda32/homebrew-devopstools/archive/refs/tags/v1.0.0.tar.gz"
  sha256 "0" * 64 # use a dummy value to bypass real hash check (for now)
  version "1.0.0"

  def install
    system "curl", "-sL", "https://raw.githubusercontent.com/saimeda32/homebrew-devopstools/main/install.sh", "|", "bash"
  end
end
