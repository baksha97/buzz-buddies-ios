import SwiftUI
import QRCode

// MARK: - Observable Model
@Observable
class QRMenuModel {
  
  var qrPreviewCornerRadius: CGFloat = 20
  
  var urlText: String = "https://example.com" {
    didSet { generateQRCode() }
  }
  
  var foregroundColor: Color = .cyan {
    didSet {
      generateQRCode()
    }
  }
  
  var backgroundColor: Color {
    foregroundColor.opacity(0.4)
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

// MARK: - Uniform Corner Radius Control
struct CornerRadiusControl: View {
  @Binding var cornerRadius: CGFloat
  var textColor: Color
  
  var body: some View {
    ZStack {
      // Background Rectangle (Matching Button Style)
      RoundedRectangle(cornerRadius: 12)
        .fill(Color.white.opacity(0.2))
        .frame(height: 50) // Ensuring same height as other controls
      
      // Full-Width Slider
      GeometryReader { geometry in
        ZStack(alignment: .leading) {
          // Filled Track
          RoundedRectangle(cornerRadius: 8)
            .fill(textColor.opacity(0.5))
            .frame(
              width: CGFloat(cornerRadius / 50) * geometry.size.width,
              height: geometry.size.height - 8
            )
            .padding(.horizontal, 4)
          
          // Static Label
          Text("Corner Radius")
            .font(.headline)
            .foregroundColor(textColor)
            .padding(.leading, 12)
            .frame(height: 50, alignment: .leading)
        }
        .gesture(
          DragGesture()
            .onChanged { value in
              let progress = min(max(0, value.location.x / geometry.size.width), 1)
              cornerRadius = progress * 50
            }
        )
      }
    }
    .frame(height: 50) // Standard height
    .frame(maxWidth: .infinity) // Match button width
    .padding(.horizontal)
  }
}






// MARK: - Main QR Code Customizer View
struct QRCodeEditorView: View {
  @State private var model = QRMenuModel()
  
  @State private var isShowingPixelSheet = false
  @State private var isShowingEyeSheet = false
  @State private var isShowingPupilSheet = false
  
  var buttonTextColor: Color {
    return model.backgroundColor.accessibleTextColor
  }
  
  var selectedPixelShapeView: Image {
    PixelShapeData.allCases[model.selectedPixelIndex].reference
    }
    
    var selectedEyeShapeView: Image {
      EyeShapeData.allCases[model.selectedEyeIndex].reference
    }
    
    var selectedPupilShapeView: Image {
      PupilShapeData.allCases[model.selectedPupilIndex].reference
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
            .cornerRadius(model.qrPreviewCornerRadius)
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
            
            ControlButton(
              title: "Pixel Shape",
              textColor: buttonTextColor,
              backgroundColor: model.backgroundColor,
              leading: {
                Image(systemName: "circle.grid.2x2")
                  .font(.headline)
                  .foregroundColor(buttonTextColor)
              },
              trailing: {
                selectedPixelShapeView
                  .resizable()
                  .scaledToFit()
              }
            ) {
              isShowingPixelSheet = true
            }

            ControlButton(
              title: "Eye Shape",
              textColor: buttonTextColor,
              backgroundColor: model.backgroundColor,
              leading: {
                Image(systemName: "eye.circle")
                  .font(.headline)
                  .foregroundColor(buttonTextColor)
              },
              trailing: {
                selectedEyeShapeView
                  .resizable()
                  .scaledToFit()
              }) {
              isShowingEyeSheet = true
            }

            ControlButton(
              title: "Pupil Shape",
              textColor: buttonTextColor,
              backgroundColor: model.backgroundColor,
              leading: {
                Image(systemName: "eye.fill")
                  .font(.headline)
                  .foregroundColor(buttonTextColor)
              },
              trailing: {
                selectedPupilShapeView
                  .resizable()
                  .scaledToFit()
              }) {
              isShowingPupilSheet = true
            }

            CornerRadiusControl(cornerRadius: $model.qrPreviewCornerRadius, textColor: buttonTextColor)

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

struct ControlButton<Leading: View, Trailing: View>: View {
  let title: String
  var textColor: Color
  let backgroundColor: Color

  @ViewBuilder let leading: Leading
  @ViewBuilder let trailing: Trailing
  let action: () -> Void
  
  var body: some View {
    Button(action: action) {
      HStack {
        leading
        
        Text(title)
          .font(.headline)
          .foregroundColor(textColor)
        
        Spacer()
        
        trailing
          .frame(width: 30, height: 30) // Ensures uniform sizing for trailing content
          .background(
            RoundedRectangle(cornerRadius: 8)
              .fill(backgroundColor)
          )
      }
      .padding()
      .background(RoundedRectangle(cornerRadius: 12).fill(Color.white.opacity(0.2)))
    }
  }
}


// MARK: - Preview
#Preview {
  QRCodeEditorView()
}
