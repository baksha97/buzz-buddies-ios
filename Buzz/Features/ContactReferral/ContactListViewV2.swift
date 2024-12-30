import SwiftUI
import Dependencies
import Sharing

struct ContactListViewV2: View {
  @State private var viewModel = ContactListViewModel()
  
  @Shared(.activeQrConfiguration)
  var configuration
  
  var body: some View {
    ZStack {
      configuration.backgroundColor
        .opacity(0.2)
        .edgesIgnoringSafeArea(.all)
      
      VStack(spacing: 0) {
        searchBar
        List {
          contactsSection
        }
        .scrollContentBackground(.hidden)
      }
      floatingActionButton
    }
    .sheet(isPresented: Binding($viewModel.destination.addContact)) {
      AddContactView()
    }
    .sheet(item: $viewModel.destination.contactDetails) { contact in
      ContactDetailsView(contactId: contact.id)
        .presentationDragIndicator(.visible)
    }
    .alert("Error", isPresented: .init(
      get: { viewModel.errorMessage != nil },
      set: { if !$0 { viewModel.viewState = .loaded } }
    )) {
      Button("OK") { viewModel.viewState = .loaded }
    } message: {
      Text(viewModel.errorMessage ?? "")
    }
    .task {
      await viewModel.initialize()
    }
  }
  
  private var searchBar: some View {
    TextField("Search contacts", text: $viewModel.searchText)
      .padding(12)
      .background(configuration.backgroundColor.opacity(0.4))
      .cornerRadius(12)
      .shadow(radius: 2, y: 1)
      .padding([.horizontal, .top], 16)
      .foregroundColor(configuration.foregroundColor)
  }
  
  private var contactsSection: some View {
    Section {
      ForEach(viewModel.filteredContacts) { contact in
        ContactReferralRowV2(
          model: contact,
          onTap: {
            viewModel.showDetails(for: contact.id)
          },
          onTapReferredContactAvatar: { referredContact in
            viewModel.showDetails(for: referredContact.id)
          }
        )
        .background(configuration.backgroundColor)
        .cornerRadius(16)
        .shadow(radius: 2, y: 1)
        .padding(.vertical, 4)
      }
    }
    .listRowBackground(Color.clear)
  }
  
  private var floatingActionButton: some View {
    VStack {
      Spacer()
      HStack {
        Spacer()
        Button {
          viewModel.showAddContact()
        } label: {
          Image(systemName: "person.badge.plus")
            .font(.title2)
            .foregroundColor(configuration.foregroundColor)
            .padding(20)
            .background(configuration.backgroundColor)
            .clipShape(Circle())
            .shadow(radius: 4, y: 2)
        }
        .padding([.trailing, .bottom], 20)
      }
    }
  }
}

struct ContactReferralRowV2: View {
  @Shared(.activeQrConfiguration)
  var configuration
  
  let model: ContactReferralModel
  let onTap: () -> Void
  let onTapReferredContactAvatar: (Contact) -> Void
  
  var body: some View {
    VStack(alignment: .leading, spacing: 12) {
      contactInfoSection
      if let referredBy = model.referredBy {
        Divider()
        referredBySection(referredBy)
      }
      if !model.referredContacts.isEmpty {
        Divider()
        referralsSection(model.referredContacts)
      }
    }
    .padding(12)
    .background(configuration.backgroundColor)
    .cornerRadius(12)
    .shadow(radius: 2, y: 1)
    .onTapGesture(perform: onTap)
  }
}

// MARK: - Subviews
private extension ContactReferralRowV2 {
  // Contact Information Section
  var contactInfoSection: some View {
    HStack {
      avatar(for: model.contact)
      VStack(alignment: .leading) {
        Text(model.contact.fullName)
          .font(.headline)
          .foregroundColor(configuration.foregroundColor)
        if let phoneNumber = model.contact.phoneNumbers.first {
          Text(phoneNumber)
            .font(.caption)
            .foregroundColor(.secondary)
        }
      }
      Spacer()
    }
  }
  
  // Referred By Section (updated to show the same avatar as the referrals)
  func referredBySection(_ referredBy: Contact) -> some View {
    HStack {
      Image(systemName: "link.circle")
        .foregroundColor(configuration.foregroundColor)
      Button(action: {
        onTapReferredContactAvatar(referredBy)
      }) {
        HStack {
          Circle()
            .fill(Color.gray.opacity(0.3))
            .frame(width: 32, height: 32)
            .shadow(radius: 2)
            .overlay {
              switch (referredBy.avatarData.flatMap(UIImage.init), referredBy.initials) {
              case (let image?, _):
                Image(uiImage: image)
                  .resizable()
                  .clipShape(Circle())
                
              case (nil, let initials?):
                Text(initials)
                  .font(.headline)
                  .foregroundColor(configuration.backgroundColor.accessibleTextColor)
                  .bold()
                
              case (nil, nil):
                Image(systemName: "person.circle.fill")
              }
            }
          Text(referredBy.fullName)
            .font(.callout)
            .foregroundColor(configuration.foregroundColor)
            .bold()
        }
      }
    }
  }
  
  // Referrals Section
  func referralsSection(_ referredContacts: [Contact]) -> some View {
    HStack {
      Image(systemName: "link.badge.plus")
        .foregroundColor(configuration.foregroundColor)
      ScrollView(.horizontal, showsIndicators: false) {
        HStack(spacing: 8) {
          ForEach(referredContacts) { referred in
            referralContact(for: referred)
          }
        }
      }
    }
  }
  
  // Referral Avatar
  func referralContact(for contact: Contact) -> some View {
    Button(action: {
      onTapReferredContactAvatar(contact)
    }) {
      HStack {
        Circle()
          .fill(Color.gray.opacity(0.3))
          .frame(width: 32, height: 32)
          .shadow(radius: 2)
          .overlay {
            switch (contact.avatarData.flatMap(UIImage.init), contact.initials) {
            case (let image?, _):
              Image(uiImage: image)
                .resizable()
                .clipShape(Circle())
              
            case (nil, let initials?):
              Text(initials)
                .font(.headline)
                .foregroundColor(configuration.backgroundColor.accessibleTextColor)
                .bold()
              
            case (nil, nil):
              Image(systemName: "person.circle.fill")
            }
          }
        Text(contact.fullName)
          .bold()
          .font(.callout)
          .foregroundColor(configuration.backgroundColor.accessibleTextColor)
      }
    }
  }
}

extension ContactReferralRowV2 {
  // Avatar View
  func avatar(for contact: Contact) -> some View {
    Circle()
      .fill(Color.gray.opacity(0.3))
      .frame(width: 50, height: 50)
      .overlay {
        switch (contact.avatarData.flatMap(UIImage.init), contact.initials) {
        case (let image?, _):
          Image(uiImage: image)
            .resizable()
            .clipShape(Circle())
          
        case (nil, let initials?):
          Text(initials)
            .font(.headline)
            .foregroundColor(configuration.foregroundColor)
            .bold()
          
        case (nil, nil):
          Image(systemName: "person.circle.fill")
        }
      }
      .padding(4)
  }
}

extension Contact {
  var initials: String? {
    guard let first = givenName.first,
          let second = familyName.first else {
      return nil
    }
    return String(first) + String(second)
  }
}

// MARK: - Preview
#Preview {
  NavigationView {
    ContactListViewV2()
      .preferredColorScheme(.dark)
  }
}
#Preview("Contact Referral Scenarios") {
  let contact1 = Contact(id: "1", givenName: "John", familyName: "Doe", phoneNumbers: ["+1 (555) 123-4567"], avatarData: nil)
  let contact2 = Contact(id: "2", givenName: "Jane", familyName: "Smith", phoneNumbers: ["+1 (555) 987-6543"], avatarData: nil)
  let bothReferrals = ContactReferralModel(contact: contact2, referredBy: contact1, referredContacts: [contact1])
  
  List {
    ContactReferralRowV2(model: bothReferrals) {
      
    } onTapReferredContactAvatar: { id in
      
    }
  }
}

extension Contact.ContactListIdentifier: @retroactive Identifiable {
  public var id: Contact.ContactListIdentifier { self }
}
