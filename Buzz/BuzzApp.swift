import SwiftUI
import SwiftData
import Dependencies

@main
struct BuzzApp: App {
  var body: some Scene {
    WindowGroup {
      RootView()
        .withTheme(AppTheme.dark)
    }
  }
}

struct RootView: View {
  
  @Dependency(\.contactsClient.requestAuthorization)
  private var requestAuthorization
  
  var body: some View {
    TabView {
      
      ContactReferralView()
        .tabItem {
          Label("Refs", systemImage: "person.fill")
        }
      
      ContactsView()
        .tabItem {
          Label("Contacts", systemImage: "person.fill")
        }

    }
    .task {
      let hasAuthorizationForContacts = await requestAuthorization()
      if !hasAuthorizationForContacts {
        fatalError("Need contacts for app to work :)")
      }
    }
  }
}
