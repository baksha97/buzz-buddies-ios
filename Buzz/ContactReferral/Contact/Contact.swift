import Contacts
import Dependencies
import DependenciesMacros
import Foundation

/// A simple domain contact model of our own, separate from `CNContact`.
public struct Contact: Equatable, Identifiable, Hashable, Sendable {
  public typealias ContactListIdentifier = String
  public let id: ContactListIdentifier
  public var givenName: String
  public var familyName: String
  public var phoneNumbers: [String]
  public var avatarData: Data?

  public init(
    id: ContactListIdentifier,
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

extension Contact {
  static let mock: Self = .init(
    id: "1",
    givenName: "Travis",
    familyName: "Box",
    phoneNumbers: ["222-222-2222"]
  )
}

extension Array where Element == Contact {
  static let mock: Self = [
    .mock,
    .init(
      id: "2",
      givenName: "Trav",
      familyName: "Box",
      phoneNumbers: ["222-222-2222"]
    ),
    .init(
      id: "3",
      givenName: "Tarv",
      familyName: "Box",
      phoneNumbers: ["222-222-2222"]
    ),
    .init(
      id: "4",
      givenName: "Travie",
      familyName: "Box",
      phoneNumbers: ["222-222-2222"]
    )
  ]
}
