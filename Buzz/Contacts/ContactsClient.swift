import Contacts
import Dependencies
import DependenciesMacros
import Foundation

/// Our ContactsClient dependency. It hides all usage of `CNContact`.
@DependencyClient
public struct ContactsClient: Sendable {
  public var requestAuthorization: @Sendable () async -> Bool = { true }
  public var fetchContacts: @Sendable () async throws -> [Contact]
  public var fetchContactById: @Sendable (_ id: UUID) async throws -> Contact
  public var addContact: @Sendable (_ contact: Contact) async throws -> Void
  
  public enum Failure: Error, Equatable {
    case unauthorized
    case fetchFailed
    case contactNotFound
    case saveFailed
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
  
  func fetchContacts() async throws -> [Contact] {
    guard CNContactStore.authorizationStatus(for: .contacts) == .authorized else {
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
  
  func fetchContactById(id: UUID) async throws -> Contact {
    guard CNContactStore.authorizationStatus(for: .contacts) == .authorized else {
      throw ContactsClient.Failure.unauthorized
    }
    
    let keys: [CNKeyDescriptor] = [
      CNContactGivenNameKey as CNKeyDescriptor,
      CNContactFamilyNameKey as CNKeyDescriptor,
      CNContactPhoneNumbersKey as CNKeyDescriptor,
      CNContactThumbnailImageDataKey as CNKeyDescriptor
    ]
    
    do {
      let contact = try store.unifiedContact(withIdentifier: id.uuidString, keysToFetch: keys)
      return domainContact(from: contact)
    } catch {
      throw ContactsClient.Failure.contactNotFound
    }
  }
  
  func addContact(_ contact: Contact) async throws {
    guard CNContactStore.authorizationStatus(for: .contacts) == .authorized else {
      throw ContactsClient.Failure.unauthorized
    }
    
    let mutable = CNMutableContact()
    mutable.givenName = contact.givenName
    mutable.familyName = contact.familyName
    mutable.phoneNumbers = contact.phoneNumbers.map {
      CNLabeledValue(label: CNLabelPhoneNumberMobile, value: CNPhoneNumber(stringValue: $0))
    }
    
    let saveRequest = CNSaveRequest()
    saveRequest.add(mutable, toContainerWithIdentifier: nil)
    do {
      try store.execute(saveRequest)
    } catch {
      throw ContactsClient.Failure.saveFailed
    }
  }
  
  // MARK: - Conversion
  
  private func domainContact(from cn: CNContact) -> Contact {
    Contact(
      id: cn.id,
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
      fetchContacts: {
        try await actor.fetchContacts()
      },
      fetchContactById: { id in
        try await actor.fetchContactById(id: id)
      },
      addContact: { contact in
        try await actor.addContact(contact)
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
      fetchContacts: { contacts.value },
      fetchContactById: { id in
        guard let contact = (contacts.value.first { $0.id == id }) else {
          throw Failure.contactNotFound
        }
        return contact
      },
      addContact: { contact in
        contacts.withValue { contacts in
          contacts.append(contact)
        }
      }
    )
  }
}
// MARK: - DependencyValues Extension

extension DependencyValues {
  public var contactsClient: ContactsClient {
    get { self[ContactsClient.self] }
    set { self[ContactsClient.self] = newValue }
  }
}
