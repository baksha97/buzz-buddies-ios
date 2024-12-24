import Foundation
import Dependencies
import DependenciesMacros

/// A client that bridges ContactsClient and ReferralRecordClient to manage referrals.
@DependencyClient
public struct ContactReferralClient: Sendable {
  public var createReferral: @Sendable (_ contact: Contact, _ referredBy: Contact?) async throws -> Void
  public var fetchReferredContacts: @Sendable (_ contact: Contact) async throws -> [Contact]
  public var fetchReferrer: @Sendable (_ contact: Contact) async throws -> Contact?
  
  public enum Failure: Error, Equatable {
    case contactAlreadyExistsInReferralRecords
    case contactNotFound
    case referralFailed
  }
}

// MARK: - Shared Implementation

extension ContactReferralClient {
  static func makeClient(
    contactsClient: ContactsClient,
    referralRecordClient: ReferralRecordClient
  ) -> ContactReferralClient {
    ContactReferralClient(
      createReferral: { contact, referredBy in
        
        // 1) Make sure person referring has a record, otherwise create it
        if let referrer = referredBy,
         try await referralRecordClient.fetchRecord(referrer.id) == nil {
         let referrerReferral = ReferralRecord(contactUUID: referrer.id)
         try await referralRecordClient.createRecord(referrerReferral)
        }
        
        // 2) Create referral, linking the person who referred them
        try await referralRecordClient.createRecord(
          ReferralRecord(
            contactUUID: contact.id,
            referredByUUID: referredBy?.id
          )
        )
        
      },
      fetchReferredContacts: { contact in
        let referredRecords = try await referralRecordClient.fetchReferredContacts(contact.id)
        let contacts = try await contactsClient.fetchContacts()
        
        return referredRecords.compactMap { record in
          contacts.first { $0.id == record.contactUUID }
        }
      },
      
      fetchReferrer: { contact in
        guard let referrerRecord = try await referralRecordClient.fetchReferrer(contact.id) else {
          return nil
        }
        
        let contacts = try await contactsClient.fetchContacts()
        return contacts.first { $0.id == referrerRecord.contactUUID }
      }
    )
  }
}

// MARK: - DependencyKey Conformance

extension ContactReferralClient: DependencyKey {
  public static var liveValue: ContactReferralClient {
    @Dependency(\.contactsClient) var contactsClient
    @Dependency(\.referralRecordClient) var referralRecordClient
    return makeClient(contactsClient: contactsClient, referralRecordClient: referralRecordClient)
  }
  
  public static var previewValue: ContactReferralClient {
    @Dependency(\.contactsClient) var contactsClient
    @Dependency(\.referralRecordClient) var referralRecordClient
    return makeClient(contactsClient: contactsClient, referralRecordClient: referralRecordClient)
  }
}

// MARK: - DependencyValues Extension

extension DependencyValues {
  public var contactReferralClient: ContactReferralClient {
    get { self[ContactReferralClient.self] }
    set { self[ContactReferralClient.self] = newValue }
  }
}
