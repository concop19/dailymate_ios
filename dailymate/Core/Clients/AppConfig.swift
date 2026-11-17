//
//  AppConfig.swift
//  dailymate
//
//  Created by ManhLe on 11/16/26.
//

import ComposableArchitecture
import Foundation

/// Cấu hình môi trường của ứng dụng, đọc từ Info.plist (được inject qua `.xcconfig`).
struct AppConfig: Sendable {
  let supabaseURL: URL
  let supabasePublishableKey: String
  let backendURL: URL?
}

extension AppConfig: DependencyKey {
  private enum InfoKey {
    static let supabaseURL = "SUPABASE_URL"
    static let supabasePublishableKey = "SUPABASE_PUBLISHABLE_KEY"
    static let backendURL = "DAILYMATE_BACKENDED_URL"
  }

  private enum Fallback {
    static let supabaseURL = URL(string: "https://cluqexxdclgtybmryati.supabase.co")!
    static let supabasePublishableKey = "sb_publishable_-aTPg2_IrpWstYEIiMAWeg_3gbTRxmG"
    static let backendURL = URL(string: "https://daily-mate-server.onrender.com")
  }

  static let liveValue: AppConfig = {
    let supabaseURL = infoString(for: InfoKey.supabaseURL)
      .flatMap(URL.init(string:)) ?? Fallback.supabaseURL

    let supabasePublishableKey = infoString(for: InfoKey.supabasePublishableKey)
      ?? Fallback.supabasePublishableKey

    let backendURL = infoString(for: InfoKey.backendURL)
      .flatMap(URL.init(string:)) ?? Fallback.backendURL

    return AppConfig(
      supabaseURL: supabaseURL,
      supabasePublishableKey: supabasePublishableKey,
      backendURL: backendURL
    )
  }()

  static let previewValue: AppConfig = AppConfig(
    supabaseURL: URL(string: "https://preview.supabase.co")!,
    supabasePublishableKey: "preview-publishable-key",
    backendURL: URL(string: "https://preview-api.dailymate.app")
  )

  static let testValue: AppConfig = AppConfig(
    supabaseURL: URL(string: "https://test.supabase.co")!,
    supabasePublishableKey: "test-publishable-key",
    backendURL: URL(string: "https://test-api.dailymate.app")
  )

  private static func infoString(for key: String) -> String? {
    guard let raw = Bundle.main.object(forInfoDictionaryKey: key) as? String else {
      return nil
    }
    let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !trimmed.isEmpty, !trimmed.hasPrefix("$("), trimmed != "https:" else {
      return nil
    }
    return trimmed
  }
}
/*
 ứng dụng khi build sẽ đóng gói toàn bộ mã máy mik 1 thư mục ten là bundle
 .main -> chính trỏ trực tiếp đến builde mà ta dag chạy
 object -> lấy giá trị môi trường được tht lập ở đây
 */
extension DependencyValues {
  var appConfig: AppConfig {
    get { self[AppConfig.self] }
    set { self[AppConfig.self] = newValue }
  }
}
