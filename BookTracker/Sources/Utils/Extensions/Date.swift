//
//  Date.swift
//  BookTracker
//
//  Created by 배성연 on 3/17/26.
//

import Foundation

extension Date {
    func toDay() -> String {
        let day = Calendar.current.component(.day, from: self)
        return "\(day)"
    }

    func toDayOfWeek() -> String {
        let weekday = Calendar.current.component(.weekday, from: self)
        let symbols = ["일", "월", "화", "수", "목", "금", "토"]
        return symbols[weekday - 1]
    }
}
