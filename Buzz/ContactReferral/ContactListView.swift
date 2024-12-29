import SwiftUI
import SwiftNavigation
import SwiftUINavigation
import Dependencies
import CasePaths
import Observation
import Sharing

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
  
  var viewState: ViewState = .loading
  var destination: Destination?
  var searchText = ""
  
  private(set) var contacts: [ContactReferralModel] = []
  private var observers: [Contact.ContactListIdentifier: Task<Void, Never>] = [:]
  
  // MARK: - Public Interface
  var filteredContacts: [ContactReferralModel] {
    filterContacts(contacts)
  }
  
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
  
  // MARK: - Lifecycle
  deinit {
    //    observers.values.forEach { $0.cancel() }
    //    observers.removeAll()
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
      // After adding contact, we'll get the update through the observer
      dismissDestination()
    }
  }
  
  @MainActor
  func createReferral(contact: ContactReferralModel, referredBy: Contact?) async {
    await performAction {
      try await client.createReferral(contact.contact.id, referredBy?.id)
      // Updates will come through observers
      dismissDestination()
    }
  }
  
  @MainActor
  func updateExistingReferral(model: ContactReferralModel, referredBy: Contact?) async {
    await performAction {
      try await client.updateReferral(model.contact.id, referredBy?.id)
      // Updates will come through observers
      dismissDestination()
    }
  }
  
  // MARK: - Data Loading and Observation
  @MainActor
  func initialize() async {
    viewState = .loading
    do {
      // First fetch to get initial list of contacts
      let initialContacts = try await client.fetchContacts()
      contacts = initialContacts
      
      // Start observing each contact
      for contact in initialContacts {
        startObserving(contact.contact.id)
      }
      
      viewState = .loaded
    } catch {
      viewState = .error("Failed to load contacts: \(error.localizedDescription)")
    }
  }
  
  @MainActor
  private func startObserving(_ contactId: Contact.ContactListIdentifier) {
    // Cancel existing observer if any
    observers[contactId]?.cancel()
    
    // Create new observer
    let task = Task { [weak self] in
      guard let self else { return }
      do {
        for try await updatedContact in client.observe(contactId) {
          // Update the contact in our array
          if let index = self.contacts.firstIndex(where: { $0.contact.id == contactId }) {
            self.contacts[index] = updatedContact
          } else {
            self.contacts.append(updatedContact)
          }
        }
      } catch {
        // Handle stream errors
        await MainActor.run {
          self.viewState = .error("Lost connection to contact \(contactId): \(error.localizedDescription)")
        }
      }
    }
    
    observers[contactId] = task
  }
  
  // MARK: - Private Helpers
  private func filterContacts(_ contactList: [ContactReferralModel]) -> [ContactReferralModel] {
    guard !searchText.isEmpty else { return contactList }
    return contactList.filter { contact in
      contact.contact.fullName.localizedCaseInsensitiveContains(searchText) ||
      contact.contact.phoneNumbers.contains { $0.contains(searchText) }
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
}

struct ContactListView: View {
  @State private var viewModel = ContactReferralViewModel()
  
  @Shared(.activeQrConfiguration)
  var configuration
  
  var body: some View {
    ZStack {
      List {
        contactsSection
      }
      .searchable(text: $viewModel.searchText, prompt: "Search contacts")
      
      floatingActionButton
    }
    .sheet(isPresented: Binding($viewModel.destination.addContact)) {
      AddContactView(
        availableReferrers: viewModel.availableReferrers,
        onSuccess: { /* No need for refresh */ }
      )
    }
    .sheet(item: $viewModel.destination.contactDetails) { contact in
      ContactDetailsView(contact: contact)
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
  
  private var contactsSection: some View {
    Section("All Contacts") {
      ForEach(viewModel.filteredContacts) { contact in
        ContactReferralRow(config: .init(
          model: contact,
          onTap: {
            viewModel.showDetails(for: contact)
          }
        ))
      }
    }
  }
  
  private var floatingActionButton: some View {
    VStack {
      Spacer()
      HStack {
        Spacer()
        Button {
          viewModel.showAddContact()
        } label: {
          Image(systemName: "person.badge.plus")
            .font(.title2)
            .foregroundColor(configuration.foregroundColor)
            .padding(20)
            .background(configuration.backgroundColor)
            .clipShape(Circle())
            .shadow(radius: 4, y: 2)
        }
        .padding([.trailing, .bottom], 20)
      }
    }
  }
}

#Preview {
  NavigationView {
    ContactListView()
  }
}
