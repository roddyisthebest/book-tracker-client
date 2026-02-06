//
//  ScalableButtonStyle.swift
//  BookTracker
//
//  Created by 배성연 on 2/6/26.
//

import SwiftUI

struct ScalableButtonStyle: ButtonStyle {
    var pressedScale: CGFloat = 0.96
    var animation: Animation = .spring(response: 0.2, dampingFraction: 0.7)

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? pressedScale : 1.0)
            .animation(animation, value: configuration.isPressed)
    }
}
