//
//  APIClient.swift
//
//
//  Copyright © 2025 Ara Hakobyan. All rights reserved.
//

import Combine
import Foundation

public struct Response<T: Sendable>: Sendable {
    public let value: T
    public let response: URLResponse
}

public enum HTTPMethod: String {
    case get, post, put, patch, delete

    var value: String {
        return rawValue.uppercased()
    }
}

public enum HTTPContentType {
    case form
    case urlencode
}

public enum ServerError: Error {
    case unauthorized
    case forbidden
    case notFound
    case internalError(Data, HTTPURLResponse)
    case externalError(Data, HTTPURLResponse)
    case badRequest
}

public protocol APIClient: Endpoint {
    var baseUrl: URL { get }
    var headers: [String: String]? { get }
}

public protocol Endpoint {
    var path: String { get }
    var queryItems: [URLQueryItem] { get }
    var bodyParameters: Any? { get }
    var httpMethod: HTTPMethod { get }
    var contentType: HTTPContentType { get }
    var formData: FormData? { get }
}

public extension Endpoint {
    var queryItems: [URLQueryItem] {
        return []
    }

    var bodyParameters: Any? {
        return nil
    }

    var httpMethod: HTTPMethod {
        return .get
    }

    var contentType: HTTPContentType {
        return .form
    }

    var formData: FormData? {
        return nil
    }

    private var httpBody: Data? {
        switch contentType {
        case .form:
            if let bodyParameters = bodyParameters as? Data {
                return bodyParameters
            }
            if let bodyParameters = bodyParameters as? String {
                print(bodyParameters)
                return bodyParameters.data(using: .utf8)
            }
            if let bodyParameters = bodyParameters, let jsonData = try? JSONSerialization.data(withJSONObject: bodyParameters, options: .prettyPrinted) {
                print(bodyParameters)
                return jsonData
            }
            return nil
        case .urlencode:
            var components = URLComponents()
            if let bodyParameters = bodyParameters as? [String: String] {
                components.queryItems = []
                bodyParameters.forEach { key, value in
                    components.queryItems?.append(URLQueryItem(name: key, value: value))
                }
            } else {
                assertionFailure("Url encoded params should be passed as a dictionary")
            }
            return components.query?.data(using: .utf8)
        }
    }
    
    func request(url: URL, headers: [String: String]?) -> URLRequest? {
        var urlComponents = URLComponents()
        urlComponents.scheme = url.scheme
        urlComponents.queryItems = queryItems
        urlComponents.host = url.host
        urlComponents.port = url.port
        urlComponents.path = url.path + path
        guard let url = urlComponents.url else {
            return nil
        }
        var request = URLRequest(url: url)
        request.httpMethod = httpMethod.value
        request.allHTTPHeaderFields = headers
        if let formData = formData {
            request.httpBody = formData.httpBody
        } else {
            request.httpBody = httpBody
        }
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        return request
    }

    func checkStatusCode(data: Data, response: URLResponse) throws {
        guard let httpResponse = response as? HTTPURLResponse else {
            log(message: "🔴 Error", value: "badRequest")
            throw ServerError.badRequest
        }
        var error: ServerError?
        if httpResponse.statusCode == 401 {
            error = .unauthorized
        } else if httpResponse.statusCode == 403 {
            error = .forbidden
        } else if httpResponse.statusCode == 404 {
            error = .notFound
        } else if 405 ..< 500 ~= httpResponse.statusCode {
            error = .internalError(data, httpResponse)
        } else if 500 ..< 600 ~= httpResponse.statusCode {
            error = .externalError(data, httpResponse)
        }
        if let error = error {
            log(message: "🔴 Error \(httpResponse.statusCode)\n", data: data)
            throw error
        }
    }

    func log(message: String, data: Data) {
        guard let json = try? JSONSerialization.jsonObject(with: data, options: []),
              let jsonData = try? JSONSerialization.data(withJSONObject: json, options: .prettyPrinted),
              let string = String(data: jsonData, encoding: .utf8)
        else {
            log(message: "🔴 Error JSONSerialization\n", value: data)
            return
        }
        log(message: message, value: string)
    }

    func log(message: String, value: Any) {
        #if DEBUG
            print(message, value)
        #endif
    }
}

// MARK: - async await

public extension APIClient {
    func execute<T: Decodable>(session: URLSession = .shared, decoder: JSONDecoder = JSONDecoder(), type: T.Type) async throws -> Response<T> {
        return try await execute(baseUrl: baseUrl, headers: headers, session: session, decoder: decoder, type: type)
    }

    func execute(session: URLSession = .shared) async throws -> Response<Data> {
        return try await execute(baseUrl: baseUrl, headers: headers, session: session)
    }
}

public extension Endpoint {
    func execute<T: Decodable>(baseUrl: URL, headers: [String: String]? = nil, session: URLSession = .shared, decoder: JSONDecoder = JSONDecoder(), type: T.Type) async throws -> Response<T> {
        let (data, response) = try await execute(baseUrl: baseUrl, headers: headers, session: session)
        log(message: "ℹ️ JSON\n", data: data)
        let value = try decoder.decode(T.self, from: data)
        return Response(value: value, response: response)
    }

    func execute(baseUrl: URL, headers: [String: String]? = nil, session: URLSession = .shared) async throws -> Response<Data> {
        let (data, response) = try await execute(baseUrl: baseUrl, headers: headers, session: session)
        log(message: "ℹ️ Data\n", value: data)
        return Response(value: data, response: response)
    }
    
    func execute(baseUrl: URL, headers: [String: String]?, session: URLSession) async throws -> (Data, URLResponse) {
        if let request = request(url: baseUrl, headers: headers) {
            var model = Model(request: request)
            let (data, response) = try await session.data(for: request)
            model.update(response, data)
            log(message: "👇 Response\n🟢", value: response)
            try checkStatusCode(data: data, response: response)
            return (data, response)
        } else {
            throw ServerError.badRequest
        }
    }
}
