// ABOUTME: Main application view composing the sidebar and terminal content area.
// ABOUTME: Uses NavigationSplitView for the sidebar/detail pattern.

import SwiftUI

struct ContentView: View {
    @State private var projects: [Project] = []
    @State private var selectedProjectID: UUID?
    @StateObject private var surfaceCache = TerminalSurfaceCache()

    var body: some View {
        NavigationSplitView {
            ProjectSidebar(
                projects: $projects,
                selectedProjectID: $selectedProjectID
            )
            .navigationSplitViewColumnWidth(min: 160, ideal: 200, max: 350)
        } detail: {
            if let selectedProjectID, let project = projects.first(where: { $0.id == selectedProjectID }) {
                TerminalContainerView(
                    projectID: project.id,
                    workingDirectory: project.directory
                )
                .id(project.id)
            } else {
                VStack(spacing: 12) {
                    Text("No project selected")
                        .font(.title2)
                        .foregroundStyle(.secondary)
                    Text("Add a project from the sidebar to get started.")
                        .foregroundStyle(.tertiary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .environmentObject(surfaceCache)
    }
}
