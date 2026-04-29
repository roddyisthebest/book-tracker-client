//
//  TermsOfServiceView.swift
//  BookTracker
//

import SwiftUI

struct TermsOfServiceView: View {
    @Environment(\.dismiss) private var dismiss

    private var markdownContent: String {
        let lang = Locale.current.language.languageCode?.identifier ?? ""
        let fileName: String
        switch lang {
        case "ko": fileName = "terms_of_service_ko"
        case "ja": fileName = "terms_of_service_ja"
        default: fileName = "terms_of_service_en"
        }
        guard let url = Bundle.main.url(forResource: fileName, withExtension: "md"),
              let content = try? String(contentsOf: url, encoding: .utf8) else {
            return ""
        }
        return content
    }

    var body: some View {
        MarkdownWebView(markdown: markdownContent)
            .ignoresSafeArea(edges: .bottom)
            .navigationTitle("terms_of_service")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden(true)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        dismiss()
                    } label: {
                        Label("back", systemImage: "chevron.left")
                    }
                }
            }
    }
}
