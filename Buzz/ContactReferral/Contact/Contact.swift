import Contacts
import Dependencies
import DependenciesMacros
import Foundation

/// A simple domain contact model of our own, separate from `CNContact`.
public struct Contact: Equatable, Identifiable, Hashable, Sendable {
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

extension Contact {
  static let mock: Self = .init(
    givenName: "Travis",
    familyName: "Box",
    phoneNumbers: ["222-222-2222"]
  )
}

extension Array where Element == Contact {
  static let mock: Self = [
    .init(
      givenName: "Travis",
      familyName: "Box",
      phoneNumbers: ["222-222-2222"]
    ),
    .init(
      givenName: "Trav",
      familyName: "Box",
      phoneNumbers: ["222-222-2222"]
    ),
    .init(
      givenName: "Tarv",
      familyName: "Box",
      phoneNumbers: ["222-222-2222"]
    ),
    .init(
      givenName: "Travie",
      familyName: "Box",
      phoneNumbers: ["222-222-2222"]
    )
  ]
}
