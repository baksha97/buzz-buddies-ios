import SwiftUI
import SwiftData
import Dependencies

// MARK: - Color Extension for Optimal Text Contrast
extension Color {
  var accessibleTextColor: Color {
    let components = UIColor(self).cgColor.components ?? [0, 0, 0, 1]
    let red = components[0]
    let green = components[1]
    let blue = components[2]
    
    let luminance = (0.2126 * red + 0.7152 * green + 0.0722 * blue)
    
    return luminance > 0.5 ? Color.black.opacity(0.7) : Color.white.opacity(0.9)
  }
}

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
  @Observable
  final class AppState {
    // Controls if the navigation drawer is open or closed
    var hasNavigationDrawerOpen: Bool = false
    
    // Stores which drawer item (screen) was last selected
    var lastDrawerItem: NavigationDrawerItem = .home
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
    .background(colorScheme == .light ? Color(white: 0.95) : Color(white: 0.08))
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

