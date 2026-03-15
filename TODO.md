# TODO

## Pre-release
- [ ] Choose final app name (currently "ff2" is a working name)
- [ ] Update bundle ID (`com.ff2.app` in project.yml)
- [ ] Update URL scheme (`ff2://` in Info.plist) to match final name
- [ ] Build and ship a standalone CLI binary (like `code` for VS Code)
- [ ] Code signing and notarization for distribution
- [ ] App icon
- [ ] Credits: David Poblador i Garcia, All Tuner Labs, Poblenou skyline

## Features
- [ ] Sidebar visual polish (custom styling beyond default SwiftUI)
- [ ] Split panes within a workstream
- [x] Rename projects (editable alias in project overview)
- [ ] Reorder projects via drag-and-drop in sidebar
- [x] Keyboard shortcuts for tabs (Cmd+0-4)
- [x] Help view with shortcuts reference
- [ ] External Chrome integration: launch Chrome with --remote-debugging-port, connect via CDP for WebMCP/Claude browser interaction
- [ ] Setup scripts: run commands when a worktree is created (e.g., npm install, pip install)
- [ ] Run scripts: configurable ways to start dev servers, build, or run the app (multiple per project)
- [ ] Teardown scripts: cleanup commands when archiving a workstream
- [x] PR management: show PRs in project overview and workstream info
- [x] GitHub integration: repo info, open PRs, branch PR status
- [x] Branch renaming: auto-rename via system prompt injection
- [ ] Archive warning: warn if worktree has uncommitted changes
- [x] Sidebar shows workstream branch name (in info tab)

## Terminal
- [x] Terminal resize flicker on session restart
- [ ] Sidebar toggle animation still causes minor flicker at the end
- [ ] Occlude non-visible terminal surfaces to save GPU (reverted, needs careful timing with initial render)
- [x] Tmux mode for session persistence
- [x] Claude session resume via --session-id
- [x] Auto-respawn on process exit

## Infrastructure
- [ ] Auto-update mechanism (Sparkle or similar)
- [ ] Crash reporting
- [ ] Move persistence from UserDefaults to a proper file (for larger state)
- [x] Settings panel
- [x] Git worktrees for workstreams
- [x] .env symlinks in worktrees
- [x] Deterministic port allocation per workstream

## Localization
- [x] Extract all user-facing strings to Localizable.strings
- [ ] Add translations (copy en.lproj to xx.lproj, translate strings)

## Probably not needed
- [ ] Claude Agent SDK integration (TypeScript): would give programmatic session control, but replaces the full CLI TUI we get for free. Only makes sense if building a custom chat UI, orchestrating multiple agents, or showing conversation metadata in the sidebar. The CLI + tmux + session-id approach covers our needs.
