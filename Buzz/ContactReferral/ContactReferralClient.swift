import Foundation
import Dependencies
import DependenciesMacros

/// Model representing a referral with detailed contact relationships.
public struct ContactReferralModel: Sendable, Equatable, Identifiable, Hashable {
  public let contact: Contact          // The primary contact
  public let referredBy: Contact?      // The contact who referred them (optional)
  public let referredContacts: [Contact] // Contacts referred by this contact
  
  public init(contact: Contact, referredBy: Contact?, referredContacts: [Contact]) {
    self.contact = contact
    self.referredBy = referredBy
    self.referredContacts = referredContacts
  }
  
  public var id: UUID {
    contact.id
  }
}


/// A client that bridges ContactsClient and ReferralRecordClient to manage referrals.
@DependencyClient
public struct ContactReferralClient: Sendable {
  // MARK: Contact Interface
  public var requestContactsAuthorization: @Sendable () async -> Bool = { true }
  public var fetchContacts: @Sendable () async throws -> [ContactReferralModel]
  public var fetchContactById: @Sendable (_ id: UUID) async throws -> ContactReferralModel
  public var fetchContactsByIds: @Sendable (_ ids: [UUID]) async throws -> [ContactReferralModel]
  
  public var addContact: @Sendable (_ contact: Contact) async throws -> Void
  
  // MARK: Referral Operations
  public var createReferral: @Sendable (_ contact: UUID, _ referredBy: UUID?) async throws -> Void
  public var updateReferral: @Sendable (_ contact: UUID, _ referredBy: UUID?) async throws -> Void
  public var fetchUnreferredContacts: @Sendable () async throws -> [ContactReferralModel]
}

// TODO: Need to figure out why this is failing to compile
// Passing closure as a 'sending' parameter risks causing data races between code in the current task and concurrent execution of the closure
//fileprivate extension Sequence {
//  func asyncThrowingTaskGroupMap<T: Sendable>(
//    _ transform: @Sendable @escaping (Element) async throws -> T
//  ) async rethrows -> [T] {
//    try await withThrowingTaskGroup(of: T.self) {
//      for element in self {
//        $0.addTask { try await transform(element) }
//      }
//      return try await $0.reduce(into: []) { $0.append($1) }
//    }
//  }
//}

fileprivate extension Sequence {
    func asyncMap<T>(
        _ transform: (Element) async throws -> T
    ) async rethrows -> [T] {
        var values = [T]()

        for element in self {
            try await values.append(transform(element))
        }
        return values
    }
}


// MARK: - Shared Implementation

extension ContactReferralClient {
  static func makeClient(
    contactsClient: ContactsClient,
    referralRecordClient: ReferralRecordClient
  ) -> ContactReferralClient {
    
    @Sendable
    func fetchModel(contactId: UUID) async throws -> ContactReferralModel {
      try await mapToModel(contact: contactsClient.fetchContactById(contactId))
    }
    
    @Sendable
    func mapToModel(contact: Contact) async throws -> ContactReferralModel {
      let record = try await referralRecordClient.fetchRecord(contactUUID: contact.id)
        ?? ReferralRecord(contactUUID: contact.id, referredByUUID: nil)
      
      let referredBy: Contact? = if let referrerUUID = record.referredByUUID {
        try await contactsClient.fetchContactById(referrerUUID)
      } else { nil }
      
      let referredContacts: [Contact] = try await referralRecordClient
        .fetchReferredContacts(contactUUID: contact.id)
        .asyncMap {
          try await contactsClient.fetchContactById($0.contactUUID)
        }
        .compactMap { $0 }
      return ContactReferralModel(
        contact: contact,
        referredBy: referredBy,
        referredContacts: referredContacts
      )
    }
    
    return ContactReferralClient(
      requestContactsAuthorization: contactsClient.requestAuthorization,
      fetchContacts: {
        try await contactsClient
          .fetchContacts()
          .asyncMap(mapToModel(contact:))
      },
      fetchContactById: {
        try await fetchModel(contactId: $0)
      },
      fetchContactsByIds: {
        try await $0.asyncMap(fetchModel(contactId:))
      },
      addContact: contactsClient.addContact(contact:),
      createReferral: { contactId, referredById in
        try await referralRecordClient.createRecord(
          ReferralRecord(
            contactUUID: contactId,
            referredByUUID: referredById
          )
        )
      },
      updateReferral: { contactId, referredById in
        try await referralRecordClient.updateRecord(
          ReferralRecord(
            contactUUID: contactId,
            referredByUUID: referredById
          )
        )
      },
      fetchUnreferredContacts: {
        try await contactsClient
          .fetchContacts()
          .asyncMap(mapToModel(contact:))
          .filter { $0.referredBy == nil }
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
