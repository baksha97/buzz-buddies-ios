import Foundation
import GRDB
import Dependencies
import DependenciesMacros

/// A client to manage ReferralRecord persistence operations.
@DependencyClient
public struct ReferralRecordClient: Sendable {
  //  public var setupDatabase: @Sendable () throws -> Void
  public var createRecord: @Sendable (_ referral: ReferralRecord) async throws -> Void
  public var updateRecord: @Sendable (_ referral: ReferralRecord) async throws -> Void
  public var fetchRecord: @Sendable (_ contactUUID: Contact.ContactListIdentifier) async throws -> ReferralRecord?
  public var fetchAllRecords: @Sendable () async throws -> [ReferralRecord]
  public var fetchReferrer: @Sendable (_ contactUUID: Contact.ContactListIdentifier) async throws -> ReferralRecord?
  public var fetchReferredContacts: @Sendable (_ contactUUID: Contact.ContactListIdentifier) async throws -> [ReferralRecord]
  public var deleteRecord: @Sendable (_ referral: ReferralRecord) async throws-> Bool
  public var deleteDatabase: @Sendable () async throws -> Void
  public var observeRecordWithReferred: @Sendable (_ contactUUID: Contact.ContactListIdentifier) -> AsyncThrowingStream<(ReferralRecord?, [ReferralRecord]), Error> = { _ in .finished() }
  
  public enum Failure: LocalizedError {
    case saveFailed
    case fetchFailed
    case notFound
    case deleteFailed
    case hasExistingRecordForContact
    case hasMissingRecordForContact
    case hasReferralAlready
    case invalidReferralRelationship
    
    public var errorDescription: String? {
      switch self {
      case .saveFailed:
        "Buzz couldn't save this referral"
      case .fetchFailed:
        "Buzz couldn't fetch this referral"
      case .notFound:
        "Buzz couldn't find this referral"
      case .deleteFailed:
        "Buzz couldn't delete this referral"
      case .hasExistingRecordForContact:
        "Buzz couldn't create this contact because contact already has a referral record"
      case .hasMissingRecordForContact:
        "Buzz couldn't update this referral since we can't find it"
      case .hasReferralAlready:
        "Buzz didn't want to overwrite this contact's existing referer"
      case .invalidReferralRelationship:
        "Buzz doesn't let you refer someone who referred you"
      }
    }
  }
}

fileprivate let dbPath = try! FileManager.default
  .url(for: .applicationSupportDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
  .appendingPathComponent("referrals.db")
  .path

// MARK: - Shared Implementation Logic
private extension ReferralRecordClient {
  static func makeClient(with dbQueue: DatabaseQueue) -> ReferralRecordClient {
    @Sendable
    func setupDatabase() {
      do {
        try dbQueue.write { db in
          try ReferralRecord.createTable(db)
        }
      } catch {
        fatalError("Database setup for referrals failed.")
      }
    }
    
    setupDatabase()
    
    return ReferralRecordClient(
      createRecord: { referral in
        try await dbQueue.write { db in
          let existingReferral = try ReferralRecord.fetchOne(db, id: referral.contactId)
          
          let isOverlappingReferral = if let existingReferral  { existingReferral.referredById != nil } else { false }
          
          if isOverlappingReferral {
            throw ReferralRecordClient.Failure.hasReferralAlready
          }
          
          // You can't refer someone who referred you
          let isReferringReferredBy = if let referredByUUID = referral.referredById,
                                         try ReferralRecord
            .filter(ReferralRecord.Columns.contactUUID == referredByUUID)
            .filter(ReferralRecord.Columns.referredByUUID == referral.contactId)
            .fetchOne(db) != nil { true }
          else { false }
          
          // If there's a referrer, check for circular referral
          if isReferringReferredBy {
            throw ReferralRecordClient.Failure.invalidReferralRelationship
          }
          
          try referral.upsert(db)
        }
      },
      updateRecord: { referral in
        try await dbQueue.write { db in
          // Check if there's an existing record for this contact
          let hasNoExistingRecordForContact = try ReferralRecord
            .filter(ReferralRecord.Columns.contactUUID == referral.contactId)
            .fetchOne(db) == nil
          
          if hasNoExistingRecordForContact {
            throw ReferralRecordClient.Failure.hasMissingRecordForContact
          }
          // You can't refer someone who referred you
          let isReferringReferredBy = if let referredByUUID = referral.referredById,
                                                try ReferralRecord
            .filter(ReferralRecord.Columns.contactUUID == referredByUUID)
            .filter(ReferralRecord.Columns.referredByUUID == referral.contactId)
            .fetchOne(db) != nil { true }
          else { false }
          
          // If there's a referrer, check for circular referral
          if isReferringReferredBy {
            throw ReferralRecordClient.Failure.invalidReferralRelationship
          }
          try referral.update(db)
        }
      },
      fetchRecord: { contactUUID in
        try await dbQueue.read { db in
          try ReferralRecord
            .filter(ReferralRecord.Columns.contactUUID == contactUUID)
            .fetchOne(db)
        }
      },
      fetchAllRecords: {
        try await dbQueue.read { db in
          try ReferralRecord.fetchAll(db)
        }
      },
      fetchReferrer: { contactUUID in
        try await dbQueue.read { db in
          guard let referral = try ReferralRecord
            .filter(ReferralRecord.Columns.contactUUID == contactUUID)
            .fetchOne(db) else {
            throw Failure.notFound
          }
          
          guard let referrerUUID = referral.referredById else { return nil }
          
          return try ReferralRecord
            .filter(ReferralRecord.Columns.contactUUID == referrerUUID)
            .fetchOne(db)
        }
      },
      fetchReferredContacts: { contactUUID in
        try await dbQueue.read { db in
          try ReferralRecord
            .filter(ReferralRecord.Columns.referredByUUID == contactUUID)
            .filter(ReferralRecord.Columns.contactUUID != contactUUID)
            .fetchAll(db)
        }
      },
      deleteRecord: { record in
        try await dbQueue.write { db in
          try record.delete(db)
        }
      },
      deleteDatabase: {
        try await dbQueue.erase()
        setupDatabase()
      },
      observeRecordWithReferred: { contactUUID in
        let observation = ValueObservation.tracking { db in
          let referral = try ReferralRecord
            .filter(ReferralRecord.Columns.contactUUID == contactUUID)
            .fetchOne(db)
          
          let referredContacts = try ReferralRecord
            .filter(ReferralRecord.Columns.referredByUUID == contactUUID)
            .fetchAll(db)
          
          return (referral, referredContacts)
        }
        
        return AsyncThrowingStream { continuation in
          let observer = observation.start(
            in: dbQueue,
            scheduling: .async(onQueue: .main),
            onError: { error in
              continuation.finish(throwing: error)
            },
            onChange: { result in
              continuation.yield(result)
            }
          )
          
          continuation.onTermination = { @Sendable _ in
            observer.cancel()
          }
        }
      }
    )
  }
}

extension ReferralRecordClient: DependencyKey {
  public static var liveValue: ReferralRecordClient {
    #if DEBUG
    .makeClient(with: try! DatabaseQueue(path: dbPath))
//    .makeClient(with: try! DatabaseQueue())
    #else
    .makeClient(with: try! DatabaseQueue(path: dbPath))
    #endif
  }
}

extension ReferralRecordClient {
  public static var previewValue: ReferralRecordClient {
    .makeClient(with: try! DatabaseQueue())
  }
}

extension DependencyValues {
  public var referralRecordClient: ReferralRecordClient {
    get { self[ReferralRecordClient.self] }
    set { self[ReferralRecordClient.self] = newValue }
  }
}
