//
//  TasteVector.swift
//  dailymate
//
//  Created by ManhLe on 11/19/26.
//


import Foundation

public struct TasteVector: Codable, Equatable, Sendable {
    public var sweet: Double
    public var sour: Double
    public var salty: Double
    public var bitter: Double
    public var umami: Double
    public var spicy: Double
    public var astringent: Double

    public static let `default` = TasteVector(
        sweet: 0.5, sour: 0.4, salty: 0.4, bitter: 0.2,
        umami: 0.6, spicy: 0.5, astringent: 0.1
    )
}