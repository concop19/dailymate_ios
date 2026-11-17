import Foundation
public struct BackendEndpoint: Sendable, Equatable {
  enum HTTPMethod: String, Sendable, Equatable {
    case get = "GET"
    case post = "POST"
    case put = "PUT"
    case delete = "DELETE"
  }

  var path: String
  var method: HTTPMethod = .get
  var queryItems: [URLQueryItem] = []
  var body: Data?
  var requiresAuth: Bool = true
  var timeoutInterval: TimeInterval = 30
  var language: String = "vi"

  static func get(
    _ path: String,
    queryItems: [URLQueryItem] = [],
    requiresAuth: Bool = true,
    timeoutInterval: TimeInterval = 30
  ) -> Self {
    Self(
      path: path,
      method: .get,
      queryItems: queryItems,
      requiresAuth: requiresAuth,
      timeoutInterval: timeoutInterval
    )
  }

  static func post<Body: Encodable>(
    _ path: String,
    body: Body,
    queryItems: [URLQueryItem] = [],
    requiresAuth: Bool = true,
    timeoutInterval: TimeInterval = 30
  ) throws -> Self {
    Self(
      path: path,
      method: .post,
      queryItems: queryItems,
      body: try BackendJSON.encoder.encode(body),
      requiresAuth: requiresAuth,
      timeoutInterval: timeoutInterval
    )
  }

  static func put<Body: Encodable>(
    _ path: String,
    body: Body,
    queryItems: [URLQueryItem] = [],
    requiresAuth: Bool = true,
    timeoutInterval: TimeInterval = 30
  ) throws -> Self {
    Self(
      path: path,
      method: .put,
      queryItems: queryItems,
      body: try BackendJSON.encoder.encode(body),
      requiresAuth: requiresAuth,
      timeoutInterval: timeoutInterval
    )
  }
}
