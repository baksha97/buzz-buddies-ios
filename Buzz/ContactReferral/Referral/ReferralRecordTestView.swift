import SwiftUI
import Dependencies
import Foundation

/// A SwiftUI View to test ReferralRecordClient behavior
struct ReferralRecordTestView: View {
  @State private var log: [String] = []
  @State private var selectedContactUUID: Contact.ContactListIdentifier? = nil
  
  @Dependency(\.referralRecordClient) private var client
  
  var body: some View {
    NavigationView {
      VStack(alignment: .leading, spacing: 16) {
        Text("Referral Record Test View")
          .font(.title)
          .bold()
        
        ScrollView {
          VStack(alignment: .leading) {
            ForEach(log, id: \.self) { entry in
              Text(entry)
                .font(.system(size: 12))
                .foregroundColor(.secondary)
                .padding(.vertical, 1)
                .textSelection(.enabled) // Enable text selection
              
            }
          }
        }
        .frame(maxHeight: 300)
        .border(Color.gray.opacity(0.2))
                
        Button("Add Mock Referrals") {
          addMockReferrals()
        }
        .buttonStyle(.bordered)
        
        if let selectedUUID = selectedContactUUID {
          Text("Selected Contact UUID: \(selectedUUID)")
            .font(.caption)
            .foregroundColor(.blue)
            .padding(.top, 8)
        }
        
        Spacer()
      }
      .padding()
      .navigationTitle("Referral Test")
    }
  }
}

// MARK: - Actions

extension ReferralRecordTestView {
  
  private func addMockReferrals() {
    Task {
      do {
        // Create a root referrer first
        let rootReferrer = ReferralRecord(contactUUID: "root")
        try await client.createRecord(rootReferrer)
        log.append("✅ Saved root referral: \(rootReferrer.contactId)")
        
        selectedContactUUID = rootReferrer.contactId
        // Create first-level referrals
        let firstReferral = ReferralRecord(contactUUID: "first", referredByUUID: rootReferrer.contactId)
        let secondReferral = ReferralRecord(contactUUID: "second", referredByUUID: rootReferrer.contactId)
        try await client.createRecord(firstReferral)
        try await client.createRecord(secondReferral)
        log.append("✅ Saved first-level referrals: \(firstReferral.contactId), \(secondReferral.contactId)")
        
        // Create a nested referral
        let nestedReferral = ReferralRecord(contactUUID: "nestedReferral", referredByUUID: firstReferral.contactId)
        try await client.createRecord(nestedReferral)
        log.append("✅ Saved nested referral: \(nestedReferral.contactId)")
        
        log.append("ℹ️ Root referral UUID selected for testing.")
      } catch {
        log.append("❌ Failed to save referrals: \(error.localizedDescription)")
      }
    }
  }
}

// MARK: - Preview

struct ReferralRecordTestView_Previews: PreviewProvider {
  static var previews: some View {
    ReferralRecordTestView()
  }
}
