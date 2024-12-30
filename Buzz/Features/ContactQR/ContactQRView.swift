import SwiftUI
import Sharing

struct ContactQRView: View {
  let contact: Contact
  
  @Shared(.activeQrConfiguration)
  private var configuration
  
  // MARK: - URL-Encoded Query Parameters
  private var text: String {
    var components = URLComponents()
    components.scheme = "buzzapp"
    components.host = "referral"
    
    // Add query parameters safely
    components.queryItems = [
      URLQueryItem(name: "id", value: contact.id),
      URLQueryItem(name: "gn", value: contact.givenName),
      URLQueryItem(name: "fn", value: contact.familyName),
      URLQueryItem(
        name: "pns",
        value: contact.phoneNumbers.joined(separator: ",")
      )
    ]
    
    return components.url?.absoluteString ?? ""
  }
  
  private var contactQrConfiguration: BuzzQRImageConfiguration {
    var temp = configuration
    temp.text = text
    return temp
  }
  
  var body: some View {
    BuzzQRImage(configuration: contactQrConfiguration)
  }
}

#Preview {
  VStack {
    ContactQRView(contact: .mock)
  }
}
