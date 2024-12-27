import Foundation
import SwiftData
import SwiftUI
import Observation

import GRDB
import Foundation

/// A Contact Referral Record stored in the database
public struct ReferralRecord: Codable, Sendable {
  public var contactId: Contact.ContactListIdentifier
  public var referredById: Contact.ContactListIdentifier?  // Optional UUID for the referrer
  
  // Database initializer
  public init(
    contactUUID: Contact.ContactListIdentifier,
    referredByUUID: Contact.ContactListIdentifier? = nil
  ) {
    self.contactId = contactUUID
    self.referredById = referredByUUID
  }
}

extension ReferralRecord: Identifiable {
  public var id: Contact.ContactListIdentifier {
    contactId
  }
}

//extension BelongsToAssociation: @unchecked @retroactive Sendable {}
//extension HasManyAssociation: @unchecked @retroactive Sendable {}

extension ReferralRecord: FetchableRecord, PersistableRecord {
  /// Database Table Name
  public static let databaseTableName = "contact_referral_records"
  
  /// Columns Enum
  public enum Columns {
    public static let contactUUID = Column("contactId")
    public static let referredByUUID = Column("referredById")
  }
  
  /// Table Creation
  public static func createTable(_ db: Database) throws {
    try db.create(table: databaseTableName, ifNotExists: true) { t in
      t.column("contactId", .text)
        .notNull()
        .unique()
        .primaryKey()
      t.column("referredById", .text)
    }
  }
}
