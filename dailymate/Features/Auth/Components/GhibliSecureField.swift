//
//  GhibliSecureField.swift
//  dailymate
//
//  Created by ManhLe on 11/16/26.
//

import SwiftUI

/// Ô nhập mật khẩu kèm nhãn, có thể bật/tắt hiển thị bằng nút con mắt.
struct GhibliSecureField: View {
  let label: String
  @Binding var text: String
  let isRevealed: Bool
  var isFocused = false
  var placeholder = "••••••••"
  var textContentType: UITextContentType? = .password
  var submitLabel: SubmitLabel = .done
  /// `nil` → ẩn nút con mắt (vd: ô xác nhận mật khẩu dùng chung trạng thái).
  var onToggleReveal: (() -> Void)?

  var body: some View {
    VStack(alignment: .leading, spacing: 6) {
      GhibliFieldLabel(label)

      HStack(spacing: 8) {
        Group {
          if isRevealed {
            TextField(label, text: $text, prompt: ghibliPrompt(placeholder))
          } else {
            SecureField(label, text: $text, prompt: ghibliPrompt(placeholder))
          }
        }
        .textContentType(textContentType)
        .textInputAutocapitalization(.never)
        .autocorrectionDisabled()
        .submitLabel(submitLabel)

        if let onToggleReveal {
          Button(action: onToggleReveal) {
            Text(isRevealed ? "🙈" : "👁️")
              .font(.system(size: 18))
          }
          .buttonStyle(.ghibliPress)
          .accessibilityLabel(isRevealed ? "Ẩn mật khẩu" : "Hiện mật khẩu")
        }
      }
      .ghibliInputContainer(isFocused: isFocused)
    }
  }
}

#Preview {
  @Previewable @State var password = ""
  @Previewable @State var isRevealed = false
  GhibliSecureField(
    label: "Mật khẩu",
    text: $password,
    isRevealed: isRevealed,
    onToggleReveal: { isRevealed.toggle() }
  )
  .padding()
}
