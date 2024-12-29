import SwiftUINavigation
import SwiftUI
import QRCode
import CasePaths
import Sharing

@Observable
class QRMenuModel {
  @ObservationIgnored
  @Shared(.activeQrConfiguration)
  var configuration = BuzzQRImageConfiguration()
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
              model
                .$configuration
                .withLock { $0 = .random(from: model.configuration) }
            }
            
            Divider()
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
          }
          Spacer()
            .frame(height: 48)
        }
        .padding()
        
        
        
      }
    }
    .ignoresSafeArea(edges: .bottom)
    .navigationBarTitleDisplayMode(.inline)
    .sheet(isPresented: Binding($model.picker.pixel)) {
      ViewReferenceablePickerSheet(current: model.configuration.pixel) { pixel in
          model
            .$configuration
            .withLock { $0.pixel = pixel }
      }.presentationDetents([.medium, .fraction(0.4)])
    }
    .sheet(isPresented: Binding($model.picker.eye)) {
      ViewReferenceablePickerSheet(current: model.configuration.eye) { eye in
        model
          .$configuration
          .withLock { $0.eye = eye }
      }.presentationDetents([.medium, .fraction(0.4)])
    }
    .sheet(isPresented: Binding($model.picker.pupil)) {
      ViewReferenceablePickerSheet(current: model.configuration.pupil) { pupil in
        model
          .$configuration
          .withLock { $0.pupil = pupil }
      }.presentationDetents([.medium, .fraction(0.4)])
    }
    .sheet(isPresented: Binding($model.picker.cornerRadius)) {
      ViewReferenceablePickerSheet(
        current: model.configuration.cornerRadius,
        action: { cornerRadius in
          model
            .$configuration
            .withLock { $0.cornerRadius = cornerRadius }
        },
        label: { item in
          let referenceConfiguration = {
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








// MARK: - Preview
#Preview {
  QRCodeEditorView()
}
