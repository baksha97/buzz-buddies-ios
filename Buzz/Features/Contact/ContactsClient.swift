import Contacts
import Dependencies
import DependenciesMacros
import Foundation



/// Our ContactsClient dependency. It hides all usage of `CNContact`.
@DependencyClient
public struct ContactsClient: Sendable {
  public var requestAuthorization: @Sendable () async -> Bool = { true }
  public var checkAuthorization: @Sendable () async -> Bool = { true }
  public var fetchContacts: @Sendable () async throws -> [Contact]
  public var fetchContactById: @Sendable (_ id: Contact.ContactListIdentifier) async throws -> Contact
  public var fetchContactsByIds: @Sendable (_ ids: [Contact.ContactListIdentifier]) async throws -> [Contact]
  public var addContact: @Sendable (_ contact: ContactCreateRequest) async throws -> Contact
  public var search: @Sendable (_ request: ContactSearchRequest) async throws -> [Contact]
  
  public enum Failure: LocalizedError, Equatable {
    case unauthorized
    case fetchFailed
    case contactNotFound
    case saveFailed
    
    public var errorDescription: String? {
      switch self {
      case .unauthorized:
        "Buzz is not authorized to view your contacts"
      case .fetchFailed:
        "Buzz failed to fetch your contacts"
      case .contactNotFound:
        "Buzz could not find a contact in your contact list"
      case .saveFailed:
        "Buzz could not save your contact"
      }
    }
  }
}

// MARK: - Live Implementation


private actor ContactsActor {
  let store = CNContactStore()
  
  func requestAuthorization() async -> Bool {
    let currentStatus = CNContactStore.authorizationStatus(for: .contacts)
    guard currentStatus == .notDetermined else {
      return currentStatus == .authorized
    }
    
    return await withCheckedContinuation { continuation in
      store.requestAccess(for: .contacts) { granted, _ in
        continuation.resume(returning: granted)
      }
    }
  }
  
  func checkAuthorization() -> Bool {
    CNContactStore.isAuthorized
  }
  
  func fetchContacts() async throws -> [Contact] {
    guard CNContactStore.isAuthorized else {
      print("failed to fetch contacts because app isn't authorized")
      throw ContactsClient.Failure.unauthorized
    }
    
    let keys: [CNKeyDescriptor] = [
      CNContactGivenNameKey as CNKeyDescriptor,
      CNContactFamilyNameKey as CNKeyDescriptor,
      CNContactPhoneNumbersKey as CNKeyDescriptor,
      CNContactThumbnailImageDataKey as CNKeyDescriptor
    ]
    
    var domainContacts: [Contact] = []
    let request = CNContactFetchRequest(keysToFetch: keys)
    
    try await withCheckedThrowingContinuation { continuation in
      do {
        try self.store.enumerateContacts(with: request) { cnContact, _ in
          let c = self.domainContact(from: cnContact)
          domainContacts.append(c)
        }
        continuation.resume(returning: ())
      } catch {
        continuation.resume(throwing: ContactsClient.Failure.fetchFailed)
      }
    }
    return domainContacts
  }
  
  func fetchContactById(id: Contact.ContactListIdentifier) async throws -> Contact {
    guard CNContactStore.isAuthorized else {
      throw ContactsClient.Failure.unauthorized
    }
    
    let keys: [CNKeyDescriptor] = [
      CNContactGivenNameKey as CNKeyDescriptor,
      CNContactFamilyNameKey as CNKeyDescriptor,
      CNContactPhoneNumbersKey as CNKeyDescriptor,
      CNContactThumbnailImageDataKey as CNKeyDescriptor
    ]
    
    do {
      // TODO: This should likely return an optional instead of throw, would require error mapping
      let contact = try store.unifiedContact(withIdentifier: id, keysToFetch: keys)
      return domainContact(from: contact)
    } catch {
      throw ContactsClient.Failure.contactNotFound
    }
  }
  
  func fetchContactsByIds(ids: [Contact.ContactListIdentifier]) async throws -> [Contact] {
    guard CNContactStore.isAuthorized else {
      throw ContactsClient.Failure.unauthorized
    }
    
    let keys: [CNKeyDescriptor] = [
      CNContactGivenNameKey as CNKeyDescriptor,
      CNContactFamilyNameKey as CNKeyDescriptor,
      CNContactPhoneNumbersKey as CNKeyDescriptor,
      CNContactThumbnailImageDataKey as CNKeyDescriptor
    ]
    
    // Build Predicate
    let predicate = CNContact.predicateForContacts(withIdentifiers: ids)
    
    do {
      let contacts = try store.unifiedContacts(matching: predicate, keysToFetch: keys)
      return contacts.map { self.domainContact(from: $0) }
    } catch {
      throw ContactsClient.Failure.fetchFailed
    }
  }
  
  func search(
    id: Contact.ContactListIdentifier,
    givenName: String,
    familyName: String,
    phoneNumber: String
  ) async throws -> [Contact] {
    if let foundContact = try? await fetchContactById(id: id) {
      return [foundContact]
    }
    return try search(givenName: givenName, familyName: familyName, phoneNumbers: [phoneNumber])
  }
  
  private func search(
    givenName: String,
    familyName: String,
    phoneNumbers: [String]
  )  throws -> [Contact] {
    let namePredicate = CNContact.predicateForContacts(matchingName: "\(givenName) \(familyName)")
    let phoneNumberPredicate = CNContact.predicateForContacts(matching: CNPhoneNumber(stringValue: phoneNumbers[0]))
    let compoundPredicate = NSCompoundPredicate(andPredicateWithSubpredicates: [namePredicate, phoneNumberPredicate])
    
    let keys: [CNKeyDescriptor] = [
      CNContactGivenNameKey as CNKeyDescriptor,
      CNContactFamilyNameKey as CNKeyDescriptor,
      CNContactPhoneNumbersKey as CNKeyDescriptor,
      CNContactThumbnailImageDataKey as CNKeyDescriptor
    ]
    let contacts = try store.unifiedContacts(matching: compoundPredicate, keysToFetch: keys as [CNKeyDescriptor])
    
    return contacts.map(domainContact)
  }
  
  func addContact(_ contactCreateRequest: ContactCreateRequest) async throws -> Contact {
    guard CNContactStore.isAuthorized else {
      throw ContactsClient.Failure.unauthorized
    }
    
    let mutable = CNMutableContact()
    mutable.givenName = contactCreateRequest.givenName
    mutable.familyName = contactCreateRequest.familyName
    mutable.phoneNumbers = contactCreateRequest.phoneNumbers.map {
      CNLabeledValue(label: CNLabelPhoneNumberMobile, value: CNPhoneNumber(stringValue: $0))
    }
    
    let saveRequest = CNSaveRequest()
    saveRequest.add(mutable, toContainerWithIdentifier: nil)
    do {
      try store.execute(saveRequest)
      let contacts = try search(
        givenName: contactCreateRequest.givenName,
        familyName: contactCreateRequest.familyName,
        phoneNumbers: contactCreateRequest.phoneNumbers
      )
      guard let savedContact = contacts.last else {
        throw ContactsClient.Failure.saveFailed
      }
      return savedContact
    } catch {
      throw ContactsClient.Failure.saveFailed
    }
  }
  
  // MARK: - Conversion
  
  private func domainContact(from cn: CNContact) -> Contact {
    return Contact(
      id: cn.identifier,
      givenName: cn.givenName,
      familyName: cn.familyName,
      phoneNumbers: cn.phoneNumbers.map { $0.value.stringValue },
      avatarData: cn.thumbnailImageData
    )
  }
}

// MARK: - DependencyKey conformance

extension ContactsClient: DependencyKey {
  public static var liveValue: ContactsClient {
    let actor = ContactsActor()
    
    return ContactsClient(
      requestAuthorization: {
        await actor.requestAuthorization()
      },
      checkAuthorization: {
        await actor.checkAuthorization()
      },
      fetchContacts: {
        try await actor.fetchContacts()
      },
      fetchContactById: { id in
        return try await actor.fetchContactById(id: id)
      },
      fetchContactsByIds: { ids in
        try await actor.fetchContactsByIds(ids: ids)
      },
      addContact: { contact in
        try await actor.addContact(contact)
      },
      search: { request in
        try await actor.search(id: request.id, givenName: request.givenName, familyName: request.familyName, phoneNumber: request.phoneNumber)
      }
    )
  }
}

// MARK: - Preview
extension ContactsClient {
  public static var previewValue: ContactsClient {
    let contacts = LockIsolated([Contact].mock)
    return ContactsClient(
      requestAuthorization: { true },
      checkAuthorization: { true },
      fetchContacts: { contacts.value },
      fetchContactById: { id in
        guard let contact = (contacts.value.first { $0.id == id }) else {
          throw Failure.contactNotFound
        }
        return contact
      },
      fetchContactsByIds: { ids in
        contacts.value.filter { ids.contains($0.id) }
      },
      addContact: { request in
        let createdContact = Contact(id: .init(), givenName: request.givenName, familyName: request.familyName, phoneNumbers: request.phoneNumbers)
        contacts.withValue { contacts in
          contacts.append(createdContact)
        }
        return createdContact
      },
      search: { request in
        // TODO: make search actually search mocks
        return contacts.value.filter { $0.id == request.id }
      }
    )
  }
}


fileprivate extension CNContactStore {
  static var isAuthorized: Bool {
    if #available(iOS 18.0, *) {
      guard CNContactStore.authorizationStatus(for: .contacts) == .authorized ||  CNContactStore.authorizationStatus(for: .contacts) == .limited else {
        return false
      }
    } else {
      guard CNContactStore.authorizationStatus(for: .contacts) == .authorized else {
        return false
      }
    }
    return true
  }
}
// MARK: - DependencyValues Extension

extension DependencyValues {
  public var contactsClient: ContactsClient {
    get { self[ContactsClient.self] }
    set { self[ContactsClient.self] = newValue }
  }
}
