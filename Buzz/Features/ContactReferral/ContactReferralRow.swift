import SwiftUI

struct ContactReferralRow: View {
  struct Configuration {
    let model: ContactReferralModel
    let onTap: () -> Void
    
    init(model: ContactReferralModel, onTap: @escaping () -> Void = {}) {
      self.model = model
      self.onTap = onTap
    }
  }
  
  let config: Configuration
  
  var body: some View {
    VStack(alignment: .leading, spacing: 4) {
      Text(config.model.contact.fullName)
        .font(.headline)
      
      if !config.model.contact.phoneNumbers.isEmpty {
        Text(config.model.contact.phoneNumbers[0])
          .font(.caption)
          .foregroundColor(.secondary)
      }
      
      if let referredBy = config.model.referredBy {
        HStack(spacing: 4) {
          Text("👋")  // Handwave emoji for "referred by"
          Text("Referred by: \(referredBy.fullName)")
        }
        .font(.subheadline)
        .foregroundColor(.secondary)
      }
      
      if !config.model.referredContacts.isEmpty {
        HStack(spacing: 4) {
          Text("🔄")  // Cycle emoji for "referrals"
          Text("Referrals: \(config.model.referredContacts.map(\.fullName).joined(separator: ", "))")
        }
        .font(.subheadline)
        .foregroundColor(.secondary)
      }
    }
    .padding(.vertical, 4)
    .onTapGesture(perform: config.onTap)
  }
}

#Preview("Contact Referral Scenarios") {
  // Sample contact data
  let contact1 = Contact(
    id: "1",
    givenName: "John",
    familyName: "Doe",
    phoneNumbers: ["+1 (555) 123-4567"],
    avatarData: nil
  )
  
  let contact2 = Contact(
    id: "2",
    givenName: "Jane",
    familyName: "Smith",
    phoneNumbers: ["+1 (555) 987-6543"],
    avatarData: nil
  )
  
  let contact3 = Contact(
    id: "3",
    givenName: "Bob",
    familyName: "Johnson",
    phoneNumbers: ["+1 (555) 246-8135"],
    avatarData: nil
  )
  
  // Sample referral models
  let noReferrals = ContactReferralModel(
    contact: contact1,
    referredBy: nil,
    referredContacts: []
  )
  
  let referredByOnly = ContactReferralModel(
    contact: contact2,
    referredBy: contact1,
    referredContacts: []
  )
  
  let referralsOnly = ContactReferralModel(
    contact: contact1,
    referredBy: nil,
    referredContacts: [contact2, contact3]
  )
  
  let bothReferrals = ContactReferralModel(
    contact: contact2,
    referredBy: contact1,
    referredContacts: [contact3]
  )
  
  return List {
    Section(header: Text("No Referrals")) {
      ContactReferralRow(config: .init(model: noReferrals))
    }
    
    Section(header: Text("Referred By Only")) {
      ContactReferralRow(config: .init(model: referredByOnly))
    }
    
    Section(header: Text("Referrals Only")) {
      ContactReferralRow(config: .init(model: referralsOnly))
    }
    
    Section(header: Text("Both Referral Types")) {
      ContactReferralRow(config: .init(model: bothReferrals))
    }
  }
}
