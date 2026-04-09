// ABOUTME: Embedded code editor with a file tree sidebar for navigating the worktree.
// ABOUTME: Supports syntax highlighting for 41+ languages via tree-sitter, file save, and dirty state tracking.

import CodeEditLanguages
import CodeEditSourceEditor
import SwiftUI

struct EditorView: View {
    let workingDirectory: String
    let fileTree: [FileNode]
    let initialFilePath: String?
    var onDirtyChanged: ((Bool) -> Void)?
    var onFileChanged: ((String?) -> Void)?

    // Current file state
    @State private var currentFilePath: String?
    @State private var text: String = ""
    @State private var originalText: String = ""
    @State private var editorState = SourceEditorState()
    @State private var language: CodeLanguage = .default
    @State private var fileLoaded = false
    @State private var loadError: String?

    // File tree visibility
    @State private var showFileTree = true

    // Save confirmation for file switching
    @State private var pendingFilePath: String?
    @State private var showSaveAlert = false

    private var isDirty: Bool { text != originalText }

    private var currentFileName: String {
        guard let path = currentFilePath else { return "file" }
        return (path as NSString).lastPathComponent
    }

    private var configuration: SourceEditorConfiguration {
        SourceEditorConfiguration(
            appearance: .init(
                theme: Self.terminalTheme,
                font: .monospacedSystemFont(ofSize: 13, weight: .regular),
                wrapLines: true
            ),
            peripherals: .init(showMinimap: false)
        )
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
                    .clipped()
            }
        }
        .onAppear {
            if let initialFilePath, currentFilePath == nil {
                navigateToFile(initialFilePath)
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
                saveFile()
                if let pending = pendingFilePath {
                    navigateToFile(pending)
                }
                pendingFilePath = nil
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
        .onChange(of: text) {
            onDirtyChanged?(isDirty)
        }
        .onReceive(NotificationCenter.default.publisher(for: .saveEditor)) { _ in
            saveFile()
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
        FileTreeView(nodes: fileTree, selectedPath: currentFilePath) { selectedPath in
            handleFileSelection(selectedPath)
        }
    }

    // MARK: - Editor Panel

    @ViewBuilder
    private var editorPanel: some View {
        if currentFilePath == nil {
            VStack(spacing: 12) {
                Image(systemName: "doc.text")
                    .font(.system(size: 36))
                    .foregroundStyle(.tertiary)
                Text("Select a file to edit")
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else if let loadError {
            VStack(spacing: 12) {
                Image(systemName: "exclamationmark.triangle")
                    .font(.system(size: 36))
                    .foregroundStyle(.tertiary)
                Text(loadError)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else if fileLoaded {
            SourceEditor(
                $text,
                language: language,
                configuration: configuration,
                state: $editorState
            )
            .id(currentFilePath)
        } else {
            ProgressView()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
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
        // Reset editor state
        text = ""
        originalText = ""
        editorState = SourceEditorState()
        fileLoaded = false
        loadError = nil

        currentFilePath = relativePath
        onFileChanged?(relativePath)
        onDirtyChanged?(false)
        loadFile()
    }

    // MARK: - File I/O

    private func loadFile() {
        guard let relativePath = currentFilePath else { return }
        let fullPath = (workingDirectory as NSString).appendingPathComponent(relativePath)
        let url = URL(fileURLWithPath: fullPath)
        language = CodeLanguage.detectLanguageFrom(url: url)

        do {
            let content = try String(contentsOf: url, encoding: .utf8)
            text = content
            originalText = content
            fileLoaded = true
        } catch {
            loadError = error.localizedDescription
        }
    }

    private func saveFile() {
        guard let relativePath = currentFilePath, fileLoaded, isDirty else { return }
        let fullPath = (workingDirectory as NSString).appendingPathComponent(relativePath)
        do {
            try text.write(toFile: fullPath, atomically: true, encoding: .utf8)
            originalText = text
            onDirtyChanged?(false)
        } catch {
            loadError = error.localizedDescription
        }
    }

    // MARK: - Theme

    private static var terminalTheme: EditorTheme {
        guard let config = TerminalApp.shared.config else { return fallbackTheme }
        return TerminalPalette.from(config).editorTheme
    }

    private static let fallbackTheme = EditorTheme(
        text: .init(color: NSColor(red: 0.83, green: 0.84, blue: 0.86, alpha: 1)),
        insertionPoint: .white,
        invisibles: .init(color: NSColor(white: 0.4, alpha: 1)),
        background: NSColor(red: 0.11, green: 0.12, blue: 0.14, alpha: 1),
        lineHighlight: NSColor(white: 1, alpha: 0.05),
        selection: NSColor(red: 0.24, green: 0.34, blue: 0.56, alpha: 1),
        keywords: .init(color: NSColor(red: 0.99, green: 0.37, blue: 0.53, alpha: 1)),
        commands: .init(color: NSColor(red: 0.67, green: 0.44, blue: 0.77, alpha: 1)),
        types: .init(color: NSColor(red: 0.39, green: 0.72, blue: 0.64, alpha: 1)),
        attributes: .init(color: NSColor(red: 0.93, green: 0.64, blue: 0.36, alpha: 1)),
        variables: .init(color: NSColor(red: 0.83, green: 0.84, blue: 0.86, alpha: 1)),
        values: .init(color: NSColor(red: 0.42, green: 0.64, blue: 0.87, alpha: 1)),
        numbers: .init(color: NSColor(red: 0.85, green: 0.73, blue: 0.42, alpha: 1)),
        strings: .init(color: NSColor(red: 0.64, green: 0.83, blue: 0.41, alpha: 1)),
        characters: .init(color: NSColor(red: 0.93, green: 0.64, blue: 0.36, alpha: 1)),
        comments: .init(color: NSColor(white: 0.45, alpha: 1), italic: true)
    )
}
