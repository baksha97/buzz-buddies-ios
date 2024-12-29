import SwiftUI
import SwiftData
import Dependencies
import Sharing

@main
struct BuzzApp: App {
  var body: some Scene {
    WindowGroup {
      RootView()
        .withTheme(AppTheme.dark)
        .preferredColorScheme(.dark)
    }
  }
}
struct RootView: View {
  
  @Dependency(\.contactReferralClient.requestContactsAuthorization)
  private var requestAuthorization
  
  var body: some View {
    NavigationHostView()
      .task {
        let hasAuthorizationForContacts = await requestAuthorization()
      }
  }
}

// MARK: - 6) Navigation Host

fileprivate struct NavigationHostView: View {
  @Shared(.activeQrConfiguration)
  var configuration
  @Observable
  final class AppState {
    // Controls if the navigation drawer is open or closed
    var hasNavigationDrawerOpen: Bool = false
    
    // Stores which drawer item (screen) was last selected
    var lastDrawerItem: NavigationDrawerItem = .qr
  }
  
  @State var appState: AppState = AppState()
  @Environment(\.colorScheme) var colorScheme
  
  var body: some View {
    NavigationDrawerHostView(
      isOpen: $appState.hasNavigationDrawerOpen,
      main: {
        // The screen we show based on lastDrawerItem
        NavigationItemScreenResolver(item: appState.lastDrawerItem)
      },
      drawer: {
        drawerContent
      },
      onDrawerIconTap: {
        appState.hasNavigationDrawerOpen.toggle()
      }
    )
  }
  
  @ViewBuilder
  var drawerContent: some View {
    NavigationDrawerContentView(
      selectedItem: appState.lastDrawerItem,
      onItemTap: { item in
        appState.lastDrawerItem = item
        appState.hasNavigationDrawerOpen.toggle()
      }
    )
    .padding()
    .frame(width: 300)
    
    .background(configuration.backgroundColor)
    .offset(x: appState.hasNavigationDrawerOpen ? 0 : -200)
    .animation(.easeInOut, value: appState.hasNavigationDrawerOpen)
    .transition(.move(edge: .leading))
  }
}

// MARK: - Drawer Container Preview

#Preview("Navigation Host") {
  NavigationHostView()
    .preferredColorScheme(.dark)
}

