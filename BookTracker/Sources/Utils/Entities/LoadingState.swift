//
//  LoadingState.swift
//  BookTracker
//

import Foundation

enum LoadingState: Equatable {
    case idle
    case loading
    case loaded
    case error
}
