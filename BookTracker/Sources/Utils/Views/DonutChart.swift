//
//  DonutChart.swift
//  BookTracker
//
//  Created by 배성연 on 2/21/26.
//
import SwiftUI

struct DonutChart: View {
    let segments: [(Color, Double)]
    let lineWidth: CGFloat

    private var total: Double {
        let sum = segments.map { $0.1 }.reduce(0, +)
        return sum == 0 ? 1 : sum
    }

    private var cumulative: [(Color, Double, Double)] {
        var start: Double = 0
        return segments.map { seg in
            let fraction = seg.1 / total
            defer { start += fraction }
            return (seg.0, start, start + fraction)
        }
    }

    var body: some View {
        ZStack {
            Circle()
                .stroke(Color.white.opacity(0.1), lineWidth: lineWidth)

            ForEach(Array(cumulative.enumerated()), id: \.offset) { _, segment in
                Circle()
                    .trim(from: segment.1, to: segment.2)
                    .rotation(Angle(degrees: -90))
                    .stroke(segment.0, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
            }
        }
    }
}
