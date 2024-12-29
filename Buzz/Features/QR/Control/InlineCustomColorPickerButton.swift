//
//  InlineCustomColorPickerButton.swift
//  Buzz
//
//  Created by Travis Baksh on 12/27/24.
//


import SwiftUI
import QRCode

struct InlineCustomColorPickerButton: View {
  var title: String
  @Binding var selectedColor: Color
  var textColor: Color
  var backgroundColor: Color // Add this property
  
  var body: some View {
    HStack {
      Image(systemName: "paintbrush.fill") // Add an icon to match other controls
        .font(.headline)
        .foregroundColor(textColor)
      
      Text(title)
        .font(.headline)
        .foregroundColor(textColor)
      
      Spacer()
      
      ZStack {
        Circle()
          .fill(selectedColor)
          .frame(width: 30, height: 30)
          .overlay(
            Circle()
              .stroke(textColor.opacity(0.5), lineWidth: 1)
          )
        ColorPicker("", selection: $selectedColor)
          .labelsHidden()
          .opacity(0.02)
          .frame(width: 30, height: 30)
          .allowsHitTesting(true)
      }
    }
    .padding()
    .background(
      RoundedRectangle(cornerRadius: 12)
        .fill(backgroundColor.opacity(0.5)) // Match ControlButton style
    )
  }
}