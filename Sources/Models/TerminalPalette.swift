// ABOUTME: Reads the Ghostty terminal palette and derives an EditorTheme that matches the terminal colors.
// ABOUTME: Maps ANSI palette indices to syntax token types (keywords, strings, types, etc.).

import Cocoa
import CodeEditSourceEditor

/// Reads foreground, background, and the 16-color ANSI palette from a Ghostty config
/// and maps them to an `EditorTheme` for the source editor.
struct TerminalPalette {
    let foreground: NSColor
    let background: NSColor
    let ansi: [NSColor] // exactly 16 entries (ANSI colors 0-15)

    /// Read colors from an existing Ghostty config via `ghostty_config_get`.
    @discardableResult
    static func from(_ config: ghostty_config_t) -> TerminalPalette {
        // Read foreground
        var fg = ghostty_config_color_s()
        let fgKey = "foreground"
        ghostty_config_get(config, &fg, fgKey, UInt(fgKey.count))

        // Read background
        var bg = ghostty_config_color_s()
        let bgKey = "background"
        ghostty_config_get(config, &bg, bgKey, UInt(bgKey.count))

        // Read full 256-color palette
        var palette = ghostty_config_palette_s()
        let palKey = "palette"
        ghostty_config_get(config, &palette, palKey, UInt(palKey.count))

        // Extract the first 16 ANSI colors from the palette.
        // Swift imports C fixed-size arrays as tuples; use withUnsafePointer to iterate.
        let ansiColors: [NSColor] = withUnsafePointer(to: &palette.colors) { tuplePtr in
            tuplePtr.withMemoryRebound(to: ghostty_config_color_s.self, capacity: 16) { ptr in
                (0..<16).map { i in
                    let c = ptr[i]
                    return NSColor(
                        red: CGFloat(c.r) / 255,
                        green: CGFloat(c.g) / 255,
                        blue: CGFloat(c.b) / 255,
                        alpha: 1
                    )
                }
            }
        }

        return TerminalPalette(
            foreground: NSColor(
                red: CGFloat(fg.r) / 255,
                green: CGFloat(fg.g) / 255,
                blue: CGFloat(fg.b) / 255,
                alpha: 1
            ),
            background: NSColor(
                red: CGFloat(bg.r) / 255,
                green: CGFloat(bg.g) / 255,
                blue: CGFloat(bg.b) / 255,
                alpha: 1
            ),
            ansi: ansiColors
        )
    }

    // MARK: - ANSI → EditorTheme Mapping
    //
    // Index | ANSI Name      | Token
    // ------|----------------|------------------
    // 1     | Red            | keywords
    // 2     | Green          | strings
    // 3     | Yellow         | numbers, characters
    // 4     | Blue           | values
    // 5     | Magenta        | commands
    // 6     | Cyan           | types
    // 8     | Bright Black   | comments (italic), invisibles
    // 9     | Bright Red     | attributes
    //
    // Derived:
    //   selection    = palette[4] (blue) at 40% alpha
    //   lineHighlight = foreground at 5% alpha

    var editorTheme: EditorTheme {
        EditorTheme(
            text: .init(color: foreground),
            insertionPoint: foreground,
            invisibles: .init(color: ansi[8]),
            background: background,
            lineHighlight: foreground.withAlphaComponent(0.05),
            selection: ansi[4].withAlphaComponent(0.40),
            keywords: .init(color: ansi[1]),
            commands: .init(color: ansi[5]),
            types: .init(color: ansi[6]),
            attributes: .init(color: ansi[9]),
            variables: .init(color: foreground),
            values: .init(color: ansi[4]),
            numbers: .init(color: ansi[3]),
            strings: .init(color: ansi[2]),
            characters: .init(color: ansi[3]),
            comments: .init(color: ansi[8], italic: true)
        )
    }
}
