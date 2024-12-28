//
//  QRMenuModel.swift
//  Buzz
//
//  Created by Travis Baksh on 12/27/24.
//


import SwiftUI
import QRCode

@Observable
class QRMenuModel {
  
  var qrPreviewCornerRadius: CGFloat = 20
  
  var urlText: String = "" {
    didSet { generateQRCode() }
  }
  
  var qrForegroundColor: Color {
    qrBackgroundColor.accessibleTextColor
  }
  
  var qrBackgroundColor: Color = .white {
    didSet { generateQRCode()  }
  }
  
  var viewBackgroundColor: Color {
    qrBackgroundColor.opacity(0.2)
  }
  
  var selectedPixelIndex: Int = 0 {
    didSet { generateQRCode() }
  }
  
  var selectedEyeIndex: Int = 0 {
    didSet { generateQRCode() }
  }
  
  var selectedPupilIndex: Int = 0 {
    didSet { generateQRCode() }
  }
  
  var qrImage: Image? = nil
  
  func generateQRCode() {
    let fgCGColor = qrForegroundColor.cgColor ?? CGColor(red: 0, green: 0, blue: 0, alpha: 1)
    let bgCGColor = qrBackgroundColor.cgColor ?? CGColor(red: 1, green: 1, blue: 1, alpha: 1)
    
    do {
      let pixelShape = PixelShapeData.allCases[selectedPixelIndex].makeShape()
      let eyeShape = EyeShapeData.allCases[selectedEyeIndex].makeShape()
      let pupilShape = PupilShapeData.allCases[selectedPupilIndex].makeShape()
      
      let pngData = try QRCode.build
        .text(urlText)
        .quietZonePixelCount(4)
        .foregroundColor(fgCGColor)
        .backgroundColor(bgCGColor)
        .onPixels.shape(pixelShape)
        .eye.shape(eyeShape)
        .pupil.shape(pupilShape)
        .generate
        .image(dimension: 400, representation: .png())
      if let uiImg = UIImage(data: pngData) {
        qrImage = Image(uiImage: uiImg)
      }
    } catch {
      print("Error generating QR code:", error)
      qrImage = nil
    }
  }
}
