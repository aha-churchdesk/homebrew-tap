# aha-churchdesk/tap

Homebrew formulae for [Headroom](https://github.com/aha-churchdesk/headroom), a macOS menu bar app that queues heavy dev commands from parallel coding agents so they don't run the Mac out of memory.

```sh
brew install aha-churchdesk/tap/headroom
brew services start headroom
headroom hook install
```

Apple Silicon only. Every hour, `.github/workflows/bump.yml` moves each formula's `url` and `sha256` to its project's latest GitHub release; run it from the Actions tab to pick up a release at once. Everything else in a formula is edited here by hand.
