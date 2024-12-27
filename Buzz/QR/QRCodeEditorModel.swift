import SwiftUI
import QRCode

// MARK: - Observable Model
@Observable
class QRMenuModel {
  
  var qrPreviewCornerRadius: CGFloat = 20
  
  var urlText: String = "https://example.com" {
    didSet { generateQRCode() }
  }
  
  var qrForegroundColor: Color {
    qrBackgroundColor.accessibleTextColor
  }
  
  var qrBackgroundColor: Color = .cyan {
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

// MARK: - Corner Radius Preset Sheet
struct CornerRadiusPresetSheet: View {
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


// MARK: - Main QR Code Customizer View
struct QRCodeEditorView: View {
  @State private var model = QRMenuModel()
  
  @State private var isShowingPixelSheet = false
  @State private var isShowingEyeSheet = false
  @State private var isShowingPupilSheet = false
  @State private var isShowingCornerRadiusSheet = false
  
  
  var buttonTextColor: Color {
    return model.qrBackgroundColor.accessibleTextColor
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
      model
        .viewBackgroundColor
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
              title: "Background Color",
              selectedColor: $model.qrBackgroundColor,
              textColor: buttonTextColor,
              backgroundColor: model.qrBackgroundColor // Add this parameter
            )
            
            ControlButton(
              title: "Pixel Shape",
              textColor: buttonTextColor,
              backgroundColor: model.qrBackgroundColor,
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
              backgroundColor: model.qrBackgroundColor,
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
              backgroundColor: model.qrBackgroundColor,
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
            
            ControlButton(
              title: "Corner Radius",
              textColor: buttonTextColor,
              backgroundColor: model.qrBackgroundColor,
              leading: {
                Image(systemName: "square.on.circle")
                  .font(.headline)
                  .foregroundColor(buttonTextColor)
              },
              trailing: {
                RoundedRectangle(cornerRadius: model.qrPreviewCornerRadius / 2)
                  .stroke(buttonTextColor, lineWidth: 2)
              }
            ) {
              isShowingCornerRadiusSheet = true
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
    .sheet(isPresented: $isShowingCornerRadiusSheet) {
      CornerRadiusPresetSheet(model: model)
        .presentationDetents([.height(250)])
    }
  }
}

// MARK: - Inline Custom Color Picker Button
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
      .background(
        RoundedRectangle(cornerRadius: 12)
          .fill(backgroundColor.opacity(0.5))
      )
    }
  }
}


// MARK: - Preview
#Preview {
  QRCodeEditorView()
}
