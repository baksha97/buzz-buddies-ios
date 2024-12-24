import SwiftUI
import Dependencies

struct ContactReferralView: View {
  // MARK: - State Properties
  
  @State private var contacts: [Contact] = []
  @State private var selectedContact: Contact?
  @State private var selectedReferrer: Contact? = nil
  
  @State private var referredContacts: [Contact] = []
  @State private var referrer: Contact?
  
  @State private var errorMessage: String?
  
  @Dependency(\.contactReferralClient) private var contactReferralClient
  @Dependency(\.contactsClient) private var contactsClient
  @Dependency(\.referralRecordClient) private var referralRecordClient
  
  // MARK: - Body
  
  var body: some View {
    NavigationView {
      VStack(spacing: 20) {
        Text("Contact Referral System")
          .font(.largeTitle)
          .padding()
        
        // MARK: - Contact Picker
        VStack(alignment: .leading) {
          Text("Select a Contact:")
            .font(.headline)
          Picker("Select Contact", selection: $selectedContact) {
            Text("None").tag(Optional<Contact>(nil))
            ForEach(contacts, id: \.id) { contact in
              Text(contact.fullName).tag(Optional(contact))
            }
          }
          .pickerStyle(.menu)
        }
        .padding(.horizontal)
        
        // MARK: - Referrer Picker
        if let selectedContact = selectedContact {
          VStack(alignment: .leading) {
            Text("Select Referrer (Optional):")
              .font(.headline)
            Picker("Select Referrer", selection: $selectedReferrer) {
              Text("None").tag(Optional<Contact>(nil))
              ForEach(contacts.filter { $0.id != selectedContact.id }, id: \.id) { contact in
                Text(contact.fullName).tag(Optional(contact))
              }
            }
            .pickerStyle(.menu)
          }
          .padding(.horizontal)
          
          // MARK: - Actions
          Button("Create Referral") {
            Task {
              do {
                try await contactReferralClient.createReferral(selectedContact, selectedReferrer)
                errorMessage = nil
                fetchReferralDetails()
              } catch ContactReferralClient.Failure.contactAlreadyExistsInReferralRecords {
                let message = "Contact '\(selectedContact.fullName)' already exists in referral records."
                print("Error: \(message)")
                errorMessage = message
              } catch {
                let message = "Error for contact '\(selectedContact.fullName)': \(error.localizedDescription)"
                print("Error: \(message)")
                errorMessage = message
              }
            }
          }
          .buttonStyle(.borderedProminent)
          .padding(.top)
          
          Divider()
          
          // MARK: - Referral Details
          VStack(alignment: .leading, spacing: 10) {
            Button("Fetch Referred Contacts") {
              Task {
                do {
                  referredContacts = try await contactReferralClient.fetchReferredContacts(selectedContact)
                } catch {
                  let message = "Failed to fetch referred contacts for '\(selectedContact.fullName)'."
                  print("Error: \(message)")
                  errorMessage = message
                }
              }
            }
            
            if !referredContacts.isEmpty {
              Text("Referred Contacts:")
                .font(.headline)
              List(referredContacts, id: \.id) { contact in
                Text(contact.fullName)
              }
              .frame(maxHeight: 150)
            }
            
            Button("Fetch Referrer") {
              Task {
                do {
                  referrer = try await contactReferralClient.fetchReferrer(selectedContact)
                } catch {
                  let message = "Failed to fetch referrer for '\(selectedContact.fullName)'."
                  print("Error: \(message)")
                  errorMessage = message
                }
              }
            }
            
            Button("Delete Database") {
              Task {
                do {
                  try await referralRecordClient.deleteDatabase()
                } catch {
                  let message = "Failed to Delete Database"
                  print("Error: \(message)")
                  errorMessage = message
                }
              }
            }
            
            if let referrer = referrer {
              Text("Referrer: \(referrer.fullName)")
                .font(.headline)
                .padding(.top)
            }
          }
          .padding(.horizontal)
        }
        
        // MARK: - Error Message
        if let errorMessage = errorMessage {
          VStack(spacing: 10) {
            Text("Error: \(errorMessage)")
              .foregroundColor(.red)
              .padding()
            
            Button("Clear Error") {
              self.errorMessage = nil
            }
            .buttonStyle(.bordered)
          }
          .padding()
        }
        
        Spacer()
      }
      .task {
        await loadContacts()
      }
      .navigationTitle("Referrals")
    }
  }
  
  // MARK: - Functions
  
  private func loadContacts() async {
    do {
      contacts = try await contactsClient.fetchContacts()
    } catch {
      let message = "Failed to load contacts."
      print("Error: \(message)")
      errorMessage = message
    }
  }
  
  private func fetchReferralDetails() {
    Task {
      do {
        referredContacts = try await contactReferralClient.fetchReferredContacts(selectedContact!)
        referrer = try await contactReferralClient.fetchReferrer(selectedContact!)
      } catch {
        let message = "Failed to fetch referral details for '\(selectedContact?.fullName ?? "Unknown Contact")'."
        print("Error: \(message)")
        errorMessage = message
      }
    }
  }
}

#Preview {
  ContactReferralView()
}
