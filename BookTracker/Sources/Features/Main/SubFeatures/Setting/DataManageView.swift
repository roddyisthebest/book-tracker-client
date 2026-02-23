//
//  DataManageView.swift
//  BookTracker
//
//  Created by 배성연 on 2/22/26.
//

import ComposableArchitecture
import SwiftUI

struct DataManageView: View {
    @Bindable var store: StoreOf<DataManageFeature>

    private var mainContent: some View {
        ScrollView {
            VStack(spacing: 15) {
                VStack(spacing: 20) {
                    VStack(alignment: .leading, spacing: 5) {
                        Text("파일 내보내기").font(.title2).fontWeight(.bold).lineLimit(1)
                        Text("독서기록을 파일로 저장합니다").font(.system(size: 15, weight: .semibold)).foregroundStyle(Color(hex: "#7E7E87", default: .gray)).lineLimit(1)

                        VStack(spacing: 18) {
                            Button(action: {}) {
                                HStack(spacing: 10) {
                                    Rectangle().fill(Color(hex: "#2C2C35", default: .black))
                                        .frame(width: 30, height: 30).cornerRadius(10).overlay {
                                            Image(systemName: "square.and.arrow.up.fill").foregroundStyle(.white).font(.system(size: 12))
                                        }

                                    HStack {
                                        Text("CSV 내보내기").font(.title3).fontWeight(.bold).foregroundStyle(.white)
                                        Spacer()
                                        Image(systemName: "chevron.right").fontWeight(.semibold).foregroundStyle(Color(hex: "#62626D", default: .gray)).font(.system(size: 16))
                                    }
                                }
                            }

                        }.frame(maxWidth: .infinity, alignment: .leading).padding(.top, 20)

                    }.frame(maxWidth: .infinity, alignment: .leading).padding(.top).padding(.horizontal)
                }
                .padding(.bottom)

                Divider().frame(height: 15).background(.black)

                VStack(spacing: 20) {
                    VStack(alignment: .leading, spacing: 5) {
                        Text("초기화").font(.title2).fontWeight(.bold).lineLimit(1)
                        Text("저장된 모든 데이터를 삭제합니다").font(.system(size: 15, weight: .semibold)).foregroundStyle(Color(hex: "#7E7E87", default: .gray)).lineLimit(1)

                        VStack(spacing: 18) {
                            Button(action: {
                                store.send(.dataResetButtonTapped)
                            }) {
                                HStack(spacing: 10) {
                                    Rectangle().fill(Color(hex: "#2C2C35", default: .black))
                                        .frame(width: 30, height: 30).cornerRadius(10).overlay {
                                            Image(systemName: "trash").foregroundStyle(.red).font(.system(size: 12))
                                        }

                                    HStack {
                                        Text("데이터 초기화").font(.title3).fontWeight(.bold).foregroundStyle(.white)
                                        Spacer()
                                        Image(systemName: "chevron.right").fontWeight(.semibold).foregroundStyle(Color(hex: "#62626D", default: .gray)).font(.system(size: 16))
                                    }
                                }
                            }

                        }.frame(maxWidth: .infinity, alignment: .leading).padding(.top, 20)

                    }.frame(maxWidth: .infinity, alignment: .leading).padding(.top).padding(.horizontal)
                }
                .padding(.bottom)
            }
        }
        .background(Color(hex: "#101013", default: .black))
    }

    var body: some View {
        mainContent
            .navigationTitle("데이터 관리")
            .navigationBarTitleDisplayMode(.inline)
            .alert(store: store.scope(state: \.$alert, action: \.alert))
    }
}

#Preview {
    NavigationStack {
        DataManageView(store: Store(initialState: DataManageFeature.State(), reducer: {
            DataManageFeature()
        }))
    }
}
