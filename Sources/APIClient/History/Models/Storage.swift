//
//  Storage.swift
//
//
//  Copyright © 2025 Ara Hakobyan. All rights reserved.
//

import Foundation

public class Storage {
    private static let lockQueue = DispatchQueue(label: "name.lock.queue")

    nonisolated(unsafe) private static var models: [Model] = []

    static func save(model: Model?) {
        guard let model else {
            return
        }

        DispatchQueue.global().async {
            self.lockQueue.async {
                if let index = self.models.firstIndex(where: { model.id == $0.id }) {
                    self.models[index] = model
                } else {
                    self.models.insert(model, at: 0)
                }
            }
        }
    }

    static func read(_ closure: (([Model]) -> Void)?) {
        DispatchQueue.global().async {
            self.lockQueue.async {
                closure?(self.models)
            }
        }
    }

    static func clear() {
        DispatchQueue.global().async {
            self.lockQueue.async {
                self.models.removeAll()
            }
        }
    }
}
