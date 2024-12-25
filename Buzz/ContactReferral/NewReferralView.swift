import SwiftUI
import Dependencies
import SwiftUI
import Dependencies

struct NewReferralView: View {
  @Environment(\.theme) private var theme
  
  // MARK: - State Properties
  @State private var unreferredContacts: [Contact] = []
  @State private var allContacts: [Contact] = []
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
        BuzzUI.Card(style: .elevated) {
          VStack(alignment: .leading, spacing: theme.spacing.md) {
            BuzzUI.Text("Select an Unreferred Contact", style: .headingMedium)
            Picker("Select Contact", selection: $selectedContact) {
              Text("None").tag(Optional<Contact>(nil))
              ForEach(unreferredContacts, id: \ .id) { contact in
                Text(contact.fullName).tag(Optional(contact))
              }
            }
            .pickerStyle(.menu)
          }
        }
        
        // Referrer Picker
        if let selectedContact = selectedContact {
          BuzzUI.Card(style: .elevated) {
            VStack(alignment: .leading, spacing: theme.spacing.md) {
              BuzzUI.Text("Select Referrer (Optional)", style: .headingMedium)
              Picker("Select Referrer", selection: $selectedReferrer) {
                Text("None").tag(Optional<Contact>(nil))
                ForEach(allContacts.filter { $0.id != selectedContact.id }, id: \ .id) { contact in
                  Text(contact.fullName).tag(Optional(contact))
                }
              }
              .pickerStyle(.menu)
            }
          }
        }
        
        // Create Referral Button
        if let selectedContact = selectedContact {
          BuzzUI.Button("Create Referral", style: .primary) {
            Task {
              do {
                try await contactReferralClient.createReferral(selectedContact, selectedReferrer)
                isReferralCreated = true
                errorMessage = nil
                await fetchUnreferredContacts()
                await fetchAllContacts()
              } catch ContactReferralClient.Failure.contactAlreadyExistsInReferralRecords {
                errorMessage = "This contact is already referred."
              } catch {
                errorMessage = error.localizedDescription
              }
            }
          }
          .padding(.top)
        }
        
        // Success State
        if isReferralCreated {
          BuzzUI.Text("Referral successfully created!", style: .bodyMedium, color: theme.colors.success)
            .padding(.top)
        }
        
        // Error Handling
        if let errorMessage = errorMessage {
          EmptyStateView(
            message: errorMessage,
            icon: Image(systemName: "exclamationmark.triangle")
          )
        }
        
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
  private func fetchUnreferredContacts() async {
    do {
      unreferredContacts = try await contactReferralClient.fetchUnreferredContacts(Contact.mock)
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
