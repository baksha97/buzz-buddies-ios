import SwiftUI

enum NavigationDrawerItem: String, CaseIterable {
  case home      = "Contacts"
  case qr        = "QR"
  case settings  = "Settings"
  case help      = "Help"
  
  var icon: String {
    switch self {
    case .home:       "person.circle.fill"
    case .qr:         "person.circle"
    case .settings:   "gear"
    case .help:       "questionmark.circle"
    }
  }
}



struct NavigationDrawerContentView: View {
  
  typealias OnDrawerItemTap = (NavigationDrawerItem) -> Void
  let selectedItem: NavigationDrawerItem
  let onItemTap: OnDrawerItemTap
  
  var body: some View {
    VStack(alignment: .leading, spacing: 16) {
      HeaderSection()
//      Divider()
      NavigationSection(
        title: nil,
        selectedItem: selectedItem,
        items: [.home],
        onItemTap: onItemTap
      )
      Divider()
      NavigationSection(
        title: "🔨 In Development",
        selectedItem: selectedItem,
        items: [.qr],
        onItemTap: onItemTap
      )
      Spacer()
      Divider()
      NavigationSection(
        title: nil,
        selectedItem: selectedItem,
        items: [.settings, .help],
        onItemTap: onItemTap
      )
    }
    .padding(12)
    
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
    case .home:     ContactListView()
    case .qr:  QRCodeCustomizerView()
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
