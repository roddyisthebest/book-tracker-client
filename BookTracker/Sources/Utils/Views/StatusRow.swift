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
            MainLabel(key)
            Spacer(minLength: 20)
            Text("\(value)").foregroundStyle(.white.opacity(0.85)).font(.system(size: 18, weight: .bold))
        }
    }
}

#Preview {
    StatusRow(key: "메모", value: "안녕하세요 저는 미켈란젤로 입니다. 사람들은 이리 말하고 저리말하지")
}
