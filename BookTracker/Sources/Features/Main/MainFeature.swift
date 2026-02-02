//
//  MainFeature.swift
//  BookTracker
//
//  Created by 배성연 on 2/2/26.
//

import ComposableArchitecture

@Reducer
struct MainFeature {
  @ObservableState
  struct State: Equatable {
    var selectedTab: MainTab = .home
  }

  enum Action: Equatable {
    case tabSelected(MainTab)
  }

  var body: some ReducerOf<Self> {
    Reduce { state, action in
      switch action {
      case let .tabSelected(tab):
        state.selectedTab = tab
        return .none
      }
    }
  }
}
