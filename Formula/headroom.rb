# url and sha256 are kept at the latest release by .github/workflows/bump.yml.
class Headroom < Formula
  desc "Queue heavy dev commands so parallel coding agents don't exhaust memory"
  homepage "https://github.com/aha-churchdesk/headroom"
  url "https://github.com/aha-churchdesk/headroom/releases/download/v0.4.11/headroom-0.4.11-aarch64-apple-darwin.tar.gz"
  sha256 "9f553403561ad5b6bbb47bf763369fa9fe6b122980c1dc7013ea586e77bbb1dd"

  depends_on arch: :arm64
  depends_on :macos

  head do
    url "https://github.com/aha-churchdesk/headroom.git", branch: "main"
    depends_on "rust" => :build
  end

  def install
    if build.head?
      system "cargo", "build", "--release", "--locked", "-p", "headroom", "-p", "headroomd"
      bin.install "target/release/headroom", "target/release/headroomd"
    else
      bin.install "bin/headroom", "bin/headroomd"
      prefix.install "Headroom.app" if File.exist?("Headroom.app")
    end
  end

  # `brew services start headroom` runs the scheduler now and at login.
  # Not kept alive: quitting from the menu bar should stay quit.
  service do
    run [opt_bin/"headroomd"]
    keep_alive false
    process_type :interactive
    log_path var/"log/headroom.log"
    error_log_path var/"log/headroom.log"
  end

  def caveats
    <<~EOS
      Start the scheduler now and at login:
        brew services start headroom
      Then send your agents' heavy commands through it:
        headroom hook install
    EOS
  end

  test do
    assert_match "heavy", shell_output("#{bin}/headroom classify 'pnpm test'")
  end
end
