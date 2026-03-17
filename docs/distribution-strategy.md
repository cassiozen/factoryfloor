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

### 3. Mac App Store

**Not recommended for Factory Floor.**

**Why:**
- **Sandboxing required.** Factory Floor needs to: run arbitrary processes (Claude, git, tmux), access any directory on disk, manage git worktrees, execute setup/teardown scripts. All of these are incompatible with the App Store sandbox.
- **No terminal embedding.** Embedding Ghostty (Metal-rendered terminal via libghostty) in a sandboxed app would require significant entitlements that Apple may reject.
- **Review delays.** Each release goes through Apple review (1-7 days), incompatible with rapid iteration.
- **Revenue cut.** Apple takes 15-30% of any paid tier.

**If reconsidered:** Would require a separate "App Store edition" with reduced functionality (no terminal, no git worktrees, limited to a web-based agent interface). Not worth the effort for the target audience.

## Auto-Update Strategy

### Recommended: Sparkle

[Sparkle](https://sparkle-project.org/) is the standard macOS auto-update framework for non-App Store apps.

**How it works:**
1. App checks an appcast XML feed on startup (and periodically)
2. If a newer version is found, shows an update dialog
3. User clicks "Install Update"
4. Sparkle downloads the DMG, verifies EdDSA signature, replaces the app, relaunches

**Implementation plan:**

1. Add Sparkle as a dependency in `project.yml`:
   ```yaml
   packages:
     Sparkle:
       url: https://github.com/sparkle-project/Sparkle
       from: "2.6.0"
   ```

2. Generate EdDSA signing keys:
   ```bash
   ./Sparkle.framework/bin/generate_keys
   ```
   Store private key in CI secrets. Public key goes in Info.plist.

3. Add to Info.plist:
   ```xml
   <key>SUFeedURL</key>
   <string>https://factory-floor.com/appcast.xml</string>
   <key>SUPublicEDKey</key>
   <string>PUBLIC_KEY_HERE</string>
   ```

4. Host `appcast.xml` on GitHub Pages (alongside the website).

5. CI release workflow generates the appcast entry after building the DMG:
   ```bash
   ./Sparkle.framework/bin/generate_appcast /path/to/releases/
   ```

6. The `bleedingEdge` setting (already in the app) controls which update channel to follow: stable releases vs pre-release builds.

**Sparkle + Homebrew coexistence:**
- Homebrew users: Sparkle detects the app is managed by Homebrew (via receipt) and can defer to `brew upgrade`. Or Sparkle can update independently (the Homebrew formula just won't know about the update until the next `brew update`).
- Direct download users: Sparkle handles everything.

### Alternative: Manual check with GitHub API

Lighter than Sparkle but worse UX:
- On launch, check `gh api repos/alltuner/factoryfloor/releases/latest` for the newest version
- Compare with current version from Info.plist
- Show a badge/banner if an update is available
- Link to the GitHub release page for manual download

**Pros:** No framework dependency, simple implementation.
**Cons:** No automatic installation, users still manually download and replace.

## Recommendation

1. **Now:** Homebrew + Direct DMG (both already working)
2. **Post-launch:** Add Sparkle for direct-download users. Use the `bleedingEdge` toggle for beta channel.
3. **Never:** Mac App Store (incompatible with the app's architecture)

## Decision Summary

| Channel | Status | Auto-update | Sandboxed | Target audience |
|---------|--------|-------------|-----------|-----------------|
| Homebrew Cask | Live | Via `brew upgrade` | No | Developers (primary) |
| Direct DMG | Live | None (Sparkle planned) | No | Non-Homebrew users |
| Mac App Store | Not planned | Via App Store | Yes (blocking) | N/A |
