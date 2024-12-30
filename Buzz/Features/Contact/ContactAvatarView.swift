//
//  ContactAvatarView.swift
//  Buzz
//
//  Created by Travis Baksh on 12/30/24.
//


import SwiftUI
import Observation
import Dependencies
import CasePaths
import SwiftUINavigation
import Sharing

struct ContactAvatarView: View {
  let contact: Contact
  
  @Shared(.activeQrConfiguration)
  var configuration
  
  var body: some View {
    ZStack {
      Circle()
        .fill(Color.gray.opacity(0.3))
        .shadow(radius: 2)
        .overlay {
          if let imageData = contact.avatarData, let uiImage = UIImage(data: imageData) {
            Image(uiImage: uiImage)
              .resizable()
              .scaledToFill()
              .clipShape(Circle())
          } else if let initials = contact.initials {
            Text(initials)
              .font(.headline)
              .foregroundColor(configuration.backgroundColor.accessibleTextColor)
              .bold()
          } else {
            Image(systemName: "person.circle.fill")
              .resizable()
              .scaledToFit()
              .foregroundColor(configuration.foregroundColor.opacity(0.6))
          }
        }
    }
  }
}

#Preview("ContactAvatarView with image") {
  // AvatarView with Image
  let contactWithImage = Contact(
    id: UUID().uuidString,
    givenName: "John",
    familyName: "Doe",
    phoneNumbers: ["123-456-7890"],
    avatarData: UIImage(systemName: "person.fill")?.pngData()
  )
  ContactAvatarView(contact: contactWithImage)
}

#Preview("ContactAvatarView contactWithInitials") {
  // AvatarView with Initials
  let contactWithInitials = Contact(
    id: UUID().uuidString,
    givenName: "John",
    familyName: "Doe",
    phoneNumbers: ["123-456-7890"]
  )
  ContactAvatarView(contact: contactWithInitials)
    .padding()
}

#Preview("ContactAvatarView withoutInitials") {
  // ContactAvatarView with Default Icon
  let contactWithoutAvatar = Contact(
    id: UUID().uuidString,
    givenName: "",
    familyName: "",
    phoneNumbers: ["123-456-7890"]
  )
  ContactAvatarView(contact: contactWithoutAvatar)
}
