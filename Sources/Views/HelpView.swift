// ABOUTME: Help view showing app info, version, and keyboard shortcuts.
// ABOUTME: Displayed in the detail pane via the help icon or Cmd+?.

import SwiftUI

struct HelpView: View {
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // App header
                VStack(spacing: 8) {
                    Image(systemName: "terminal.fill")
                        .font(.system(size: 48))
                        .foregroundStyle(.secondary)
                    Text(AppConstants.appID)
                        .font(.system(size: 28, weight: .bold))
                    Text("Version \(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "0.1.0")")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding(.top, 32)

                // Shortcuts
                Form {
                    Section("Navigation") {
                        ShortcutRow(keys: "0", description: "Project view")
                        ShortcutRow(keys: "1", description: "Info tab")
                        ShortcutRow(keys: "2", description: "Coding Agent tab")
                        ShortcutRow(keys: "3", description: "Terminal tab")
                        ShortcutRow(keys: "4", description: "Browser tab")
                        ShortcutRow(keys: "[ ]", shift: true, description: "Cycle tabs")
                    }

                    Section("Projects & Workstreams") {
                        ShortcutRow(keys: "N", description: "New workstream (in project) or project")
                        ShortcutRow(keys: "N", shift: true, description: "New project")
                    }

                    Section("External Apps") {
                        ShortcutRow(keys: "O", shift: true, description: "Open in external browser")
                        ShortcutRow(keys: "E", shift: true, description: "Open in external terminal")
                    }

                    Section("App") {
                        ShortcutRow(keys: ",", description: "Settings")
                        ShortcutRow(keys: "?", shift: true, description: "Help")
                    }
                }
                .formStyle(.grouped)
                .scrollDisabled(true)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

private struct ShortcutRow: View {
    let keys: String
    var shift: Bool = false
    let description: String

    var body: some View {
        LabeledContent(description) {
            HStack(spacing: 2) {
                Image(systemName: "command")
                if shift {
                    Image(systemName: "shift")
                }
                Text(keys)
            }
            .font(.system(size: 12, design: .monospaced))
            .foregroundStyle(.secondary)
        }
    }
}
