// ABOUTME: Renders markdown content using WKWebView with inline conversion.
// ABOUTME: No external dependencies, handles headings, code, lists, links.

import SwiftUI
import WebKit

struct MarkdownView: NSViewRepresentable {
    let markdown: String

    func makeNSView(context: Context) -> WKWebView {
        let config = WKWebViewConfiguration()
        config.preferences.setValue(true, forKey: "developerExtrasEnabled")
        let webView = WKWebView(frame: .zero, configuration: config)
        webView.setValue(false, forKey: "drawsBackground")
        loadMarkdown(webView)
        return webView
    }

    func updateNSView(_ webView: WKWebView, context: Context) {
        loadMarkdown(webView)
    }

    private func loadMarkdown(_ webView: WKWebView) {
        let html = Self.markdownToHTML(markdown)
        let page = Self.wrapInPage(html)
        webView.loadHTMLString(page, baseURL: nil)
    }

    /// Minimal markdown to HTML converter. Handles the common cases
    /// without any external dependencies.
    private static func markdownToHTML(_ md: String) -> String {
        var lines = md.components(separatedBy: "\n")
        var html = ""
        var inCodeBlock = false
        var inList = false
        var listType = ""

        for i in 0..<lines.count {
            var line = lines[i]

            // Fenced code blocks
            if line.hasPrefix("```") {
                if inCodeBlock {
                    html += "</code></pre>\n"
                    inCodeBlock = false
                } else {
                    let lang = String(line.dropFirst(3)).trimmingCharacters(in: .whitespaces)
                    html += "<pre><code class=\"language-\(lang)\">"
                    inCodeBlock = true
                }
                continue
            }
            if inCodeBlock {
                html += escapeHTML(line) + "\n"
                continue
            }

            // Close list if needed
            if inList && !line.hasPrefix("- ") && !line.hasPrefix("* ") && !line.matches(of: /^\d+\.\s/).isEmpty == false && line.trimmingCharacters(in: .whitespaces).isEmpty {
                html += "</\(listType)>\n"
                inList = false
            }

            // Empty line
            if line.trimmingCharacters(in: .whitespaces).isEmpty {
                if inList {
                    html += "</\(listType)>\n"
                    inList = false
                }
                html += "<br>\n"
                continue
            }

            // Headings
            if line.hasPrefix("######") { html += "<h6>\(inlineFormat(String(line.dropFirst(6).trimmingCharacters(in: .whitespaces))))</h6>\n"; continue }
            if line.hasPrefix("#####") { html += "<h5>\(inlineFormat(String(line.dropFirst(5).trimmingCharacters(in: .whitespaces))))</h5>\n"; continue }
            if line.hasPrefix("####") { html += "<h4>\(inlineFormat(String(line.dropFirst(4).trimmingCharacters(in: .whitespaces))))</h4>\n"; continue }
            if line.hasPrefix("###") { html += "<h3>\(inlineFormat(String(line.dropFirst(3).trimmingCharacters(in: .whitespaces))))</h3>\n"; continue }
            if line.hasPrefix("##") { html += "<h2>\(inlineFormat(String(line.dropFirst(2).trimmingCharacters(in: .whitespaces))))</h2>\n"; continue }
            if line.hasPrefix("#") { html += "<h1>\(inlineFormat(String(line.dropFirst(1).trimmingCharacters(in: .whitespaces))))</h1>\n"; continue }

            // Horizontal rule
            if line.trimmingCharacters(in: .whitespaces).allSatisfy({ $0 == "-" || $0 == "*" || $0 == "_" }) && line.count >= 3 {
                html += "<hr>\n"; continue
            }

            // Blockquote
            if line.hasPrefix("> ") {
                html += "<blockquote>\(inlineFormat(String(line.dropFirst(2))))</blockquote>\n"; continue
            }

            // Unordered list
            if line.hasPrefix("- ") || line.hasPrefix("* ") {
                if !inList { html += "<ul>\n"; inList = true; listType = "ul" }
                html += "<li>\(inlineFormat(String(line.dropFirst(2))))</li>\n"; continue
            }

            // Ordered list
            if let match = line.firstMatch(of: /^(\d+)\.\s(.*)/) {
                if !inList { html += "<ol>\n"; inList = true; listType = "ol" }
                html += "<li>\(inlineFormat(String(match.output.2)))</li>\n"; continue
            }

            // Paragraph
            html += "<p>\(inlineFormat(line))</p>\n"
        }

        if inCodeBlock { html += "</code></pre>\n" }
        if inList { html += "</\(listType)>\n" }

        return html
    }

    /// Inline formatting: bold, italic, code, links, images.
    private static func inlineFormat(_ text: String) -> String {
        var s = escapeHTML(text)
        // Inline code (before bold/italic to avoid conflicts)
        s = s.replacingOccurrences(of: "`([^`]+)`", with: "<code>$1</code>", options: .regularExpression)
        // Bold
        s = s.replacingOccurrences(of: "\\*\\*(.+?)\\*\\*", with: "<strong>$1</strong>", options: .regularExpression)
        s = s.replacingOccurrences(of: "__(.+?)__", with: "<strong>$1</strong>", options: .regularExpression)
        // Italic
        s = s.replacingOccurrences(of: "\\*(.+?)\\*", with: "<em>$1</em>", options: .regularExpression)
        s = s.replacingOccurrences(of: "_(.+?)_", with: "<em>$1</em>", options: .regularExpression)
        // Links
        s = s.replacingOccurrences(of: "\\[([^\\]]+)\\]\\(([^)]+)\\)", with: "<a href=\"$2\">$1</a>", options: .regularExpression)
        // Checkboxes
        s = s.replacingOccurrences(of: "\\[x\\]", with: "&#9745;", options: .regularExpression)
        s = s.replacingOccurrences(of: "\\[ \\]", with: "&#9744;", options: .regularExpression)
        return s
    }

    private static func escapeHTML(_ s: String) -> String {
        s.replacingOccurrences(of: "&", with: "&amp;")
         .replacingOccurrences(of: "<", with: "&lt;")
         .replacingOccurrences(of: ">", with: "&gt;")
    }

    private static func wrapInPage(_ body: String) -> String {
        """
        <!DOCTYPE html>
        <html>
        <head>
        <meta charset="utf-8">
        <style>
            :root { color-scheme: light dark; }
            body {
                font-family: -apple-system, BlinkMacSystemFont, sans-serif;
                font-size: 14px;
                line-height: 1.6;
                padding: 8px 16px;
                margin: 0;
                background: transparent;
            }
            @media (prefers-color-scheme: dark) {
                body { color: #e0e0e0; }
                code, pre { background: #1e1e1e; }
                a { color: #6cb6ff; }
                blockquote { border-color: #333; }
                hr { border-color: #333; }
            }
            @media (prefers-color-scheme: light) {
                body { color: #1d1d1f; }
                code, pre { background: #f5f5f5; }
                a { color: #0066cc; }
                blockquote { border-color: #ddd; }
                hr { border-color: #ddd; }
            }
            h1 { font-size: 1.8em; font-weight: 700; margin: 0.6em 0 0.3em; }
            h2 { font-size: 1.4em; font-weight: 600; margin: 0.6em 0 0.3em; }
            h3 { font-size: 1.15em; font-weight: 600; margin: 0.5em 0 0.2em; }
            h4, h5, h6 { font-size: 1em; font-weight: 600; margin: 0.5em 0 0.2em; }
            code {
                font-family: "SF Mono", Menlo, monospace;
                font-size: 0.9em;
                padding: 2px 6px;
                border-radius: 4px;
            }
            pre {
                padding: 12px 16px;
                border-radius: 8px;
                overflow-x: auto;
            }
            pre code { padding: 0; }
            a { text-decoration: none; }
            a:hover { text-decoration: underline; }
            blockquote {
                border-left: 3px solid;
                margin-left: 0;
                padding-left: 16px;
                opacity: 0.7;
            }
            hr { border: none; border-top: 1px solid; margin: 1.5em 0; }
            ul, ol { padding-left: 24px; }
            li { margin: 2px 0; }
            p { margin: 0.5em 0; }
            br { display: block; margin: 0.3em 0; content: ""; }
        </style>
        </head>
        <body>\(body)</body>
        </html>
        """
    }
}
