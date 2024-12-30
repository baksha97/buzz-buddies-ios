import Sharing
import Dependencies
import SwiftUI

struct ContactAvatarNameAndPhoneView: View {
  let contact: Contact
  
  @Shared(.activeQrConfiguration)
  var configuration
  
  var body: some View {
    HStack(spacing: 12) {
      ContactAvatarView(contact: contact)
        .frame(width: 60, height: 60)
      
      VStack(alignment: .leading, spacing: 6) {
        Text(contact.fullName)
          .foregroundColor(configuration.foregroundColor)
          .font(.title2) // Larger font for name
          .fontWeight(.bold)
        
        if let phoneNumber = contact.phoneNumbers.first {
          HStack(spacing: 8) {
            Image(systemName: "phone.fill")
              .foregroundColor(configuration.foregroundColor)
            Text(phoneNumber)
              .foregroundColor(configuration.foregroundColor)
          }
          .font(.subheadline)
        }
      }
      Spacer()
    }
    .padding()
    .background(
      RoundedRectangle(cornerRadius: 12)
        .fill(configuration.backgroundColor)
    )
    .padding(.top, 24)
  }
}

#Preview("ContactAvatarNameAndPhoneView") {
  ContactAvatarNameAndPhoneView(contact: Contact.mock)
}
