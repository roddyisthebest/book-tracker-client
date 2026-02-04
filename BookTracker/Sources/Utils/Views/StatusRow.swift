//
//  StatusRow.swift
//  BookTracker
//
//  Created by 배성연 on 2/4/26.
//

import SwiftUI

struct StatusRow: View {
    let key: String
    let value: String

    var body: some View {
        HStack(alignment: .top) {
            Text("\(key)").foregroundStyle(.white.opacity(0.65)).font(.system(size: 18, weight: .medium))
            Spacer()
            Text("\(value)").foregroundStyle(.white.opacity(0.85)).font(.system(size: 18, weight: .bold))
        }
    }
}
