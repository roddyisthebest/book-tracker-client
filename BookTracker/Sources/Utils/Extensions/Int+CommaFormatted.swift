//
//  Int+CommaFormatted.swift
//  BookTracker
//

import Foundation

extension Int {
    private static let commaFormatter: NumberFormatter = {
        let f = NumberFormatter()
        f.numberStyle = .decimal
        return f
    }()

    var commaFormatted: String {
        Self.commaFormatter.string(from: NSNumber(value: self)) ?? "\(self)"
    }
}
