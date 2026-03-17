// ABOUTME: Tests for workspace tab restoration and custom tab reordering.
// ABOUTME: Verifies only fixed tabs are restored and custom tabs reorder deterministically.

import XCTest
@testable import FactoryFloor

final class WorkspaceTabStateTests: XCTestCase {
    func testCustomTabsPersistAsInfo() {
        XCTAssertEqual(RestorableWorkspaceTab(activeTab: .terminal(UUID())), .info)
        XCTAssertEqual(RestorableWorkspaceTab(activeTab: .browser(UUID())), .info)
    }

    func testEnvironmentRestoresToInfoWhenUnavailable() {
        XCTAssertEqual(RestorableWorkspaceTab.environment.workspaceTab(hasEnvironmentTab: false), .info)
        XCTAssertEqual(RestorableWorkspaceTab.environment.workspaceTab(hasEnvironmentTab: true), .environment)
    }

    func testReorderedCustomTabsKeepsFixedTabsInPlace() {
        let terminalA = WorkspaceTab.terminal(UUID(uuidString: "AAAAAAAA-AAAA-AAAA-AAAA-AAAAAAAAAAAA")!)
        let browserB = WorkspaceTab.browser(UUID(uuidString: "BBBBBBBB-BBBB-BBBB-BBBB-BBBBBBBBBBBB")!)
        let terminalC = WorkspaceTab.terminal(UUID(uuidString: "CCCCCCCC-CCCC-CCCC-CCCC-CCCCCCCCCCCC")!)
        let tabs: [WorkspaceTab] = [.info, .agent, .environment, terminalA, browserB, terminalC]

        let reordered = reorderedCustomTabs(tabs, dragging: terminalC, to: terminalA)

        XCTAssertEqual(reordered, [.info, .agent, .environment, terminalC, terminalA, browserB])
    }
}
