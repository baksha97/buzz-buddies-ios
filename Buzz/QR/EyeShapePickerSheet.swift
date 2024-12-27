//
//  EyeShapePickerSheet.swift
//  Buzz
//
//  Created by Travis Baksh on 12/26/24.
//


import SwiftUI
import QRCode

struct EyeShapePickerSheet: View {
  var model: QRMenuModel
  
  var body: some View {
    let shapes = EyeShapeData.allCases
    
    NavigationStack {
      ScrollView {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 100))], spacing: 16) {
          ForEach(shapes.indices, id: \..self) { index in
            Button {
              model.selectedEyeIndex = index
            } label: {
              PickerShapeCell(image: shapes[index].reference, isSelected: model.selectedEyeIndex == index)
            }
          }
        }
        .padding()
      }
    }
  }
}

// MARK: - Picker Shape Sheets

struct PickerShapeCell: View {
  let image: Image
  let isSelected: Bool
  
  var body: some View {
    image
      .resizable()
      .scaledToFit()
      .frame(width: 80, height: 80)
      .cornerRadius(8)
      .overlay(
        RoundedRectangle(cornerRadius: 8)
          .stroke(isSelected ? Color.blue : Color.clear, lineWidth: 2)
      )
  }
}

struct PixelShapePickerSheet: View {
  var model: QRMenuModel
  
  var body: some View {
    ScrollView {
      LazyVGrid(columns: [GridItem(.adaptive(minimum: 100))]) {
        ForEach(PixelShapeData.allCases.indices, id: \.self) { index in
          Button {
            model.selectedPixelIndex = index
          } label: {
            PickerShapeCell(image: PixelShapeData.allCases[index].reference,
                            isSelected: model.selectedPixelIndex == index)
          }
        }
      }
      .padding()
    }
  }
}
