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
  
  enum Preset: Double, Identifiable, CaseIterable {
    case none = 0
    case subtle = 5
    case rounded = 12
//    case circle = 24
    
    var id: String {
      "\(rawValue)"
    }
  }
  
  var body: some View {
    ScrollView(.horizontal) {
      HStack(spacing: 16) {
        ForEach(Preset.allCases, id: \.id) { preset in
          Button(action: {
            model.qrPreviewCornerRadius = preset
            dismiss()
          }) {
            RoundedRectangle(cornerRadius: preset.rawValue)
              .fill(model.qrBackgroundColor)
              .frame(width: 100, height: 100)
              .overlay(
                RoundedRectangle(cornerRadius: preset.rawValue)
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
