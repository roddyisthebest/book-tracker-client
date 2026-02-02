//
//  AppFeature.swift
//  BookTracker
//
//  Created by 배성연 on 2/2/26.
//

import Foundation
import ComposableArchitecture


@Reducer
struct AppFeature {

  @ObservableState
  struct State: Equatable {
    enum Route: Equatable {
      case auth(AuthFeature.State)
      case main(MainFeature.State)
    }

    var route: Route = .auth(.init())
  }

  enum Action {
    case route(RouteAction)   // ✅ 추가
  }

  enum RouteAction {
    case auth(AuthFeature.Action)
    case main(MainFeature.Action)
  }

  var body: some ReducerOf<Self> {
    Reduce { state, action in
      switch action {

      case .route(.auth(.delegate(.setAuthenticated))):
        state.route = .main(.init())
        return .none

      case .route:
        return .none
      }
    }
  }
}

