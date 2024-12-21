import Foundation
import SwiftData
// MARK: - Data Service

protocol ClientDataService {
    func fetchClients() -> [Client]
    func addClient(name: String, phone: String, referrer: Client?)
    func addReward(client: Client, notes: String, referralsConsumed: Int)
    func deleteClients(at offsets: IndexSet)
    func deleteRewards(for client: Client, at offsets: IndexSet)
    func deleteClient(by id: String) // New method to delete by ID

}

final class SwiftDataService: ClientDataService {
    private let modelContext: ModelContext

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    func fetchClients() -> [Client] {
        do {
            let descriptor = FetchDescriptor<Client>(sortBy: [SortDescriptor(\.name)])
            return try modelContext.fetch(descriptor)
        } catch {
            print("Error fetching clients: \(error)")
            return []
        }
    }

    func addClient(name: String, phone: String, referrer: Client?) {
        let newClient = Client(name: name, phoneNumber: phone, referredBy: referrer)
        modelContext.insert(newClient)
        try? modelContext.save()
    }

    func addReward(client: Client, notes: String, referralsConsumed: Int) {
        let reward = Reward(client: client, notes: notes, referralsConsumed: referralsConsumed)
        modelContext.insert(reward)
        try? modelContext.save()
    }

    func deleteClients(at offsets: IndexSet) {
        let clients = fetchClients()
        for index in offsets {
            let client = clients[index]
            modelContext.delete(client)
        }
        try? modelContext.save()
    }

    func deleteRewards(for client: Client, at offsets: IndexSet) {
        for index in offsets {
            let reward = client.rewards[index]
            modelContext.delete(reward)
        }
        try? modelContext.save()
    }
  
  // New function to delete a client by ID
      func deleteClient(by id: String) {
          do {
              // Create a fetch descriptor with a predicate to find the client by ID
              let predicate = #Predicate<Client> { $0.id == id }
              let descriptor = FetchDescriptor<Client>(predicate: predicate)

              // Fetch the client
              if let clientToDelete = try modelContext.fetch(descriptor).first {
                  // Delete the client
                  modelContext.delete(clientToDelete)
                  try? modelContext.save()
              } else {
                  print("Client with ID \(id) not found.")
              }
          } catch {
              print("Error deleting client: \(error)")
          }
      }
}

// MARK: - In-Memory (Preview) Data Service

final class PreviewDataService: ClientDataService {
    private var clients: [Client] = []

    init(clients: [Client] = []) {
        self.clients = clients
    }

    func fetchClients() -> [Client] {
        return clients
    }

    func addClient(name: String, phone: String, referrer: Client?) {
        let newClient = Client(name: name, phoneNumber: phone, referredBy: referrer)
        clients.append(newClient)
        if let referrer = referrer, let index = clients.firstIndex(where: { $0.id == referrer.id }) {
            clients[index].referred.append(newClient) // Update the referrer's referred list
        }
    }

    func addReward(client: Client, notes: String, referralsConsumed: Int) {
        if let index = clients.firstIndex(where: { $0.id == client.id }) {
            let reward = Reward(client: client, notes: notes, referralsConsumed: referralsConsumed)
            clients[index].rewards.append(reward)
        }
    }

    func deleteClients(at offsets: IndexSet) {
        // Create a new array, excluding the clients that should be deleted
        var newClients = [Client]()
        for i in 0..<clients.count {
            if !offsets.contains(i) {
                newClients.append(clients[i])
            }
        }
        clients = newClients
    }

    func deleteRewards(for client: Client, at offsets: IndexSet) {
        if let clientIndex = clients.firstIndex(where: { $0.id == client.id }) {
            // Filter out rewards to delete, similar to deleteClients
            var newRewards = [Reward]()
            for i in 0..<clients[clientIndex].rewards.count {
                if !offsets.contains(i) {
                    newRewards.append(clients[clientIndex].rewards[i])
                }
            }
            clients[clientIndex].rewards = newRewards
        }
    }

    func deleteClient(by id: String) {
        clients.removeAll(where: { $0.id == id })
    }
}

// MARK: - Preview Data

extension PreviewDataService {
    static func generateSampleData() -> [Client] {
        // Create some sample clients
        let client1 = Client(name: "Alice", phoneNumber: "123-456-7890")
        let client2 = Client(name: "Bob", phoneNumber: "987-654-3210")
        let client3 = Client(name: "Charlie", phoneNumber: "555-123-4567", referredBy: client1)
        let client4 = Client(name: "David", phoneNumber: "555-987-6543", referredBy: client1)
        let client5 = Client(name: "Emily", phoneNumber: "555-555-5555", referredBy: client2)

        // Add some rewards
        client1.rewards = [
            Reward(client: client1, notes: "Reward 1", referralsConsumed: 1),
            Reward(client: client1, notes: "Reward 2", referralsConsumed: 2)
        ]
        client2.rewards = [
            Reward(client: client2, notes: "Reward A", referralsConsumed: 3)
        ]

        // Update referred clients for client1 and client2
        client1.referred = [client3, client4]
        client2.referred = [client5]
        

        return [client1, client2, client3, client4, client5]
    }
}
