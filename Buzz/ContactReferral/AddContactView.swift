//
//  AddContactViewModel.swift
//  Buzz
//
//  Created by Travis Baksh on 12/26/24.
//


// AddContactView.swift
import SwiftUI
import Observation

@Observable
final class AddContactViewModel {
    var givenName = ""
    var familyName = ""
    var phoneNumber = ""
    var additionalPhoneNumbers: [String] = []
    var showingContactPicker = false
    var selectedReferrer: Contact?
    
    var isValid: Bool {
        !givenName.isEmpty && !familyName.isEmpty && !phoneNumber.isEmpty
    }
    
    func createRequest() -> ContactReferralClientCreateRequest {
        var allPhoneNumbers = [phoneNumber]
        allPhoneNumbers.append(contentsOf: additionalPhoneNumbers.filter { !$0.isEmpty })
        
        return ContactReferralClientCreateRequest(
            givenName: givenName,
            familyName: familyName,
            phoneNumbers: allPhoneNumbers,
            referredBy: selectedReferrer
        )
    }
}

struct AddContactView: View {
    struct Configuration {
        let availableReferrers: [ContactReferralModel]
        let onAdd: (ContactReferralClientCreateRequest) async -> Void
        
        init(
            availableReferrers: [ContactReferralModel],
            onAdd: @escaping (ContactReferralClientCreateRequest) async -> Void
        ) {
            self.availableReferrers = availableReferrers
            self.onAdd = onAdd
        }
    }
    
    let config: Configuration
    @State private var viewModel = AddContactViewModel()
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Name")) {
                    TextField("Given Name", text: $viewModel.givenName)
                    TextField("Family Name", text: $viewModel.familyName)
                }
                
                Section(header: Text("Phone Numbers")) {
                    TextField("Primary Phone Number", text: $viewModel.phoneNumber)
                    
                    ForEach(viewModel.additionalPhoneNumbers.indices, id: \.self) { index in
                        TextField("Additional Phone", text: $viewModel.additionalPhoneNumbers[index])
                    }
                    
                    Button("Add Phone Number") {
                        viewModel.additionalPhoneNumbers.append("")
                    }
                }
                
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
                
                Button("Add Contact") {
                    Task {
                        await config.onAdd(viewModel.createRequest())
                        dismiss()
                    }
                }
                .disabled(!viewModel.isValid)
            }
            .navigationTitle("Add Contact")
            .navigationBarItems(
                trailing: Button("Cancel") { dismiss() }
            )
            .sheet(isPresented: $viewModel.showingContactPicker) {
                ContactPickerView(config: .init(
                    contacts: config.availableReferrers,
                    selectedContactId: viewModel.selectedReferrer?.id,
                    onSelect: { selected in
                        viewModel.selectedReferrer = selected
                    }
                ))
            }
        }
    }
}