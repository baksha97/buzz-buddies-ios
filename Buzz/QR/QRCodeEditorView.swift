import SwiftUINavigation
import SwiftUI
import QRCode
import CasePaths

struct BuzzQRImage: View {
  let configuration: BuzzQRConfiguration
  @State
  private var error: Error?
  
  var body: some View {
    Group {
      switch build(with: configuration) {
      case .success(let image):
        Image(uiImage: image)
          .resizable()
          .interpolation(.none)
          .scaledToFit()
          .frame(width: 250, height: 250)
      case .failure(let error):
        ErrorMessageView(error: error)
      }
    }
  }
  
  func build(with configuration: BuzzQRConfiguration) -> Result<UIImage, Error> {
    Result {
      let data = try QRCode.build
        .text(configuration.text)
        .quietZonePixelCount(4)
        .foregroundColor(configuration.foregroundColor.cgColor ?? CGColor(red: 0, green: 0, blue: 100, alpha: 0))
        .backgroundColor(configuration.backgroundColor.cgColor ?? CGColor(red: 1, green: 1, blue: 1, alpha: 1))
        .onPixels.shape(configuration.pixel.generator)
        .eye.shape(configuration.eye.generator)
        .pupil.shape(configuration.pupil.generator)
        .background.cornerRadius(configuration.cornerRadius.rawValue)
        .generate
        .image(dimension: configuration.dimension, representation: .png())
      guard let image = UIImage(data: data) else {
        throw Failure.unableToConvertImage
      }
      return image
    }
  }
  
  enum Failure: Error {
    case unableToConvertImage
  }
}

struct ErrorMessageView: View {
  let error: Error
  var body: some View {
    VStack {
      Text("Something has went wrong!")
      Text(error.localizedDescription)
    }
  }
}

@Observable
class QRMenuModel {
  var configuration: BuzzQRConfiguration = BuzzQRConfiguration()
  var picker: PickerSheet? = nil
  @CasePathable
  enum PickerSheet {
    case pixel
    case eye
    case pupil
    case cornerRadius
  }
}


// MARK: - Main QR Code Customizer View
struct QRCodeEditorView: View {
  @State private var model = QRMenuModel()
  
  var body: some View {
    ZStack {
      model
        .configuration
        .backgroundColor
        .opacity(0.2)
        .edgesIgnoringSafeArea(.all)
      
      VStack {
        Spacer()
        
        BuzzQRImage(configuration: model.configuration)
        
        
        Spacer()
        
        // Controls
        ScrollView {
          VStack(spacing: 12) {
            ControlTextField(
              placeholder: "URL",
              textColor: model.configuration.foregroundColor,
              backgroundColor: model.configuration.backgroundColor,
              text: $model.configuration.text
            )
            
            ControlButton(
              title: "Corner Radius",
              textColor: model.configuration.foregroundColor,
              backgroundColor: model.configuration.backgroundColor,
              leading: {
                Image(systemName: "square.on.circle")
                  .font(.headline)
                  .foregroundColor(model.configuration.foregroundColor)
              },
              trailing: EmptyView.init
            ) {
              model.picker = .cornerRadius
            }
            
            InlineCustomColorPickerButton(
              title: "Background Color",
              selectedColor: $model.configuration.backgroundColor,
              textColor: model.configuration.foregroundColor,
              backgroundColor: model.configuration.backgroundColor // Add this parameter
            )
            
            ControlButton(
              title: "Pixel Shape",
              textColor: model.configuration.foregroundColor,
              backgroundColor: model.configuration.backgroundColor,
              leading: {
                Image(systemName: "circle.grid.2x2")
                  .font(.headline)
                  .foregroundColor(model.configuration.foregroundColor)
              },
              trailing: {
                model
                  .configuration
                  .pixel
                  .reference
                  .resizable()
                  .scaledToFit()
              }
            ) {
              model.picker = .pixel
            }
            
            ControlButton(
              title: "Eye Shape",
              textColor: model.configuration.foregroundColor,
              backgroundColor: model.configuration.backgroundColor,
              leading: {
                Image(systemName: "eye.circle")
                  .font(.headline)
                  .foregroundColor(model.configuration.foregroundColor)
              },
              trailing: {
                model
                  .configuration
                  .eye
                  .reference
                  .resizable()
                  .scaledToFit()
              }) {
                model.picker = .eye
              }
            
            ControlButton(
              title: "Pupil Shape",
              textColor: model.configuration.foregroundColor,
              backgroundColor: model.configuration.backgroundColor,
              leading: {
                Image(systemName: "eye.fill")
                  .font(.headline)
                  .foregroundColor(model.configuration.foregroundColor)
              },
              trailing: {
                model
                  .configuration
                  .pupil
                  .reference
                  .resizable()
                  .scaledToFit()
              }) {
                model.picker = .pupil
              }
            
            Divider()
            ControlButton(
              title: "Shuffle",
              textColor: model.configuration.foregroundColor,
              backgroundColor: model.configuration.backgroundColor,
              leading: {
                Image(systemName: "shuffle")
                  .font(.headline)
                  .foregroundColor(model.configuration.foregroundColor)
              },
              trailing: EmptyView.init
            ) {
              model.configuration = .random(from: model.configuration)
              }
          }
          }
          .padding()
          

        
        Spacer()
          .frame(height: 48)
      }
    }
    .navigationBarTitleDisplayMode(.inline)
    .sheet(isPresented: Binding($model.picker.pixel)) {
      ImageReferencablePickerSheet(current: model.configuration.pixel) {
        model.configuration.pixel = $0
      }.presentationDetents([.medium, .fraction(0.4)])
    }
    .sheet(isPresented: Binding($model.picker.eye)) {
      ImageReferencablePickerSheet(current: model.configuration.eye) {
        model.configuration.eye = $0
      }.presentationDetents([.medium, .fraction(0.4)])
    }
    .sheet(isPresented: Binding($model.picker.pupil)) {
      ImageReferencablePickerSheet(current: model.configuration.pupil) {
        model.configuration.pupil = $0
      }.presentationDetents([.medium, .fraction(0.4)])
    }
    .sheet(isPresented: Binding($model.picker.cornerRadius)) {
      ImageReferencablePickerSheet2(
        current: model.configuration.cornerRadius,
        action: { model.configuration.cornerRadius = $0 },
        label: { item in
          let referenceConfiguration: BuzzQRConfiguration = {
            var temp = model.configuration
            temp.cornerRadius = item
            return temp
          }()
          BuzzQRImage(configuration: referenceConfiguration)
        }
      ).presentationDetents([.height(250)])
    }
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
