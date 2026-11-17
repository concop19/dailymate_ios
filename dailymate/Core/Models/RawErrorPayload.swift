//
//  RawErrorPayload.swift
//  dailymate
//
//  Created by ManhLe on 11/17/26.
//
import Foundation

struct RawErrorPayload: Decodable {
  let error: String?
  let detail: String?
  let requestId: String?
  let retryAfter: TimeInterval?
  let success: Bool?

  enum CodingKeys: String, CodingKey {
    case error
    case detail
    case requestId = "request_id"
    case retryAfter = "retry_after"
    case success
  }
}
