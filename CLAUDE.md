# Claude Usage — Developer Notes

A SwiftUI macOS menu bar app that polls the Anthropic usage API and shows subscription usage. This file captures what future-you (or Claude) needs to work on this repo: layout, how the auth/API actually work, and the testing + release steps.

## Architecture

Swift Package with two targets:

- `ClaudeUsageCore` — pure library, no UI. Contains:
  - `KeychainHelper.swift` — reads OAuth token from `~/.claude/.credentials.json` first, then falls back to macOS Keychain (`Claude Code-credentials` service). Caches in memory for the session; call `clearCachedToken()` to force re-read.
  - `UsageData.swift` — Codable models for the API response, plus `UsageData.from(response:)` which normalizes/clamps values and parses ISO8601 reset dates.
  - `PeakTimeHelper.swift` — peak-hour math (weekdays 5am–11am PT).
- `ClaudeUsage` — the executable target (menu bar app).
  - `ClaudeUsageApp.swift` — `MenuBarExtra` entry point, shows `⬡ NN%` or `⬡ --`.
  - `UsageService.swift` — `@MainActor @Observable`, polls every 180s, handles retry/backoff/401/429.
  - `PopoverView.swift` — the dropdown UI (usage bars, peak badge, extra-usage line, Retry button on error).
  - `UsageBarView.swift` — progress bar with reset countdown.

Tests live under `Tests/ClaudeUsageCoreTests/` and use the Swift Testing framework (`@Test`, `#expect`, `#require`) — not XCTest.

## Auth & API — the tricky bits

The app does NOT use an API key. It reuses the OAuth token that `claude` (the CLI) stores on the user's machine:

- **Credentials file** (preferred, no prompt): `~/.claude/.credentials.json` — JSON shaped like `{"claudeAiOauth": {"accessToken": "sk-ant-oat01-..."}}`. Path can be overridden via `CLAUDE_CONFIG_DIR`.
- **Keychain fallback** (prompts once per launch): `security find-generic-password -s "Claude Code-credentials"`. Returns the same JSON blob as the credentials file.

The API endpoint:

```
GET https://api.anthropic.com/api/oauth/usage
Authorization: Bearer <token>
anthropic-beta: oauth-2025-04-20
```

**The `anthropic-beta` header is required.** Without it the API returns `401 authentication_error: "OAuth authentication is currently not supported."`

The response includes fields the model ignores (e.g. `seven_day_oauth_apps`, `seven_day_opus`, `seven_day_sonnet`, `seven_day_cowork`, `iguana_necktie`). `extra_usage.used_credits` and `monthly_limit` come back as JSON numbers with decimals (`0.0`, `3.50`) — models use `Double?`, not `Int?`, to avoid parse errors once credits accumulate.

## Error handling behavior

`UsageService` surfaces these strings via `lastError`:

| String | Meaning |
|---|---|
| `No OAuth token found` | No credentials file and no keychain entry. Popover shows `claude login` hint. |
| `Token expired — click Retry` | 401. Cached token is cleared; user clicks Retry to re-read. |
| `Rate limited` | 429. Backs off for `Retry-After` seconds (default 300). |
| `HTTP NNN` | Any other non-200. |
| `Network error` | URLSession threw (timeout 5s, or DNS/TLS failure). |
| `Incomplete data` / `Parse error` | Response decode failed. |

The Retry button calls `UsageService.retryNow()`, which clears `retryAfter`, clears the cached token, and forces `fetch()`. Without this users were stuck for 5 minutes after a transient 429.

## Manual testing

After making changes, run these before shipping:

```bash
# 1. Unit tests
swift test

# 2. Build the release binary + .app bundle
make bundle

# 3. Sanity-check the API with curl using the same token/headers the app uses
TOKEN=$(security find-generic-password -s "Claude Code-credentials" -w \
  | python3 -c "import sys,json; print(json.loads(sys.stdin.read())['claudeAiOauth']['accessToken'])")
curl -s -w "\nHTTP_STATUS:%{http_code}\n" \
  -H "Authorization: Bearer $TOKEN" \
  -H "anthropic-beta: oauth-2025-04-20" \
  "https://api.anthropic.com/api/oauth/usage"
# → should return 200 with five_hour/seven_day/extra_usage JSON

# 4. Install locally and launch (replaces /Applications/ClaudeUsage.app).
#    Quit the running instance first or the copy will fail silently.
osascript -e 'tell application "ClaudeUsage" to quit'
make install
open /Applications/ClaudeUsage.app
```

Then click the menu bar icon and verify:
- Usage bars render with reasonable percentages and reset countdowns.
- Peak/off-peak badge matches current time (weekdays 5–11am PT = peak).
- Extra Usage line shows if `extra_usage.is_enabled` is true on your account.
- Forcing an error path works: temporarily rename `~/.claude/.credentials.json` and kill the app off the keychain — the "No OAuth token found" message and `claude login` hint should appear, and the Retry button should be visible.

## Releasing a new version

Version lives in two places — keep them in sync:
- `Makefile` → `VERSION = X.Y.Z`
- `Sources/ClaudeUsage/Info.plist` → `CFBundleShortVersionString`

Release flow:

```bash
# 1. Bump both version fields, commit.
# 2. Build + test (as above: swift test, make bundle).
# 3. Produce the distributable zip:
make zip
# → ClaudeUsage-X.Y.Z.zip

# 4. Tag and push:
git tag vX.Y.Z
git push origin main
git push origin vX.Y.Z
```

**Manual step (the GitHub release itself):** create the release in the browser — if `gh auth` is signed into a different account on your machine, `gh release create` won't have access:

1. Go to https://github.com/aarongraham/claude-usage/releases/new
2. Choose the `vX.Y.Z` tag
3. Title: `vX.Y.Z`
4. Attach `ClaudeUsage-X.Y.Z.zip` from the repo root
5. Write release notes (a few bullets about what changed is plenty)
6. Publish

After publishing, update the download link version in `README.md` if the user-facing docs mention a specific zip filename.

## Common pitfalls

- **Don't** add `@testable import` for types that need to stay `public` — the core library exposes its API via `public` on purpose so the app target can use it.
- **Don't** change the polling interval much below 180s without adding smarter backoff — the API will 429.
- **Don't** remove the `anthropic-beta` header; the API rejects OAuth without it.
- **Don't** amend shipped commits; history past `v1.0.0` is public.
- The running menu bar app holds an exclusive lock on the bundle — `make install` will appear to succeed but run the old binary if you forget to quit the app first.
