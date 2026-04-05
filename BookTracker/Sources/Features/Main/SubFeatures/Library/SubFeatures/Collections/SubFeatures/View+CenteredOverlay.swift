// View+CenteredOverlay.swift
// A reusable helper to center an overlay (e.g., loading indicator) across the available space.

import SwiftUI

public extension View {
    /// Places the given overlay view centered over the receiver when `isPresented` is true.
    /// The base view expands to fill the available space so centering is reliable inside stacks and lists.
    /// - Parameters:
    ///   - isPresented: Whether to show the overlay.
    ///   - alignment: Where to place the overlay; defaults to center.
    ///   - overlay: The overlay content, such as a ProgressView.
    /// - Returns: A view with a centered overlay applied when presented.
    func centeredOverlay<Overlay: View>(
        isPresented: Bool,
        alignment: Alignment = .center,
        @ViewBuilder overlay: () -> Overlay
    ) -> some View {
        self
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .overlay(alignment: alignment) {
                if isPresented {
                    overlay()
                }
            }
    }
}

// MARK: - Preview (example usage)
#if DEBUG
struct CenteredOverlay_Previews: PreviewProvider {
    static var previews: some View {
        VStack {
            Text("Content")
                .padding()
                .background(Color.blue.opacity(0.2))
        }
        .centeredOverlay(isPresented: true) {
            ProgressView()
                .scaleEffect(1.1)
                .padding(16)
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
        }
        .padding()
    }
}
#endif
