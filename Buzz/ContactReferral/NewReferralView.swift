import SwiftUI
import Dependencies

// MARK: - Contact Picker View
struct ContactPickerView: View {
    @Environment(\.theme) private var theme
    let unreferredContacts: [ContactReferralModel]
    let selectedContact: Contact?
    let onSelectContact: (Contact?) -> Void
    
    var body: some View {
        BuzzUI.Card(style: .elevated) {
            VStack(alignment: .leading, spacing: theme.spacing.md) {
                BuzzUI.Text("Select an Unreferred Contact", style: .headingMedium)
                Picker("Select Contact", selection: .init(
                    get: { selectedContact },
                    set: { onSelectContact($0) }
                )) {
                    Text("None").tag(Optional<Contact>(nil))
                  ForEach(unreferredContacts.map{ $0.contact }, id: \.id) { contact in
                        Text(contact.fullName).tag(Optional(contact))
                    }
                }
                .pickerStyle(.menu)
            }
        }
    }
}

// MARK: - Referrer Picker View
struct ReferrerPickerView: View {
    @Environment(\.theme) private var theme
    let selectedContact: Contact
    let selectedReferrer: Contact?
    let allContacts: [ContactReferralModel]
    let onSelectReferrer: (Contact?) -> Void
    
    var body: some View {
        BuzzUI.Card(style: .elevated) {
            VStack(alignment: .leading, spacing: theme.spacing.md) {
                BuzzUI.Text("Select Referrer (Optional)", style: .headingMedium)
                Picker("Select Referrer", selection: .init(
                    get: { selectedReferrer },
                    set: { onSelectReferrer($0) }
                )) {
                    Text("None").tag(Optional<Contact>(nil))
                    ForEach(allContacts.map{ $0.contact }.filter { $0.id != selectedContact.id }, id: \.id) { contact in
                        Text(contact.fullName).tag(Optional(contact))
                    }
                }
                .pickerStyle(.menu)
            }
        }
    }
}

// MARK: - Status Message View
struct StatusMessageView: View {
    let isSuccess: Bool
    let errorMessage: String?
    @Environment(\.theme) private var theme
    
    var body: some View {
        VStack {
            if isSuccess {
                BuzzUI.Text("Referral successfully created!",
                           style: .bodyMedium,
                           color: theme.colors.success)
                    .padding(.top)
            }
            
            if let errorMessage = errorMessage {
                EmptyStateView(
                    message: errorMessage,
                    icon: Image(systemName: "exclamationmark.triangle")
                )
            }
        }
    }
}

// MARK: - Main View
struct NewReferralView: View {
    @Environment(\.theme) private var theme
    
    // MARK: - State Properties
    @State private var unreferredContacts: [ContactReferralModel] = []
    @State private var allContacts: [ContactReferralModel] = []
    @State private var selectedContact: Contact?
    @State private var selectedReferrer: Contact?
    @State private var errorMessage: String?
    @State private var isReferralCreated: Bool = false
    
    @Dependency(\.contactReferralClient) private var contactReferralClient
    
    // MARK: - Body
    var body: some View {
        NavigationView {
            VStack(spacing: theme.spacing.lg) {
                // Title
                BuzzUI.Text("Create a New Referral", style: .displayLarge)
                    .padding()
                
                // Contact Picker
                ContactPickerView(
                    unreferredContacts: unreferredContacts,
                    selectedContact: selectedContact,
                    onSelectContact: { contact in
                        selectedContact = contact
                        selectedReferrer = nil // Reset referrer when contact changes
                    }
                )
                
                // Referrer Picker
                if let selectedContact = selectedContact {
                    ReferrerPickerView(
                        selectedContact: selectedContact,
                        selectedReferrer: selectedReferrer,
                        allContacts: allContacts,
                        onSelectReferrer: { referrer in
                            selectedReferrer = referrer
                        }
                    )
                    
                    // Create Referral Button
                    BuzzUI.Button("Create Referral", style: .primary) {
                        Task {
                            await createReferral()
                        }
                    }
                    .padding(.top)
                }
                
                // Status Messages
                StatusMessageView(
                    isSuccess: isReferralCreated,
                    errorMessage: errorMessage
                )
                
                Spacer()
            }
            .padding(theme.spacing.containerPadding)
            .task {
                await fetchUnreferredContacts()
                await fetchAllContacts()
            }
            .navigationTitle("New Referral")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .bottomBar) {
                    FloatingActionButton(
                        icon: Image(systemName: "plus"),
                        action: {}
                    )
                }
            }
        }
    }
    
    // MARK: - Functions
    private func createReferral() async {
        guard let selectedContact = selectedContact else { return }
        
        do {
            try await contactReferralClient.createReferral(selectedContact, selectedReferrer)
            isReferralCreated = true
            errorMessage = nil
            await fetchUnreferredContacts()
            await fetchAllContacts()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
    
    private func fetchUnreferredContacts() async {
        do {
            unreferredContacts = try await contactReferralClient.fetchUnreferredContacts()
        } catch {
            errorMessage = "Failed to fetch unreferred contacts."
        }
    }
    
    private func fetchAllContacts() async {
        do {
            allContacts = try await contactReferralClient.fetchContacts()
        } catch {
            errorMessage = "Failed to fetch all contacts."
        }
    }
}

#Preview {
    NewReferralView()
}
