//
//  GhibliTextField.swift
//  dailymate
//
//  Created by ManhLe on 11/16/26.
//

import SwiftUI

/// Ô nhập text thường (email, tên...) kèm nhãn.
struct GhibliTextField: View {
  let label: String
  let placeholder: String
  @Binding var text: String
  var isFocused = false
  var keyboardType: UIKeyboardType = .default
  var textContentType: UITextContentType?
  var submitLabel: SubmitLabel = .next

  var body: some View {
    VStack(alignment: .leading, spacing: 6) {
      GhibliFieldLabel(label)

      TextField(label, text: $text, prompt: ghibliPrompt(placeholder))
        .keyboardType(keyboardType)
        .textContentType(textContentType)
        .textInputAutocapitalization(.never)
        .autocorrectionDisabled()
        .submitLabel(submitLabel)
        .ghibliInputContainer(isFocused: isFocused)
    }
  }
}

#Preview {
  @Previewable @State var email = ""
  GhibliTextField(
    label: "Email",
    placeholder: "hello@example.com",
    text: $email,
    keyboardType: .emailAddress
  )
  .padding()
}
