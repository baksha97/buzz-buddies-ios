import SwiftUI
import Dependencies

struct ContactReferralView: View {
  
  @Environment(\.theme) private var theme
  // MARK: - State Properties
  @State private var contacts: [Contact] = []
  @State private var unreferredContacts: [Contact] = []
  @State private var selectedContact: Contact?
  @State private var selectedReferrer: Contact? = nil
  @State private var referredContacts: [Contact] = []
  @State private var referrer: Contact?
  @State private var errorMessage: String?
  
  @Dependency(\.contactReferralClient) private var contactReferralClient
  
  // MARK: - Body
  var body: some View {
    NavigationView {
      VStack(spacing: theme.spacing.lg) {
        BuzzUI.Text("Contact Referral System", style: .displayLarge)
          .padding()
        
        // MARK: - Contact Picker
        BuzzUI.Card(style: .elevated) {
          VStack(alignment: .leading, spacing: theme.spacing.md) {
            BuzzUI.Text("Select an Unreferred Contact:", style: .headingMedium)
            Picker("Select Contact", selection: $selectedContact) {
              Text("None").tag(Optional<Contact>(nil))
              ForEach(unreferredContacts, id: \ .id) { contact in
                Text(contact.fullName).tag(contact)
              }
            }
            .pickerStyle(.menu)
          }
        }
        
        // MARK: - Referrer Picker
        if let selectedContact = selectedContact {
          BuzzUI.Card(style: .elevated) {
            VStack(alignment: .leading, spacing: theme.spacing.md) {
              BuzzUI.Text("Select Referrer (Optional):", style: .headingMedium)
              Picker("Select Referrer", selection: $selectedReferrer) {
                Text("None").tag(Optional<Contact>(nil))
                ForEach(contacts.filter { $0.id != selectedContact.id }, id: \ .id) { contact in
                  Text(contact.fullName).tag(Optional(contact))
                }
              }
              .pickerStyle(.menu)
            }
          }
          
          BuzzUI.Button("Create Referral", style: .primary) {
            Task {
              do {
                try await contactReferralClient.createReferral(selectedContact, selectedReferrer)
                errorMessage = nil
                fetchReferralDetails()
                fetchUnreferredContacts()
              } catch ContactReferralClient.Failure.contactAlreadyExistsInReferralRecords {
                errorMessage = "Contact already exists in referral records."
              } catch {
                errorMessage = error.localizedDescription
              }
            }
          }
          .padding(.top)
        }
        
        // MARK: - Referral Details
        if let selectedContact = selectedContact {
          SectionHeader(title: "Referral Details")
          
          BuzzUI.Button("Fetch Referred Contacts", style: .secondary) {
            Task {
              do {
                referredContacts = try await contactReferralClient.fetchReferredContacts(selectedContact)
              } catch {
                errorMessage = error.localizedDescription
              }
            }
          }
          
          if !referredContacts.isEmpty {
            ReferredContactsList(contacts: referredContacts) { contact in }
              .frame(maxHeight: 150)
          }
          
          BuzzUI.Button("Fetch Referrer", style: .secondary) {
            Task {
              do {
                referrer = try await contactReferralClient.fetchReferrer(selectedContact)
              } catch {
                errorMessage = error.localizedDescription
              }
            }
          }
          
          if let referrer = referrer {
            BuzzUI.Text("Referrer: \(referrer.fullName)", style: .bodyMedium)
          }
        }
        
        // MARK: - Error Handling
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
        await loadContacts()
        fetchUnreferredContacts()
      }
      .navigationTitle("Referrals")
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
  private func loadContacts() async {
    do {
      contacts = try await contactReferralClient.fetchContacts()
    } catch {
      errorMessage = "Failed to load contacts."
    }
  }
  
  private func fetchUnreferredContacts() {
    Task {
      do {
        unreferredContacts = try await contactReferralClient.fetchUnreferredContacts(Contact.mock)
      } catch {
        errorMessage = "Failed to fetch unreferred contacts."
      }
    }
  }
  
  private func fetchReferralDetails() {
    Task {
      do {
        referredContacts = try await contactReferralClient.fetchReferredContacts(selectedContact!)
        referrer = try await contactReferralClient.fetchReferrer(selectedContact!)
      } catch {
        errorMessage = error.localizedDescription
      }
    }
  }
}

#Preview {
  ContactReferralView()
}
