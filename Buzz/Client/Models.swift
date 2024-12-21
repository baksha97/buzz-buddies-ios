import Foundation
import SwiftData
import SwiftUI
import Observation

// MARK: - Models

@Model
final class Client {
    @Attribute(.unique)
    var id: String
    var name: String
    var phoneNumber: String
    var created: Date
    var referred: [Client]

    @Relationship(inverse: \Client.referred)
    var referredBy: Client?
    @Relationship(deleteRule: .cascade, inverse: \Reward.client)
    var rewards: [Reward]

    init(id: UUID = UUID(), name: String, phoneNumber: String, referredBy: Client? = nil) {
        self.id = id.uuidString
        self.name = name
        self.phoneNumber = phoneNumber
        self.referredBy = referredBy
        self.created = Date()
        self.referred = []
        self.rewards = []
    }
}

@Model
final class Reward {

    @Attribute(.unique)
    var id: String
    var client: Client?
    var created: Date
    var claimed: Date?
    var notes: String
    var referralsConsumed: Int

    init(id: UUID = UUID(), client: Client, notes: String = "", referralsConsumed: Int = 0) {
        self.id = id.uuidString
        self.client = client
        self.created = Date()
        self.notes = notes
        self.referralsConsumed = referralsConsumed
    }
}

extension Client {
  static var mock: Self {
    .init(id: UUID(), name: "John Doe", phoneNumber: "+123456789")
  }
}
