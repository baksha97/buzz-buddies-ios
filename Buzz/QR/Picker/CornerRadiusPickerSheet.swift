//
//  CornerRadiusPickerSheet.swift
//  Buzz
//
//  Created by Travis Baksh on 12/27/24.
//


import SwiftUI
import QRCode

struct CornerRadiusPickerSheet: View {
  @Environment(\.dismiss) private var dismiss
  @State var model: QRMenuModel
  
  // Define presets
  private let presets: [(name: String, value: CGFloat)] = [
    ("Subtle", 8),
    ("Medium", 20),
    ("Full Round", 40)
  ]
  
  var body: some View {
    NavigationView {
      HStack(spacing: 16) {
        ForEach(presets, id: \.name) { preset in
          Button(action: {
            model.qrPreviewCornerRadius = preset.value
            dismiss()
          }) {
            RoundedRectangle(cornerRadius: preset.value)
              .fill(model.qrBackgroundColor)
              .frame(width: 100, height: 100)
              .overlay(
                RoundedRectangle(cornerRadius: preset.value)
                  .stroke(model.qrForegroundColor, lineWidth: 2)
              )
          }
        }
      }
      .padding()
      .navigationTitle("Corner Radius")
      .navigationBarTitleDisplayMode(.inline)
      .toolbar {
        ToolbarItem(placement: .topBarTrailing) {
          Button("Done") {
            dismiss()
          }
        }
      }
    }
  }
}
