//
//  AuthFeature.swift
//  BookTracker
//
//  Created by 배성연 on 2/2/26.
//

import Foundation
import ComposableArchitecture

enum SnsLoginMethod: Equatable {
  case apple
  case google
}

@Reducer
struct AuthFeature{
    
    @ObservableState
    struct State: Equatable { }
    
    enum Action{
        case snsLoginButtonTapped(SnsLoginMethod)
        
        case delegate(Delegate)
        enum Delegate:Equatable{
            case setAuthenticated
        }
        
    }
    
    var body: some Reducer<State, Action>{
        Reduce{ _, action in
            switch action {
                case .snsLoginButtonTapped(let method):
                    return .send(.delegate(.setAuthenticated))
                case .delegate:
                    return .none;
            }
        }
    }
    
}
