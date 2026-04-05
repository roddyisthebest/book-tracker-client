//
//  DayBadge.swift
//  BookTracker
//
//  Created by 배성연 on 2/20/26.
//
import SwiftUI

struct DayBadge<Content: View>: View {
    let day: String
    let overlayContent: Content

    init(day: String, @ViewBuilder overlay: () -> Content) {
        self.day = day
        self.overlayContent = overlay()
    }

    var body: some View {
        VStack {
            Text(day)
                .font(.subheadline)
                .foregroundStyle(Color.appSecondaryText)
            RoundedRectangle(cornerRadius: 10)
                .fill(Color.appSurfaceDeeper)
                .frame(width: 40, height: 40)
                .overlay(overlayContent)
        }
    }
}
