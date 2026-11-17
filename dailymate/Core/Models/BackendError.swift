//
//  BackendError.swift
//  dailymate
//
//  Created by ManhLe on 11/17/26.
//
import Foundation
enum BackendError: LocalizedError, Equatable, Sendable {
  case missingBaseURL
  case invalidURL
  case payloadTooLarge(byteCount: Int)
  case unauthorized
  case invalidResponse
  case api(APIError)

  struct APIError: Equatable, Sendable {
    let statusCode: Int
    let message: String
    let requestId: String?
    let retryAfter: TimeInterval?
  }

  var errorDescription: String? {
    switch self {
    case .missingBaseURL:
      "Chưa cấu hình địa chỉ máy chủ backend."
    case .invalidURL:
      "Địa chỉ API không hợp lệ."
    case let .payloadTooLarge(byteCount):
      "Dữ liệu gửi lên vượt quá giới hạn 256 KB (\(byteCount) bytes)."
    case .unauthorized:
      "Phiên đăng nhập đã hết hạn. Vui lòng đăng nhập lại."
    case .invalidResponse:
      "Phản hồi từ máy chủ không hợp lệ."
    case let .api(apiError):
      apiError.message
    }
  }
}
