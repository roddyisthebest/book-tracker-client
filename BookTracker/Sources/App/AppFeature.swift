//
//  AppFeature.swift
//  BookTracker
//
//  Created by 배성연 on 2/3/26.
//

import ComposableArchitecture
import CasePaths

@Reducer
struct AppFeature {
  @ObservableState
  @CasePathable
  enum State: Equatable {
    case auth(AuthFeature.State)
    case main(MainFeature.State)
  }

  @CasePathable
  enum Action {
    case auth(AuthFeature.Action)
    case main(MainFeature.Action)
  }

  var body: some ReducerOf<Self> {
    Scope(state: \.auth, action: \.auth) { AuthFeature() }
    Scope(state: \.main, action: \.main) { MainFeature() }

    Reduce { state, action in
      switch action {
      case .auth(.delegate(.setAuthenticated)):
          state = .main(MainFeature.State())
          return .none
      case .auth:
          return .none
      case .main:
          return .none
      }
    }
  }
}
