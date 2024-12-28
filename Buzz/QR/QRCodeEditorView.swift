import SwiftUI
import QRCode

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
            ControlTextField(
              placeholder: "URL",
              textColor: buttonTextColor,
              backgroundColor: model.qrBackgroundColor,
              text: $model.urlText
            )
            
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
      // Floating Shuffle Button
            VStack {
              Spacer()
              HStack {
                Spacer()
                Button(action: shuffleQRCode) {
                  Image(systemName: "shuffle")
                    .font(.system(size: 24))
                    .foregroundColor(buttonTextColor)
                    .padding()
                    .background(model.qrBackgroundColor)
                    .clipShape(Circle())
                    .shadow(radius: 5)
                }
                .padding()
              }
            }
    }
    .navigationBarTitleDisplayMode(.inline)
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
      CornerRadiusPickerSheet(model: model)
        .presentationDetents([.height(250)])
    }
  }
  
  // MARK: - Shuffle Functionality
    private func shuffleQRCode() {
      model.qrBackgroundColor = Color(
        red: Double.random(in: 0...1),
        green: Double.random(in: 0...1),
        blue: Double.random(in: 0...1)
      )
      model.selectedPixelIndex = Int.random(in: 0..<PixelShapeData.allCases.count)
      model.selectedEyeIndex = Int.random(in: 0..<EyeShapeData.allCases.count)
      model.selectedPupilIndex = Int.random(in: 0..<PupilShapeData.allCases.count)
      model.qrPreviewCornerRadius = CGFloat.random(in: 0...50)
      model.generateQRCode()
    }
}

struct ControlTextField: View {
  let placeholder: String
  let textColor: Color
  let backgroundColor: Color
  @Binding var text: String
  
  var body: some View {
    HStack {
      // Leading icon
      Image(systemName: "link")
        .font(.headline)
        .foregroundColor(textColor)
      
      // TextField
      TextField(placeholder, text: $text)
      .font(.headline)
      .foregroundColor(textColor)
      
      // Trailing icon/clear button
      if !text.isEmpty {
        Button(action: { text = "" }) {
          Image(systemName: "xmark.circle.fill")
            .foregroundColor(textColor)
        }
        .frame(width: 30, height: 30)
        .background(
          RoundedRectangle(cornerRadius: 8)
            .fill(backgroundColor)
        )
      }
    }
    .padding()
    .background(
      RoundedRectangle(cornerRadius: 12)
        .fill(backgroundColor.opacity(0.5))
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
