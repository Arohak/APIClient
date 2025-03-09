//
//  RequestItemView.swift
//
//
//  Copyright © 2025 Ara Hakobyan. All rights reserved.
//

import Foundation
import SwiftUI

struct ListItemView: View {
    let model: Model

    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Text(model.method)
                    .font(.headline)

                Text("\(model.code)")
                    .padding(3)
                    .font(.callout)
                    .overlay(
                        RoundedRectangle(cornerRadius: 5)
                            .stroke(model.code >= 400 ? .red : .green, lineWidth: 2)
                    )
                    .padding(.vertical, 1)

                Text(model.duration?.formattedMilliseconds() ?? "")
                    .font(.footnote)
            }

            Text(model.url)
                .font(.caption)
        }
    }
}

struct ListItemView_Previews: PreviewProvider {
    static var previews: some View {
        ListItemView(model: .mock)
    }
}
