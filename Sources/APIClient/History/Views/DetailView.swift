//
//  DetailView.swift
//
//
//  Copyright © 2025 Ara Hakobyan. All rights reserved.
//

import SwiftUI

enum DetailTab: String, CaseIterable {
    case info, request, response

    var index: Int {
        switch self {
        case .info: return 0
        case .request: return 1
        case .response: return 2
        }
    }
}

struct DetailView: View {
    @State private var selectedTab: Int = 0

    let model: Model
    let items = DetailTab.allCases

    var body: some View {
        Picker("", selection: $selectedTab) {
            ForEach(items, id: \.self) { item in
                Text(item.rawValue.capitalized).tag(item.index)
            }
        }
        .pickerStyle(.segmented)

        DetailTabView(tab: items[selectedTab], model: model)

        Spacer()
    }
}

struct DetailView_Previews: PreviewProvider {
    static var previews: some View {
        DetailView(model: .mock)
    }
}
