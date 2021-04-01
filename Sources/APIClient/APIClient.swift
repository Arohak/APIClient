//
//  APIClient.swift
//  xcconfig_template
//
//  Created by Ara Hakobyan on 31.03.21.
//  Copyright © 2021 Ara Hakobyan. All rights reserved.
//

import Foundation
import Combine

public struct Response<T> {
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

public enum APIError: Error {
    case badRequest
}

public protocol APIClient {
    var baseUrl: URL { get }
    var path: String { get }
    var queryItems: [URLQueryItem] { get }
    var headers: [String: String]? { get }
    var bodyParameters: Any? { get }
    var httpMethod: HTTPMethod { get }
    var contentType: HTTPContentType { get }
    var file: FormData? { get }
    
    func execute<T: Decodable>(session: URLSession, decoder: JSONDecoder, type: T.Type) -> AnyPublisher<Response<T>, Error>
    func execute(session: URLSession) -> AnyPublisher<Response<Any>, Error>
    func execute(session: URLSession) -> AnyPublisher<Data, Error>
}

public extension APIClient {
    var queryItems: [URLQueryItem] {
        return []
    }
    
    var headers: [String: String]? {
        return nil
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
    
    var file: FormData? {
        return nil
    }
    
    private var httpBody: Data? {
        switch contentType {
        case .form:
            if let bodyParameters = bodyParameters as? Data {
                return bodyParameters
            }
            if let bodyParameters = bodyParameters, let jsonData = try? JSONSerialization.data(withJSONObject: bodyParameters, options: .prettyPrinted) {
                return jsonData
            }
            return nil
        case .urlencode:
            var components = URLComponents()
            if let bodyParameters = bodyParameters as? [String: String] {
                components.queryItems = []
                bodyParameters.forEach { (key, value) in
                    components.queryItems?.append(URLQueryItem(name: key, value: value))
                }
            } else {
                assertionFailure("Url encoded params should be passed as a dictionary")
            }
            return components.query?.data(using: .utf8)
        }
    }
    
    var request: URLRequest? {
        var urlComponents = URLComponents()
        urlComponents.scheme = baseUrl.scheme
        urlComponents.queryItems = queryItems
        urlComponents.host = baseUrl.host
        urlComponents.path = baseUrl.path + path
        guard let url = urlComponents.url else {
            return nil
        }
        var request = URLRequest(url: url)
        request.httpMethod = httpMethod.value
        request.allHTTPHeaderFields = headers
        if let file = file {
            request.httpBody = file.httpBody
        } else {
            request.httpBody = httpBody
        }
        return request
    }
    
    func execute<T: Decodable>(session: URLSession = .shared, decoder: JSONDecoder = JSONDecoder(), type: T.Type) -> AnyPublisher<Response<T>, Error> {
        if let request = request {
            return session
                .dataTaskPublisher(for: request)
                .print("👇")
                .handleEvents(receiveOutput: {
                    do {
                        let json = try JSONSerialization.jsonObject(with: $0.data, options: [])
                        print("ℹ️ JSON\n", json )
                    } catch let error {
                        print("🔴 JSON\n", error)
                    }
                })
                .tryMap { result -> Response<T> in
                    do {
                        let value = try decoder.decode(T.self, from: result.data)
                        let response = Response(value: value, response: result.response)
                        print("🟢 Response\n", response)
                        return response
                    } catch let error {
                        print("🔴 Response\n", error)
                        throw error
                    }
                }
                .receive(on: DispatchQueue.main)
                .eraseToAnyPublisher()
        } else {
            return Result<Response<T>, Error>.Publisher(.failure(APIError.badRequest)).eraseToAnyPublisher()
        }
    }
    
    func execute(session: URLSession = .shared) -> AnyPublisher<Response<Any>, Error> {
        if let request = request {
            return session
                .dataTaskPublisher(for: request)
                .print("👇")
                .tryMap { result -> Response<Any> in
                    do {
                        let value = try JSONSerialization.jsonObject(with: result.data, options: [])
                        let response = Response(value: value, response: result.response)
                        print("🟢 Response\n", response)
                        return response
                    } catch let error {
                        print("🔴 Response\n", error)
                        throw error
                    }
                }
                .receive(on: DispatchQueue.main)
                .eraseToAnyPublisher()
        } else {
            return Result<Response<Any>, Error>.Publisher(.failure(APIError.badRequest)).eraseToAnyPublisher()
        }
    }
    
    func execute(session: URLSession = .shared) -> AnyPublisher<Data, Error> {
        if let request = request {
            return session
                .dataTaskPublisher(for: request)
                .print("👇")
                .tryMap { response -> Data in
                    print("🟢 Response\n", response)
                    return response.data
                }
                .receive(on: DispatchQueue.main)
                .eraseToAnyPublisher()
        } else {
            return Result<Data, Error>.Publisher(.failure(APIError.badRequest)).eraseToAnyPublisher()
        }
    }
}

