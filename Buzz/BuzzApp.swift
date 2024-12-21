import ComposableArchitecture
import SwiftUI

@main
struct BuzzApp: App {
  
  var body: some Scene {
    WindowGroup {
      AppRootView()
    }
    .modelContainer(for: Client.self)
    .modelContainer(for: Reward.self)
  }
}

