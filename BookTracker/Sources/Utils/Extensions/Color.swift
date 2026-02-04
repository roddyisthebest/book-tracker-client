//
//  Color.swift
//  BookTracker
//
//  Created by 배성연 on 2/3/26.
//

import SwiftUI

extension Color {
    // Initialize a Color from common hex string formats:
    // - "#RRGGBB", "RRGGBB"
    // - "#AARRGGBB", "AARRGGBB"
    // - "#RGB", "RGB" (12-bit, each nibble duplicated)
    // - "#ARGB", "ARGB" (16-bit, each nibble duplicated)
    // - "0xRRGGBB", "0xAARRGGBB"
    init?(hex: String) {
        let cleaned = hex
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "0x", with: "", options: [.caseInsensitive])
            .replacingOccurrences(of: "#", with: "")

        var value: UInt64 = 0
        guard Scanner(string: cleaned).scanHexInt64(&value) else {
            return nil
        }

        let r, g, b, a: Double

        switch cleaned.count {
        case 3: // RGB (12-bit) -> duplicate each nibble
            let rNib = (value >> 8) & 0xF
            let gNib = (value >> 4) & 0xF
            let bNib = value & 0xF
            r = Double((rNib << 4) | rNib) / 255.0
            g = Double((gNib << 4) | gNib) / 255.0
            b = Double((bNib << 4) | bNib) / 255.0
            a = 1.0

        case 4: // ARGB (16-bit) -> duplicate each nibble
            let aNib = (value >> 12) & 0xF
            let rNib = (value >> 8) & 0xF
            let gNib = (value >> 4) & 0xF
            let bNib = value & 0xF
            a = Double((aNib << 4) | aNib) / 255.0
            r = Double((rNib << 4) | rNib) / 255.0
            g = Double((gNib << 4) | gNib) / 255.0
            b = Double((bNib << 4) | bNib) / 255.0

        case 6: // RRGGBB (24-bit)
            r = Double((value >> 16) & 0xFF) / 255.0
            g = Double((value >> 8) & 0xFF) / 255.0
            b = Double(value & 0xFF) / 255.0
            a = 1.0

        case 8: // AARRGGBB (32-bit)
            a = Double((value >> 24) & 0xFF) / 255.0
            r = Double((value >> 16) & 0xFF) / 255.0
            g = Double((value >> 8) & 0xFF) / 255.0
            b = Double(value & 0xFF) / 255.0

        default:
            return nil
        }

        self = Color(red: r, green: g, blue: b, opacity: a)
    }

    // Convenience initializer that falls back to a default color when parsing
    init(hex: String, default defaultColor: Color) {
        if let color = Color(hex: hex) {
            self = color
        } else {
            self = defaultColor
        }
    }
}

// MARK: - App Color Tokens (Light/Dark aware)

enum AppColor {
    case background
    case primaryText
    case secondaryText
    case accent
    case sheetBackground
}

extension AppColor {
    /// Returns a color for the given color scheme (light/dark) using the hex initializer above.
    func color(_ scheme: ColorScheme) -> Color {
        switch self {
        case .sheetBackground:
            return scheme == .dark
                ? Color(hex: "#FFFFFF", default: .black)
                : Color(hex: "#111111", default: .white)

        case .background:
            return scheme == .dark
                ? Color(hex: "#0B0B0B", default: .black)
                : Color(hex: "#FFFFFF", default: .white)

        case .primaryText:
            return scheme == .dark
                ? Color(hex: "#F2F2F2", default: .white)
                : Color(hex: "#111111", default: .black)

        case .secondaryText:
            return scheme == .dark
                ? Color(hex: "#B0B0B0", default: .gray)
                : Color(hex: "#6B6B6B", default: .gray)

        case .accent:
            // Example: light uses your sample #341212, dark uses a slightly lighter accent
            return scheme == .dark
                ? Color(hex: "#BA6F6F", default: .red)
                : Color(hex: "#341212", default: .red)
        }
    }
}

extension Color {
    /// Convenience to access an AppColor token with an explicit scheme.
    static func app(_ token: AppColor, scheme: ColorScheme) -> Color {
        token.color(scheme)
    }
}

/*
 Usage Example in a View:

 struct ExampleView: View {
     @Environment(\.colorScheme) private var colorScheme

     var body: some View {
         VStack(spacing: 16) {
             Text("Title")
                 .foregroundStyle(AppColor.primaryText.color(colorScheme))

             RoundedRectangle(cornerRadius: 12)
                 .fill(Color.app(.accent, scheme: colorScheme))
                 .frame(height: 44)
         }
         .background(AppColor.background.color(colorScheme))
     }
 }
 */
