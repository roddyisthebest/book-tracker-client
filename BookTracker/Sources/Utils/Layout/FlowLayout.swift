//
//  FlowLayout.swift
//  BookTracker
//
//  Created by 배성연 on 2/17/26.
//
import Foundation
import SwiftUI

struct FlowLayout: Layout {
    var spacing: CGFloat = 8
    var rowSpacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let maxWidth = proposal.width ?? .infinity

        var contentWidth: CGFloat = 0
        var contentHeight: CGFloat = 0
        var rowWidth: CGFloat = 0
        var rowHeight: CGFloat = 0

        func commitRow() {
            guard rowHeight > 0 else { return }
            if contentHeight > 0 { contentHeight += rowSpacing }
            contentHeight += rowHeight
            contentWidth = max(contentWidth, rowWidth)
            rowWidth = 0
            rowHeight = 0
        }

        for subview in subviews {
            // Measure each subview with the maximum row width so truncation can occur.
            let measured = subview.sizeThatFits(ProposedViewSize(width: maxWidth, height: nil))
            let viewWidth = min(measured.width, maxWidth)
            let viewHeight = measured.height

            let nextWidth = rowWidth == 0 ? viewWidth : rowWidth + spacing + viewWidth
            if nextWidth > maxWidth {
                commitRow()
                rowWidth = viewWidth
                rowHeight = viewHeight
            } else {
                rowWidth = nextWidth
                rowHeight = max(rowHeight, viewHeight)
            }
        }

        commitRow()

        let finalWidth = proposal.width ?? contentWidth
        return CGSize(width: finalWidth, height: contentHeight)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let maxWidth = bounds.width
        var x = bounds.minX
        var y = bounds.minY
        var rowHeight: CGFloat = 0
        var isFirstInRow = true

        func newLine() {
            x = bounds.minX
            y += rowHeight + rowSpacing
            rowHeight = 0
            isFirstInRow = true
        }

        for subview in subviews {
            // Measure with the row's maximum width so the view can compute a truncated size.
            let measured = subview.sizeThatFits(ProposedViewSize(width: maxWidth, height: nil))
            let viewWidth = min(measured.width, maxWidth)
            let viewHeight = measured.height

            let neededWidth = (isFirstInRow ? 0 : spacing) + viewWidth
            if (x - bounds.minX) + neededWidth > maxWidth {
                newLine()
            }

            if !isFirstInRow { x += spacing }

            // Place with the measured size so the view does not expand to fill the whole row.
            subview.place(
                at: CGPoint(x: x, y: y),
                proposal: ProposedViewSize(width: viewWidth, height: viewHeight)
            )

            x += viewWidth
            rowHeight = max(rowHeight, viewHeight)
            isFirstInRow = false
        }
    }
}
