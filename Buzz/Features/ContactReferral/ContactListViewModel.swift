//
//  ContactListViewModel.swift
//  Buzz
//
//  Created by Travis Baksh on 12/29/24.
//


import SwiftUI
import SwiftNavigation
import SwiftUINavigation
import Dependencies
import CasePaths
import Observation
import Sharing

@MainActor
@Observable
final class ContactListViewModel {
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
    case contactDetails(contactId: Contact.ContactListIdentifier)
  }
  
  var viewState: ViewState = .loading
  var destination: Destination? {
    didSet {
      // whenever we dismiss a sheet, let's refresh our contacts
      refreshContacts()
    }
  }
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
  
  func showDetails(for contactId: Contact.ContactListIdentifier) {
    destination = .contactDetails(contactId: contactId)
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
      contacts = initialContacts.sorted { $0.contact.fullName < $1.contact.fullName }
      
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
  func refreshContacts() {
    Task {
      viewState = .loading
      do {
        // First fetch to get initial list of contacts
        let initialContacts = try await client.fetchContacts()
        contacts = initialContacts.sorted { $0.contact.fullName < $1.contact.fullName }
      } catch {
        viewState = .error("Failed to load contacts: \(error.localizedDescription)")
      }
      viewState = .loaded
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
    .sorted { $0.contact.fullName < $1.contact.fullName }
  }
  
  private func performAction(_ action: () async throws -> Void) async {
    viewState = .loading
    do {
      try await action()
      viewState = .loaded
    } catch {
      viewState = .error("\(error.localizedDescription)")
    }
  }
}
