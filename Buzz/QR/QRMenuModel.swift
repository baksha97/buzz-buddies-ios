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
  
  var qrPreviewCornerRadius: CornerRadiusPickerSheet.Preset = .medium {
    didSet { generateQRCode() }
  }
  
  var urlText: String = "" {
    didSet { generateQRCode() }
  }
  
  var qrForegroundColor: Color {
    qrBackgroundColor.accessibleTextColor
  }
  
  var qrBackgroundColor: Color = Color(red: 0.15, green: 0.75, blue: 0.72) {
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
    
    // Foreground color components
    let qrForegroundColorComponent = qrForegroundColor
    let fgColorCG = qrForegroundColorComponent.cgColor
    let fgColorDefault = CGColor(red: 0, green: 0, blue: 0, alpha: 1)
    let fgCGColor = fgColorCG ?? fgColorDefault

    print("Foreground Components:")
    print("Original Color: \(qrForegroundColorComponent)")
    print("CG Color: \(fgColorCG)")
//    print("Default Color: \(fgColorDefault)")
//    print("Final Color: \(fgCGColor)")

    // Background color components
    let qrBackgroundColorComponent = qrBackgroundColor
    let bgColorCG = qrBackgroundColorComponent.cgColor
    let bgColorDefault = CGColor(red: 1, green: 1, blue: 1, alpha: 1)
    let bgCGColor = bgColorCG ?? bgColorDefault

    print("Background Components:")
    print("Original Color: \(qrBackgroundColorComponent)")
    print("CG Color: \(bgColorCG)")
//    print("Default Color: \(bgColorDefault)")
//    print("Final Color: \(bgCGColor)")
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
        .background.cornerRadius(qrPreviewCornerRadius.rawValue)
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
