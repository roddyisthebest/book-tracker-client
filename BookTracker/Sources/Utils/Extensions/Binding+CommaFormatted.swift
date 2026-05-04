//
//  Binding+CommaFormatted.swift
//  BookTracker
//

import SwiftUI

extension Binding where Value == String {
    func commaFormatted() -> Binding<String> {
        Binding(
            get: {
                guard let value = Int(wrappedValue), value > 0 else { return wrappedValue }
                return value.commaFormatted
            },
            set: { newValue in
                wrappedValue = newValue.filter(\.isNumber)
            }
        )
    }
}
