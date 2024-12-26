//
//  ContactPickerView.swift
//  Buzz
//
//  Created by Travis Baksh on 12/26/24.
//


// ContactPickerView.swift
import SwiftUI

struct ContactPickerView: View {
    struct Configuration {
        let contacts: [ContactReferralModel]
        let selectedContactId: Contact.ContactListIdentifier?
        let excludeContactId: Contact.ContactListIdentifier?
        let onSelect: (Contact?) -> Void
        
        init(
            contacts: [ContactReferralModel],
            selectedContactId: Contact.ContactListIdentifier? = nil,
            excludeContactId: Contact.ContactListIdentifier? = nil,
            onSelect: @escaping (Contact?) -> Void
        ) {
            self.contacts = contacts
            self.selectedContactId = selectedContactId
            self.excludeContactId = excludeContactId
            self.onSelect = onSelect
        }
    }
    
    let config: Configuration
    
    @Environment(\.dismiss) private var dismiss
    @State private var searchText = ""
    
    private var filteredContacts: [ContactReferralModel] {
        let filtered = config.contacts.filter { contact in
            if contact.id == config.excludeContactId {
                return false
            }
            if searchText.isEmpty {
                return true
            }
            return contact.contact.fullName.localizedCaseInsensitiveContains(searchText)
        }
        return filtered
    }
    
    var body: some View {
        NavigationView {
            List {
                Section {
                    Button("None") {
                        config.onSelect(nil)
                        dismiss()
                    }
                }
                
                Section {
                    ForEach(filteredContacts) { contact in
                        Button {
                            config.onSelect(contact.contact)
                            dismiss()
                        } label: {
                            HStack {
                                VStack(alignment: .leading) {
                                    Text(contact.contact.fullName)
                                        .foregroundColor(.primary)
                                    if !contact.contact.phoneNumbers.isEmpty {
                                        Text(contact.contact.phoneNumbers[0])
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                }
                                Spacer()
                                if contact.id == config.selectedContactId {
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
        }
    }
}