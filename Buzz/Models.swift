import Foundation
import SwiftData

import SwiftUI


@Model
final class Client {
  @Attribute(.unique)
  var id: String
  var name: String
  var phoneNumber: String
  var created: Date
  var referred: [Client]
  
  @Relationship(inverse: \Client.referred)
  var referredBy: Client?
  @Relationship(deleteRule: .cascade, inverse: \Reward.client)
  var rewards: [Reward]
  
  init(id: UUID = UUID(), name: String, phoneNumber: String, referredBy: Client? = nil) {
    self.id = id.uuidString
    self.name = name
    self.phoneNumber = phoneNumber
    self.referredBy = referredBy
    self.created = Date()
    self.referred = []
    self.rewards = []
  }
}

@Model
final class Reward {
  
  @Attribute(.unique)
  var id: String
  var client: Client?
  var created: Date
  var claimed: Date?
  var notes: String
  var referralsConsumed: Int
  
  init(id: UUID = UUID(), client: Client, notes: String = "", referralsConsumed: Int = 0) {
    self.id = id.uuidString
    self.client = client
    self.created = Date()
    self.notes = notes
    self.referralsConsumed = referralsConsumed
  }
}

struct ClientRewardTestView: View {
  @Environment(\.modelContext) private var context
  @Query var clients: [Client]
  @Query var rewards: [Reward]
  @State private var isAddingClient = false
  @State private var newClientName = ""
  @State private var newClientPhone = ""
  @State private var selectedReferrer: Client? = nil
  @State private var selectedClient: Client? = nil
  
  var body: some View {
    NavigationView {
      VStack {
        Text("Clients and Rewards")
          .font(.largeTitle)
          .fontWeight(.bold)
          .padding(.bottom)
        
        List {
          Section("Clients") {
            ForEach(clients) { client in
              NavigationLink(destination: ClientDetailView(client: client)) { // Use NavigationLink
                Text(client.name)
              }
            }
            .onDelete(perform: deleteClients)
          }
        }
        .listStyle(.insetGrouped) // Use insetGrouped list style
        
        Button("Add Client") {
          isAddingClient = true
        }
        .buttonStyle(.borderedProminent)
        .padding(.bottom)
      }
    }
    .padding()
    .sheet(isPresented: $isAddingClient) {
      AddClientForm(
        name: $newClientName,
        phone: $newClientPhone,
        referrer: $selectedReferrer,
        clients: clients,
        onSave: {
          addClient(name: newClientName, phone: newClientPhone, referrer: selectedReferrer)
          isAddingClient = false
          newClientName = ""
          newClientPhone = ""
          selectedReferrer = nil
        }
      )
    }
    .sheet(item: $selectedClient) { client in
      ClientDetailView(client: client)
    }
  }
  
  func addClient(name: String, phone: String, referrer: Client?) {
    let newClient = Client(name: name, phoneNumber: phone, referredBy: referrer)
    context.insert(newClient)
    saveContext()
  }
  
  func addReward() {
    guard let client = clients.first else { return }
    let reward = Reward(client: client, notes: "Free coffee", referralsConsumed: 1)
    context.insert(reward)
    saveContext()
  }
  
  func deleteClients(at offsets: IndexSet) {
    for index in offsets {
      let client = clients[index]
      context.delete(client)
    }
    saveContext()
  }
  
  func saveContext() {
    do {
      try context.save()
    } catch {
      print("Error saving context: \(error)")
    }
  }
}


struct ClientDetailView: View {
  @Environment(\.modelContext) private var context // Add this
  let client: Client
  @State private var isAddingReward = false
  @State private var newRewardNotes = ""
  @State private var newRewardReferralsConsumed = 0
  
  var body: some View {
    VStack {
      Text("Client Details")
        .font(.headline)
      
      Text("Name: \(client.name)")
      Text("Phone: \(client.phoneNumber)")
      Text("Referred by: \(client.referredBy?.name ?? "None")")
      Text("Referred: \(client.referred.map { $0.name }.joined(separator: ", "))")
      
      List {
        Section("Rewards") {
          ForEach(client.rewards) { reward in // Use client.rewards
            VStack(alignment: .leading) {
              Text("Notes: \(reward.notes)")
              Text("Referrals Consumed: \(reward.referralsConsumed)")
            }
          }
          .onDelete(perform: deleteRewards) // Add onDelete modifier
          
        }
      }
      
      Button("Add Reward") {
        isAddingReward = true
      }
      .sheet(isPresented: $isAddingReward) {
        AddRewardForm(
          notes: $newRewardNotes,
          referralsConsumed: $newRewardReferralsConsumed,
          maxReferrals: client.referred.count - client.rewards.map { $0.referralsConsumed }.reduce(0, +), // Calculate available referrals
          onSave: {
            addReward(notes: newRewardNotes, referralsConsumed: newRewardReferralsConsumed)
            isAddingReward = false
            newRewardNotes = ""
            newRewardReferralsConsumed = 0
          }
        )
      }
      
      Spacer()
    }
    .padding()
  }
  
  func addReward(notes: String, referralsConsumed: Int) {
    let newReward = Reward(client: client, notes: notes, referralsConsumed: referralsConsumed)
    context.insert(newReward)
    saveContext()
  }
  
  func deleteRewards(at offsets: IndexSet) {
    withAnimation {
      for index in offsets {
        let reward = client.rewards[index]
        context.delete(reward)
      }
      saveContext()
    }
  }
  
  func saveContext() {
    do {
      try context.save()
    } catch {
      print("Error saving context: \(error)")
    }
  }
}

struct AddClientForm: View {
  @Binding var name: String
  @Binding var phone: String
  @Binding var referrer: Client?
  let clients: [Client]
  let onSave: () -> Void
  
  var body: some View {
    NavigationView {
      Form {
        TextField("Name", text: $name)
        TextField("Phone", text: $phone)
        
        Picker("Referred By", selection: $referrer) {
          Text("None").tag(nil as Client?)
          ForEach(clients) { client in
            Text(client.name).tag(client as Client?)
          }
        }
      }
      .navigationTitle("Add Client")
      .toolbar {
        ToolbarItem(placement: .cancellationAction) {
          Button("Cancel") {
            onSave() // Just close the sheet
          }
        }
        ToolbarItem(placement: .confirmationAction) {
          Button("Save") {
            onSave() // Perform save action
          }
        }
      }
    }
  }
}

struct AddRewardForm: View {
  @Binding var notes: String
  @Binding var referralsConsumed: Int
  let maxReferrals: Int // Add this property
  let onSave: () -> Void
  
  var body: some View {
    NavigationView {
      Form {
        TextField("Notes", text: $notes)
        Stepper("Referrals Consumed: \(referralsConsumed)", value: $referralsConsumed, in: 0...maxReferrals) // Use maxReferrals in Stepper
      }
      .navigationTitle("Add Reward")
      .toolbar {
        ToolbarItem(placement: .cancellationAction) {
          Button("Cancel") {
            onSave()
          }
        }
        ToolbarItem(placement: .confirmationAction) {
          Button("Save") {
            onSave()
          }
        }
      }
    }
  }
}


#Preview {
  ClientRewardTestView()
    .modelContainer(for: Client.self, inMemory: true)
}
