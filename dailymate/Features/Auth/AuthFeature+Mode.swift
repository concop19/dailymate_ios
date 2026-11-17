//
//  AuthFeature+Mode.swift
//  dailymate
//
//  Created by ManhLe on 11/16/26.
//

import Foundation

/// Nội dung hiển thị theo từng mode (tạm dùng text trực tiếp, chưa localize).
extension AuthFeature.Mode {
  var emoji: String {
    switch self {
    case .login: "🍳"
    case .register: "🌿"
    case .forgot: "🔑"
    }
  }

  var title: String {
    switch self {
    case .login: "Chào mừng trở lại"
    case .register: "Tạo tài khoản"
    case .forgot: "Quên mật khẩu"
    }
  }

  var subtitle: String {
    switch self {
    case .login: "Đăng nhập để tiếp tục hành trình ăn uống cùng DailyMate"
    case .register: "Bắt đầu những bữa ăn lành mạnh mỗi ngày"
    case .forgot: "Nhập email, chúng mình sẽ gửi liên kết đặt lại mật khẩu"
    }
  }

  var mascotMessage: String {
    switch self {
    case .login: "Meo~ Hôm nay mình nấu món gì ngon nhỉ?"
    case .register: "Meo! Rất vui được làm quen với bạn đó~"
    case .forgot: "Đừng lo, ai cũng có lúc quên mà. Meo~"
    }
  }

  var ctaIcon: String {
    switch self {
    case .login: "🍳"
    case .register: "🌿"
    case .forgot: "📬"
    }
  }

  var ctaTitle: String {
    switch self {
    case .login: "Đăng nhập"
    case .register: "Đăng ký"
    case .forgot: "Gửi liên kết"
    }
  }

  var showsPassword: Bool { self != .forgot }
  var showsConfirmPassword: Bool { self == .register }
  var showsForgotLink: Bool { self == .login }
  var showsGoogle: Bool { self != .forgot }
}
