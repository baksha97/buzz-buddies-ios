import Dependencies
import SwiftUI

struct ContactPickerView: View {

  
  let selectedContact: Contact.ContactListIdentifier?
  let exclusions: [Contact.ContactListIdentifier]
  let onSelect: (Contact?) -> Void
  
  
  @State
  var contacts: [Contact] = []
  
  
  @Environment(\.dismiss) private var dismiss
  @Dependency(\.contactsClient.fetchContacts)
  private var fetchContacts
  @State private var searchText = ""
  
  private var filteredContacts: [Contact] {
    let filtered = contacts.filter { contact in
      if exclusions.contains(contact.id) {
        return false
      }
      if searchText.isEmpty {
        return true
      }
      return contact.fullName.localizedCaseInsensitiveContains(searchText)
    }
    return filtered
  }
  
  var body: some View {
    NavigationView {
      List {
        Section {
          Button("None") {
            onSelect(nil)
            dismiss()
          }
        }
        Section {
          ForEach(filteredContacts) { contact in
            Button {
              onSelect(contact)
              dismiss()
            } label: {
              HStack {
                VStack(alignment: .leading) {
                  Text(contact.fullName)
                    .foregroundColor(.primary)
                  if !contact.phoneNumbers.isEmpty {
                    Text(contact.phoneNumbers[0])
                      .font(.caption)
                      .foregroundColor(.secondary)
                  }
                }
                Spacer()
                if contact.id == selectedContact {
                  Image(systemName: "checkmark")
                    .foregroundColor(.accentColor)
                }
              }
            }
          }
        }
      }
      .searchable(text: $searchText, prompt: "Search contacts")
      .navigationTitle("Select Contact")
      .navigationBarItems(trailing: Button("Cancel") { dismiss() })
      .task {
        do {
          contacts = try await fetchContacts()
        } catch {
          print(error)
        }
      }
    }
  }
}
