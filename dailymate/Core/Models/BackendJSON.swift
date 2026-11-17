//
//  BackendJSON.swift
//  dailymate
//
//  Created by ManhLe on 11/17/26.
//
import Foundation
enum BackendJSON {
  static let encoder: JSONEncoder = {
    let encoder = JSONEncoder()
    encoder.keyEncodingStrategy = .convertToSnakeCase
    return encoder
  }()

  static let decoder: JSONDecoder = {
    let decoder = JSONDecoder()
    decoder.keyDecodingStrategy = .convertFromSnakeCase
    return decoder
  }()
}
