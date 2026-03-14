// ABOUTME: NSView subclass that hosts a single ghostty terminal surface.
// ABOUTME: Handles keyboard, mouse, resize, and focus events for the terminal.

import Cocoa
import os

private let logger = Logger(subsystem: "ff2", category: "terminal-view")

final class TerminalView: NSView {
    private(set) var surface: ghostty_surface_t?
    private var trackingArea: NSTrackingArea?

    init(app: ghostty_app_t, workingDirectory: String? = nil) {
        super.init(frame: NSRect(x: 0, y: 0, width: 800, height: 600))

        wantsLayer = true
        layer?.isOpaque = true

        var config = ghostty_surface_config_new()
        config.userdata = Unmanaged.passUnretained(self).toOpaque()
        config.platform_tag = GHOSTTY_PLATFORM_MACOS
        config.platform = ghostty_platform_u(
            macos: ghostty_platform_macos_s(
                nsview: Unmanaged.passUnretained(self).toOpaque()
            )
        )
        config.scale_factor = Double(NSScreen.main?.backingScaleFactor ?? 2.0)
        config.font_size = 0 // inherit from ghostty config
        config.context = GHOSTTY_SURFACE_CONTEXT_WINDOW

        if let workingDirectory {
            workingDirectory.withCString { cstr in
                config.working_directory = cstr
                self.surface = ghostty_surface_new(app, &config)
            }
        } else {
            self.surface = ghostty_surface_new(app, &config)
        }

        guard surface != nil else {
            logger.error("ghostty_surface_new failed")
            return
        }
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) is not supported")
    }

    deinit {
        if let surface {
            ghostty_surface_free(surface)
        }
    }

    // MARK: - View lifecycle

    override var acceptsFirstResponder: Bool { true }

    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        guard let surface else { return }

        if let screen = window?.screen {
            ghostty_surface_set_display_id(surface, screen.displayID)
        }

        let scale = window?.backingScaleFactor ?? NSScreen.main?.backingScaleFactor ?? 2.0
        ghostty_surface_set_content_scale(surface, scale, scale)

        let size = bounds.size
        let scaledWidth = UInt32(size.width * scale)
        let scaledHeight = UInt32(size.height * scale)
        if scaledWidth > 0 && scaledHeight > 0 {
            ghostty_surface_set_size(surface, scaledWidth, scaledHeight)
        }
    }

    override func viewDidChangeBackingProperties() {
        super.viewDidChangeBackingProperties()
        guard let surface else { return }
        let scale = window?.backingScaleFactor ?? 2.0
        ghostty_surface_set_content_scale(surface, scale, scale)
    }

    override func setFrameSize(_ newSize: NSSize) {
        super.setFrameSize(newSize)
        guard let surface else { return }
        let scale = window?.backingScaleFactor ?? NSScreen.main?.backingScaleFactor ?? 2.0
        let w = UInt32(newSize.width * scale)
        let h = UInt32(newSize.height * scale)
        if w > 0 && h > 0 {
            ghostty_surface_set_size(surface, w, h)
        }
    }

    override func updateTrackingAreas() {
        if let trackingArea {
            removeTrackingArea(trackingArea)
        }
        let area = NSTrackingArea(
            rect: bounds,
            options: [.activeInKeyWindow, .mouseMoved, .mouseEnteredAndExited, .inVisibleRect],
            owner: self,
            userInfo: nil
        )
        addTrackingArea(area)
        trackingArea = area
        super.updateTrackingAreas()
    }

    func setFocused(_ focused: Bool) {
        guard let surface else { return }
        ghostty_surface_set_focus(surface, focused)
        if focused {
            window?.makeFirstResponder(self)
        }
    }

    func surfaceClosed() {
        // Terminal process exited; could notify the UI here in the future
    }

    // MARK: - Keyboard

    override func keyDown(with event: NSEvent) {
        guard let surface else {
            interpretKeyEvents([event])
            return
        }

        let mods = ghostty_surface_key_translation_mods(surface, Self.eventMods(event))
        var keyEvent = ghostty_input_key_s(
            action: GHOSTTY_ACTION_PRESS,
            mods: mods,
            consumed_mods: GHOSTTY_MODS_NONE,
            keycode: UInt32(event.keyCode),
            text: nil,
            unshifted_codepoint: 0,
            composing: false
        )

        // Provide the text for the key event
        if let chars = event.characters, !chars.isEmpty {
            chars.withCString { cstr in
                keyEvent.text = cstr
                if let scalar = chars.unicodeScalars.first {
                    keyEvent.unshifted_codepoint = scalar.value
                }
                _ = ghostty_surface_key(surface, keyEvent)
            }
        } else {
            _ = ghostty_surface_key(surface, keyEvent)
        }
    }

    override func keyUp(with event: NSEvent) {
        guard let surface else { return }
        let mods = Self.eventMods(event)
        var keyEvent = ghostty_input_key_s(
            action: GHOSTTY_ACTION_RELEASE,
            mods: mods,
            consumed_mods: GHOSTTY_MODS_NONE,
            keycode: UInt32(event.keyCode),
            text: nil,
            unshifted_codepoint: 0,
            composing: false
        )
        _ = ghostty_surface_key(surface, keyEvent)
    }

    override func flagsChanged(with event: NSEvent) {
        guard let surface else { return }
        let mods = Self.eventMods(event)
        var keyEvent = ghostty_input_key_s(
            action: GHOSTTY_ACTION_PRESS,
            mods: mods,
            consumed_mods: GHOSTTY_MODS_NONE,
            keycode: UInt32(event.keyCode),
            text: nil,
            unshifted_codepoint: 0,
            composing: false
        )
        _ = ghostty_surface_key(surface, keyEvent)
    }

    // MARK: - Mouse

    override func mouseDown(with event: NSEvent) {
        guard let surface else { return }
        let mods = Self.eventMods(event)
        _ = ghostty_surface_mouse_button(surface, GHOSTTY_MOUSE_PRESS, GHOSTTY_MOUSE_LEFT, mods)
    }

    override func mouseUp(with event: NSEvent) {
        guard let surface else { return }
        let mods = Self.eventMods(event)
        _ = ghostty_surface_mouse_button(surface, GHOSTTY_MOUSE_RELEASE, GHOSTTY_MOUSE_LEFT, mods)
    }

    override func rightMouseDown(with event: NSEvent) {
        guard let surface else { return }
        let mods = Self.eventMods(event)
        _ = ghostty_surface_mouse_button(surface, GHOSTTY_MOUSE_PRESS, GHOSTTY_MOUSE_RIGHT, mods)
    }

    override func rightMouseUp(with event: NSEvent) {
        guard let surface else { return }
        let mods = Self.eventMods(event)
        _ = ghostty_surface_mouse_button(surface, GHOSTTY_MOUSE_RELEASE, GHOSTTY_MOUSE_RIGHT, mods)
    }

    override func mouseMoved(with event: NSEvent) {
        guard let surface else { return }
        let point = convert(event.locationInWindow, from: nil)
        let mods = Self.eventMods(event)
        ghostty_surface_mouse_pos(surface, point.x, point.y, mods)
    }

    override func mouseDragged(with event: NSEvent) {
        guard let surface else { return }
        let point = convert(event.locationInWindow, from: nil)
        let mods = Self.eventMods(event)
        ghostty_surface_mouse_pos(surface, point.x, point.y, mods)
    }

    override func scrollWheel(with event: NSEvent) {
        guard let surface else { return }
        let x = event.scrollingDeltaX
        let y = event.scrollingDeltaY

        // Build scroll mods as a packed int matching ghostty's expectations
        var scrollMods: Int32 = 0
        if event.hasPreciseScrollingDeltas {
            scrollMods |= (1 << 0) // precision bit
        }
        ghostty_surface_mouse_scroll(surface, x, y, scrollMods)
    }

    // MARK: - Modifier translation

    private static func eventMods(_ event: NSEvent) -> ghostty_input_mods_e {
        var mods = GHOSTTY_MODS_NONE.rawValue
        let flags = event.modifierFlags
        if flags.contains(.shift) { mods |= GHOSTTY_MODS_SHIFT.rawValue }
        if flags.contains(.control) { mods |= GHOSTTY_MODS_CTRL.rawValue }
        if flags.contains(.option) { mods |= GHOSTTY_MODS_ALT.rawValue }
        if flags.contains(.command) { mods |= GHOSTTY_MODS_SUPER.rawValue }
        if flags.contains(.capsLock) { mods |= GHOSTTY_MODS_CAPS.rawValue }
        return ghostty_input_mods_e(rawValue: mods)
    }
}

// MARK: - NSScreen display ID helper

extension NSScreen {
    var displayID: UInt32 {
        guard let screenNumber = deviceDescription[NSDeviceDescriptionKey("NSScreenNumber")] as? NSNumber else {
            return 0
        }
        return screenNumber.uint32Value
    }
}
