// Instructions: ONLY CHANGE ITEMS IN THIS FILE. PROVIDE THIS FULL FILE WITH REFACTORED CODE AS NEEDED. ONLY PROVIDE THESE MODELS OR ADDITIONAL CREATED MODELS. I SHOULD BE ABLE TO PASTE OVER THIS FILE TO HAVE IT COMPILE TO VIEW YOUR CHANGES

import SwiftUI
import Observation
import Dependencies
import CasePaths
import SwiftUINavigation
import Sharing

// MARK: - Main Contact Details View

struct ContactDetailsView: View {
  @State private var viewModel: ContactDetailsViewModel
  @Environment(\.dismiss) private var dismiss
  
  @Shared(.activeQrConfiguration)
  var configuration
  
  init(contactId: Contact.ContactListIdentifier) {
    _viewModel = State(initialValue: ContactDetailsViewModel(contactId: contactId))
  }
  
  var body: some View {
    // No navigation bar or toolbar; user swipes down to dismiss.
    content
      .background(
        configuration.backgroundColor.opacity(0.2))
      .task {
        await viewModel.initialize()
      }
  }
  
  @ViewBuilder
  private var content: some View {
    switch viewModel.viewState {
    case .loading:
      ProgressView()
        .tint(configuration.foregroundColor)
      
    case .error(let message):
      Text(message)
        .foregroundColor(configuration.foregroundColor)
      
    case .loaded(let contact):
      ZStack {
        ScrollView {
          VStack(alignment: .leading, spacing: 12) {
            
            // MARK: - Avatar, Name + Phone
            AvatarNameAndPhoneView(contact: contact.contact)
            
            // MARK: - Referred By
            ReferredByView(contact: contact, onEditReferrer: {
              viewModel.contactPickerDestination = .referrer
            })
            
            // MARK: - Referred Contacts
            ReferredContactsView(
              referredContacts: contact.referredContacts,
              onAddReferral: {
                viewModel.contactPickerDestination = .refer
              },
              onRemoveReferral: { contactToRemove in
                viewModel.requestRemoveReferral(for: contactToRemove)
              }
            )
            
            // MARK: - QR Code
            ContactQRView(contact: contact.contact)
              .frame(maxWidth: .infinity, alignment: .center)
              .padding(.top, 8)
            
          }
          .padding(.horizontal)
          .padding(.top, 12)
          .padding(.bottom, 24)
        }
        
        if viewModel.isLoading {
          ProgressView()
            .tint(configuration.foregroundColor)
        }
      }
      .sheet(isPresented: Binding($viewModel.contactPickerDestination.referrer)) {
        ContactPickerView(
          selectedContact: contact.referredBy?.id,
          exclusions: viewModel.referrerIdExclusions
        ) { selected in
          viewModel.updateReferrer(selected)
        }
      }
      .sheet(isPresented: Binding($viewModel.contactPickerDestination.refer)) {
        ContactPickerView(
          selectedContact: nil,
          exclusions: viewModel.referrerIdExclusions
        ) { selected in
          if let selected {
            viewModel.referContact(selected.id)
          }
        }
      }
      .confirmationDialog(
        item: $viewModel.referralToRemove,
        titleVisibility: .hidden,
        title: { Text("Removing \($0.fullName)") },
        actions: { contactToRemove in
          Button("Remove \(contactToRemove.fullName)", role: .destructive) {
            viewModel.confirmRemoveReferral(for: contactToRemove.id)
          }
          Button("Cancel", role: .cancel) {
            viewModel.referralToRemove = nil
          }
        },
        message: { contactToRemove in
          Text("Are you sure you want to remove the referral for \(contactToRemove.fullName)?")
        }
      )
      .alert("Error", isPresented: Binding(
        get: { viewModel.errorMessage != nil },
        set: { if !$0 { viewModel.errorMessage = nil } }
      )) {
        Button("OK") { viewModel.errorMessage = nil }
      } message: {
        if let errorMessage = viewModel.errorMessage {
          Text(errorMessage)
        }
      }
    }
  }
}

// MARK: - Subviews

struct AvatarNameAndPhoneView: View {
  let contact: Contact
  
  @Shared(.activeQrConfiguration)
  var configuration
  
  var body: some View {
    HStack(spacing: 12) {
      ContactDetailsAvatarView(contact: contact)
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

fileprivate struct ContactDetailsAvatarView: View {
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

struct ReferredByView: View {
  let contact: ContactReferralModel
  
  @Shared(.activeQrConfiguration)
  var configuration
  
  let onEditReferrer: () -> Void
  
  init(contact: ContactReferralModel, onEditReferrer: @escaping () -> Void) {
    self.contact = contact
    self.onEditReferrer = onEditReferrer
  }
  
  var body: some View {
    VStack(alignment: .leading, spacing: 0) {
      HStack(spacing: 8) {
        Image(systemName: "person.fill.badge.plus")
          .foregroundColor(configuration.foregroundColor)
        Text("Referred By")
          .foregroundColor(configuration.foregroundColor)
          .fontWeight(.bold)
        Spacer()
        
        // The referredBy contact name after the bold text
        Text(contact.referredBy?.fullName ?? "None")
          .foregroundColor(configuration.foregroundColor)
        Button(action: onEditReferrer) {
          Image(systemName: "pencil")
            .foregroundColor(configuration.foregroundColor)
        }
      }
    }
    .padding()
    .background(
      RoundedRectangle(cornerRadius: 12)
        .fill(configuration.backgroundColor)
    )
  }
}

struct ReferredContactsView: View {
  let referredContacts: [Contact]
  
  @Shared(.activeQrConfiguration)
  var configuration
  
  let onAddReferral: () -> Void
  let onRemoveReferral: (Contact) -> Void
  
  init(referredContacts: [Contact], onAddReferral: @escaping () -> Void, onRemoveReferral: @escaping (Contact) -> Void) {
    self.referredContacts = referredContacts
    self.onAddReferral = onAddReferral
    self.onRemoveReferral = onRemoveReferral
  }
  
  var body: some View {
    VStack(alignment: .leading, spacing: 12) {
      
      // Header row with label
      HStack(alignment: .bottom) {
        Image(systemName: "arrowshape.turn.up.right.circle")
          .foregroundColor(configuration.foregroundColor)
        Text("Referred Contacts")
          .foregroundColor(configuration.foregroundColor)
          .fontWeight(.bold)
        Spacer()
      }
      
      // The number of referrals
      let count = referredContacts.count
      if count > 0 {
        HStack(spacing: 6) {
          Image(systemName: "person.2.fill")
            .foregroundColor(configuration.foregroundColor)
            .font(.subheadline)
          Text("\(count) referral(s).")
            .foregroundColor(configuration.foregroundColor)
            .font(.subheadline)
        }
      } else {
        HStack(spacing: 6) {
          Image(systemName: "person.2.fill")
            .foregroundColor(configuration.foregroundColor)
            .font(.subheadline)
          Text("No referrals yet.")
            .foregroundColor(configuration.foregroundColor)
            .font(.subheadline)
        }
      }
      
      // The actual list of referred contacts
      if !referredContacts.isEmpty {
        VStack(spacing: 0) {
          ForEach(referredContacts, id: \.id) { referredContact in
            VStack {
              ReferredContactView(contact: referredContact, onRemove: {
                onRemoveReferral(referredContact)
              })
              
              // Divider after each contact except the last
              if referredContact.id != referredContacts.last?.id {
                Divider()
                  .overlay(configuration.foregroundColor.opacity(0.3))
              }
            }
          }
        }
      }
      
      // The plus button to refer new contacts
      Button {
        onAddReferral()
      } label: {
        Image(systemName: "plus.circle.fill")
          .foregroundColor(configuration.foregroundColor)
          .font(.title2)
      }
      .frame(maxWidth: .infinity, alignment: .center)
      
    }
    .padding()
    .background(
      RoundedRectangle(cornerRadius: 12)
        .fill(configuration.backgroundColor)
    )
  }
}

struct ReferredContactView: View {
  let contact: Contact
  
  @Shared(.activeQrConfiguration)
  var configuration
  
  let onRemove: () -> Void
  
  init(contact: Contact, onRemove: @escaping () -> Void) {
    self.contact = contact
    self.onRemove = onRemove
  }
  
  var body: some View {
    HStack {
      ContactDetailsAvatarView(contact: contact)
        .frame(width: 32, height: 32)
      
      Text(contact.fullName)
        .foregroundColor(configuration.foregroundColor)
        .bold()
      
      Spacer()
      // Remove referral button
      Button {
        onRemove()
      } label: {
        Image(systemName: "xmark.circle.fill")
          .foregroundColor(configuration.foregroundColor)
      }
      .padding(.vertical, 8)
    }
  }
}

// MARK: - SwiftUI Preview

struct ContactDetailsView_Previews: PreviewProvider {
  static var previews: some View {
    ContactDetailsView(contactId: Contact.mock.id)
  }
}

struct NameAndPhoneView_Previews: PreviewProvider {
  static var previews: some View {
    AvatarNameAndPhoneView(contact: Contact.mock)
      .padding()
  }
}

struct ReferredByView_Previews: PreviewProvider {
  static var previews: some View {
    ReferredByView(
      contact: ContactReferralModel.mock,
      onEditReferrer: { /* Mock action */ }
    )
  }
}

struct ReferredContactsView_Previews: PreviewProvider {
  static var previews: some View {
    ReferredContactsView(
      referredContacts: [Contact.mock],
      onAddReferral: { /* Mock add referral */ },
      onRemoveReferral: { _ in /* Mock remove referral */ }
    )
  }
}

struct ReferredContactView_Previews: PreviewProvider {
  static var previews: some View {
    ReferredContactView(
      contact: Contact.mock,
      onRemove: { /* Mock remove action */ }
    )
  }
}

#Preview("ContactDetailsAvatarView with image") {
  // AvatarView with Image
  let contactWithImage = Contact(
    id: UUID().uuidString,
    givenName: "John",
    familyName: "Doe",
    phoneNumbers: ["123-456-7890"],
    avatarData: UIImage(systemName: "person.fill")?.pngData()
  )
  ContactDetailsAvatarView(contact: contactWithImage)
}

#Preview("ContactDetailsAvatarView contactWithInitials") {
  // AvatarView with Initials
  let contactWithInitials = Contact(
    id: UUID().uuidString,
    givenName: "John",
    familyName: "Doe",
    phoneNumbers: ["123-456-7890"]
  )
  ContactDetailsAvatarView(contact: contactWithInitials)
    .padding()
}

#Preview("ContactDetailsAvatarView withoutInitials") {
  // ContactDetailsAvatarView with Default Icon
  let contactWithoutAvatar = Contact(
    id: UUID().uuidString,
    givenName: "",
    familyName: "",
    phoneNumbers: ["123-456-7890"]
  )
  ContactDetailsAvatarView(contact: contactWithoutAvatar)
}
