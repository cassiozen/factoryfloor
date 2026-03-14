// ABOUTME: Detects installed tools and apps at startup.
// ABOUTME: Shared across the app as an environment object.

import SwiftUI

@MainActor
final class AppEnvironment: ObservableObject {
    @Published var toolStatus = ToolStatus()
    @Published var installedTerminals: [AppInfo] = []
    @Published var installedBrowsers: [AppInfo] = []
    @Published var isDetecting = false

    func refresh() {
        isDetecting = true
        Task.detached {
            let tools = await ToolStatus.detect()
            let terminals = AppInfo.detectTerminals()
            let browsers = AppInfo.detectBrowsers()
            await MainActor.run {
                self.toolStatus = tools
                self.installedTerminals = terminals
                self.installedBrowsers = browsers
                self.isDetecting = false
            }
        }
    }
}
