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
              ClientRewardTestView(viewModel: ClientRewardTestView.ViewModel(dataService: SwiftDataService(modelContext: container.mainContext)))
          }
          .modelContainer(container)
      }
}

// MARK: - App
//
//@main
//struct ClientRewardTestApp: App {
//    let container: ModelContainer
//
//    init() {
//        do {
//            container = try ModelContainer(for: Client.self, Reward.self)
//        } catch {
//            fatalError("Failed to create ModelContainer for Client and Reward.")
//        }
//    }
//
//    var body: some Scene {
//        WindowGroup {
//            ClientRewardTestView(viewModel: ClientRewardTestView.ViewModel(dataService: SwiftDataService(modelContext: container.mainContext)))
//        }
//        .modelContainer(container)
//    }
//}
