import SwiftUI
import Dependencies

struct ContactsView: View {
  @Environment(\.theme) private var theme
  @State private var errorMessage: String? = nil
  @State private var contacts: [Contact] = []
  @State private var isShowingAddContact = false
  
  
  @Dependency(\.contactsClient.fetchContacts)
  private var fetchContacts
  
  var body: some View {
    NavigationView {
      ScrollView {
        VStack(spacing: theme.spacing.md) {
          if let error = errorMessage {
            errorView(message: error)
          } else {
            contactsList
          }
        }
        .padding(theme.spacing.md)
      }
      .background(theme.colors.background)
      .navigationBarTitleDisplayMode(.large)
      .navigationTitle("Contacts")
      .toolbar {
        ToolbarItem(placement: .navigationBarTrailing) {
          BuzzUI.Button("Add", style: .tertiary) {
            isShowingAddContact = true
          }
        }
      }
      .sheet(isPresented: $isShowingAddContact) {
        AddContactModal()
      }
      .task {
        do {
          contacts = try await fetchContacts()
        }
        catch {
          errorMessage = error.localizedDescription
        }
      }
    }
  }
  
  private var contactsList: some View {
    BuzzUI.Card {
      VStack(spacing: theme.spacing.sm) {
        ForEach(contacts) { contact in
          ContactRow(contact: contact)
          
          if contact.id != contacts.last?.id {
            Divider()
              .background(theme.colors.divider)
          }
        }
      }
    }
  }
  
  private func errorView(message: String) -> some View {
    BuzzUI.Card(style: .filled) {
      VStack(spacing: theme.spacing.md) {
        Image(systemName: "exclamationmark.triangle")
          .font(.largeTitle)
          .foregroundColor(theme.colors.error)
        
        BuzzUI.Text(message, style: .bodyLarge)
      }
      .frame(maxWidth: .infinity)
    }
  }
}

struct ContactRow: View {
  @Environment(\.theme) private var theme
  let contact: Contact
  
  var body: some View {
    BuzzUI.ListItem(
      title: contact.fullName,
      subtitle: contact.phoneNumbers.first,
      leading: { contactAvatar },
      trailing: {
        Text(contact.id.uuidString)
        Spacer()
        Image(systemName: "chevron.right")
          .foregroundColor(theme.colors.textTertiary)
      }
    )
  }
  
  @ViewBuilder
  private var contactAvatar: some View {
    if let data = contact.avatarData,
       let uiImage = UIImage(data: data) {
      Image(uiImage: uiImage)
        .resizable()
        .scaledToFill()
        .frame(width: 40, height: 40)
        .clipShape(Circle())
    } else {
      Image(systemName: "person.circle.fill")
        .resizable()
        .frame(width: 40, height: 40)
        .foregroundColor(theme.colors.textTertiary)
    }
  }
}
#Preview("Contacts - Light") {
  ContactsView()
    .withTheme(AppTheme.light)
}

#Preview("Contacts - Dark") {
  ContactsView()
    .withTheme(AppTheme.dark)
    .preferredColorScheme(.dark)
}
