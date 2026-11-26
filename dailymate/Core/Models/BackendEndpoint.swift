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



extension BackendEndpoint {
  /// GET /api/v1/onboarding/allergy-ingredients?group=<key>&lang=<lang>
  static func onboardingAllergyIngredients(
    group: AllergyGroup,
    language: String = "vi"
  ) -> Self {
    var endpoint = Self.get(
      "/api/v1/onboarding/allergy-ingredients",
      queryItems: [
        URLQueryItem(name: "group", value: group.rawValue),
        URLQueryItem(name: "lang", value: language),
      ],
      requiresAuth: true,
      timeoutInterval: 12
    )
    endpoint.language = language
    return endpoint
  }

  /// POST /api/v1/onboarding/flashcards?lang=<lang>
  static func onboardingFlashcards(
    _ body: FlashcardsRequestDTO,
    language: String = "vi"
  ) throws -> Self {
    var endpoint = try Self.post(
      "/api/v1/onboarding/flashcards",
      body: body,
      queryItems: [URLQueryItem(name: "lang", value: language)],
      requiresAuth: true,
      timeoutInterval: 12
    )
    endpoint.language = language
    return endpoint
  }

  /// GET /api/weather?lat=<lat>&lon=<lon>
  static func weather(
    lat: Double,
    lon: Double,
    language: String = "vi"
  ) -> Self {
    var endpoint = Self.get(
      "/api/weather",
      queryItems: [
        URLQueryItem(name: "lat", value: String(lat)),
        URLQueryItem(name: "lon", value: String(lon)),
      ],
      requiresAuth: true,
      timeoutInterval: 15
    )
    endpoint.language = language
    return endpoint
  }
  /// POST /api/v1/suggest-ingredients?lang=<lang>
  static func ingredientSuggest(
    searchParam: SearchParamsDTO,
    language: String = "vi"
  ) throws -> Self {
    var endpoint = try Self.post(
      "/api/v1/suggest-ingredients",
      body: searchParam,
      queryItems: [URLQueryItem(name: "lang", value: language)],
      requiresAuth: true,
      timeoutInterval: 30
    )
    endpoint.language = language
    return endpoint
  }

  /// POST /api/v1/recommend?lang=<lang>
  static func recommend(
    searchParam: SearchParamsDTO,
    language: String = "vi"
  ) throws -> Self {
    var endpoint = try Self.post(
      "/api/v1/recommend",
      body: searchParam,
      queryItems: [URLQueryItem(name: "lang", value: language)],
      requiresAuth: true,
      timeoutInterval: 30
    )
    endpoint.language = language
    return endpoint
  }
  /// POST /api/v1/onboarding/taste-profile?lang=<lang>
  static func onboardingTasteProfile(
    _ body: TasteProfileRequestDTO,
    language: String = "vi"
  ) throws -> Self {
    var endpoint = try Self.post(
      "/api/v1/onboarding/taste-profile",
      body: body,
      queryItems: [URLQueryItem(name: "lang", value: language)],
      requiresAuth: true,
      timeoutInterval: 12
    )
    endpoint.language = language
    return endpoint
  }
}
