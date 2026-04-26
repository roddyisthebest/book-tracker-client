//
//  MarkdownWebView.swift
//  BookTracker
//

import SwiftUI
import WebKit

struct MarkdownWebView: UIViewRepresentable {
    let markdown: String

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    func makeUIView(context: Context) -> WKWebView {
        let webView = WKWebView()
        webView.isOpaque = false
        webView.backgroundColor = .clear
        webView.scrollView.backgroundColor = .clear
        webView.alpha = 0
        webView.navigationDelegate = context.coordinator
        return webView
    }

    func updateUIView(_ webView: WKWebView, context: Context) {
        let html = convertToHTML(markdown)
        webView.loadHTMLString(html, baseURL: nil)
    }

    final class Coordinator: NSObject, WKNavigationDelegate {
        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            UIView.animate(withDuration: 0.2) {
                webView.alpha = 1
            }
        }
    }

    private func convertToHTML(_ markdown: String) -> String {
        let lines = markdown.components(separatedBy: "\n")
        var htmlBody = ""
        var inList = false

        for line in lines {
            if line.hasPrefix("# ") {
                if inList { htmlBody += "</ol>"; inList = false }
                let text = String(line.dropFirst(2))
                htmlBody += "<h1>\(text)</h1>\n"
            } else if line.hasPrefix("## ") {
                if inList { htmlBody += "</ol>"; inList = false }
                let text = String(line.dropFirst(3))
                htmlBody += "<h2>\(text)</h2>\n"
            } else if let range = line.range(of: #"^\d+\.\s+"#, options: .regularExpression) {
                if !inList { htmlBody += "<ol>"; inList = true }
                let text = String(line[range.upperBound...])
                htmlBody += "<li>\(text)</li>\n"
            } else if line.trimmingCharacters(in: .whitespaces).isEmpty {
                if inList { htmlBody += "</ol>"; inList = false }
                htmlBody += "\n"
            } else {
                if inList { htmlBody += "</ol>"; inList = false }
                htmlBody += "<p>\(line)</p>\n"
            }
        }
        if inList { htmlBody += "</ol>" }

        return """
        <!DOCTYPE html>
        <html>
        <head>
        <meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0">
        <style>
            :root { color-scheme: light dark; }
            body {
                font-family: -apple-system, BlinkMacSystemFont, sans-serif;
                font-size: 16px;
                line-height: 1.7;
                padding: 16px 20px 60px 20px;
                margin: 0;
                color: #e0e0e0;
                background-color: transparent;
            }
            @media (prefers-color-scheme: light) {
                body { color: #1a1a1a; }
            }
            h1 {
                font-size: 22px;
                font-weight: 700;
                margin: 0 0 8px 0;
            }
            h2 {
                font-size: 18px;
                font-weight: 700;
                margin: 28px 0 8px 0;
            }
            p {
                margin: 6px 0;
            }
            ol {
                padding-left: 24px;
                margin: 6px 0;
            }
            li {
                margin: 4px 0;
            }
        </style>
        </head>
        <body>
        \(htmlBody)
        </body>
        </html>
        """
    }
}
