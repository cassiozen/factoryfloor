// ABOUTME: Info tab for a workstream showing metadata and rendered README.md.
// ABOUTME: Default tab when opening a workstream.

import SwiftUI

struct WorkstreamInfoView: View {
    let workstreamName: String
    let workingDirectory: String
    let projectName: String

    @State private var readmeContent: String?
    @State private var branchName: String?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // Workstream metadata
                Form {
                    Section("Workstream") {
                        LabeledContent("Name") {
                            Text(workstreamName)
                                .font(.system(.body, design: .monospaced))
                        }

                        if let branch = branchName {
                            LabeledContent("Branch") {
                                HStack(spacing: 4) {
                                    Image(systemName: "arrow.triangle.branch")
                                        .font(.caption)
                                    Text(branch)
                                }
                                .foregroundStyle(.secondary)
                            }
                        }

                        LabeledContent("Directory") {
                            Text(abbreviatePath(workingDirectory))
                                .font(.system(.body, design: .monospaced))
                                .foregroundStyle(.secondary)
                                .lineLimit(1)
                                .truncationMode(.middle)
                        }

                        LabeledContent("Project") {
                            Text(projectName)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                .formStyle(.grouped)
                .scrollDisabled(true)
                .frame(maxHeight: 200)

                // README
                if let readme = readmeContent {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Image(systemName: "doc.text")
                                .foregroundStyle(.secondary)
                            Text("README.md")
                                .font(.system(.body, weight: .medium))
                                .foregroundStyle(.secondary)
                        }
                        .padding(.horizontal, 24)

                        MarkdownView(markdown: readme)
                            .padding(.horizontal, 16)
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .onAppear { loadInfo() }
    }

    private func loadInfo() {
        // Load branch name
        Task.detached {
            let branch = GitOperations.repoInfo(at: workingDirectory).branch
            await MainActor.run { branchName = branch }
        }

        // Load README.md
        let readmePath = URL(fileURLWithPath: workingDirectory).appendingPathComponent("README.md")
        Task.detached {
            guard let content = try? String(contentsOfFile: readmePath.path, encoding: .utf8) else { return }
            await MainActor.run { readmeContent = content }
        }
    }

    private func abbreviatePath(_ path: String) -> String {
        let home = FileManager.default.homeDirectoryForCurrentUser.path
        if path.hasPrefix(home) {
            return "~" + path.dropFirst(home.count)
        }
        return path
    }
}
