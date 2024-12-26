import SwiftUI
import Dependencies
import Observation

@MainActor
@Observable
final class ContactReferralViewModel {
  @ObservationIgnored
  @Dependency(\.contactReferralClient) private var client
  
  // Main view state
  enum ViewState {
    case loading
    case loaded
    case error(String)
  }
  
  // Sheet presentation state
  enum SheetState {
    case none
    case addingContact
    case showingDetails(ContactReferralModel)
  }
  
  // Authorization state
  enum AuthorizationState {
    case unauthorized
    case authorized
  }
  
  // State properties
  var viewState: ViewState = .loading
  var sheetState: SheetState = .none
  var authState: AuthorizationState = .unauthorized
  var searchText = ""
  
  // Model data
  var contacts: [ContactReferralModel] = []
  var unreferredContacts: [ContactReferralModel] = []
  
  // Filtered contacts based on search
  var filteredContacts: [ContactReferralModel] {
    guard !searchText.isEmpty else { return contacts }
    return contacts.filter { contact in
      contact.contact.fullName.localizedCaseInsensitiveContains(searchText) ||
      contact.contact.phoneNumbers.contains { $0.contains(searchText) }
    }
  }
  
  var filteredUnreferredContacts: [ContactReferralModel] {
    guard !searchText.isEmpty else { return unreferredContacts }
    return unreferredContacts.filter { contact in
      contact.contact.fullName.localizedCaseInsensitiveContains(searchText) ||
      contact.contact.phoneNumbers.contains { $0.contains(searchText) }
    }
  }
  
  // Computed properties for view binding
  var isShowingDetailsSheet: Bool {
    get {
      if case .showingDetails = sheetState { return true }
      return false
    }
    set {
      if !newValue { sheetState = .none }
    }
  }
  
  var isAddingContact: Bool {
    get {
      if case .addingContact = sheetState { return true }
      return false
    }
    set {
      if !newValue { sheetState = .none }
      else { sheetState = .addingContact }
    }
  }
  
  var selectedContact: ContactReferralModel? {
    get {
      if case let .showingDetails(contact) = sheetState { return contact }
      return nil
    }
  }
  
  var isAuthorized: Bool {
    get { authState == .authorized }
  }
  
  var errorMessage: String? {
    get {
      if case let .error(message) = viewState { return message }
      return nil
    }
  }
  
  var isLoading: Bool {
    get {
      guard case .loaded = viewState else {
        return false
      }
      return true
    }
  }
  
  // MARK: - Actions
  
  func requestAuthorization() async {
    let isAuthorized = await client.requestContactsAuthorization()
    authState = isAuthorized ? .authorized : .unauthorized
  }
  
  func loadContacts() async {
    do {
      contacts = try await client.fetchContacts()
      viewState = .loaded
    } catch {
      viewState = .error("Failed to load contacts: \(error.localizedDescription)")
    }
  }
  
  func loadUnreferredContacts() async {
    do {
      unreferredContacts = try await client.fetchUnreferredContacts()
      viewState = .loaded
    } catch {
      viewState = .error("Failed to load unreferred contacts: \(error.localizedDescription)")
    }
  }
  
  func addContact(_ contact: Contact) async {
    viewState = .loading
    do {
      try await client.addContact(contact)
      await loadContacts()
      await loadUnreferredContacts()
      sheetState = .none
    } catch {
      viewState = .error("Failed to add contact: \(error.localizedDescription)")
    }
  }
  
  func createReferral(model: ContactReferralModel, referredBy: Contact?) async {
    viewState = .loading
    do {
      try await client.createReferral(model.contact.id, model.referredBy?.id)
      await loadContacts()
      await loadUnreferredContacts()
      sheetState = .none
    } catch {
      viewState = .error("Failed to create referral: \(error.localizedDescription)")
    }
  }
  
  func loadInitialData() async {
    viewState = .loading
    await loadContacts()
    await loadUnreferredContacts()
  }
  
  func showDetails(for contact: ContactReferralModel) {
    sheetState = .showingDetails(contact)
  }
  
  func clearSelectedContact() {
    sheetState = .none
  }
  
  func dismissError() {
    viewState = .loaded
  }
  
  func checkAuthorization() async {
    await requestAuthorization()
  }
}

struct ContactReferralTestView: View {
  @State private var viewModel = ContactReferralViewModel()
  
  var body: some View {
    NavigationView {
      VStack(spacing: 0) {
        // Action Buttons
        HStack(spacing: 12) {
          Button(action: {
            viewModel.isAddingContact = true
          }) {
            Label("Add Contact", systemImage: "person.badge.plus")
              .frame(maxWidth: .infinity)
          }
          .buttonStyle(.borderedProminent)
          
          Button(action: {
            Task {
              await viewModel.loadInitialData()
            }
          }) {
            Label("Refresh", systemImage: "arrow.clockwise")
              .frame(maxWidth: .infinity)
          }
          .buttonStyle(.bordered)
        }
        .padding()
        
        List {
          // Authorization Status
          HStack {
            Text(viewModel.isAuthorized ? "✅ Authorized" : "⚠️ Unauthorized")
              .foregroundColor(viewModel.isAuthorized ? .green : .orange)
            Spacer()
          }
          
          Section("All Contacts") {
            ForEach(viewModel.filteredContacts) { contact in
              ContactReferralRow(model: contact)
                .onTapGesture {
                  viewModel.showDetails(for: contact)
                }
            }
          }
          
          Section("Unreferred Contacts") {
            ForEach(viewModel.filteredUnreferredContacts) { contact in
              ContactReferralRow(model: contact)
                .onTapGesture {
                  viewModel.showDetails(for: contact)
                }
            }
          }
        }
        .searchable(text: $viewModel.searchText, prompt: "Search contacts")
      }
      .navigationTitle("Contact Referral Tests")
      .sheet(isPresented: $viewModel.isAddingContact) {
        AddContactView(isPresented: $viewModel.isAddingContact) { contact in
          Task {
            await viewModel.addContact(contact)
          }
        }
      }
      .sheet(isPresented: $viewModel.isShowingDetailsSheet) {
        if let contact = viewModel.selectedContact {
          ContactDetailsView(
            contact: contact,
            availableReferrers: viewModel.contacts,
            onUpdateReferral: { contact, referrer in
              Task {
                await viewModel.createReferral(model: contact, referredBy: referrer)
              }
            }
          )
        }
      }
      .alert("Error", isPresented: .init(
        get: { viewModel.errorMessage != nil },
        set: { if !$0 { viewModel.dismissError() } }
      )) {
        Button("OK") { viewModel.dismissError() }
      } message: {
        Text(viewModel.errorMessage ?? "")
      }
      .task {
        await viewModel.checkAuthorization()
        await viewModel.loadInitialData()
      }
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

struct ContactDetailsView: View {
  let contact: ContactReferralModel
  let availableReferrers: [ContactReferralModel]
  let onUpdateReferral: (ContactReferralModel, Contact?) -> Void
  
  @Environment(\.dismiss) var dismiss
  @State private var selectedReferrerId: UUID?
  
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
        
        if let referredBy = contact.referredBy {
          Section("Referred By") {
            Text(referredBy.fullName)
          }
        } else {
          Section("Add Referrer") {
            Picker("Referred By", selection: $selectedReferrerId) {
              Text("None").tag(Optional<UUID>.none)
              ForEach(availableReferrers.filter { $0.id != contact.id }) { referrer in
                Text(referrer.contact.fullName).tag(Optional(referrer.id))
              }
            }
            
            if selectedReferrerId != nil {
              Button("Update Referrer") {
                let referrer = availableReferrers.first { $0.id == selectedReferrerId }?.contact
                onUpdateReferral(contact, referrer)
                dismiss()
              }
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
        // Prepopulate the selected referrer if one exists
        if let referredBy = contact.referredBy {
          selectedReferrerId = referredBy.id
        }
      }
    }
  }
}

#Preview {
  ContactReferralTestView()
}
