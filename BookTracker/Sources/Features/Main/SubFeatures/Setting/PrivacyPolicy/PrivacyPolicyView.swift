//
//  PrivacyPolicyView.swift
//  BookTracker
//

import SwiftUI

struct PrivacyPolicyView: View {
    @Environment(\.dismiss) private var dismiss

    private var markdownContent: String {
        let lang = Locale.current.language.languageCode?.identifier ?? ""
        let fileName: String
        switch lang {
        case "ko": fileName = "privacy_policy_ko"
        case "ja": fileName = "privacy_policy_ja"
        default: fileName = "privacy_policy_en"
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
            .navigationTitle("privacy_policy")
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
