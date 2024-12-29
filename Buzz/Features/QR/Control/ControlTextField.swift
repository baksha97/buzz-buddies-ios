//
//  ControlTextField.swift
//  Buzz
//
//  Created by Travis Baksh on 12/28/24.
//


import SwiftUINavigation
import SwiftUI
import QRCode
import CasePaths

struct ControlTextField: View {
  let placeholder: String
  let textColor: Color
  let backgroundColor: Color
  @Binding var text: String
  
  var body: some View {
    HStack {
      // Leading icon
      Image(systemName: "link")
        .font(.headline)
        .foregroundColor(textColor)
      
      // TextField
      TextField(placeholder, text: $text)
        .font(.headline)
        .foregroundColor(textColor)
      
      // Trailing icon/clear button
      if !text.isEmpty {
        Button(action: { text = "" }) {
          Image(systemName: "xmark.circle.fill")
            .foregroundColor(textColor)
        }
        .frame(width: 30, height: 30)
        .background(
          RoundedRectangle(cornerRadius: 8)
            .fill(backgroundColor)
        )
      }
    }
    .padding()
    .background(
      RoundedRectangle(cornerRadius: 12)
        .fill(backgroundColor.opacity(0.5))
    )
    
  }
}