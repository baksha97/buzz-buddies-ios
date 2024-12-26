import Foundation

public extension Sequence where Element: Sendable {
  public func asyncThrowingTaskGroupMap<T: Sendable>(
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
