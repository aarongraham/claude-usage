# Claude Usage

A macOS menu bar app that shows your Anthropic (Claude) subscription usage at a glance.

> **Disclaimer:** This is a vibe-coded app I made for myself. It works for me on macOS 15. No guarantees, no support, no roadmap. If it works for you too, great.

![Claude Usage screenshot](screenshot.png)

## What it does

- Shows your 5-hour session usage percentage in the menu bar
- Click to expand a popover with:
  - 5-hour session usage with reset countdown
  - Weekly usage with reset countdown
  - Peak/off-peak indicator (weekdays 5am-11am PT)
  - Extra usage spend (if enabled on your account)
- Polls the Anthropic usage API every 3 minutes
- Menu bar text shifts to orange during peak hours

## Requirements

- macOS 15.0+
- An active Claude Pro or Max subscription
- Claude Code installed and authenticated (the app reads your OAuth token from the macOS Keychain)

## Install

### From release

1. Download `ClaudeUsage-1.1.2.zip` from [Releases](https://github.com/aarongraham/claude-usage/releases)
2. Unzip and drag `ClaudeUsage.app` to `/Applications`
3. Open it. If macOS blocks it, go to System Settings > Privacy & Security and click "Open Anyway"

### From source

```bash
git clone https://github.com/aarongraham/claude-usage.git
cd claude-usage
make install
```

Requires Xcode or Xcode Command Line Tools with Swift 6.0+.

#### One-time: create a self-signed code signing cert

The Makefile signs the bundle with a stable identity called `ClaudeUsage Self-Signed`. Without it, `make install` fails with `errSecCSNoIdentity`, and even if you override with ad-hoc signing, macOS will re-prompt you with "ClaudeUsage wants to access 'Claude Code-credentials' in your keychain" after every rebuild (because ad-hoc signatures change on each build, invalidating the Keychain's "Always Allow" grant).

Create the cert once per machine:

1. Open **Keychain Access** (⌘+Space → "Keychain Access")
2. Menu bar → **Keychain Access** → **Certificate Assistant** → **Create a Certificate…**
3. Fill in:
   - **Name:** `ClaudeUsage Self-Signed`
   - **Identity Type:** Self Signed Root
   - **Certificate Type:** Code Signing
4. Click **Create** and accept the warning
5. Run `make install`. On first launch, macOS will ask once to access the Keychain — click **Always Allow**. It should stick from then on across rebuilds.

No paid Apple Developer account required — the cert lives only in your login Keychain.

If you'd rather skip the cert, override with ad-hoc signing (you'll see the Keychain prompt on every rebuild):

```bash
make install CODESIGN_IDENTITY=-
```

## How it works

The app reads your Claude Code OAuth token from the macOS Keychain (`Claude Code-credentials` service) and calls `GET https://api.anthropic.com/api/oauth/usage` to get your current usage data. No API keys are stored in the app - it piggybacks on your existing Claude Code authentication.

## License

MIT
