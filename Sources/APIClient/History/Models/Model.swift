//
//  Model.swift
//
//
//  Copyright © 2025 Ara Hakobyan. All rights reserved.
//

import Foundation

public struct Model: Identifiable, Sendable {
    public let id: String
    public let date: Date
    public let request: URLRequest
    public var response: URLResponse?
    public var data: Data?
    public var duration: Double?

    public var url: String { request.url?.absoluteString ?? "" }
    public var method: String { request.httpMethod?.uppercased() ?? "" }
    public var code: Int { (response as? HTTPURLResponse)?.statusCode ?? 0 }
    public var responseHeaders: [String: String]? { (response as? HTTPURLResponse)?.allHeaderFields as? [String: String] }

    init(request: URLRequest) {
        id = UUID().uuidString
        date = Date()
        self.request = request
    }

    mutating func update(_ response: URLResponse, _ data: Data) {
        self.response = response
        self.data = data
        duration = fabs(date.timeIntervalSinceNow) * 1000

        Storage.save(model: self)
    }

    static let mock = Model(request: URLRequest(url: URL(string: "https://jsonplaceholder.typicode.com/todos/1")!))
}
