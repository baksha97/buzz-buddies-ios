import SwiftUI
import Dependencies

struct ContactsView: View {
  // Access the ContactsClient via swift-dependencies
  @Dependency(\.contactsClient) var contactsClient

  @State private var contacts: [Contact] = []
  @State private var isAuthorized: Bool = false
  @State private var errorMessage: String?

  var body: some View {
    NavigationView {
      List {
        if let error = errorMessage {
          Text("Error: \(error)")
        } else {
          ForEach(contacts) { contact in
            ContactRow(contact: contact)
          }
        }
      }
      .navigationTitle("Contacts")
      .toolbar {
        ToolbarItem(placement: .navigationBarTrailing) {
          Button("Add") {
            Task {
              // Example: Add a new random contact
              do {
                let randomName = ["New", "Random", "Sample"].shuffled().first!
                let newContact = Contact(
                  givenName: randomName,
                  familyName: "User",
                  phoneNumbers: ["555-\(Int.random(in: 1000...9999))"]
                )
                try await contactsClient.addContact(newContact)
                // Refresh list
                contacts = try await contactsClient.fetchContacts()
              } catch {
                self.errorMessage = "Failed to add contact."
              }
            }
          }
        }
      }
      .task {
        // On appear, request authorization, then fetch contacts if granted
        let granted = await contactsClient.requestAuthorization()
        isAuthorized = granted
        if granted {
          do {
            contacts = try await contactsClient.fetchContacts()
          } catch {
            errorMessage = "Failed to fetch contacts."
          }
        } else {
          errorMessage = "Not authorized to read contacts."
        }
      }
    }
  }
}

struct ContactRow: View {
  let contact: Contact

  var body: some View {
    HStack {
      if let data = contact.avatarData,
         let uiImage = UIImage(data: data) {
        Image(uiImage: uiImage)
          .resizable()
          .scaledToFill()
          .frame(width: 40, height: 40)
          .clipShape(Circle())
      } else {
        Circle()
          .fill(Color.gray)
          .frame(width: 40, height: 40)
      }
      VStack(alignment: .leading) {
        Text(contact.fullName).font(.headline)
        if let number = contact.phoneNumbers.first {
          Text(number).foregroundColor(.secondary)
        }
      }
    }
  }
}

#Preview {
  ContactsView()
}
