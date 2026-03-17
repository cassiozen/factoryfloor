# Distribution & Auto-Update Strategy

## Distribution Channels

### 1. Homebrew Cask (Primary, must-have)

**Status:** Live at `alltuner/homebrew-tap`

```bash
brew install --cask alltuner/tap/factoryfloor
```

**Pros:**
- Developer audience is already on Homebrew
- Automated via CI (cask updated on each release)
- No App Store review process
- No sandboxing requirements
- Version pinning and rollback via Homebrew

**Cons:**
- Users must have Homebrew installed
- No auto-update (users run `brew upgrade`)
- CLI (`ff`) not auto-installed by the cask (requires manual symlink)

**Update mechanism:** `brew upgrade --cask factoryfloor`. Homebrew checks for updates on `brew update` (daily by default).

### 2. Direct DMG Download (Secondary)

**Status:** Live via GitHub Releases

Users download `FactoryFloor-VERSION.dmg` from GitHub releases, open the DMG, drag to Applications.

**Pros:**
- No dependencies (no Homebrew needed)
- Works for any macOS user
- Full control over distribution

**Cons:**
- No auto-update out of the box
- Users must manually check for updates
- Gatekeeper prompts on first launch (mitigated by notarization)

**Update mechanism:** Requires Sparkle or similar (see below).

## Update Notifications (v1)

The app checks `https://factory-floor.com/versions.json` periodically (on launch + every 6 hours). If a newer stable version is available, a red badge appears in the sidebar linking to `factory-floor.com/get`.

**versions.json format:**
```json
{
  "stable": "0.1.0",
  "latest": "0.1.0"
}
```

Update `versions.json` when cutting a release (CI or manual).

## Auto-Update (Post-v1)

Sparkle integration planned for after the first release. See the Sparkle section below for implementation details. The `bleedingEdge` setting already exists for future beta channel support.

## Decision Summary

| Channel | Status | Update notification | Target |
|---------|--------|---------------------|--------|
| Homebrew Cask | Live | versions.json check | Developers (primary) |
| Direct DMG | Planned | versions.json check | Non-Homebrew users |
