//
//  ContactReferralViewModel.swift
//  Buzz
//
//  Created by Travis Baksh on 12/26/24.
//

import SwiftUI
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
