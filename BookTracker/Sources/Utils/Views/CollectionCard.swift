//
//  CollectionCard.swift
//  BookTracker
//
//  Created by 배성연 on 2/11/26.
//

import ComposableArchitecture
import SwiftUI

struct CollectionCard: View {
    let onTap: () -> Void
    let onDelete: () -> Void

    // Optional asset names for two images; falls back to system symbols if missing
    var leadingImageName: String?
    var trailingImageName: String?
    var title: String = "구매한책"
    var countText: String = "4권"

    // Safe image builder: tries asset by name, else uses a background placeholder with photo icon
    @ViewBuilder
    private func safeImage(name: String?) -> some View {
        if let name, UIImage(named: name) != nil {
            Image(name)
                .resizable()
                .scaledToFill()
        } else {
            ZStack {
                // Subtle placeholder background
                Color.black.opacity(0.2)
                // Photo icon overlay
                Image(systemName: "photo")
                    .symbolRenderingMode(.hierarchical)
                    .foregroundStyle(.secondary)
                    .imageScale(.large)
            }
        }
    }

    var body: some View {
        Button { onTap() } label: {
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 6) {
                    safeImage(name: leadingImageName)
                        .frame(height: 80)
                        .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
                    safeImage(name: trailingImageName)
                        .frame(height: 80)
                        .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
                }
                VStack(alignment: .leading) {
                    Text(title)
                        .font(.headline)
                        .foregroundStyle(.primary)

                    Text(countText)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }.padding(.top, 8)
            }
            .padding(15)
            .background(Color(hex: "#2C2C35", default: .black))
            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
            .contextMenu {
                Button(role: .destructive) {
                    onDelete()
                } label: {
                    Label("삭제", systemImage: "trash")
                }

                // 필요하면 다른 메뉴도 추가 가능 (예: 공유)
                Button {
                    // 공유 등 다른 액션
                } label: {
                    Label("공유", systemImage: "square.and.arrow.up")
                }
            }
        }
    }
}

#Preview("CollectionCard – with and without assets") {
    VStack(spacing: 20) {
        // Preview with missing assets (will show system symbols)
        CollectionCard(onTap: {}, onDelete: {}, leadingImageName: nil, trailingImageName: nil, title: "구매한책", countText: "4권")
            .frame(width: 180)

        // Preview with pretend asset names (if present, they'll load; else fallback)
        CollectionCard(onTap: {}, onDelete: {}, leadingImageName: "cover1", trailingImageName: "cover2", title: "추가한 책", countText: "12권")
            .frame(width: 180)
    }
    .padding()
    .background(Color.black)
}
