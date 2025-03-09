//
//  ApiHistoryView.swift
//
//
//  Copyright © 2025 Ara Hakobyan. All rights reserved.
//

import SwiftUI

public struct ApiHistoryView: View {
    @State var models: [Model] = []

    var completion: (() -> Void)?

    public init(completion: (() -> Void)?) {
        self.completion = completion
    }

    public var body: some View {
        NavigationView {
            ListView(models: models)
                .navigationTitle("Requests")
                .toolbar {
                    ToolbarItem {
                        Button("Done") { completion?() }
                    }
                }
        }
        .onAppear {
            Storage.read { models in
                self.models = models
            }
        }
    }
}
