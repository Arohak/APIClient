//
//  ListView.swift
//
//
//  Copyright © 2025 Ara Hakobyan. All rights reserved.
//

import SwiftUI

struct ListView: View {
    let models: [Model]

    var body: some View {
        List {
            ForEach(models) { model in
                NavigationLink {
                    DetailView(model: model)
                } label: {
                    ListItemView(model: model)
                }
            }
        }
    }
}

struct ListView_Previews: PreviewProvider {
    static var previews: some View {
        ListView(models: [.mock, .mock])
    }
}
