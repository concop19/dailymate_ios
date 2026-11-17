//
//  ShakeClient.swift
//  dailymate
//
//  Created by ManhLe on 11/16/26.
//

import ComposableArchitecture
import UIKit

/// Client xử lý phản hồi rung (Haptic Feedback) cho các sự kiện UI.
/// Viết thủ công (không dùng macro @DependencyClient) để tránh lỗi macro plugin.
struct ShakeClient: Sendable {
  enum ImpactStyle: Sendable, Equatable {
    /// Rung rất nhẹ, thanh thoát (chạm nút phụ, icon nhỏ, toggle nhẹ).
    case light
    /// Rung vừa phải, rõ ràng (bấm nút CTA chính, xác nhận thao tác).
    case medium
    /// Rung mạnh, dứt khoát (thao tác quan trọng, cảnh báo va chạm lớn).
    case heavy
    /// Rung mềm, êm và có độ nảy dịu (thả item, chuyển trạng thái mượt).
    case soft
    /// Rung cứng, sắc và ngắn gọn (chạm giới hạn, snap vào vị trí).
    case rigid

    @MainActor
    var uiKitStyle: UIImpactFeedbackGenerator.FeedbackStyle {
      switch self {
      case .light: return .light
      case .medium: return .medium
      case .heavy: return .heavy
      case .soft: return .soft
      case .rigid: return .rigid
      }
    }
  }

  enum NotificationType: Sendable, Equatable {
    case success
    case warning
    case error

    @MainActor
    var uiKitType: UINotificationFeedbackGenerator.FeedbackType {
      switch self {
      case .success: return .success
      case .warning: return .warning
      case .error: return .error
      }
    }
  }

  /// Rung va chạm nhẹ/vừa/mạnh (dùng cho nút bấm, tương tác UI).
  var impact: @Sendable (_ style: ImpactStyle) async -> Void
  /// Rung thông báo kết quả (thành công, cảnh báo, lỗi/rung thẻ).
  var notification: @Sendable (_ type: NotificationType) async -> Void
  /// Rung nhẹ khi thay đổi lựa chọn (chuyển tab/mode, toggle).
  var selection: @Sendable () async -> Void
}

extension ShakeClient {
  /// Tiện ích rung nhẹ (slight) cho các tương tác chạm thông thường.
  func slight() async {
    await impact(.light)
  }
}
/*tại sao là main actor */
extension ShakeClient: DependencyKey {
  static var liveValue: ShakeClient {
    ShakeClient(
      impact: { style in
        await MainActor.run {
          let generator = UIImpactFeedbackGenerator(style: style.uiKitStyle)
          generator.prepare()
          generator.impactOccurred()
        }
      },
      notification: { type in
        await MainActor.run {
          let generator = UINotificationFeedbackGenerator()
          generator.prepare()
          generator.notificationOccurred(type.uiKitType)
        }
      },
      selection: {
        await MainActor.run {
          let generator = UISelectionFeedbackGenerator()
          generator.prepare()
          generator.selectionChanged()
        }
      }
    )
  }

  static var previewValue: ShakeClient {
    ShakeClient(
      impact: { _ in },
      notification: { _ in },
      selection: {}
    )
  }

  static var testValue: ShakeClient { previewValue }
}

extension DependencyValues {
  var shakeClient: ShakeClient {
    get { self[ShakeClient.self] }
    set { self[ShakeClient.self] = newValue }
  }
}
