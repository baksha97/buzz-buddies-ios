import SwiftUI
import SwiftData
import Dependencies
import Sharing
import SwiftUINavigation

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
  
  @CasePathable
  enum Destination {
    case scannedQr(request: ContactSearchRequest)
  }
  
  @State
  var destination: Destination? = nil
  
  var body: some View {
    NavigationHostView()
      .task {
        _ =  await requestAuthorization()
      }
      .onOpenURL { url in
        guard url.scheme == "buzzapp" else { return }
        guard let parsed = parse(url: url) else {
          print("failed to parse link \(url)")
          return
        }
        destination = .scannedQr(
          request: .init(
            id: parsed.id,
            givenName: parsed.gn,
            familyName: parsed.fn,
            phoneNumber: parsed.phoneNumbers.first ?? ""
          )
        )
      }
      .sheet(item: $destination.scannedQr) { request in
        ContactSearchView(searchRequest: request)
      }
  }
  
  func parse(url: URL) -> (id: String, gn: String, fn: String, phoneNumbers: [String])? {
      guard url.scheme == "buzzapp", url.host == "referral" else {
        return nil
      }
      
      let queryItems = URLComponents(url: url, resolvingAgainstBaseURL: false)?.queryItems
      let id = queryItems?.first(where: { $0.name == "id" })?.value
      let gn = queryItems?.first(where: { $0.name == "gn" })?.value
      let fn = queryItems?.first(where: { $0.name == "fn" })?.value
      let phoneNos = queryItems?.first(where: { $0.name == "pns" })?.value?.components(separatedBy: ",")
      
      if let id = id, let gn = gn, let fn = fn, let phoneNos = phoneNos {
        return (id, gn, fn, phoneNos)
      }
      
      return nil
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

