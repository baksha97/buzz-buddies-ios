import SwiftUI
import Dependencies
import Foundation

/// A SwiftUI View to test ReferralRecordClient behavior
struct ReferralRecordTestView: View {
  @State private var log: [String] = []
  @State private var selectedContactUUID: UUID? = nil
  
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
        
        Button("Fetch Referral with Relationships") {
          fetchReferralWithRelationships()
        }
        .buttonStyle(.bordered)
        
        if let selectedUUID = selectedContactUUID {
          Text("Selected Contact UUID: \(selectedUUID.uuidString)")
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
        let rootReferrer = ReferralRecord(contactUUID: UUID())
        try await client.createRecord(rootReferrer)
        log.append("✅ Saved root referral: \(rootReferrer.contactUUID)")
        
        selectedContactUUID = rootReferrer.contactUUID
        // Create first-level referrals
        let firstReferral = ReferralRecord(contactUUID: UUID(), referredByUUID: rootReferrer.contactUUID)
        let secondReferral = ReferralRecord(contactUUID: UUID(), referredByUUID: rootReferrer.contactUUID)
        try await client.createRecord(firstReferral)
        try await client.createRecord(secondReferral)
        log.append("✅ Saved first-level referrals: \(firstReferral.contactUUID), \(secondReferral.contactUUID)")
        
        // Create a nested referral
        let nestedReferral = ReferralRecord(contactUUID: UUID(), referredByUUID: firstReferral.contactUUID)
        try await client.createRecord(nestedReferral)
        log.append("✅ Saved nested referral: \(nestedReferral.contactUUID)")
        
        log.append("ℹ️ Root referral UUID selected for testing.")
      } catch {
        log.append("❌ Failed to save referrals: \(error.localizedDescription)")
      }
    }
  }
  
  
  private func fetchReferralWithRelationships() {
    guard let selectedUUID = selectedContactUUID else {
      log.append("⚠️ No contact UUID selected for testing.")
      return
    }
    
    Task {
      do {
        let (referrer, referredContacts) = try await client.fetchReferralWithRelationships(selectedUUID)
        
        if let referrer {
          log.append("🧩 Referrer UUID: \(referrer.contactUUID)")
        } else {
          log.append("ℹ️ No referrer found for this contact.")
        }
        
        log.append("📊 Found \(referredContacts.count) referred contacts:")
        referredContacts.forEach { child in
          log.append("➡️ Child Referral UUID: \(child.contactUUID)")
        }
      } catch {
        log.append("❌ Failed to fetch referral with relationships: \(error.localizedDescription)")
        print(error.localizedDescription)
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
