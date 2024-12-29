// AddContactViewModel.swift
import SwiftUI
import Dependencies
import Observation
import CasePaths

@Observable
final class AddContactViewModel {
  @ObservationIgnored
  @Dependency(\.contactReferralClient.addContact)
  private var addContact
  
  // MARK: - State
  @CasePathable
  enum ViewState {
    case editing
    case loading
    case error(String)
  }
  
  var viewState: ViewState = .editing
  var givenName = ""
  var familyName = ""
  var phoneNumber = ""
  var additionalPhoneNumbers: [String] = []
  var showingContactPicker = false
  var selectedReferrer: Contact?
  
  // MARK: - Computed Properties
  var isValid: Bool {
    !givenName.isEmpty && !familyName.isEmpty && !phoneNumber.isEmpty
  }
  
  var errorMessage: String? {
    if case let .error(message) = viewState { return message }
    return nil
  }
  
  var isLoading: Bool {
    if case .loading = viewState { return true }
    return false
  }
  
  // MARK: - Actions
  @MainActor
  func addContact() async throws {
    let request = createRequest()
    await performAction {
      try await addContact(request)
    }
  }
  
  // MARK: - Private Helpers
  private func createRequest() -> ContactReferralClientCreateRequest {
    var allPhoneNumbers = [phoneNumber]
    allPhoneNumbers.append(contentsOf: additionalPhoneNumbers.filter { !$0.isEmpty })
    
    return ContactReferralClientCreateRequest(
      givenName: givenName,
      familyName: familyName,
      phoneNumbers: allPhoneNumbers,
      referredBy: selectedReferrer
    )
  }
  
  @MainActor
  private func performAction(_ action: () async throws -> Void) async {
    viewState = .loading
    do {
      try await action()
      viewState = .editing
    } catch {
      viewState = .error("Failed to add contact: \(error.localizedDescription)")
    }
  }
}

// AddContactView.swift
import SwiftUI
import Dependencies

struct AddContactView: View {
  @State private var viewModel = AddContactViewModel()
  @Environment(\.dismiss) private var dismiss
  
  var onSuccess: (() -> Void)? = nil
  
  var body: some View {
    NavigationView {
      FormContent(
        viewModel: viewModel,
        onSuccess: onSuccess,
        dismiss: dismiss
      )
      .navigationTitle("Add Contact")
      .navigationBarItems(
        trailing: Button("Cancel") { dismiss() }
      )
    }
  }
}

// MARK: - Subviews
private struct FormContent: View {
  @State var viewModel: AddContactViewModel
  let onSuccess: (() -> Void)?
  let dismiss: DismissAction
  
  var body: some View {
    Form {
      NameSection(viewModel: viewModel)
      PhoneNumbersSection(viewModel: viewModel)
      ReferrerSection(viewModel: viewModel)
      AddButtonSection(
        viewModel: viewModel,
        onSuccess: onSuccess,
        dismiss: dismiss
      )
    }
    .contactPickerSheet(
      isPresented: $viewModel.showingContactPicker,
      viewModel: viewModel
    )
    .errorAlert(viewModel: viewModel)
    .disabled(viewModel.isLoading)
    .overlay {
      if viewModel.isLoading {
        ProgressView()
      }
    }
  }
}

private struct NameSection: View {
  @State var viewModel: AddContactViewModel
  
  var body: some View {
    Section(header: Text("Name")) {
      TextField("Given Name", text: $viewModel.givenName)
      TextField("Family Name", text: $viewModel.familyName)
    }
  }
}

private struct PhoneNumbersSection: View {
  @State var viewModel: AddContactViewModel
  
  var body: some View {
    Section(header: Text("Phone Numbers")) {
      TextField("Primary Phone Number", text: $viewModel.phoneNumber)
      
      ForEach(viewModel.additionalPhoneNumbers.indices, id: \.self) { index in
        TextField("Additional Phone", text: $viewModel.additionalPhoneNumbers[index])
      }
      
      Button("Add Phone Number") {
        viewModel.additionalPhoneNumbers.append("")
      }
    }
  }
}

private struct ReferrerSection: View {
  @State var viewModel: AddContactViewModel
  
  var body: some View {
    Section("Referrer") {
      Button {
        viewModel.showingContactPicker = true
      } label: {
        HStack {
          Text("Referred By")
          Spacer()
          Text(viewModel.selectedReferrer?.fullName ?? "None")
            .foregroundColor(.secondary)
        }
      }
    }
  }
}

private struct AddButtonSection: View {
  @State var viewModel: AddContactViewModel
  let onSuccess: (() -> Void)?
  let dismiss: DismissAction
  
  var body: some View {
    Section {
      Button("Add Contact") {
        Task {
          try? await viewModel.addContact()
          onSuccess?()
          dismiss()
        }
      }
      .disabled(!viewModel.isValid || viewModel.isLoading)
    }
  }
}

// MARK: - View Modifiers
private extension View {
  func contactPickerSheet(
    isPresented: Binding<Bool>,
    viewModel: AddContactViewModel
  ) -> some View {
    sheet(isPresented: isPresented) {
      ContactPickerView(
        selectedContact: viewModel.selectedReferrer?.id,
        exclusions: [],
        onSelect: { selected in
          viewModel.selectedReferrer = selected
        }
      )
    }
  }
  
  func errorAlert(viewModel: AddContactViewModel) -> some View {
    alert("Error", isPresented: .init(
      get: { viewModel.errorMessage != nil },
      set: { if !$0 { viewModel.viewState = .editing } }
    )) {
      Button("OK") { viewModel.viewState = .editing }
    } message: {
      Text(viewModel.errorMessage ?? "")
    }
  }
}
