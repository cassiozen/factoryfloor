// ABOUTME: NSViewRepresentable that bridges a TerminalView into SwiftUI.
// ABOUTME: Manages the lifecycle of terminal surfaces per project, caching them for fast switching.

import SwiftUI

struct TerminalContainerView: NSViewRepresentable {
    let projectID: UUID?
    let workingDirectory: String?

    @EnvironmentObject var surfaceCache: TerminalSurfaceCache

    func makeNSView(context: Context) -> NSView {
        let container = NSView()
        container.wantsLayer = true
        return container
    }

    func updateNSView(_ container: NSView, context: Context) {
        // Remove all existing subviews
        container.subviews.forEach { $0.removeFromSuperview() }

        guard let projectID else { return }
        guard let app = TerminalApp.shared.app else { return }

        let terminalView = surfaceCache.surface(
            for: projectID,
            app: app,
            workingDirectory: workingDirectory
        )

        container.addSubview(terminalView)
        terminalView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            terminalView.topAnchor.constraint(equalTo: container.topAnchor),
            terminalView.bottomAnchor.constraint(equalTo: container.bottomAnchor),
            terminalView.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            terminalView.trailingAnchor.constraint(equalTo: container.trailingAnchor),
        ])

        // Focus the terminal after a brief delay to let the view settle
        DispatchQueue.main.async {
            terminalView.setFocused(true)
        }
    }
}

/// Caches terminal surfaces so switching projects doesn't destroy/recreate them.
final class TerminalSurfaceCache: ObservableObject {
    private var surfaces: [UUID: TerminalView] = [:]

    func surface(for projectID: UUID, app: ghostty_app_t, workingDirectory: String?) -> TerminalView {
        if let existing = surfaces[projectID] {
            return existing
        }
        let view = TerminalView(app: app, workingDirectory: workingDirectory)
        surfaces[projectID] = view
        return view
    }

    func removeSurface(for projectID: UUID) {
        surfaces.removeValue(forKey: projectID)
    }
}
