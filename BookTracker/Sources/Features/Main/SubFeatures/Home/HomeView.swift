//
//  HomeView.swift
//  BookTracker
//
//  Created by 배성연 on 2/19/26.
//

import ComposableArchitecture
import SwiftUI

struct HomeView: View {
    @Bindable var store: StoreOf<HomeFeature>

    @ViewBuilder
    private func destinationView(for destinationStore: StoreOf<HomeFeature.Path>) -> some View {
        switch destinationStore.state {
        case .myBooks:
            if let store = destinationStore.scope(state: \.myBooks, action: \.myBooks) {
                MyBookListView(store: store)
            }
        }
    }

    var body: some View {
        NavigationStack(path: $store.scope(state: \.path, action: \.path)) {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    VStack(alignment: .leading, spacing: 25) { // 상위 VStack도 leading
                        VStack(alignment: .leading, spacing: 5) {
                            Text("독서 기록")
                                .foregroundStyle(.white)
                                .font(.title2)
                                .fontWeight(.bold)
                            Text("오늘 하루 독서 유무를 기록해보세요")
                                .foregroundStyle(.gray).fontWeight(.semibold).font(.subheadline).lineLimit(1)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)

                        HStack(alignment: .center) {
                            DayBadge(day: "금") {
                                Text("23")
                                    .foregroundStyle(.white)
                                    .font(.headline)
                            }
                            DayBadge(day: "토") {
                                Text("24")
                                    .foregroundStyle(.white)
                                    .font(.headline)
                            }
                            DayBadge(day: "일") {
                                Text("25")
                                    .foregroundStyle(.white)
                                    .font(.headline)
                            }
                            DayBadge(day: "월") {
                                Text("26")
                                    .foregroundStyle(.white)
                                    .font(.headline)
                            }
                            DayBadge(day: "화") {
                                Text("27")
                                    .foregroundStyle(.white)
                                    .font(.headline)
                            }
                            DayBadge(day: "수") {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundStyle(.green)
                            }
                            DayBadge(day: "목") {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundStyle(.green)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        DefaultButton(action: {}, label: {
                            Text("독서를 했습니다")
                        })
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(20)
                    .background(Color(hex: "#17171C", default: .black))
                    .cornerRadius(15)

                    Button(action: { store.send(.myBooksButtonTapped) }) {
                        HStack(spacing: 10) {
                            RoundedRectangle(cornerRadius: 15)
                                .fill(Color(hex: "#20385E", default: .black))
                                .frame(width: 50, height: 50)
                                .overlay(Image(systemName: "books.vertical.fill").foregroundStyle(.blue))

                            VStack(alignment: .leading, spacing: 2.5) {
                                Text("내 서재 보기")
                                    .foregroundStyle(.white).lineLimit(1)
                                    .font(.system(size: 18, weight: .bold))
                                Text("독서 상태별로 책을 한눈에 볼 수 있어요")
                                    .foregroundStyle(.gray).fontWeight(.semibold).font(.system(size: 14)).lineLimit(1)
                            }
                            Spacer()
                            Image(systemName: "chevron.forward").foregroundStyle(.gray).fontWeight(.semibold)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(20)
                        .background(Color(hex: "#17171C", default: .black))
                        .cornerRadius(15)
                    }

                    VStack(alignment: .leading, spacing: 25) { // 상위 VStack도 leading
                        VStack(alignment: .leading, spacing: 5) {
                            Text("구매/대여")
                                .foregroundStyle(.white)
                                .font(.title2)
                                .fontWeight(.bold)
                            Text("한번에 책을 담고, 대출증 영수증을 발급 할 수 있어요")
                                .foregroundStyle(.gray).fontWeight(.semibold).font(.subheadline).lineLimit(1)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        VStack(alignment: .leading, spacing: 15) {
                            Button(action: {
                                store.send(.receiptIssueButtonTapped(type: .rental))
                            }) {
                                HStack {
                                    RoundedRectangle(cornerRadius: 15)
                                        .fill(Color(hex: "#2F2F49", default: .black))
                                        .frame(width: 40, height: 40)
                                        .overlay(Image(systemName: "person.text.rectangle.fill").foregroundStyle(Color(hex: "#7D7DFF", default: .accentColor)))

                                    Text("대출증 발급").font(.system(size: 18)).fontWeight(.bold).foregroundStyle(Color(hex: "#C3C3C6", default: .gray))
                                    RoundedRectangle(cornerRadius: 5)
                                        .fill(.red)
                                        .frame(width: 20, height: 20)
                                        .overlay(Text("15").font(.caption).fontWeight(.semibold).foregroundStyle(.white)
                                        )
                                    Spacer()
                                    Image(systemName: "chevron.forward").foregroundStyle(.gray).fontWeight(.semibold)
                                }
                                .frame(maxWidth: .infinity, alignment: .leading)
                            }

                            Button(action: {
                                store.send(.receiptIssueButtonTapped(type: .purchase))
                            }) {
                                HStack {
                                    RoundedRectangle(cornerRadius: 15)
                                        .fill(Color(hex: "#343D39", default: .black))
                                        .frame(width: 40, height: 40)
                                        .overlay(Image(systemName: "receipt.fill").foregroundStyle(Color(hex: "#67E9AF", default: .accentColor)))

                                    Text("영수증 발급").font(.system(size: 18)).fontWeight(.bold).foregroundStyle(Color(hex: "#C3C3C6", default: .gray))

                                    Spacer()
                                    Image(systemName: "chevron.forward").foregroundStyle(.gray).fontWeight(.semibold)
                                }
                                .frame(maxWidth: .infinity, alignment: .leading)
                            }

                        }.frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(20)
                    .background(Color(hex: "#17171C", default: .black))
                    .cornerRadius(15)

                }.frame(maxWidth: .infinity).padding()
            }
            .frame(maxWidth: .infinity)
            .background(Color(hex: "#101013", default: .black))
            .navigationTitle("홈")
            .navigationBarTitleDisplayMode(.inline)
        } destination: { destinationStore in
            destinationView(for: destinationStore)
        }
        .sheet(item: $store.scope(state: \.destination?.selectBooks, action: \.destination.selectBooks)) {
            receiptSelectBooksStore in
            NavigationStack {
                ReceiptSelectBooksView(store: receiptSelectBooksStore)
            }
        }
    }
}

#Preview {
    NavigationStack {
        HomeView(store: Store(initialState: HomeFeature.State(), reducer: {
            HomeFeature()
        }))
    }
}
