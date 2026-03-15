// ABOUTME: Renders markdown content using WKWebView for full formatting.
// ABOUTME: Supports headings, code blocks, lists, links, and more.

import SwiftUI
import WebKit

struct MarkdownView: NSViewRepresentable {
    let markdown: String

    func makeNSView(context: Context) -> WKWebView {
        let webView = WKWebView()
        webView.setValue(false, forKey: "drawsBackground")
        loadMarkdown(webView)
        return webView
    }

    func updateNSView(_ webView: WKWebView, context: Context) {
        loadMarkdown(webView)
    }

    private func loadMarkdown(_ webView: WKWebView) {
        let html = wrapInHTML(markdown)
        webView.loadHTMLString(html, baseURL: nil)
    }

    private func wrapInHTML(_ md: String) -> String {
        // Escape for JS string
        let escaped = md
            .replacingOccurrences(of: "\\", with: "\\\\")
            .replacingOccurrences(of: "`", with: "\\`")
            .replacingOccurrences(of: "$", with: "\\$")

        return """
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
                padding: 16px 0;
                margin: 0;
                color: var(--text);
                background: transparent;
            }
            @media (prefers-color-scheme: dark) {
                :root { --text: #e0e0e0; --code-bg: #1e1e1e; --border: #333; --link: #6cb6ff; }
            }
            @media (prefers-color-scheme: light) {
                :root { --text: #1d1d1f; --code-bg: #f5f5f5; --border: #ddd; --link: #0066cc; }
            }
            h1 { font-size: 1.8em; font-weight: 700; margin: 0.8em 0 0.4em; }
            h2 { font-size: 1.4em; font-weight: 600; margin: 0.8em 0 0.4em; }
            h3 { font-size: 1.15em; font-weight: 600; margin: 0.6em 0 0.3em; }
            code {
                font-family: "SF Mono", Menlo, monospace;
                font-size: 0.9em;
                background: var(--code-bg);
                padding: 2px 6px;
                border-radius: 4px;
            }
            pre {
                background: var(--code-bg);
                padding: 12px 16px;
                border-radius: 8px;
                overflow-x: auto;
            }
            pre code { background: none; padding: 0; }
            a { color: var(--link); text-decoration: none; }
            a:hover { text-decoration: underline; }
            blockquote {
                border-left: 3px solid var(--border);
                margin-left: 0;
                padding-left: 16px;
                color: #888;
            }
            hr { border: none; border-top: 1px solid var(--border); margin: 1.5em 0; }
            table { border-collapse: collapse; width: 100%; }
            th, td { border: 1px solid var(--border); padding: 6px 12px; text-align: left; }
            th { font-weight: 600; }
            img { max-width: 100%; }
        </style>
        <script src="https://cdn.jsdelivr.net/npm/marked/marked.min.js"></script>
        </head>
        <body>
        <div id="content"></div>
        <script>
            document.getElementById('content').innerHTML = marked.parse(`\(escaped)`);
        </script>
        </body>
        </html>
        """
    }
}
