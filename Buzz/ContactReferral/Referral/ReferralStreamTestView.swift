import Foundation
import GRDB
import Dependencies
import DependenciesMacros
import SwiftUI
import Dependencies

struct ReferralStreamTestView: View {
  @Dependency(\.referralRecordClient) var referralClient
  
  let contactUUID: Contact.ContactListIdentifier
  
  @State private var referral: ReferralRecord?
  @State private var referredContacts: [ReferralRecord] = []
  
  var body: some View {
    VStack(alignment: .leading, spacing: 20) {
      // Current referral info
      Group {
        Text("Current Referral")
          .font(.headline)
        
        if let referral {
          Text("Contact: \(referral.contactId)")
          if let referredBy = referral.referredById {
            Text("Referred by: \(referredBy)")
          }
        } else {
          Text("No referral found")
            .foregroundColor(.secondary)
        }
      }
      
      Divider()
      
      // Referred contacts
      Group {
        Text("Referred Contacts")
          .font(.headline)
        
        if referredContacts.isEmpty {
          Text("No contacts referred")
            .foregroundColor(.secondary)
        } else {
          ForEach(referredContacts, id: \.contactId) { contact in
            Text(contact.contactId)
          }
        }
      }
      
      Spacer()
      
      // Test buttons
      VStack {
        Button("Add Test Referral") {
          Task {
            let newReferral = ReferralRecord(
              contactUUID: contactUUID,
              referredByUUID: nil
            )
            try await referralClient.createRecord(newReferral)
          }
        }
        
        Button("Add Referred Contact") {
          Task {
            let referred = ReferralRecord(
              contactUUID: UUID().uuidString,
              referredByUUID: contactUUID
            )
            try await referralClient.createRecord(referred)
          }
        }
      }
    }
    .padding()
    .task {
      // Start streaming updates
      do {
        for try await (newReferral, newReferredContacts) in referralClient.observeRecordWithReferred(contactUUID: contactUUID) {
          print("New val observed")
          referral = newReferral
          referredContacts = newReferredContacts
        }
      } catch {
        print("Error occuring watching stream: \(error)")
      }
    }
  }
}

#Preview {
  ReferralStreamTestView(contactUUID: "test-contact-123")
}
