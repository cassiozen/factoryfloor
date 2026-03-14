# ff2

A macOS terminal app for managing coding projects with embedded [Ghostty](https://ghostty.org) terminals.

Each project maps to a directory on disk. Inside each project you create workstreams, each with its own set of tabs: a coding agent terminal, a workspace terminal, and an embedded browser for previewing local dev servers.

## Build

Requires: Xcode, XcodeGen (`brew install xcodegen`), Zig (`brew install zig`).

```bash
# First time: build the Ghostty terminal engine
cd ghostty && zig build -Demit-xcframework=true -Dxcframework-target=universal -Doptimize=ReleaseFast && cd ..

# Build the app
./dev.sh build

# Build and run
./dev.sh br

# Run (if already built)
./dev.sh run

# Run with a specific directory
./dev.sh run ~/repos/myproject

# Run tests
./dev.sh test

# Release build
./dev.sh build-release
```

## Projects

Every project is created under the **base directory** (configurable in Settings, defaults to `~/Documents`). You can add projects by:

- **Cmd+Shift+N** to open the directory picker
- **Cmd+N** when no workstream is selected
- Dragging a folder onto the sidebar
- Running `./dev.sh run /path/to/project` from the terminal

If a project with the same directory already exists, it will be activated instead of duplicated.

## Keyboard Shortcuts

### Global

| Shortcut | Action |
|---|---|
| Cmd+N | Context-sensitive: add workstream (if in a project) or add project |
| Cmd+Shift+N | Add new project |
| Cmd+, | Toggle settings |

### Workstream Tabs

| Shortcut | Action |
|---|---|
| Cmd+Shift+A | Switch to Coding Agent tab |
| Cmd+Shift+T | Switch to Terminal tab |
| Cmd+Shift+B | Switch to Browser tab (reloads default URL) |
| Cmd+Shift+O | Open default URL in external browser |

## Workstream Tabs

Each workstream has three tabs:

- **Coding Agent** — runs the `claude` CLI if installed, otherwise a regular shell
- **Terminal** — workspace shell for running commands
- **Browser** — embedded WKWebView, defaults to `http://localhost:8000`

## Settings

Open with **Cmd+,** or click the gear icon in the sidebar.

- **Environment** — shows detected tools (claude, gh, git, tmux) with versions
- **Projects** — base directory for new projects
- **Terminal** — tmux mode, external terminal app
- **Coding Agent** — bypass permission prompts
- **Applications** — default external browser
- **Language** — override the app language (English, Catalan, Spanish, Swedish)

## Localization

All user-facing strings are localized. To add a new language:

1. Copy `Localization/en.lproj` to `Localization/xx.lproj`
2. Translate all values in `Localizable.strings` (keep keys unchanged)
3. Run `xcodegen generate` to pick up the new locale
4. Add the new lproj path to `project.yml` under sources

See [CLAUDE.md](CLAUDE.md) for localization rules when writing code.
