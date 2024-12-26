import SwiftUI
import SwiftNavigation
import SwiftUINavigation
import Dependencies
import Observation

// MARK: - View Model
@MainActor
@Observable
final class ContactReferralViewModel {
  @ObservationIgnored
  @Dependency(\.contactReferralClient) private var client
  
  // MARK: - State
  @CasePathable
  enum ViewState {
    case loading
    case loaded
    case error(String)
  }
  
  @CasePathable
  enum Destination {
    case addContact
    case contactDetails(ContactReferralModel)
  }
  
  @CasePathable
  enum AuthorizationState {
    case unauthorized
    case authorized
  }
  
  // MARK: - Properties
  var viewState: ViewState = .loading
  var destination: Destination?
  var authState: AuthorizationState = .unauthorized
  var searchText = ""
  
  private(set) var contacts: [ContactReferralModel] = []
  private(set) var unreferredContacts: [ContactReferralModel] = []
  
  // MARK: - Computed Properties
  var filteredContacts: [ContactReferralModel] {
    filterContacts(contacts)
  }
  
  var filteredUnreferredContacts: [ContactReferralModel] {
    filterContacts(unreferredContacts)
  }
  
  var isAuthorized: Bool { authState == .authorized }
  var authorizationStatusText: String { isAuthorized ? "✅ Authorized" : "⚠️ Unauthorized" }
  var authorizationStatusColor: Color { isAuthorized ? .green : .orange }
  
  var errorMessage: String? {
    if case let .error(message) = viewState { return message }
    return nil
  }
  
  var isLoading: Bool {
    if case .loading = viewState { return true }
    return false
  }
  
  var availableReferrers: [ContactReferralModel] {
    contacts
  }
  
  // MARK: - Navigation Actions
  func showAddContact() {
    destination = .addContact
  }
  
  func showDetails(for contact: ContactReferralModel) {
    destination = .contactDetails(contact)
  }
  
  func dismissDestination() {
    destination = nil
  }
  
  // MARK: - Contact Management
  @MainActor
  func addContact(_ request: ContactReferralClientCreateRequest) async {
    await performAction {
      try await client.addContact(request)
      await loadAllData()
      dismissDestination()
    }
  }
  
  @MainActor
  func createReferral(contact: ContactReferralModel, referredBy: Contact?) async {
    await performAction {
      try await client.createReferral(contact.contact.id, referredBy?.id)
      await loadAllData()
      dismissDestination()
    }
  }
  
  @MainActor
  func updateExistingReferral(model: ContactReferralModel, referredBy: Contact?) async {
    await performAction {
      try await client.updateReferral(model.contact.id, referredBy?.id)
      await loadAllData()
      dismissDestination()
    }
  }
  
  // MARK: - Data Loading
  @MainActor
  func initialize() async {
    await checkAuthorization()
    await loadAllData()
  }
  
  @MainActor
  func refreshData() async {
    await loadAllData()
  }
  
  // MARK: - Private Helpers
  private func filterContacts(_ contactList: [ContactReferralModel]) -> [ContactReferralModel] {
    guard !searchText.isEmpty else { return contactList }
    return contactList.filter { contact in
      contact.contact.fullName.localizedCaseInsensitiveContains(searchText) ||
      contact.contact.phoneNumbers.contains { $0.contains(searchText) }
    }
  }
  
  @MainActor
  private func loadAllData() async {
    await performAction {
      async let contactsResult = client.fetchContacts()
      async let unreferredResult = client.fetchUnreferredContacts()
      
      let (fetchedContacts, fetchedUnreferred) = try await (contactsResult, unreferredResult)
      contacts = fetchedContacts
      unreferredContacts = fetchedUnreferred
    }
  }
  
  private func performAction(_ action: () async throws -> Void) async {
    viewState = .loading
    do {
      try await action()
      viewState = .loaded
    } catch {
      viewState = .error("Operation failed: \(error.localizedDescription)")
    }
  }
  
  @MainActor
  private func checkAuthorization() async {
    let isAuthorized = await client.requestContactsAuthorization()
    authState = isAuthorized ? .authorized : .unauthorized
  }
}

// MARK: - Main View
struct ContactReferralView: View {
  @State private var viewModel = ContactReferralViewModel()
  
  var body: some View {
    NavigationView {
      VStack(spacing: 0) {
        actionButtons
        
        List {
          authorizationStatus
          contactsSections
        }
        .searchable(text: $viewModel.searchText, prompt: "Search contacts")
      }
      .navigationTitle("Contact Referral")
      .sheet(isPresented: Binding($viewModel.destination.addContact)) { 
        AddContactView { contact in
          Task {
            await viewModel.addContact(contact)
          }
        }
      }
      .sheet(item: $viewModel.destination.contactDetails) { contact in
          ContactDetailsView(
              contact: contact,
              availableReferrers: viewModel.availableReferrers
          ) { contact, referrer in
              Task {
                  if contact.referredBy == nil {
                      await viewModel.createReferral(contact: contact, referredBy: referrer)
                  } else {
                      await viewModel.updateExistingReferral(model: contact, referredBy: referrer)
                  }
              }
          }
      }
      .alert("Error", isPresented: .init(
        get: { viewModel.errorMessage != nil },
        set: { if !$0 { viewModel.viewState = .loaded } }
      )) {
        Button("OK") { viewModel.viewState = .loaded }
      } message: {
        Text(viewModel.errorMessage ?? "")
      }
      .task {
        await viewModel.initialize()
      }
    }
  }
  
  private var actionButtons: some View {
    HStack(spacing: 12) {
      Button {
        viewModel.showAddContact()
      } label: {
        Label("Add Contact", systemImage: "person.badge.plus")
          .frame(maxWidth: .infinity)
      }
      .buttonStyle(.borderedProminent)
      
      Button {
        Task {
          await viewModel.refreshData()
        }
      } label: {
        Label("Refresh", systemImage: "arrow.clockwise")
          .frame(maxWidth: .infinity)
      }
      .buttonStyle(.bordered)
    }
    .padding()
  }
  
  private var authorizationStatus: some View {
    HStack {
      Text(viewModel.authorizationStatusText)
        .foregroundColor(viewModel.authorizationStatusColor)
      Spacer()
    }
  }
  
  private var contactsSections: some View {
    Group {
      Section("All Contacts") {
        contactsList(contacts: viewModel.filteredContacts)
      }
      
      Section("Unreferred Contacts") {
        contactsList(contacts: viewModel.filteredUnreferredContacts)
      }
    }
  }
  
  private func contactsList(contacts: [ContactReferralModel]) -> some View {
    ForEach(contacts) { contact in
      ContactReferralRow(model: contact)
        .onTapGesture {
          viewModel.showDetails(for: contact)
        }
    }
  }
}

// MARK: - Supporting Views
struct ContactReferralRow: View {
  let model: ContactReferralModel
  
  var body: some View {
    VStack(alignment: .leading, spacing: 4) {
      Text(model.contact.fullName)
        .font(.headline)
      
      Text("ID: \(model.contact.id)")
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
  let onAdd: (ContactReferralClientCreateRequest) async -> Void
  @Environment(\.dismiss) private var dismiss
  
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
          
          let contact = ContactReferralClientCreateRequest(
            givenName: givenName,
            familyName: familyName,
            phoneNumbers: allPhoneNumbers,
            referredBy: nil // TODO: provide the ability to refer
          )
          
          Task {
            await onAdd(contact)
            dismiss()
          }
        }
        .disabled(givenName.isEmpty || familyName.isEmpty)
      }
      .navigationTitle("Add Contact")
      .navigationBarItems(
        trailing: Button("Cancel") {
          dismiss()
        }
      )
    }
  }
}

struct ContactDetailsView: View {
  let contact: ContactReferralModel
  let availableReferrers: [ContactReferralModel]
  let onUpdateReferral: (ContactReferralModel, Contact?) -> Void
  
  @Environment(\.dismiss) private var dismiss
  @State private var selectedReferrerId: Contact.ContactListIdentifier?
  
  var body: some View {
    NavigationView {
      Form {
        Section("Contact Details") {
          Text("Name: \(contact.contact.fullName)")
          
          if !contact.contact.phoneNumbers.isEmpty {
            ForEach(contact.contact.phoneNumbers, id: \.self) { number in
              Text("Phone: \(number)")
            }
          }
        }
        
        Section("Referrer") {
          Picker("Referred By", selection: $selectedReferrerId) {
            Text("None").tag(Optional<UUID>.none)
            ForEach(availableReferrers.filter { $0.id != contact.id }) { referrer in
              Text(referrer.contact.fullName).tag(Optional(referrer.id))
            }
          }
          
          if selectedReferrerId != contact.referredBy?.id {
            Button(contact.referredBy == nil ? "Add Referrer" : "Update Referrer") {
              let referrer = availableReferrers
                .first { $0.id == selectedReferrerId }?.contact
              onUpdateReferral(contact, referrer)
              dismiss()
            }
          }
        }
        
        if !contact.referredContacts.isEmpty {
          Section("Referrals Made") {
            ForEach(contact.referredContacts, id: \.id) { referredContact in
              Text(referredContact.fullName)
            }
          }
        }
      }
      .navigationTitle("Contact Details")
      .navigationBarItems(
        trailing: Button("Done") {
          dismiss()
        }
      )
      .onAppear {
        selectedReferrerId = contact.referredBy?.id
      }
    }
  }
}

// MARK: - Preview
#Preview {
  ContactReferralView()
}
