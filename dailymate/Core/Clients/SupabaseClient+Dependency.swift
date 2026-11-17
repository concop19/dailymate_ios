//
//  SupabaseClient+Dependency.swift
//  dailymate
//
//  Created by ManhLe on 11/16/26.
//

import ComposableArchitecture
import Foundation
import Supabase

private enum SupabaseClientKey: DependencyKey {
  static let liveValue: SupabaseClient = {
    @Dependency(\.appConfig) var config
    return SupabaseClient(
      supabaseURL: config.supabaseURL,
      supabaseKey: config.supabasePublishableKey
    )
  }()

  static let testValue: SupabaseClient = {
    SupabaseClient(
      supabaseURL: URL(string: "https://test.supabase.co")!,
      supabaseKey: "test-publishable-key"
    )
  }()
}

extension DependencyValues {
  var supabase: SupabaseClient {
    get { self[SupabaseClientKey.self] }
    set { self[SupabaseClientKey.self] = newValue }
  }
}
