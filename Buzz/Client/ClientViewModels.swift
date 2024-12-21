import Foundation

// MARK: - View Models

extension ClientRewardTestView {
    @Observable
    class ViewModel {
        private(set) var dataService: ClientDataService
        var clients: [Client] = []

        var isAddingClient: Bool = false
        var newClientName: String = ""
        var newClientPhone: String = ""
        var selectedReferrer: Client? = nil

        init(dataService: ClientDataService) {
            self.dataService = dataService
            fetchClients()
        }

        func fetchClients() {
            clients = dataService.fetchClients()
        }

        func addClient() {
            dataService.addClient(name: newClientName, phone: newClientPhone, referrer: selectedReferrer)
            fetchClients()
            isAddingClient = false
            newClientName = ""
            newClientPhone = ""
            selectedReferrer = nil
        }

        func deleteClients(at offsets: IndexSet) {
            dataService.deleteClients(at: offsets)
            fetchClients()
        }
    }
}

extension ClientDetailView {
    @Observable
    class ViewModel {
        private let dataService: ClientDataService
        let client: Client
        var isAddingReward: Bool = false
        var newRewardNotes: String = ""
        var newRewardReferralsConsumed: Int = 0

        var maxReferrals: Int {
            client.referred.count - client.rewards.map { $0.referralsConsumed }.reduce(0, +)
        }

        init(dataService: ClientDataService, client: Client) {
            self.dataService = dataService
            self.client = client
        }

        func addReward() {
            dataService.addReward(client: client, notes: newRewardNotes, referralsConsumed: newRewardReferralsConsumed)
            isAddingReward = false
            newRewardNotes = ""
            newRewardReferralsConsumed = 0
        }

        func deleteRewards(at offsets: IndexSet) {
            dataService.deleteRewards(for: client, at: offsets)
        }
      
      func deleteClient() {
        dataService.deleteClient(by: client.id)
      }
    }
}
