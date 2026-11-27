//
//  BackendJSON.swift
//  dailymate
//
//  Created by ManhLe on 11/17/26.
//

import Foundation

/// Cấu hình `JSONEncoder` / `JSONDecoder` dùng chung cho toàn bộ request/response của BackendClient.
enum BackendJSON {
  static let encoder: JSONEncoder = {
    let encoder = JSONEncoder()
    return encoder
  }()

  static let decoder: JSONDecoder = {
    let decoder = JSONDecoder()
    return decoder
  }()
}
