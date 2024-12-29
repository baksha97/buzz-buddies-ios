import CasePaths
import Dependencies
import SwiftUI

struct ContactPickerView: View {

  @CasePathable
  enum Destination {
    case addContact
  }
  
  let selectedContact: Contact.ContactListIdentifier?
  let exclusions: [Contact.ContactListIdentifier]
  let onSelect: (Contact?) -> Void
  
  
  @State
  var contacts: [Contact] = []
  
  
  @Environment(\.dismiss) private var dismiss
  @Dependency(\.contactsClient.fetchContacts)
  private var fetchContacts
  @State private var searchText = ""
  
  
  @State private var sheet: Destination? = nil
  
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
          Button("Add new contact") {
            sheet = .addContact
          }
        }
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
      .sheet(isPresented: Binding($sheet)) {
        AddContactView {
          refreshContactList()
        }
      }
      .searchable(text: $searchText, prompt: "Search contacts")
      .navigationTitle("Select Contact")
      .navigationBarItems(trailing: Button("Cancel") { dismiss() })
      .onAppear(perform: refreshContactList)
    }
  }
  
  func refreshContactList() {
    Task {
      do {
        contacts = try await fetchContacts()
        print(contacts)
      } catch {
        print(error)
      }
    }
  }
}

#Preview {
  ContactPickerView(selectedContact: "1", exclusions: []) {
    print($0)
  }
}
