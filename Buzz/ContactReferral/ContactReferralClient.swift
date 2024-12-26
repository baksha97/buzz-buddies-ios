import Foundation
import Dependencies
import DependenciesMacros

/// Model representing the request to add a new contact from the application
public struct ContactReferralClientCreateRequest: Equatable, Hashable, Sendable {
  public var givenName: String
  public var familyName: String
  public var phoneNumbers: [String]
  public var avatarData: Data?
  public var referredBy: Contact?

  public init(
    givenName: String,
    familyName: String,
    phoneNumbers: [String] = [],
    avatarData: Data? = nil,
    referredBy: Contact? = nil
  ) {
    self.givenName = givenName
    self.familyName = familyName
    self.phoneNumbers = phoneNumbers
    self.avatarData = avatarData
    self.referredBy = referredBy
  }
}

fileprivate extension ContactReferralClientCreateRequest {
  func toContactsClientCreateRequest() -> ContactClientCreateRequest {
    .init(
      givenName: givenName,
      familyName: familyName,
      phoneNumbers: phoneNumbers,
      avatarData: avatarData
    )
  }
}

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
  
  public var id: Contact.ContactListIdentifier {
    contact.id
  }
}


/// A client that bridges ContactsClient and ReferralRecordClient to manage referrals.
@DependencyClient
public struct ContactReferralClient: Sendable {
  // MARK: Contact Interface
  public var requestContactsAuthorization: @Sendable () async -> Bool = { true }
  public var fetchContacts: @Sendable () async throws -> [ContactReferralModel]
  public var fetchContactById: @Sendable (_ id: Contact.ContactListIdentifier) async throws -> ContactReferralModel
  public var fetchContactsByIds: @Sendable (_ ids: [Contact.ContactListIdentifier]) async throws -> [ContactReferralModel]
  
  public var addContact: @Sendable (_ contact: ContactReferralClientCreateRequest) async throws -> Void
  
  // MARK: Referral Operations
  public var createReferral: @Sendable (_ contact: Contact.ContactListIdentifier, _ referredBy: Contact.ContactListIdentifier?) async throws -> Void
  public var updateReferral: @Sendable (_ contact: Contact.ContactListIdentifier, _ referredBy: Contact.ContactListIdentifier?) async throws -> Void
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
    func fetchModel(contactId: Contact.ContactListIdentifier) async throws -> ContactReferralModel {
      try await mapToModel(contact: contactsClient.fetchContactById(contactId))
    }
    
    @Sendable
    func mapToModel(contact: Contact) async throws -> ContactReferralModel {
      let record = try await referralRecordClient.fetchRecord(contactUUID: contact.id)
      ?? ReferralRecord(contactUUID: contact.id, referredByUUID: nil)
      
      let referredBy: Contact? = if let referrerUUID = record.referredById {
        try await contactsClient.fetchContactById(referrerUUID)
      } else { nil }
      
      let referredContacts: [Contact] = try await referralRecordClient
        .fetchReferredContacts(contactUUID: contact.id)
        .asyncMap {
          try await contactsClient.fetchContactById($0.contactId)
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
      addContact: { request in
        let addedContact = try await contactsClient.addContact(request.toContactsClientCreateRequest())
        if let refferedById = request.referredBy?.id {
          try await referralRecordClient.createRecord(
            ReferralRecord(
              contactUUID: addedContact.id,
              referredByUUID: refferedById
            )
          )
        }
      },
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
