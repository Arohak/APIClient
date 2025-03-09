//
//  FormData.swift
// 
//
//  Copyright © 2025 Ara Hakobyan. All rights reserved.
//

import Foundation

public struct FormData: Sendable {
    public struct File : Sendable{
        let data: Data
        let key: String
        let name: String
        var mimeType: MimeType
        
        public init(data: Data, key: String, name: String, mimeType: MimeType) {
            self.data = data
            self.key = key
            self.name = name
            self.mimeType = mimeType
        }
    }
    
    public enum MimeType: String, Sendable {
        case jpeg = "image/jpeg"
        case pdf = "application/pdf"

        var fileExtension: String {
            switch self {
            case .jpeg: return "image"
            case .pdf: return "pdf"
            }
        }
    }

    var params: [String: String] = [:]
    var files: [File] = []

    public let boundary = "Boundary-\(NSUUID().uuidString)"

    public var type: String { files.first?.mimeType.fileExtension ?? "" }

    var httpBody: Data {
        var body = Data()
        let lineBreak = "\r\n"
        for (key, value) in params {
            body.append("--\(boundary)\(lineBreak)")
            body.append("Content-Disposition: form-data; name=\"\(key)\"\(lineBreak)\(lineBreak)")
            body.append("\(value)\(lineBreak)")
        }
        for file in files {
            body.append("--\(boundary)\(lineBreak)")
            body.append("Content-Disposition: form-data; name=\"\(file.key)\"; filename=\"\(file.name)\"\(lineBreak)")
            body.append("Content-Type: \(file.mimeType.rawValue)\(lineBreak)\(lineBreak)")
            body.append(file.data)
            body.append(lineBreak)
        }
        body.append("--\(boundary)--\(lineBreak)")
        return body
    }

    public init(params: [String: String] = [:], data: Data? = nil, mimeType: MimeType? = nil) {
        self.params = params
        if let data {
            let mimeType = mimeType ?? .jpeg
            let name = "\(Int(Date().timeIntervalSince1970 * 1_000_000)).\(mimeType.fileExtension)"
            let file = File(data: data, key: "file", name: name, mimeType: mimeType)
            self.files = [file]
        }
    }
}

extension FormData {
    public init(files: [File]) {
        self.files = files
    }
}

extension Data {
    mutating func append(_ string: String, using encoding: String.Encoding = .utf8) {
        guard let data = string.data(using: encoding) else { return }
        append(data)
    }
}
