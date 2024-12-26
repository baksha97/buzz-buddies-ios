import SwiftUI
import Observation
import Dependencies
import CasePaths

@Observable
final class ContactDetailsViewModel {
    @ObservationIgnored
    @Dependency(\.contactReferralClient) private var client
    
    let contact: ContactReferralModel
    var showingContactPicker = false
    var selectedReferrer: Contact?
    var errorMessage: String?
    var isLoading = false
    private(set) var availableContacts: [ContactReferralModel] = []
    
    init(contact: ContactReferralModel) {
        self.contact = contact
        self.selectedReferrer = contact.referredBy
    }
    
    var canUpdateReferrer: Bool {
        selectedReferrer?.id != contact.referredBy?.id
    }
    
    var referrerActionTitle: String {
        contact.referredBy == nil ? "Add Referrer" : "Update Referrer"
    }
    
    @MainActor
    func updateReferral() async {
        isLoading = true
        do {
            if contact.referredBy == nil {
                try await client.createReferral(contact.contact.id, selectedReferrer?.id)
            } else {
                try await client.updateReferral(contact.contact.id, selectedReferrer?.id)
            }
            isLoading = false
        } catch {
            isLoading = false
            errorMessage = "Failed to update referral: \(error.localizedDescription)"
        }
    }
    
    @MainActor
    func fetchAvailableReferrers() async {
        do {
            availableContacts = try await client.fetchContacts()
        } catch {
            errorMessage = "Failed to fetch referrers: \(error.localizedDescription)"
            availableContacts = []
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
            .sheet(isPresented: $viewModel.showingContactPicker) {
                contactPickerView
            }
            .alert("Error", isPresented: .init(
                get: { viewModel.errorMessage != nil },
                set: { if !$0 { viewModel.errorMessage = nil } }
            )) {
                Button("OK") { viewModel.errorMessage = nil }
            } message: {
                if let errorMessage = viewModel.errorMessage {
                    Text(errorMessage)
                }
            }
        }.task {
              await viewModel.fetchAvailableReferrers()
        }
    }
    
    @ViewBuilder
    private var mainContent: some View {
        Form {
            contactDetailsSection
            referrerSection
            if !viewModel.contact.referredContacts.isEmpty {
                referralsMadeSection
            }
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
    private var referrerButton: some View {
        Button {
            viewModel.showingContactPicker = true
        } label: {
            HStack {
                Text("Referred By")
                Spacer()
                Text(viewModel.selectedReferrer?.fullName ??
                     viewModel.contact.referredBy?.fullName ?? "None")
                    .foregroundColor(.secondary)
            }
        }
    }
    
    @ViewBuilder
    private var updateReferrerButton: some View {
        Button(viewModel.referrerActionTitle) {
            Task {
                await viewModel.updateReferral()
                dismiss()
            }
        }
        .foregroundColor(.accentColor)
        .disabled(viewModel.isLoading)
    }
    
    @ViewBuilder
    private var referralsMadeSection: some View {
        Section("Referrals Made") {
            ForEach(viewModel.contact.referredContacts, id: \.id) { referredContact in
                Text(referredContact.fullName)
            }
        }
    }
    
    @ViewBuilder
    private var contactPickerView: some View {
        ContactPickerView(config: .init(
            contacts: viewModel.availableContacts,
            selectedContactId: viewModel.selectedReferrer?.id ?? viewModel.contact.referredBy?.id,
            excludeContactId: viewModel.contact.contact.id,
            onSelect: { selected in
                viewModel.selectedReferrer = selected
            }
        ))
    }
}

#Preview {
    ContactDetailsView(contact: .mock)
}
