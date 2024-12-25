import Foundation
import Dependencies
import DependenciesMacros

/// Model representing a referral with detailed contact relationships.
public struct ContactReferralModel: Sendable, Equatable {
  public let contact: Contact          // The primary contact
  public let referredBy: Contact?      // The contact who referred them (optional)
  public let referredContacts: [Contact] // Contacts referred by this contact
  
  public init(contact: Contact, referredBy: Contact?, referredContacts: [Contact]) {
    self.contact = contact
    self.referredBy = referredBy
    self.referredContacts = referredContacts
  }
}


/// A client that bridges ContactsClient and ReferralRecordClient to manage referrals.
@DependencyClient
public struct ContactReferralClient: Sendable {
  // MARK: Contact Interface
  public var requestContactsAuthorization: @Sendable () async -> Bool = { true }
  public var fetchContacts: @Sendable () async throws -> [Contact]
  public var fetchContactById: @Sendable (_ id: UUID) async throws -> Contact
  public var fetchContactsByIds: @Sendable (_ ids: [UUID]) async throws -> [Contact]
  public var fetchContactsWithoutIds: @Sendable (_ ids: [UUID]) async throws -> [Contact]
  public var addContact: @Sendable (_ contact: Contact) async throws -> Void
  
  // MARK: Referral Interface
  public var createReferral: @Sendable (_ contact: Contact, _ referredBy: Contact?) async throws -> Void
  public var fetchUnreferredContacts: @Sendable (_ contact: Contact) async throws -> [Contact]
  public var fetchReferredContacts: @Sendable (_ contact: Contact) async throws -> [Contact]
  public var fetchReferrer: @Sendable (_ contact: Contact) async throws -> Contact?
  
  // MARK: Fetch all referral records as ContactReferralModel
  public var fetchAllReferralRecords: @Sendable () async throws -> [ContactReferralModel]
  
  
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
      requestContactsAuthorization: contactsClient.requestAuthorization,
      fetchContacts: contactsClient.fetchContacts,
      fetchContactById: contactsClient.fetchContactById(id:),
      fetchContactsByIds: contactsClient.fetchContactsByIds(ids:),
      fetchContactsWithoutIds: contactsClient.fetchContactsWithoutIds(ids:),
      addContact: contactsClient.addContact(contact:),
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
      fetchUnreferredContacts: { contact in
        let allReferralRecords = try await referralRecordClient.fetchAllRecords()
        let referredContactIDs = allReferralRecords.map { $0.contactUUID }
        // Filter out contacts that have referral records
        return try await contactsClient.fetchContactsWithoutIds(ids: referredContactIDs)
      },
      fetchReferredContacts: { contact in
        let allReferralRecords = try await referralRecordClient.fetchAllRecords()
        let referredContactIDs = allReferralRecords.map { $0.contactUUID }
        // Filter out contacts that have referral records
        return try await contactsClient.fetchContactsByIds(ids: referredContactIDs)
      },
      
      fetchReferrer: { contact in
        guard let referrerRecord = try await referralRecordClient.fetchReferrer(contact.id) else {
          return nil
        }
        let contacts = try await contactsClient.fetchContacts()
        return contacts.first { $0.id == referrerRecord.contactUUID }
      },
      fetchAllReferralRecords: {
        let allContacts = try await contactsClient.fetchContacts()
        
        return try await withThrowingTaskGroup(of: ContactReferralModel?.self) { group in
          for contact in allContacts {
            group.addTask {
              let referrerRecord = try await referralRecordClient.fetchReferrer(contact.id)
              let referredRecords = try await referralRecordClient.fetchReferredContacts(contact.id)
              
              let referredByContact = referrerRecord.flatMap { referrer in
                allContacts.first { $0.id == referrer.contactUUID }
              }
              
              let referredContacts = referredRecords.compactMap { record in
                allContacts.first { $0.id == record.contactUUID }
              }
              
              return ContactReferralModel(
                contact: contact,
                referredBy: referredByContact,
                referredContacts: referredContacts
              )
            }
          }
          
          var models: [ContactReferralModel] = []
          for try await model in group.compactMap({ $0 }) {
            models.append(model)
          }
          
          return models
        }
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
