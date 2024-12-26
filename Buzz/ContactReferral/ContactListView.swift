//
//  ContactListView.swift
//  Buzz
//
//  Created by Travis Baksh on 12/26/24.
//


// ContactListView.swift
import SwiftUI
import SwiftNavigation
import SwiftUINavigation

struct ContactListView: View {
    @State private var viewModel = ContactReferralViewModel()
    
    var body: some View {
        ZStack {
            List {
                contactsSection
            }
            .searchable(text: $viewModel.searchText, prompt: "Search contacts")
            
            floatingActionButton
        }
        .sheet(isPresented: Binding($viewModel.destination.addContact)) {
            AddContactView(config: .init(
                availableReferrers: viewModel.availableReferrers,
                onAdd: { contact in
                    Task {
                        await viewModel.addContact(contact)
                    }
                }
            ))
        }
        .sheet(item: $viewModel.destination.contactDetails) { contact in
            ContactDetailsView(config: .init(
                contact: contact,
                availableReferrers: viewModel.availableReferrers,
                onUpdateReferral: { contact, referrer in
                    Task {
                        if contact.referredBy == nil {
                            await viewModel.createReferral(contact: contact, referredBy: referrer)
                        } else {
                            await viewModel.updateExistingReferral(model: contact, referredBy: referrer)
                        }
                    }
                }
            ))
        }
        .alert("Error", isPresented: .init(
            get: { viewModel.errorMessage != nil },
            set: { if !$0 { viewModel.viewState = .loaded } }
        )) {
            Button("OK") { viewModel.viewState = .loaded }
        } message: {
            Text(viewModel.errorMessage ?? "")
        }
        .task {
            await viewModel.initialize()
        }
        .refreshable {
            await viewModel.refreshData()
        }
    }
    
    private var contactsSection: some View {
        Section("All Contacts") {
            ForEach(viewModel.filteredContacts) { contact in
                ContactReferralRow(config: .init(
                    model: contact,
                    onTap: {
                        viewModel.showDetails(for: contact)
                    }
                ))
            }
        }
    }
    
    private var floatingActionButton: some View {
        VStack {
            Spacer()
            HStack {
                Spacer()
                Button {
                    viewModel.showAddContact()
                } label: {
                    Image(systemName: "person.badge.plus")
                        .font(.title2)
                        .foregroundColor(.white)
                        .padding(20)
                        .background(Color.accentColor)
                        .clipShape(Circle())
                        .shadow(radius: 4, y: 2)
                }
                .padding([.trailing, .bottom], 20)
            }
        }
    }
}

#Preview {
    NavigationView {
        ContactListView()
    }
}
