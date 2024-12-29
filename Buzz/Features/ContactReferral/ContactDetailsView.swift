import SwiftUI
import Observation
import Dependencies
import CasePaths
import SwiftUINavigation

struct ContactDetailFormState {
  var referredBy: Contact?
  var referrals: [Contact]
}

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
  
  // MARK: - Form State
  var formState: ContactDetailFormState = .init(referrals: [])
  
  // MARK: - Navigation (Sheets & Confirmation Dialog)
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
  
  /// True if we have a loaded contact and our form's `referredBy` is different than the loaded state's `referredBy`.
  var canUpdateReferrer: Bool {
    guard case let .loaded(contact) = viewState else { return false }
    return formState.referredBy?.id != contact.referredBy?.id
  }
  
  var referrerActionTitle: String {
    guard case let .loaded(contact) = viewState else { return "" }
    return contact.referredBy == nil ? "Add Referrer" : "Update Referrer"
  }
  
  var referrerIdExclusions: [Contact.ContactListIdentifier] {
    guard case let .loaded(contact) = viewState else { return [] }
    return [contact.contact.id] + contact.referredContacts.map(\.id)
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
  
  /// Create or update the current contact's referrer
  func updateReferral() {
    Task {
      await performAction {
        guard case let .loaded(contact) = self.viewState else { return }
        if contact.referredBy == nil {
          try await client.createReferral(contact.contact.id, formState.referredBy?.id)
        } else {
          try await client.updateReferral(contact.contact.id, formState.referredBy?.id)
        }
      }
    }
  }
  
  /// Refer another contact
  func referContact(_ contactId: String) {
    Task {
      await performAction {
        guard case let .loaded(contact) = self.viewState else { return }
        try await client.createReferral(contactId, contact.contact.id)
      }
    }
  }
  
  /// Called when a user taps the "X" next to a referred contact
  /// -> set that contact to `referralToRemove` so the confirmation dialog appears.
  func requestRemoveReferral(for contact: Contact) {
    referralToRemove = contact
  }
  
  /// Called after the user confirms removal in the dialog
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
  
  /// Observe changes to the contact
  private func startObservingContact() {
    observationTask = Task { [id = self.id] in
      isObserving = true
      viewState = .loading
      errorMessage = nil
      do {
        for try await updatedContact in client.observe(id) {
          self.formState.referredBy = updatedContact.referredBy
          self.formState.referrals = updatedContact.referredContacts
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

// MARK: - SwiftUI View

struct ContactDetailsView: View {
  @State private var viewModel: ContactDetailsViewModel
  @Environment(\.dismiss) private var dismiss
  
  init(contactId: Contact.ContactListIdentifier) {
    _viewModel = State(initialValue: ContactDetailsViewModel(contactId: contactId))
  }
  
  var body: some View {
    NavigationView {
      ZStack {
        mainContent
        if viewModel.isLoading {
          ProgressView()
        }
      }
      .navigationTitle("Contact Details")
      .navigationBarItems(trailing: Button("Done") { dismiss() })
      
      // MARK: Sheets
      .sheet(isPresented: Binding($viewModel.contactPickerDestination.referrer)) {
        ContactPickerView(
          selectedContact: viewModel.formState.referredBy?.id,
          exclusions: viewModel.referrerIdExclusions
        ) { selected in
          viewModel.formState.referredBy = selected
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
      
      // MARK: Confirmation Dialog
      .confirmationDialog(
        item: $viewModel.referralToRemove,
        titleVisibility: .hidden,
        title: { Text("Removing \($0.fullName)") },
        actions: { contact in
          Button("Remove \(contact.fullName)", role: .destructive) {
            viewModel.confirmRemoveReferral(for: contact.id)
          }
          Button("Cancel", role: .cancel) {
            viewModel.referralToRemove = nil
          }
        },
        message: { contact in
          Text("Are you sure you want to remove the referral for \(contact.fullName)?")
        }
      )
      
      // MARK: Error Alert
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
      .task {
        await viewModel.initialize()
      }
    }
  }
  
  // MARK: - Main Content
  
  @ViewBuilder
  private var mainContent: some View {
    VStack {
      Form {
        contactDetailsSection
        referrerSection
        referContactsSection
      }
      if case let .loaded(contact) = viewModel.viewState {
        ContactReferralQRView(contact: contact.contact)
      }
    }
  }
  
  @ViewBuilder
  private var contactDetailsSection: some View {
    Section("Contact Details") {
      if case let .loaded(contact) = viewModel.viewState {
        Text("Name: \(contact.contact.fullName)")
        
        if !contact.contact.phoneNumbers.isEmpty {
          ForEach(contact.contact.phoneNumbers, id: \.self) { number in
            Text("Phone: \(number)")
          }
        }
      }
    }
  }
  
  @ViewBuilder
  private var referrerSection: some View {
    Section("Referrer") {
      Button {
        viewModel.contactPickerDestination = .referrer
      } label: {
        HStack {
          Text("Referred By")
          Spacer()
          Text(viewModel.formState.referredBy?.fullName ?? "None")
            .foregroundColor(.secondary)
        }
      }
      if viewModel.canUpdateReferrer {
        Button(viewModel.referrerActionTitle) {
          viewModel.updateReferral()
          dismiss()
        }
        .foregroundColor(.accentColor)
        .disabled(viewModel.isLoading)
      }
    }
  }
  
  @ViewBuilder
  private var referContactsSection: some View {
    Section("Refer Contacts") {
      Button("Add Referral") {
        viewModel.contactPickerDestination = .refer
      }
      if !viewModel.formState.referrals.isEmpty {
        ForEach(viewModel.formState.referrals, id: \.id) { referredContact in
          HStack {
            Text(referredContact.fullName)
            Spacer()
            Text("Referred")
              .foregroundColor(.secondary)
            Button {
              viewModel.requestRemoveReferral(for: referredContact)
            } label: {
              Image(systemName: "xmark")
                .font(.system(size: 12))
                .background(Color.red.opacity(0.1))
                .foregroundColor(.red)
            }
          }
        }
      } else {
        Text("No referrals made yet")
          .foregroundColor(.secondary)
      }
    }
  }
}

// MARK: - SwiftUI Preview

#Preview {
  ContactDetailsView(contactId: Contact.mock.id)
}
