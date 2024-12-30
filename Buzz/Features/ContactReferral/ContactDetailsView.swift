// PLEASE INCLUDE THIS COMMENT IN YOUR REFACTORED RESPONSE
// Instructions: ONLY CHANGE ITEMS IN THIS FILE. PROVIDE THIS FULL FILE WITH REFACTORED CODE AS NEEDED. ONLY PROVIDE THESE MODELS OR ADDITIONAL CREATED MODELS. I SHOULD BE ABLE TO PASTE OVER THIS FILE TO HAVE IT COMPILE TO VIEW YOUR CHANGES

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

// MARK: - Main Contact Details View

struct ContactDetailsView: View {
  @State private var viewModel: ContactDetailsViewModel
  @Environment(\.dismiss) private var dismiss
  
  @Shared(.activeQrConfiguration)
  var configuration
  
  init(contactId: Contact.ContactListIdentifier) {
    _viewModel = State(initialValue: ContactDetailsViewModel(contactId: contactId))
  }
  
  var body: some View {
    // No navigation bar or toolbar; user swipes down to dismiss.
    content
      .background(
        configuration.backgroundColor.opacity(0.2))
      .task {
        await viewModel.initialize()
      }
  }
  
  @ViewBuilder
  private var content: some View {
    switch viewModel.viewState {
    case .loading:
      ProgressView()
        .tint(configuration.foregroundColor)
      
    case .error(let message):
      Text(message)
        .foregroundColor(configuration.foregroundColor)
      
    case .loaded(let contact):
      ZStack {
        ScrollView {
          VStack(alignment: .leading, spacing: 12) {
            
            // MARK: - Name + Phone
            VStack(alignment: .leading, spacing: 6) {
              // Row: Name + person icon
              HStack(spacing: 8) {
                Image(systemName: "person.circle.fill")
                  .foregroundColor(configuration.foregroundColor)
                  .font(.title2)
                Text(contact.contact.fullName)
                  .foregroundColor(configuration.foregroundColor)
                  .font(.title2) // Larger font for name
                  .fontWeight(.bold)
              }
              .frame(maxWidth: .infinity)
              
              // Row: phone + phone icon
              if let phoneNumber = contact.contact.phoneNumbers.first {
                HStack(spacing: 8) {
                  Image(systemName: "phone.fill")
                    .foregroundColor(configuration.foregroundColor)
                  Text(phoneNumber)
                    .foregroundColor(configuration.foregroundColor)
                }
              }
            }
            .padding()
            .background(
              RoundedRectangle(cornerRadius: 12)
                .fill(configuration.backgroundColor)
            )
            .padding(.top, 24)
            // MARK: - Referred By
            VStack(alignment: .leading, spacing: 0) {
              HStack(spacing: 8) {
                Image(systemName: "person.fill.badge.plus")
                  .foregroundColor(configuration.foregroundColor)
                Text("Referred By")
                  .foregroundColor(configuration.foregroundColor)
                  .fontWeight(.bold)
                
                // The referredBy contact name after the bold text
                Text(contact.referredBy?.fullName ?? "None")
                  .foregroundColor(configuration.foregroundColor)
                
                Spacer()
                Button(action: { viewModel.contactPickerDestination = .referrer }) {
                  Image(systemName: "pencil")
                    .foregroundColor(configuration.foregroundColor)
                }
              }
            }
            .padding()
            .background(
              RoundedRectangle(cornerRadius: 12)
                .fill(configuration.backgroundColor)
            )
            .onTapGesture {
              
            }
            
            // MARK: - Referred Contacts
            VStack(alignment: .leading, spacing: 12) {
              
              // Header row with label
              HStack(alignment: .bottom) {
                Image(systemName: "arrowshape.turn.up.right.circle")
                  .foregroundColor(configuration.foregroundColor)
                Text("Referred Contacts")
                  .foregroundColor(configuration.foregroundColor)
                  .fontWeight(.bold)
                Spacer()
              }
              
              // The number of referrals
              let count = contact.referredContacts.count
              if count > 0 {
                HStack(spacing: 6) {
                  Image(systemName: "person.2.fill")
                    .foregroundColor(configuration.foregroundColor)
                    .font(.subheadline)
                  Text("\(count) referral(s).")
                    .foregroundColor(configuration.foregroundColor)
                }
              } else {
                HStack(spacing: 6) {
                  Image(systemName: "person.2.fill")
                    .foregroundColor(configuration.foregroundColor)
                    .font(.subheadline)
                  Text("No referrals yet.")
                    .foregroundColor(configuration.foregroundColor)
                }
              }
              
              // The actual list of referred contacts
              if !contact.referredContacts.isEmpty {
                VStack(spacing: 0) {
                  ForEach(contact.referredContacts, id: \.id) { referredContact in
                    VStack {
                      HStack(spacing: 8) {
                        Text(referredContact.fullName)
                          .foregroundColor(configuration.foregroundColor)
                          .bold()
                        
                        Spacer()
                        // put the remove referral icon on the trailing side
                        Button {
                          viewModel.requestRemoveReferral(for: referredContact)
                        } label: {
                          Image(systemName: "xmark.circle.fill")
                            .foregroundColor(configuration.foregroundColor)
                        }
                      }
                      .padding(.vertical, 8)
                      
                      // Divider after each contact except the last
                      if referredContact.id != contact.referredContacts.last?.id {
                        Divider()
                          .overlay(configuration.foregroundColor.opacity(0.3))
                      }
                    }
                  }
                }
              }
              
              // The plus button to refer new contacts
              Button {
                viewModel.contactPickerDestination = .refer
              } label: {
                Image(systemName: "plus.circle.fill")
                  .foregroundColor(configuration.foregroundColor)
                  .font(.title2)
              }
              .frame(maxWidth: .infinity, alignment: .center)
              
            }
            .padding()
            .background(
              RoundedRectangle(cornerRadius: 12)
                .fill(configuration.backgroundColor)
            )
            
            // MARK: - QR Code
            // Center the QR code on screen
            ContactQRView(contact: contact.contact)
              .frame(maxWidth: .infinity, alignment: .center)
              .padding(.top, 8)
            
          }
          .padding(.horizontal)
          .padding(.top, 12)
          .padding(.bottom, 24)
        }
        
        if viewModel.isLoading {
          ProgressView()
            .tint(configuration.foregroundColor)
        }
      }
      .sheet(isPresented: Binding($viewModel.contactPickerDestination.referrer)) {
        ContactPickerView(
          selectedContact: contact.referredBy?.id,
          exclusions: viewModel.referrerIdExclusions
        ) { selected in
          viewModel.updateReferrer(selected)
        }
      }
      .sheet(isPresented: Binding($viewModel.contactPickerDestination.refer)) {
        ContactPickerView(
          selectedContact: nil,
          exclusions: viewModel.referrerIdExclusions
        ) { selected in
          if let selected {
            viewModel.referContact(selected.id)
          }
        }
      }
      .confirmationDialog(
        item: $viewModel.referralToRemove,
        titleVisibility: .hidden,
        title: { Text("Removing \($0.fullName)") },
        actions: { contactToRemove in
          Button("Remove \(contactToRemove.fullName)", role: .destructive) {
            viewModel.confirmRemoveReferral(for: contactToRemove.id)
          }
          Button("Cancel", role: .cancel) {
            viewModel.referralToRemove = nil
          }
        },
        message: { contactToRemove in
          Text("Are you sure you want to remove the referral for \(contactToRemove.fullName)?")
        }
      )
      .alert("Error", isPresented: Binding(
        get: { viewModel.errorMessage != nil },
        set: { if !$0 { viewModel.errorMessage = nil } }
      )) {
        Button("OK") { viewModel.errorMessage = nil }
      } message: {
        if let errorMessage = viewModel.errorMessage {
          Text(errorMessage)
        }
      }
    }
  }
}

// MARK: - SwiftUI Preview

#Preview {
  ContactDetailsView(contactId: Contact.mock.id)
}
