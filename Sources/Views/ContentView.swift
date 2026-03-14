// ABOUTME: Main application view composing the sidebar and terminal content area.
// ABOUTME: Uses NavigationSplitView for the sidebar/detail pattern.

import SwiftUI

struct ContentView: View {
    @State private var projects: [Project] = ProjectStore.load()
    @State private var selectedWorkstreamID: UUID?
    @State private var focusedProjectID: UUID?
    @StateObject private var surfaceCache = TerminalSurfaceCache()

    /// The currently relevant project, derived from selected workstream or explicit focus.
    private var activeProject: Project? {
        if let wsID = selectedWorkstreamID {
            return projects.first(where: { $0.workstreams.contains(where: { $0.id == wsID }) })
        }
        if let pid = focusedProjectID {
            return projects.first(where: { $0.id == pid })
        }
        return nil
    }

    var body: some View {
        NavigationSplitView {
            ProjectSidebar(
                projects: $projects,
                selectedWorkstreamID: $selectedWorkstreamID,
                focusedProjectID: $focusedProjectID,
                onProjectsChanged: { ProjectStore.save(projects) }
            )
            .navigationSplitViewColumnWidth(min: 160, ideal: 200, max: 350)
        } detail: {
            if let selectedWorkstreamID,
               let project = activeProject,
               let workstream = project.workstreams.first(where: { $0.id == selectedWorkstreamID }) {
                TerminalContainerView(
                    workstreamID: selectedWorkstreamID,
                    workingDirectory: project.directory
                )
                .id(selectedWorkstreamID)
                .navigationTitle(workstream.name)
                .navigationSubtitle(project.name)
            } else if let project = activeProject {
                VStack(spacing: 12) {
                    Text("No workstream selected")
                        .font(.title2)
                        .foregroundStyle(.secondary)
                    Text("Create a workstream to get started.")
                        .foregroundStyle(.tertiary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .navigationTitle(project.name)
                .navigationSubtitle("ff2")
            } else {
                VStack(spacing: 12) {
                    Text("No project selected")
                        .font(.title2)
                        .foregroundStyle(.secondary)
                    Text("Add a project from the sidebar to get started.")
                        .foregroundStyle(.tertiary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .navigationTitle("ff2")
            }
        }
        .environmentObject(surfaceCache)
        .onChange(of: projects) { _, newValue in
            ProjectStore.save(newValue)
        }
    }
}

enum ProjectStore {
    private static let key = "ff2.projects"

    static func load() -> [Project] {
        guard let data = UserDefaults.standard.data(forKey: key) else { return [] }
        return (try? JSONDecoder().decode([Project].self, from: data)) ?? []
    }

    static func save(_ projects: [Project]) {
        guard let data = try? JSONEncoder().encode(projects) else { return }
        UserDefaults.standard.set(data, forKey: key)
    }
}
