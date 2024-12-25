import SwiftUI

enum NavigationDrawerItem: String, CaseIterable {
  case home      = "Home"
  case profile   = "Profile"
  case settings  = "Settings"
  case help      = "Help"

  var icon: String {
    switch self {
      case .home:     return "house.fill"
      case .profile:  return "person.circle"
      case .settings: return "gear"
      case .help:     return "questionmark.circle"
    }
  }
}

typealias OnDrawerItemTap = (NavigationDrawerItem) -> Void


struct NavigationDrawerContentView: View {
  let selectedItem: NavigationDrawerItem
  let onItemTap: OnDrawerItemTap

  var body: some View {
    ScrollView {
      VStack(alignment: .leading, spacing: 16) {
        HeaderSection()
        Divider()
        
        NavigationSection(
          title: "Main",
          selectedItem: selectedItem,
          items: NavigationDrawerItem.allCases,
          onItemTap: onItemTap
        )

        Spacer()
      }
      .padding(12)
    }
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
      case .home:     HomeScreen()
      case .profile:  ProfileScreen()
      case .settings: SettingsScreen()
      case .help:     HelpScreen()
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
      Text("Settings Screen").font(.largeTitle)
    }
  }

  struct HelpScreen: View {
    var body: some View {
      Text("Help Screen").font(.largeTitle)
    }
  }
}

private struct HeaderSection: View {
  var body: some View {
    VStack(spacing: 8) {
      HStack {
        Image(systemName: "app.fill")
          .resizable()
          .frame(width: 40, height: 40)

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
  let title: String
  let selectedItem: NavigationDrawerItem
  let items: [NavigationDrawerItem]
  let onItemTap: OnDrawerItemTap

  var body: some View {
    Section(header: Text(title).bold()) {
      ForEach(items, id: \.rawValue) { item in
        DrawerItemView(
          item: item,
          isSelected: selectedItem == item,
          onTap: onItemTap
        )
      }
    }
  }
}

private struct DrawerItemView: View {
  let item: NavigationDrawerItem
  let isSelected: Bool
  let onTap: OnDrawerItemTap

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
      .foregroundColor(isSelected ? .red : .primary)
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
