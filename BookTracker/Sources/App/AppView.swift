//
//  AppView.swift
//  BookTracker
//
//  Created by 배성연 on 2/2/26.
//

import SwiftUI
import ComposableArchitecture

struct AppView: View {
  let store: StoreOf<AppFeature>

  var body: some View {
    SwitchStore(self.store.scope(state: { $0.route }, action: { $0 })) {
      CaseLet(/AppFeature.State.Route.auth, action: AppFeature.RouteAction.auth) { authStore in
        AuthView(store: authStore)
      }

      CaseLet(/AppFeature.State.Route.main, action: AppFeature.RouteAction.main) { mainStore in
        MainView(store: mainStore)
      }
    }
  }
}

