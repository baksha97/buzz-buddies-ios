//
//  ContactDetailsViewModel.swift
//  Buzz
//
//  Created by Travis Baksh on 12/30/24.
//


import SwiftUI
import Observation
import Dependencies
import CasePaths
import SwiftUINavigation
import Sharing

@MainActor
@Observable
final class ContactDetailsViewModel {
  @ObservationIgnored
  @Dependency(\.contactReferralClient) private var client
  
  // MARK: - Observed Data State
  
  @CasePathable
  enum ViewState {
    case loading
    case loaded(ContactReferralModel)
    case error(String)
  }
  
  @CasePathable
  enum ContactPickerSheetDestination {
    case referrer
    case refer
  }
  
  let id: Contact.ContactListIdentifier
  
  // The currently loaded/observed data state
  var viewState: ViewState = .loading
  
  // Whether we are actively observing the contact in a stream
  var isObserving: Bool = false
  
  // Whether we are performing a user action (update, remove, etc.)
  var isPerformingAction: Bool = false
  
  // General error message for showing an alert
  var errorMessage: String?
  
  // Navigation (Sheets & Confirmation Dialog)
  var contactPickerDestination: ContactPickerSheetDestination? = nil
  
  /// The contact the user wants to remove, triggers a confirmation dialog.
  /// Must be `Identifiable` for `.confirmationDialog(item:)`.
  var referralToRemove: Contact? = nil
  
  private var observationTask: Task<Void, Never>?
  
  // MARK: - Init
  
  init(contactId: Contact.ContactListIdentifier) {
    self.id = contactId
  }
  
  // MARK: - Computed Helpers
  
  var referrerIdExclusions: [Contact.ContactListIdentifier] {
    guard case let .loaded(contact) = viewState else { return [] }
    return [contact.contact.id, contact.referredBy?.id].compactMap(\.self) + contact.referredContacts.map(\.id)
  }
  
  /// For showing a spinner while *either* observing or performing an action.
  var isLoading: Bool {
    isObserving || isPerformingAction
  }
  
  // MARK: - Lifecycle
  
  func initialize() async {
    startObservingContact()
  }
  
  // MARK: - Actions
  
  func updateReferrer(_ newReferrer: Contact?) {
    Task {
      await performAction {
        guard case let .loaded(contact) = self.viewState else { return }
        if contact.referredBy == nil {
          try await client.createReferral(contact.contact.id, newReferrer?.id)
        } else {
          try await client.updateReferral(contact.contact.id, newReferrer?.id)
        }
      }
    }
  }
  
  func referContact(_ contactId: String) {
    Task {
      await performAction {
        guard case let .loaded(contact) = self.viewState else { return }
        try await client.createReferral(contactId, contact.contact.id)
      }
    }
  }
  
  func requestRemoveReferral(for contact: Contact) {
    referralToRemove = contact
  }
  
  func confirmRemoveReferral(for contactId: String) {
    Task {
      await performAction {
        guard case let .loaded(contact) = self.viewState else { return }
        _ = try await client.removeReferral(contactId, contact.contact.id)
      }
      referralToRemove = nil
    }
  }
  
  // MARK: - Private
  
  private func performAction(_ action: () async throws -> Void) async {
    isPerformingAction = true
    defer { isPerformingAction = false }
    errorMessage = nil
    do {
      try await action()
    } catch {
      errorMessage = error.localizedDescription
    }
  }
  
  private func startObservingContact() {
    observationTask = Task { [id = self.id] in
      isObserving = true
      viewState = .loading
      errorMessage = nil
      do {
        for try await updatedContact in client.observe(id) {
          self.viewState = .loaded(updatedContact)
          isObserving = false
        }
      } catch {
        isObserving = false
        viewState = .error("Failed to observe contact updates: \(error.localizedDescription)")
        errorMessage = "Failed to observe contact updates: \(error.localizedDescription)"
      }
    }
  }
}