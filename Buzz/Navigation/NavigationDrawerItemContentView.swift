import SwiftUI
import Dependencies
import Sharing

enum NavigationDrawerItem: String, CaseIterable {
  case home                   = "Contacts"
  case qr                     = "QR Creator"
  case settings               = "Settings"
  case help                   = "Help"
  
  var icon: String {
    switch self {
    case .home:"person.circle.fill"
    case .qr: "house.circle"
    case .settings: "gear"
    case .help: "questionmark.circle"
    }
  }
}

struct NavigationDrawerContentView: View {
  
  @Shared(.activeQrConfiguration)
  var configuration
  
  typealias OnDrawerItemTap = (NavigationDrawerItem) -> Void
  let selectedItem: NavigationDrawerItem
  let onItemTap: OnDrawerItemTap
  
  @Dependency(\.contactReferralClient.checkAuthorization)
  private var checkAuthorization
  
  @State
  var hasContactAccess = true
  
  var body: some View {
    VStack(alignment: .leading, spacing: 16) {
      HeaderSection()
        .padding([.leading, .trailing], 12)  // Padding first
      Divider()
      NavigationSection(
        title: nil,
        selectedItem: selectedItem,
        items: [.home],
        onItemTap: onItemTap
      )
      .padding([.leading, .trailing], 12)  // Padding first

      Spacer()
      if !hasContactAccess {
        Divider()
        HStack {
          Image(systemName: "person.crop.circle.badge.exclamationmark.fill")
          Text("Buzz is missing contact access!")
            .font(.callout)
            .bold()
        }
        .foregroundColor(.red)
        .padding([.leading, .trailing], 12)  // Padding first
      }
      
      Divider()
      
      qrNavigationButton
      
      NavigationSection(
        title: nil,
        selectedItem: selectedItem,
        items: [.settings, .help],
        onItemTap: onItemTap
      )
      .padding([.leading, .trailing], 12)  // Padding first
    }
    .task {
      hasContactAccess = await checkAuthorization()
    }
    .padding([.leading, .trailing], 2)  // Padding first
    .foregroundColor(configuration.foregroundColor)
    .background(configuration.backgroundColor)  // Background after padding
    .ignoresSafeArea(.all, edges: .vertical)  // Make background extend full height
  }
  
  @ViewBuilder
  var qrNavigationButton: some View {
    Button(action: { onItemTap(.qr) }) {
      VStack {
        BuzzQRImage(configuration: configuration)
        HStack {
          if !configuration.text.trimmingCharacters(in: .whitespaces).isEmpty {
            Image(systemName: "link.circle.fill")
            Text(configuration.text)
              .bold()
          }
          else {
            Image(systemName: "pencil.and.scribble")
              .italic()
            Text("Customize URL")
              .italic()
          }
        }
      }
    }
    .buttonStyle(ElevatedButtonStyle(fillColor: configuration.backgroundColor))
  }
}


struct NavigationItemScreenResolver: View {
  let item: NavigationDrawerItem
  
  var body: some View {
    screen
      .navigationTitle(item.rawValue)
  }
  
  @ViewBuilder
  private var screen: some View {
    switch item {
    case .home:             ContactListViewV2()
    case .qr:               QRCodeEditorView()
    case .settings:         SettingsScreen()
    case .help:             HelpScreen()
    }
  }
  
  // MARK: - Example Screens
  struct HomeScreen: View {
    var body: some View {
      Text("Home Screen").font(.largeTitle)
    }
  }
  
  struct ProfileScreen: View {
    var body: some View {
      Text("Profile Screen").font(.largeTitle)
    }
  }
  
  struct SettingsScreen: View {
    var body: some View {
      Text("nothing to see here at the moment sorry").font(.largeTitle)
    }
  }
  
  struct HelpScreen: View {
    var body: some View {
      Text("i can't help right now").font(.largeTitle)
    }
  }
}

private struct HeaderSection: View {
  var body: some View {
    VStack(spacing: 8) {
      HStack {
        VStack(alignment: .leading) {
          Text("Buzz App").bold()
          Text("v1.0.0")
            .font(.caption)
        }
        Spacer()
      }
    }
  }
}

private struct NavigationSection: View {
  let title: String?
  let selectedItem: NavigationDrawerItem
  let items: [NavigationDrawerItem]
  let onItemTap: NavigationDrawerContentView.OnDrawerItemTap
  
  var body: some View {
    if let title {
      Section(header: Text(title).bold()) {
        navigationItemViews
      }
    }
    else {
      navigationItemViews
    }
  }
  
  @ViewBuilder
  var navigationItemViews: some View {
    ForEach(items, id: \.rawValue) { item in
      DrawerItemView(
        item: item,
        isSelected: selectedItem == item,
        onTap: onItemTap
      )
    }
  }
}

private struct DrawerItemView: View {
  let item: NavigationDrawerItem
  let isSelected: Bool
  let onTap: NavigationDrawerContentView.OnDrawerItemTap
  
  @Shared(.activeQrConfiguration)
  var configuration
  
  
  var body: some View {
    Button {
      onTap(item)
    } label: {
      HStack {
        Image(systemName: item.icon)
        Text(item.rawValue)
          .font(.headline)
        Spacer()
      }
      .foregroundColor(isSelected ? configuration.foregroundColor.accessibleTextColor : configuration.backgroundColor.accessibleTextColor)
      .padding(.vertical, 6)
    }
  }
}


#Preview("NavigationDrawerContentView") {
  NavigationDrawerContentView(selectedItem: .home) { item in
    print("Preview tapped: \(item)")
  }
}

#Preview("Navigation Resolver") {
  NavigationItemScreenResolver(item: .settings)
}

struct ElevatedButtonStyle: ButtonStyle {
  let fillColor: Color
  func makeBody(configuration: Configuration) -> some View {
    configuration.label
      .padding()
      .background(
        RoundedRectangle(cornerRadius: 8)
          .fill(fillColor)
          .shadow(
            color: .black.opacity(configuration.isPressed ? 0.1 : 0.2),
            radius: configuration.isPressed ? 2 : 4,
            x: 0,
            y: configuration.isPressed ? 1 : 2
          )
      )
      .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
  }
}
