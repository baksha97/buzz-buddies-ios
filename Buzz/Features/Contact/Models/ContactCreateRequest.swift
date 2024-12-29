//
//  ContactCreateRequest.swift
//  Buzz
//
//  Created by Travis Baksh on 12/28/24.
//


import Contacts
import Dependencies
import DependenciesMacros
import Foundation

public struct ContactCreateRequest: Equatable, Hashable, Sendable {
  public var givenName: String
  public var familyName: String
  public var phoneNumbers: [String]
  
  public init(
    givenName: String,
    familyName: String,
    phoneNumbers: [String] = []
  ) {
    self.givenName = givenName
    self.familyName = familyName
    self.phoneNumbers = phoneNumbers
  }
}
