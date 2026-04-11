//
//  Label.swift
//  BookTracker
//
//  Created by 배성연 on 2/7/26.
//

import SwiftUI

struct FormLabel: View {
    let text: String

    var body: some View {
        Text(text).foregroundStyle(Color.appSecondaryText).font(.callout)
    }
}

#Preview {
    VStack {
        FormLabel(text: "마팀마스쿼")
    }
}
