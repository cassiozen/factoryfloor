// ABOUTME: SwiftUI sidebar showing the list of projects.
// ABOUTME: Supports adding and selecting projects, with the active project highlighted.

import SwiftUI

struct ProjectSidebar: View {
    @Binding var projects: [Project]
    @Binding var selectedProjectID: UUID?
    @State private var showingAddSheet = false
    @State private var newProjectName = ""
    @State private var newProjectDirectory = ""

    var body: some View {
        VStack(spacing: 0) {
            List(selection: $selectedProjectID) {
                ForEach(projects) { project in
                    ProjectRow(project: project)
                        .tag(project.id)
                }
                .onDelete(perform: deleteProjects)
            }
            .listStyle(.sidebar)

            Divider()

            HStack {
                Button(action: { showingAddSheet = true }) {
                    Image(systemName: "plus")
                }
                .buttonStyle(.plain)
                .padding(8)

                Spacer()
            }
        }
        .sheet(isPresented: $showingAddSheet) {
            AddProjectSheet(
                name: $newProjectName,
                directory: $newProjectDirectory,
                onAdd: addProject,
                onCancel: { showingAddSheet = false }
            )
        }
    }

    private func addProject() {
        guard !newProjectName.isEmpty, !newProjectDirectory.isEmpty else { return }
        let project = Project(name: newProjectName, directory: newProjectDirectory)
        projects.append(project)
        selectedProjectID = project.id
        newProjectName = ""
        newProjectDirectory = ""
        showingAddSheet = false
    }

    private func deleteProjects(at offsets: IndexSet) {
        let idsToDelete = offsets.map { projects[$0].id }
        projects.remove(atOffsets: offsets)
        if let selected = selectedProjectID, idsToDelete.contains(selected) {
            selectedProjectID = projects.first?.id
        }
    }
}

private struct ProjectRow: View {
    let project: Project

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(project.name)
                .font(.system(.body, weight: .medium))
            Text(abbreviatePath(project.directory))
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(1)
        }
        .padding(.vertical, 4)
    }

    private func abbreviatePath(_ path: String) -> String {
        let home = FileManager.default.homeDirectoryForCurrentUser.path
        if path.hasPrefix(home) {
            return "~" + path.dropFirst(home.count)
        }
        return path
    }
}

private struct AddProjectSheet: View {
    @Binding var name: String
    @Binding var directory: String
    let onAdd: () -> Void
    let onCancel: () -> Void

    var body: some View {
        VStack(spacing: 16) {
            Text("Add Project")
                .font(.headline)

            TextField("Project Name", text: $name)
                .textFieldStyle(.roundedBorder)

            HStack {
                TextField("Directory", text: $directory)
                    .textFieldStyle(.roundedBorder)

                Button("Browse...") {
                    let panel = NSOpenPanel()
                    panel.canChooseFiles = false
                    panel.canChooseDirectories = true
                    panel.allowsMultipleSelection = false
                    if panel.runModal() == .OK, let url = panel.url {
                        directory = url.path
                        if name.isEmpty {
                            name = url.lastPathComponent
                        }
                    }
                }
            }

            HStack {
                Button("Cancel", action: onCancel)
                    .keyboardShortcut(.cancelAction)
                Spacer()
                Button("Add", action: onAdd)
                    .keyboardShortcut(.defaultAction)
                    .disabled(name.isEmpty || directory.isEmpty)
            }
        }
        .padding(20)
        .frame(width: 400)
    }
}
