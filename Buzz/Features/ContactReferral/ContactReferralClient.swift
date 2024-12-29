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
  func toContactsClientCreateRequest() -> ContactCreateRequest {
    .init(
      givenName: givenName,
      familyName: familyName,
      phoneNumbers: phoneNumbers
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
  
  static let mock: Self = .init(contact: .mock, referredBy: nil, referredContacts: [])
}


/// A client that bridges ContactsClient and ReferralRecordClient to manage referrals.
@DependencyClient
public struct ContactReferralClient: Sendable {
  // MARK: Contact Interface
  public var requestContactsAuthorization: @Sendable () async -> Bool = { true }
  public var checkAuthorization: @Sendable () async -> Bool = { true }
  public var fetchContacts: @Sendable () async throws -> [ContactReferralModel]
  public var fetchContactById: @Sendable (_ id: Contact.ContactListIdentifier) async throws -> ContactReferralModel
  public var fetchContactsByIds: @Sendable (_ ids: [Contact.ContactListIdentifier]) async throws -> [ContactReferralModel]
  
  public var addContact: @Sendable (_ contact: ContactReferralClientCreateRequest) async throws -> Void
  public var search: @Sendable (_ request: ContactSearchRequest) async throws -> [ContactReferralModel]

  // MARK: Referral Operations
  public var createReferral: @Sendable (_ contact: Contact.ContactListIdentifier, _ referredBy: Contact.ContactListIdentifier?) async throws -> Void
  public var updateReferral: @Sendable (_ contact: Contact.ContactListIdentifier, _ referredBy: Contact.ContactListIdentifier?) async throws -> Void
  public var fetchUnreferredContacts: @Sendable () async throws -> [ContactReferralModel]
  public var observe: @Sendable (_ id: Contact.ContactListIdentifier) -> AsyncThrowingStream<ContactReferralModel, Error> = { _ in .finished() }
}

// TODO: Figure out why the public extension isn't visible here and we need to have it in this file scope???
fileprivate extension Sequence where Element: Sendable {
  func asyncThrowingTaskGroupMap<T: Sendable>(
    _ transform: @Sendable @escaping (Element) async throws -> T
  ) async rethrows -> [T] {
    try await withThrowingTaskGroup(of: T.self) {
      for element in self {
        $0.addTask { try await transform(element) }
      }
      return try await $0.reduce(into: []) { $0.append($1) }
    }
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
        .asyncThrowingTaskGroupMap {
          try await contactsClient.fetchContactById($0.contactId)
        }
      return ContactReferralModel(
        contact: contact,
        referredBy: referredBy,
        referredContacts: referredContacts
      )
    }
    
    return ContactReferralClient(
      requestContactsAuthorization: contactsClient.requestAuthorization,
      checkAuthorization: contactsClient.checkAuthorization,
      fetchContacts: {
        try await contactsClient
          .fetchContacts()
          .asyncThrowingTaskGroupMap(mapToModel(contact:))
      },
      fetchContactById: {
        try await fetchModel(contactId: $0)
      },
      fetchContactsByIds: {
        try await $0.asyncThrowingTaskGroupMap(fetchModel(contactId:))
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
      search: { request in
        try await contactsClient.search(request: request)
          .asyncThrowingTaskGroupMap(mapToModel)
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
          .asyncThrowingTaskGroupMap(mapToModel(contact:))
          .filter { $0.referredBy == nil }
      },
      observe: { id in
        // TODO: Check if this is leaking
        // It would be nicer if we could just map the existing stream with the for-in body and have it be managed by swift itself
        AsyncThrowingStream { continuation in
          Task {
            do {
              let baseContact = try await contactsClient.fetchContactById(id)
              
              for try await (contactRecord, referredByContactRecords) in referralRecordClient.observeRecordWithReferred(contactUUID: id) {
                // Get the referrer contact if it exists
                let referrer: Contact? = if let referrerId = contactRecord?.referredById {
                  try await contactsClient.fetchContactById(referrerId)
                } else {
                  nil
                }
                
                // Map the referred contacts records to Contact models
                let referredContacts = try await referredByContactRecords
                  .map(\.contactId)
                  .asyncThrowingTaskGroupMap(contactsClient.fetchContactById(id:))
                
                // Create and emit the model
                let model = ContactReferralModel(
                  contact: baseContact,
                  referredBy: referrer,
                  referredContacts: referredContacts
                )
                
                continuation.yield(model)
              }
              
              continuation.finish()
            } catch {
              continuation.finish(throwing: error)
            }
          }
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
