// ContactDetailsView.swift
import SwiftUI
import Observation

@Observable
final class ContactDetailsViewModel {
    let contact: ContactReferralModel
    var showingContactPicker = false
    var selectedReferrer: Contact?
    
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
}

struct ContactDetailsView: View {
    struct Configuration {
        let contact: ContactReferralModel
        let availableReferrers: [ContactReferralModel]
        let onUpdateReferral: (ContactReferralModel, Contact?) -> Void
        
        init(
            contact: ContactReferralModel,
            availableReferrers: [ContactReferralModel],
            onUpdateReferral: @escaping (ContactReferralModel, Contact?) -> Void
        ) {
            self.contact = contact
            self.availableReferrers = availableReferrers
            self.onUpdateReferral = onUpdateReferral
        }
    }
    
    let config: Configuration
    @State private var viewModel: ContactDetailsViewModel
    @Environment(\.dismiss) private var dismiss
    
    init(config: Configuration) {
        self.config = config
        self._viewModel = State(initialValue: ContactDetailsViewModel(contact: config.contact))
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section("Contact Details") {
                    Text("Name: \(viewModel.contact.contact.fullName)")
                    
                    if !viewModel.contact.contact.phoneNumbers.isEmpty {
                        ForEach(viewModel.contact.contact.phoneNumbers, id: \.self) { number in
                            Text("Phone: \(number)")
                        }
                    }
                }
                
                Section("Referrer") {
                    Button {
                        viewModel.showingContactPicker = true
                    } label: {
                        HStack {
                            Text("Referred By")
                            Spacer()
                            Text(viewModel.selectedReferrer?.fullName ?? viewModel.contact.referredBy?.fullName ?? "None")
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    if viewModel.canUpdateReferrer {
                        Button(viewModel.referrerActionTitle) {
                            config.onUpdateReferral(viewModel.contact, viewModel.selectedReferrer)
                            dismiss()
                        }
                        .foregroundColor(.accentColor)
                    }
                }
                
                if !viewModel.contact.referredContacts.isEmpty {
                    Section("Referrals Made") {
                        ForEach(viewModel.contact.referredContacts, id: \.id) { referredContact in
                            Text(referredContact.fullName)
                        }
                    }
                }
            }
            .navigationTitle("Contact Details")
            .navigationBarItems(trailing: Button("Done") { dismiss() })
            .sheet(isPresented: $viewModel.showingContactPicker) {
                ContactPickerView(config: .init(
                    contacts: config.availableReferrers,
                    selectedContactId: viewModel.selectedReferrer?.id ?? viewModel.contact.referredBy?.id,
                    excludeContactId: viewModel.contact.id, onSelect: { selected in
                      viewModel.selectedReferrer = selected
                    }
                ))
            }
        }
    }
}
