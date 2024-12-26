import SwiftUI
import Dependencies

struct ContactReferralTestView: View {
    @Dependency(\.contactReferralClient) var client
    
    @State private var contacts: [ContactReferralModel] = []
    @State private var unreferredContacts: [ContactReferralModel] = []
    @State private var selectedContact: ContactReferralModel?
    @State private var isShowingReferralSheet = false
    @State private var isAuthorized = false
    @State private var errorMessage: String?
    @State private var isAddingContact = false
    @State private var isCreatingReferral = false
    
    var body: some View {
        NavigationView {
            List {
                Section("Authorization Status") {
                    HStack {
                        Text(isAuthorized ? "Authorized" : "Unauthorized")
                        Spacer()
                        Button("Request Authorization") {
                            Task {
                                isAuthorized = await client.requestContactsAuthorization()
                            }
                        }
                    }
                }
                
                Section("All Contacts") {
                    ForEach(contacts) { contact in
                        ContactReferralRow(model: contact)
                            .onTapGesture {
                                selectedContact = contact
                                isShowingReferralSheet = true
                            }
                    }
                    
                    Button("Refresh Contacts") {
                        Task {
                            await loadContacts()
                        }
                    }
                    
                    Button("Add Contact") {
                        isAddingContact = true
                    }
                }
                
                Section("Unreferred Contacts") {
                    ForEach(unreferredContacts) { contact in
                        ContactReferralRow(model: contact)
                    }
                    
                    Button("Load Unreferred") {
                        Task {
                            await loadUnreferredContacts()
                        }
                    }
                }
            }
            .navigationTitle("Contact Referral Tests")
            .sheet(isPresented: $isAddingContact) {
                AddContactView(isPresented: $isAddingContact, onAdd: { contact in
                    Task {
                        await addContact(contact)
                    }
                })
            }
            .sheet(isPresented: $isShowingReferralSheet, onDismiss: { selectedContact = nil }) {
                if let contact = selectedContact {
                CreateReferralView(
                    contact: contact,
                    availableReferrers: contacts,
                    onCreateReferral: { contact, referrer in
                        Task {
                            await createReferral(contact: contact, referredBy: referrer)
                        }
                    }
                )
                }
            }
            .alert("Error", isPresented: .init(
                get: { errorMessage != nil },
                set: { if !$0 { errorMessage = nil } }
            )) {
                Button("OK") { errorMessage = nil }
            } message: {
                Text(errorMessage ?? "")
            }
            .task {
                await loadContacts()
                await loadUnreferredContacts()
            }
        }
    }
    
    private func loadContacts() async {
        do {
            contacts = try await client.fetchContacts()
        } catch {
            errorMessage = "Failed to load contacts: \(error.localizedDescription)"
        }
    }
    
    private func loadUnreferredContacts() async {
        do {
            unreferredContacts = try await client.fetchUnreferredContacts()
        } catch {
            errorMessage = "Failed to load unreferred contacts: \(error.localizedDescription)"
        }
    }
    
    private func addContact(_ contact: Contact) async {
        do {
            try await client.addContact(contact)
            await loadContacts()
            await loadUnreferredContacts()
        } catch {
            errorMessage = "Failed to add contact: \(error.localizedDescription)"
        }
    }
    
    private func createReferral(contact: ContactReferralModel, referredBy: Contact?) async {
        do {
            try await client.createReferral(contact.contact, referredBy)
            await loadContacts()
            await loadUnreferredContacts()
        } catch {
            errorMessage = "Failed to create referral: \(error.localizedDescription)"
        }
    }
}

struct ContactReferralRow: View {
    let model: ContactReferralModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(model.contact.fullName)
                .font(.headline)
            
            if !model.contact.phoneNumbers.isEmpty {
                Text(model.contact.phoneNumbers[0])
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            if let referredBy = model.referredBy {
                Text("Referred by: \(referredBy.fullName)")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            if !model.referredContacts.isEmpty {
                Text("Referrals: \(model.referredContacts.map(\.fullName).joined(separator: ", "))")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
}

struct AddContactView: View {
    @Binding var isPresented: Bool
    let onAdd: (Contact) -> Void
    
    @State private var givenName = ""
    @State private var familyName = ""
    @State private var phoneNumber = ""
    @State private var additionalPhoneNumbers: [String] = []
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Name")) {
                    TextField("Given Name", text: $givenName)
                    TextField("Family Name", text: $familyName)
                }
                
                Section(header: Text("Phone Numbers")) {
                    TextField("Primary Phone Number", text: $phoneNumber)
                    
                    ForEach(additionalPhoneNumbers.indices, id: \.self) { index in
                        TextField("Additional Phone", text: $additionalPhoneNumbers[index])
                    }
                    
                    Button("Add Phone Number") {
                        additionalPhoneNumbers.append("")
                    }
                }
                
                Button("Add Contact") {
                    var allPhoneNumbers = [phoneNumber]
                    allPhoneNumbers.append(contentsOf: additionalPhoneNumbers.filter { !$0.isEmpty })
                    
                    let contact = Contact(
                        id: UUID(),
                        givenName: givenName,
                        familyName: familyName,
                        phoneNumbers: allPhoneNumbers
                    )
                    onAdd(contact)
                    isPresented = false
                }
                .disabled(givenName.isEmpty || familyName.isEmpty)
            }
            .navigationTitle("Add Contact")
            .navigationBarItems(
                trailing: Button("Cancel") {
                    isPresented = false
                }
            )
        }
    }
}

struct CreateReferralView: View {
    let contact: ContactReferralModel
    let availableReferrers: [ContactReferralModel]
    let onCreateReferral: (ContactReferralModel, Contact?) -> Void
    
    @Environment(\.dismiss) var dismiss
    @State private var selectedReferrerId: UUID?
    
    var body: some View {
        NavigationView {
            Form {
                Section("Create Referral") {
                    Text("Creating referral for: \(contact.contact.fullName)")
                    
                    Picker("Referred By", selection: $selectedReferrerId) {
                        Text("None").tag(Optional<UUID>.none)
                        ForEach(availableReferrers.filter { $0.id != contact.id }) { referrer in
                            Text(referrer.contact.fullName).tag(Optional(referrer.id))
                        }
                    }
                }
                
                Button("Create Referral") {
                    let referrer = availableReferrers.first { $0.id == selectedReferrerId }?.contact
                    onCreateReferral(contact, referrer)
                    dismiss()
                }
            }
            .navigationTitle("Create Referral")
            .navigationBarItems(
                trailing: Button("Cancel") {
                    dismiss()
                }
            )
        }
    }
}

#Preview {
    ContactReferralTestView()
}
