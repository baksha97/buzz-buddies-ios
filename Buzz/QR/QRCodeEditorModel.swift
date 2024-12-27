import SwiftUI
import QRCode

// MARK: - Observable Model
@Observable
class QRMenuModel {
  var urlText: String = "https://example.com" {
    didSet { generateQRCode() }
  }
  
  var foregroundColor: Color = .black {
    didSet {
      updateBackgroundColor()
      generateQRCode()
    }
  }
  
  var backgroundColor: Color = .white
  
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

  func updateBackgroundColor() {
    backgroundColor = foregroundColor.opacity(0.2)
  }

  func generateQRCode() {
    let fgCGColor = foregroundColor.cgColor ?? CGColor(red: 0, green: 0, blue: 0, alpha: 1)
    let bgCGColor = backgroundColor.cgColor ?? CGColor(red: 1, green: 1, blue: 1, alpha: 1)

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

      #if os(iOS) || os(tvOS)
      if let uiImg = UIImage(data: pngData) {
        qrImage = Image(uiImage: uiImg)
      }
      #elseif os(macOS)
      if let nsImg = NSImage(data: pngData) {
        qrImage = Image(nsImage: nsImg)
      }
      #endif
    } catch {
      print("Error generating QR code:", error)
      qrImage = nil
    }
  }
}

// MARK: - Main QR Code Customizer View
struct QRCodeCustomizerView: View {
  @State private var model = QRMenuModel()
  
  @State private var isShowingPixelSheet = false
  @State private var isShowingEyeSheet = false
  @State private var isShowingPupilSheet = false
  
  var buttonTextColor: Color {
    return model.backgroundColor.accessibleTextColor
  }
  
  var body: some View {
    ZStack {
      // Background Color (Implicit from Foreground)
      model.backgroundColor
        .edgesIgnoringSafeArea(.all)
      
      VStack {
        Spacer()
        
        // QR Code Display
        if let qrImage = model.qrImage {
          qrImage
            .resizable()
            .interpolation(.none)
            .scaledToFit()
            .frame(width: 250, height: 250)
            .background(RoundedRectangle(cornerRadius: 20)
              .fill(model.backgroundColor.opacity(0.3)))
        } else {
          ProgressView()
            .frame(width: 250, height: 250)
        }
        
        Spacer()
        
        // Controls
        ScrollView {
          VStack(spacing: 12) {
            InlineCustomColorPickerButton(
              title: "Foreground Color",
              selectedColor: $model.foregroundColor,
              textColor: buttonTextColor
            )
            
            ControlButton(title: "Pixel Shape", icon: "circle.grid.2x2", textColor: buttonTextColor) {
              isShowingPixelSheet = true
            }
            ControlButton(title: "Eye Shape", icon: "eye.circle", textColor: buttonTextColor) {
              isShowingEyeSheet = true
            }
            ControlButton(title: "Pupil Shape", icon: "eye.fill", textColor: buttonTextColor) {
              isShowingPupilSheet = true
            }
          }
          .padding()
        }
        
        Spacer()
      }
    }
    .onAppear {
      model.generateQRCode()
    }
    .sheet(isPresented: $isShowingPixelSheet) {
      PixelShapePickerSheet(model: model)
        .presentationDetents([.medium, .fraction(0.4)])
    }
    .sheet(isPresented: $isShowingEyeSheet) {
      EyeShapePickerSheet(model: model)
        .presentationDetents([.medium, .fraction(0.4)])
    }
    .sheet(isPresented: $isShowingPupilSheet) {
      PupilShapePickerSheet(model: model)
        .presentationDetents([.medium, .fraction(0.4)])
    }
  }
}

// MARK: - Inline Custom Color Picker Button
struct InlineCustomColorPickerButton: View {
  var title: String
  @Binding var selectedColor: Color
  var textColor: Color
  
  var body: some View {
    HStack {
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
    .background(RoundedRectangle(cornerRadius: 12).fill(Color.white.opacity(0.2)))
  }
}

// MARK: - Control Button
struct ControlButton: View {
  var title: String
  var icon: String
  var textColor: Color
  var action: () -> Void
  
  var body: some View {
    Button(action: action) {
      HStack {
        Text(title)
          .font(.headline)
          .foregroundColor(textColor)
        Spacer()
        Image(systemName: icon)
          .font(.headline)
          .foregroundColor(textColor)
      }
      .padding()
      .background(RoundedRectangle(cornerRadius: 12).fill(Color.white.opacity(0.2)))
    }
  }
}

// MARK: - Preview
#Preview {
  QRCodeCustomizerView()
}
