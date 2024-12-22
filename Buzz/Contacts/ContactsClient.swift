import Contacts
import Dependencies
import DependenciesMacros
import Foundation

/// A simple domain contact model of our own, separate from `CNContact`.
public struct Contact: Equatable, Identifiable, Sendable {
  public let id: UUID
  public var givenName: String
  public var familyName: String
  public var phoneNumbers: [String]
  public var avatarData: Data?

  public init(
    id: UUID = UUID(),
    givenName: String,
    familyName: String,
    phoneNumbers: [String] = [],
    avatarData: Data? = nil
  ) {
    self.id = id
    self.givenName = givenName
    self.familyName = familyName
    self.phoneNumbers = phoneNumbers
    self.avatarData = avatarData
  }

  public var fullName: String {
    "\(givenName) \(familyName)".trimmingCharacters(in: .whitespaces)
  }
}

/// Our ContactsClient dependency. It hides all usage of `CNContact`.
@DependencyClient
public struct ContactsClient : Sendable{
  public var requestAuthorization: @Sendable () async -> Bool = { true }
  public var fetchContacts: @Sendable () async throws -> [Contact]
  public var addContact: @Sendable (_ contact: Contact) async throws -> Void

  public enum Failure: Error, Equatable {
    case unauthorized
    case fetchFailed
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
    // If you want to write an image:
    // mutable.imageData = contact.avatarData

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
      addContact: { contact in
        try await actor.addContact(contact)
      }
    )
  }
}

// MARK: - Preview
extension ContactsClient {
  public static var previewValue: ContactsClient {
    ContactsClient(
      requestAuthorization: {
        // Pretend always authorized
        true
      },
      fetchContacts: {
        // Return a couple of fake domain contacts
        [
          Contact(givenName: "Alice", familyName: "Smith", phoneNumbers: ["555-1111"]),
          Contact(givenName: "Bob", familyName: "Johnson", phoneNumbers: ["555-2222"])
        ]
      },
      addContact: { contact in
        // No-op
      }
    )
  }
}

extension DependencyValues {
  public var contactsClient: ContactsClient {
    get { self[ContactsClient.self] }
    set { self[ContactsClient.self] = newValue }
  }
}
