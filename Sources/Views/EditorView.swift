// ABOUTME: Embedded code editor with a file tree sidebar for navigating the worktree.
// ABOUTME: Uses Monaco editor in a shared WKWebView via MonacoEditorBridge for syntax highlighting.

import SwiftUI
import WebKit

struct EditorView: View {
    let workingDirectory: String
    let fileTree: [FileNode]
    let gitStatus: GitFileStatusProvider
    let initialFilePath: String?
    let bridge: MonacoEditorBridge
    let modelId: String
    @Binding var isDirtyState: Bool
    var onFileChanged: ((String?) -> Void)?
    var onExpandFolder: ((String) -> Void)?

    // Current file state
    @State private var currentFilePath: String?
    @State private var fileLoaded = false
    @State private var loadError: String?

    /// File tree visibility
    @State private var showFileTree = true

    // Save confirmation for file switching
    @State private var pendingFilePath: String?
    @State private var showSaveAlert = false

    private var isDirty: Bool {
        isDirtyState
    }

    private var currentFileName: String {
        guard let path = currentFilePath else { return "file" }
        return (path as NSString).lastPathComponent
    }

    var body: some View {
        HStack(spacing: 0) {
            if showFileTree {
                fileTreePanel
                    .frame(width: 220)
                Divider()
            }
            VStack(spacing: 0) {
                editorToolbar
                editorPanel
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .onAppear {
            if let initialFilePath, currentFilePath == nil {
                navigateToFile(initialFilePath)
            } else if fileLoaded {
                bridge.switchModel(modelId: modelId)
            }
        }
        .alert(
            Text(String(
                format: NSLocalizedString("Do you want to save changes to \"%@\"?", comment: ""),
                currentFileName
            )),
            isPresented: $showSaveAlert
        ) {
            Button(NSLocalizedString("Save", comment: "")) {
                Task {
                    await saveFile()
                    if let pending = pendingFilePath {
                        navigateToFile(pending)
                    }
                    pendingFilePath = nil
                }
            }
            Button(NSLocalizedString("Don't Save", comment: ""), role: .destructive) {
                if let pending = pendingFilePath {
                    navigateToFile(pending)
                }
                pendingFilePath = nil
            }
            Button(NSLocalizedString("Cancel", comment: ""), role: .cancel) {
                pendingFilePath = nil
            }
        } message: {
            Text("Your changes will be lost if you don't save them.")
        }
        .onReceive(NotificationCenter.default.publisher(for: .saveEditor)) { _ in
            Task { await saveFile() }
        }
        .onReceive(NotificationCenter.default.publisher(for: .saveEditorAs)) { _ in
            Task { await saveFileAs() }
        }
    }

    // MARK: - Editor Toolbar

    private var editorToolbar: some View {
        HStack {
            Button {
                withAnimation(.easeInOut(duration: 0.15)) {
                    showFileTree.toggle()
                }
            } label: {
                Image(systemName: "sidebar.left")
                    .foregroundStyle(showFileTree ? .primary : .secondary)
            }
            .buttonStyle(.plain)
            .help("Toggle file tree")

            if let currentFilePath {
                Text((currentFilePath as NSString).lastPathComponent)
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }

            Spacer()
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(.bar)
    }

    // MARK: - File Tree Panel

    private var fileTreePanel: some View {
        FileTreeView(nodes: fileTree, selectedPath: currentFilePath, gitStatus: gitStatus) { selectedPath in
            handleFileSelection(selectedPath)
        } onExpandFolder: { path in
            onExpandFolder?(path)
        }
    }

    // MARK: - Editor Panel

    /// MonacoEditorView is ALWAYS in the tree so the WKWebView starts loading
    /// immediately when the editor tab opens (before the user picks a file).
    /// Placeholder and error states overlay on top with opaque backgrounds.
    private var editorPanel: some View {
        ZStack {
            MonacoEditorView(bridge: bridge)
            if currentFilePath == nil {
                VStack(spacing: 12) {
                    Image(systemName: "doc.text")
                        .font(.system(size: 36))
                        .foregroundStyle(.tertiary)
                    Text("Select a file to edit")
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(.background)
            } else if let loadError {
                VStack(spacing: 12) {
                    Image(systemName: "exclamationmark.triangle")
                        .font(.system(size: 36))
                        .foregroundStyle(.tertiary)
                    Text(loadError)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(.background)
            }
        }
    }

    // MARK: - Navigation

    private func handleFileSelection(_ path: String) {
        guard path != currentFilePath else { return }

        if isDirty {
            pendingFilePath = path
            showSaveAlert = true
        } else {
            navigateToFile(path)
        }
    }

    private func navigateToFile(_ relativePath: String) {
        // Don't toggle fileLoaded — MonacoEditorView must stay in the tree.
        // Just clear errors and update the path; loadFile() will push new content.
        loadError = nil
        isDirtyState = false

        currentFilePath = relativePath
        onFileChanged?(relativePath)

        loadFile()
    }

    // MARK: - File I/O

    private func loadFile() {
        guard let relativePath = currentFilePath else { return }
        let fullPath = (workingDirectory as NSString).appendingPathComponent(relativePath)
        let url = URL(fileURLWithPath: fullPath)

        do {
            let content = try String(contentsOf: url, encoding: .utf8)
            let fileName = (relativePath as NSString).lastPathComponent
            let langId = MonacoLanguage.id(for: fileName)
            bridge.openFile(modelId: modelId, text: content, languageId: langId, filePath: fullPath)
            isDirtyState = false
            fileLoaded = true
            loadError = nil
        } catch {
            loadError = error.localizedDescription
        }
    }

    private func saveFile() async {
        guard let relativePath = currentFilePath, fileLoaded, isDirty else { return }
        let fullPath = (workingDirectory as NSString).appendingPathComponent(relativePath)
        guard let content = await bridge.getContent(modelId: modelId) else { return }
        do {
            try content.write(toFile: fullPath, atomically: true, encoding: .utf8)
            bridge.markClean(modelId: modelId)
            isDirtyState = false

        } catch {
            loadError = error.localizedDescription
        }
    }

    private func saveFileAs() async {
        guard fileLoaded else { return }
        guard let content = await bridge.getContent(modelId: modelId) else { return }

        let panel = NSSavePanel()
        panel.nameFieldStringValue = currentFileName
        if let currentFilePath {
            let fullPath = (workingDirectory as NSString).appendingPathComponent(currentFilePath)
            panel.directoryURL = URL(fileURLWithPath: fullPath).deletingLastPathComponent()
        }

        guard let window = NSApp.keyWindow else { return }
        let response = await panel.beginSheetModal(for: window)
        guard response == .OK, let url = panel.url else { return }

        do {
            try content.write(to: url, atomically: true, encoding: .utf8)
            bridge.markClean(modelId: modelId)
            isDirtyState = false

        } catch {
            loadError = error.localizedDescription
        }
    }
}
