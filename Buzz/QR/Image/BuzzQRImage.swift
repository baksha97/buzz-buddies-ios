import SwiftUINavigation
import SwiftUI
import QRCode
import CasePaths

struct BuzzQRImage: View {
  let configuration: BuzzQRImageConfiguration
  
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
  
  func build(with configuration: BuzzQRImageConfiguration) -> Result<UIImage, Error> {
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

fileprivate struct ErrorMessageView: View {
  let error: Error
  var body: some View {
    VStack {
      Text("Something has went wrong!")
      Text(error.localizedDescription)
    }
  }
}

#Preview {
  BuzzQRImage(configuration: .init())
}
