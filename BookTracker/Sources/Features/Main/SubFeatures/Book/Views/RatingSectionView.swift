import ComposableArchitecture
import SwiftUI

struct RatingSectionView: View {
    @Bindable var store: StoreOf<BookFormFeature>

    var body: some View {
        VStack(alignment: .leading) {
            let starCount = 5
            let starSpacing: CGFloat = 8
            let starSymbolSize: CGFloat = 24

            HStack(spacing: 8) {
                // 별 HStack: 내용 크기만큼만 차지
                HStack(spacing: starSpacing) {
                    ForEach(1 ... starCount, id: \.self) { index in
                        let current: Double = store.rating
                        let fullThreshold = Double(index)
                        let halfThreshold: Double = fullThreshold - 0.5
                        let isFull: Bool = current >= fullThreshold
                        let isHalf: Bool = !isFull && current >= halfThreshold
                        let symbolName: String = {
                            if isFull { return "star.fill" }
                            if isHalf { return "star.leadinghalf.filled" }
                            return "star"
                        }()
                        Image(systemName: symbolName)
                            .foregroundStyle((isFull || isHalf) ? .yellow : .gray)
                            .imageScale(.large)
                            .frame(width: starSymbolSize, height: starSymbolSize)
                    }
                }
                .fixedSize() // 별 영역은 내용 폭만 갖도록 강제
                .padding(.trailing, 10)
                .background(
                    GeometryReader { starsGeo in
                        Color.clear
                            .contentShape(Rectangle())
                            .gesture(
                                DragGesture(minimumDistance: 0)
                                    .onChanged { value in
                                        let width: CGFloat = starsGeo.size.width
                                        if width <= 0 { return }
                                        let x: CGFloat = value.location.x
                                        let clampedX: CGFloat = max(0, min(width, x))
                                        let relative = Double(clampedX / width) // 0...1
                                        let raw: Double = relative * Double(starCount) // 0...5
                                        let snapped: Double = (raw * 2).rounded() / 2 // 0.5 steps
                                        let clamped: Double = max(0, min(Double(starCount), snapped))
                                        store.rating = clamped
                                    }
                                    .onEnded { value in
                                        let width: CGFloat = starsGeo.size.width
                                        if width <= 0 { return }
                                        let x: CGFloat = value.location.x
                                        let clampedX: CGFloat = max(0, min(width, x))
                                        let relative = Double(clampedX / width)
                                        let raw: Double = relative * Double(starCount)
                                        let snapped: Double = (raw * 2).rounded() / 2
                                        let clamped: Double = max(0, min(Double(starCount), snapped))
                                        store.rating = clamped
                                    }
                            )
                            .onTapGesture { location in
                                let width: CGFloat = starsGeo.size.width
                                if width <= 0 { return }
                                let x: CGFloat = location.x
                                let clampedX: CGFloat = max(0, min(width, x))
                                let relative = Double(clampedX / width)
                                let raw: Double = relative * Double(starCount)
                                let whole: Double = raw == 0 ? 0 : ceil(raw)
                                let clampedWhole: Double = max(0, min(Double(starCount), whole))
                                store.rating = clampedWhole
                            }
                    }
                )
                Spacer()
                let ratingText = String(format: "%.1f/5", store.rating)
                Text(ratingText)
                    .foregroundStyle(.secondary)
            }
            .padding()
            .background(Color(hex: "#17171C", default: .accentColor))
            .cornerRadius(15)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .frame(maxWidth: .infinity)
        .listRowBackground(Color.clear)
        .listRowSeparator(.hidden)
    }
}
