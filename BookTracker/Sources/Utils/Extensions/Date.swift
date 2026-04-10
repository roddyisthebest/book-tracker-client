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
        let formatter = DateFormatter()
        formatter.locale = Locale.current
        formatter.dateFormat = "EEE"
        return formatter.string(from: self)
    }
}
