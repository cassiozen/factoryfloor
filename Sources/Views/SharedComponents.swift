// ABOUTME: Reusable UI primitives shared across views.
// ABOUTME: IconActionButton, InlineTabButton, and StatusBadge.

import SwiftUI

/// A small icon button with hover effect. Replaces SidebarIconButton, SidebarBottomButton, DirectoryActionButton.
struct IconActionButton: View {
    var icon: String = ""
    var assetIcon: String?
    var size: CGFloat = 22
    var iconSize: CGFloat = 11
    var color: Color?
    var tooltip: String?
    let action: () -> Void

    @State private var isHovering = false

    var body: some View {
        Button(action: action) {
            (assetIcon.map { Image($0) } ?? Image(systemName: icon))
                .font(.system(size: iconSize))
                .foregroundStyle(color ?? (isHovering ? Color.primary : Color.secondary))
                .frame(width: size, height: size)
                .background(isHovering ? FFDesign.Colors.hoverBg : .clear)
                .clipShape(RoundedRectangle(cornerRadius: FFDesign.Radii.small))
        }
        .buttonStyle(.borderless)
        .onHover { isHovering = $0 }
        .help(tooltip ?? "")
        .accessibilityLabel(tooltip ?? "")
    }
}

/// A small inline tab button with active/hover states. Replaces DocTabButton.
struct InlineTabButton: View {
    let label: String
    let isActive: Bool
    let action: () -> Void

    @State private var isHovering = false

    var body: some View {
        Button(action: action) {
            Text(label)
                .font(FFDesign.Typography.captionMono)
                .fontWeight(isActive ? .medium : .regular)
                .padding(.horizontal, FFDesign.Spacing.md)
                .padding(.vertical, 3)
                .background(
                    isActive
                        ? Color.primary.opacity(FFDesign.Opacity.hover)
                        : (isHovering ? Color.primary.opacity(FFDesign.Opacity.hoverSubtle) : .clear)
                )
                .clipShape(RoundedRectangle(cornerRadius: FFDesign.Radii.small))
                .foregroundStyle(isActive ? .primary : .secondary)
        }
        .buttonStyle(.borderless)
        .onHover { isHovering = $0 }
    }
}

/// A colored single-letter badge for file change status (A/M/D/R).
struct StatusBadge: View {
    let letter: String
    let color: Color

    var body: some View {
        Text(letter)
            .font(FFDesign.Typography.badge)
            .foregroundStyle(color)
            .frame(width: 20, height: 20)
            .background(color.opacity(FFDesign.Opacity.selection))
            .clipShape(RoundedRectangle(cornerRadius: FFDesign.Radii.small))
    }
}
