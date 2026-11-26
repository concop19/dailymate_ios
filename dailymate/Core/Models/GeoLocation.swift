//
//  GeoLocation.swift
//  dailymate
//
//  Created by ManhLe on 11/23/26.
//
import ComposableArchitecture
import Foundation
struct GeoLocation: Sendable, Equatable , Codable
{
    var lat: Double
    var lon: Double
    var province: String?
    
    
}
// response of geo
