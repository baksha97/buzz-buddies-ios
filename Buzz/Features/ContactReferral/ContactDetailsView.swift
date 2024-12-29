import SwiftUI
import Observation
import Dependencies
import CasePaths


struct ContactDetailFormState {
  var referredBy: Contact?
  var referrals: [Contact]
}

@MainActor
@Observable
final class ContactDetailsViewModel {
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
  enum ContactPickerSheetDestination {
    case referrer
    case refer
  }
  
  var contact: ContactReferralModel
  var viewState: ViewState = .loading
  var formState: ContactDetailFormState = .init(referrals: [])
  var contactPickerDestination: ContactPickerSheetDestination? = nil
  
  private var observationTask: Task<Void, Never>?
  
  init(contact: ContactReferralModel) {
    self.contact = contact
  }
  
  // MARK: - Public Interface
  var errorMessage: String? {
    if case let .error(message) = viewState { return message }
    return nil
  }
  
  var isLoading: Bool {
    if case .loading = viewState { return true }
    return false
  }
  
  var canUpdateReferrer: Bool {
    formState.referredBy?.id != contact.referredBy?.id
  }
  
  var referrerActionTitle: String {
    contact.referredBy == nil ? "Add Referrer" : "Update Referrer"
  }
  
  var referrerIdExclusions: [Contact.ContactListIdentifier] {
    [contact.contact.id] + contact.referredContacts.map(\.id)
  }
  
  // MARK: - Actions
  @MainActor
  func initialize() async {
    startObservingContact()
  }
  
  func updateReferral() {
    Task {
      await performAction {
        if contact.referredBy == nil {
          try await client.createReferral(contact.contact.id, formState.referredBy?.id)
        } else {
          try await client.updateReferral(contact.contact.id, formState.referredBy?.id)
        }
      }
    }
  }
  
  func referContact(_ contactId: String) {
    Task {
      await performAction {
        try await client.createReferral(contactId, contact.contact.id)
      }
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
  
  // MARK: - Observation
  private func startObservingContact() {
    observationTask = Task { [id = contact.contact.id] in
      viewState = .loading
      do {
        for try await updatedContact in client.observe(id) {
          self.contact = updatedContact
          self.formState.referredBy = updatedContact.referredBy
          self.formState.referrals = updatedContact.referredContacts
          self.viewState = .loaded
        }
      } catch {
        viewState = .error("Failed to observe contact updates: \(error.localizedDescription)")
      }
    }
  }
}

struct ContactDetailsView: View {
  @State private var viewModel: ContactDetailsViewModel
  @Environment(\.dismiss) private var dismiss
  
  init(contact: ContactReferralModel) {
    _viewModel = State(initialValue: ContactDetailsViewModel(contact: contact))
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
      .sheet(isPresented: Binding($viewModel.contactPickerDestination.referrer)) {
        ContactPickerView(
          selectedContact: viewModel.formState.referredBy?.id ?? viewModel.contact.referredBy?.id,
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
        .alert("Error", isPresented: .init(
          get: { viewModel.errorMessage != nil },
          set: { if !$0 { viewModel.viewState = .loaded } }
        )) {
          Button("OK") { viewModel.viewState = .loaded }
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
    
    @ViewBuilder
    private var mainContent: some View {
      VStack {
        Form {
          contactDetailsSection
          referrerSection
          referContactsSection
        }
        ContactReferralQRView(contact: viewModel.contact.contact)
      }
    }
    
    @ViewBuilder
    private var contactDetailsSection: some View {
      Section("Contact Details") {
        Text("Name: \(viewModel.contact.contact.fullName)")
        
        if !viewModel.contact.contact.phoneNumbers.isEmpty {
          ForEach(viewModel.contact.contact.phoneNumbers, id: \.self) { number in
            Text("Phone: \(number)")
          }
        }
      }
    }
    
    @ViewBuilder
    private var referrerSection: some View {
      Section("Referrer") {
        referrerButton
        if viewModel.canUpdateReferrer {
          updateReferrerButton
        }
      }
    }
    
    @ViewBuilder
    private var updateReferrerButton: some View {
      Button(viewModel.referrerActionTitle) {
        viewModel.updateReferral()
        dismiss()
      }
      .foregroundColor(.accentColor)
      .disabled(viewModel.isLoading)
    }
    
    
    @ViewBuilder
    private var referrerButton: some View {
      Button {
        viewModel.contactPickerDestination = .referrer
      } label: {
        HStack {
          Text("Referred By")
          Spacer()
          Text(viewModel.formState.referredBy?.fullName ??
               viewModel.contact.referredBy?.fullName ?? "None")
          .foregroundColor(.secondary)
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
            }
          }
        } else {
          Text("No referrals made yet")
            .foregroundColor(.secondary)
        }
      }
    }
  }
  
  #Preview {
    ContactDetailsView(contact: .mock)
  }
