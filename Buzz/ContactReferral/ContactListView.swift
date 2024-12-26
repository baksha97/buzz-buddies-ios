import SwiftUI
import SwiftNavigation
import SwiftUINavigation
import Dependencies
import CasePaths
import Observation

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
      let fetchedContacts = try await client.fetchContacts()
      contacts = fetchedContacts
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
        onSuccess: {
          Task {
            await viewModel.refreshData()
          }
        }
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
    .refreshable {
      await viewModel.refreshData()
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
            .foregroundColor(.white)
            .padding(20)
            .background(Color.accentColor)
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
