//
//  ContactReferralRow.swift
//  Buzz
//
//  Created by Travis Baksh on 12/26/24.
//


// ContactReferralRow.swift
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
                Text("Referred by: \(referredBy.fullName)")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            if !config.model.referredContacts.isEmpty {
                Text("Referrals: \(config.model.referredContacts.map(\.fullName).joined(separator: ", "))")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 4)
        .onTapGesture(perform: config.onTap)
    }
}