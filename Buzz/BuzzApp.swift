import SwiftUI
import SwiftData
@main
struct BuzzApp: App {
  let container: ModelContainer
  
  init() {
    do {
      container = try ModelContainer(for: Client.self, Reward.self)
    } catch {
      fatalError("Failed to create ModelContainer for Client and Reward.")
    }
  }
  
  var body: some Scene {
    WindowGroup {
      RootView(container: container)
    }
    .modelContainer(container)
  }
}

struct RootView: View {
  
  let container: ModelContainer
  var body: some View {
    TabView {
      ClientListView(viewModel: ClientListView.ViewModel(dataService: SwiftDataService(modelContext: container.mainContext)))
        .tabItem {
          Label("List", systemImage: "list.dash")
        }
      ContactsView()
        .tabItem {
          Label("Contacts", systemImage: "person.fill")
        }
    }
  }
}
