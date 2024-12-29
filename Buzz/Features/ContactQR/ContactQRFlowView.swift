import SwiftUI
import Dependencies

import SwiftUI
import Dependencies

struct ContactSearchView: View {
  let searchRequest: ContactSearchRequest
  
  @Dependency(\.contactReferralClient.search)
  private var search
  
  @State private var isLoading: Bool = true
  @State private var foundContact: ContactReferralModel?
  @State private var errorMessage: String?
  
  var body: some View {
    VStack {
      if isLoading {
        ProgressView("Searching for contact...")
      } else if let errorMessage = errorMessage {
        ErrorView(message: errorMessage)
      } else if let contact = foundContact {
        ContactDetailsView(contact: contact)
      }
    }
    .task {
      await performSearch()
    }
  }
  
  private func performSearch() async {
    print(searchRequest)
    isLoading = true
    do {
      foundContact = try await search(searchRequest).last
      if foundContact == nil {
        errorMessage = "No contact found for the given information."
      }
    } catch {
      errorMessage = "Failed to search for contact: \(error.localizedDescription)"
    }
    isLoading = false
  }
}

struct ErrorView: View {
  let message: String
  
  var body: some View {
    VStack {
      Image(systemName: "exclamationmark.triangle.fill")
        .font(.largeTitle)
      Text(message)
        .font(.headline)
        .multilineTextAlignment(.center)
        .padding()
      Button("Retry") {
        // Retry logic can be handled here or passed as a closure
      }
      .buttonStyle(.borderedProminent)
    }
    .padding()
  }
}

struct ContactActionView: View {
  let model: ContactReferralModel
  
  var body: some View {
    VStack(spacing: 20) {
      Text("Found Contact: \(model.contact.fullName)")
        .font(.title2)
        .multilineTextAlignment(.center)
        .padding()
      
      Button("Connect to Existing Contact") {
        // Logic for connecting to an existing contact
      }
      .buttonStyle(.borderedProminent)
      
      Button("Create New Contact") {
        // Logic for creating a new contact
      }
      .buttonStyle(.bordered)
    }
    .padding()
  }
}
