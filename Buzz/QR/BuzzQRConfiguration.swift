//
//  QRMenuModel.swift
//  Buzz
//
//  Created by Travis Baksh on 12/27/24.
//


import SwiftUI
import QRCode

struct BuzzQRConfiguration {
  var text: String = ""
  var backgroundColor: Color = Color(red: 0.25, green: 0.88, blue: 0.82)
  var foregroundColor: Color {
    backgroundColor.accessibleTextColor
  }
  var pixel: PixelShapeData = .curvePixel
  var eye: EyeShapeData = .barsHorizontal
  var pupil: PupilShapeData = .blobby
  var cornerRadius: CornerShapeData = .subtle
  var dimension: Int = 400
}

extension BuzzQRConfiguration {
  static func random(from existing: Self = .init()) -> BuzzQRConfiguration {
    BuzzQRConfiguration(
      text: existing.text, // Using UUID as sample random text
      backgroundColor: Color(
        red: Double.random(in: 0...1),
        green: Double.random(in: 0...1),
        blue: Double.random(in: 0...1)
      ),
      pixel: PixelShapeData.allCases.randomElement() ?? .arrow,
      eye: EyeShapeData.allCases.randomElement() ?? .square,
      pupil: PupilShapeData.allCases.randomElement() ?? .blobby,
      cornerRadius: CornerShapeData.allCases.randomElement() ?? .subtle,
      dimension: Int.random(in: 200...800)
    )
  }
}
