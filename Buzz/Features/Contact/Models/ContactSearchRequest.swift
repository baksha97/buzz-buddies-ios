import Foundation

public struct ContactSearchRequest: Equatable, Hashable, Sendable, Identifiable {
  public var id: Contact.ContactListIdentifier
  public var givenName: String
  public var familyName: String
  public var phoneNumber: String
  
  public init(
    id: Contact.ContactListIdentifier,
    givenName: String,
    familyName: String,
    phoneNumber: String
  ) {
    self.id = id
    self.givenName = givenName
    self.familyName = familyName
    self.phoneNumber = phoneNumber
  }
}
