//
//  FormData.swift
//  xcconfig_template
//
//  Created by Ara Hakobyan on 31.03.21.
//  Copyright © 2021 Ara Hakobyan. All rights reserved.
//

import Foundation

public struct FormData {
    enum MimeType: String {
        case png = "image/png"
        case jpeg = "image/jpeg"
        case pdf = "application/pdf"
        
        var fileExtension: String {
            switch self {
            case .png:  return "png"
            case .jpeg: return "jpeg"
            case .pdf:  return "pdf"
            }
        }
    }
    
    var data: Data
    var name: String
    var dataName: String = "file"
    var parameters: [String: String] = [:]
    var mimeType: MimeType

    var httpBody: Data {
        var body = Data()
        let boundary = "Boundary-\(NSUUID().uuidString)"
        let fullName = name + "." + mimeType.fileExtension
        let lineBreak = "\r\n"
        for parameter in parameters {
            body.append("--\(boundary)\r\n")
            body.append("Content-Disposition: form-data; name=\"\(parameter.key)\"\r\n\r\n")
            body.append("\(parameter.value)\r\n")
        }
        body.append("--\(boundary)\(lineBreak)".data(using: .utf8)!)
        body.append("Content-Disposition:form-data; name=\"\(dataName)\"; filename=\"\(fullName)\"\(lineBreak)".data(using: .utf8)!)
        body.append("Content-Type: \(mimeType.rawValue)\(lineBreak)\(lineBreak)".data(using: .utf8)!)
        body.append(data)
        body.append("\(lineBreak)".data(using: .utf8)!)
        body.append("--\(boundary)--\(lineBreak)".data(using: .utf8)!)
        return body
    }
}

extension Data {
    mutating func append(_ string: String, using encoding: String.Encoding = .utf8) {
        guard let data = string.data(using: encoding) else { return }
        append(data)
    }
}
