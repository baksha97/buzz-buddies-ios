import SwiftUI

// MARK: - Views

struct ClientRewardTestView: View {
  @State private var viewModel: ViewModel
  
  init(viewModel: ViewModel) {
    _viewModel = State(initialValue: viewModel)
  }
  
  var body: some View {
    NavigationView {
      ScrollView {
        VStack {
          headerView
          clientSection
          addClientButton
        }
      }
      .background(Theme.Colors.background)
    }
    .themedNavigationView()
    .sheet(isPresented: $viewModel.isAddingClient) {
      AddClientForm(
        name: $viewModel.newClientName,
        phone: $viewModel.newClientPhone,
        referrer: $viewModel.selectedReferrer,
        clients: viewModel.clients,
        onSave: {
          viewModel.addClient()
        }
      )
      .presentationDetents([.medium])
      .onAppear {
        viewModel.fetchClients()
      }
    }
  }
  
  private var headerView: some View {
    HStack {
      Text("Clients and Rewards")
        .font(Theme.Fonts.title)
        .foregroundColor(Theme.Colors.text)
      
      Theme.Images.reward // Use reward emoji
        .font(.largeTitle)
        .foregroundColor(Theme.Colors.accent)
    }
    .padding(.bottom)
  }
  
  private var clientSection: some View {
    VStack(alignment: .leading) {
      HStack {
        Text("Clients")
          .font(Theme.Fonts.headline)
          .foregroundColor(Theme.Colors.text)
        
        Theme.Images.client
          .font(.title2)
          .foregroundColor(Theme.Colors.accent)
      }
      .padding([.horizontal, .top])
      
      ForEach(viewModel.clients) { client in
        clientRow(for: client)
      }
      .onDelete(perform: viewModel.deleteClients)
    }
    .background(Theme.Colors.background)
  }
  
  private func clientRow(for client: Client) -> some View {
    NavigationLink(destination: ClientDetailView(viewModel: ClientDetailView.ViewModel(dataService: viewModel.dataService, client: client), onDismiss: viewModel.fetchClients)) {
      HStack {
        Theme.Images.client
          .font(.title2)
          .foregroundColor(Theme.Colors.accent)
        
        Text(client.name)
          .font(Theme.Fonts.body)
          .foregroundColor(Theme.Colors.text)
        Spacer()
        Image(systemName: "chevron.right")
          .foregroundColor(Theme.Colors.secondary)
      }
      .padding([.horizontal, .bottom])
    }
    .buttonStyle(.plain)
  }
  
  private var addClientButton: some View {
    Button {
      viewModel.isAddingClient = true
    } label: {
      HStack {
        Theme.Images.add
        Text("Add Client")
      }
    }
    .buttonStyle(Theme.Styles.borderedProminentButtonStyle)
    .tint(Theme.Colors.accent)
    .padding(.vertical)
  }
}


struct ClientDetailView: View {
  @State private var viewModel: ViewModel
  let onDismiss: () -> Void
  
  @Environment(\.dismiss)
  var dismiss
  
  init(viewModel: ViewModel, onDismiss: @escaping () -> Void) {
    _viewModel = State(initialValue: viewModel)
    self.onDismiss = onDismiss
  }
  
  var body: some View {
    ScrollView {
      VStack {
        clientInfo
        rewardsSection
        addRewardButton
        Spacer()
        deleteClientButton
      }
    }
    .padding(.horizontal)
    .background(Theme.Colors.background)
    .sheet(isPresented: $viewModel.isAddingReward) {
      AddRewardForm(
        notes: $viewModel.newRewardNotes,
        referralsConsumed: $viewModel.newRewardReferralsConsumed,
        maxReferrals: viewModel.maxReferrals,
        onSave: {
          viewModel.addReward()
        }
      )
      .presentationDetents([.medium])
    }
    .navigationTitle(viewModel.client.name)
  }
  
  private var clientInfo: some View {
    VStack {
      HStack {
        Theme.Images.phone
        Text("Phone: \(viewModel.client.phoneNumber)")
          .font(Theme.Fonts.body)
          .foregroundColor(Theme.Colors.text)
      }
      HStack {
        Theme.Images.referredBy
        Text("Referred by: \(viewModel.client.referredBy?.name ?? "None")")
          .font(Theme.Fonts.body)
          .foregroundColor(Theme.Colors.text)
      }
      HStack {
        Theme.Images.referred
        Text("Referred: \(viewModel.client.referred.map { $0.name }.joined(separator: ", "))")
          .font(Theme.Fonts.body)
          .foregroundColor(Theme.Colors.text)
      }
    }
  }
  
  private var rewardsSection: some View {
    VStack(alignment: .leading) {
      HStack {
        Text("Rewards")
          .font(Theme.Fonts.headline)
          .foregroundColor(Theme.Colors.text)
        
        Theme.Images.reward // Use reward emoji
          .font(.title2)
          .foregroundColor(Theme.Colors.accent)
      }
      .padding([.horizontal, .top])
      
      ForEach(viewModel.client.rewards) { reward in
        rewardRow(for: reward)
      }
      .onDelete(perform: viewModel.deleteRewards)
    }
    .background(Theme.Colors.background)
  }
  
  private func rewardRow(for reward: Reward) -> some View {
    VStack(alignment: .leading) {
      HStack {
        Theme.Images.notes
        Text("Notes: \(reward.notes)")
          .font(Theme.Fonts.body)
          .foregroundColor(Theme.Colors.text)
      }
      Text("Referrals Consumed: \(reward.referralsConsumed)")
        .font(Theme.Fonts.caption)
        .foregroundColor(Theme.Colors.secondary)
    }
    .padding([.horizontal, .bottom])
  }
  
  private var addRewardButton: some View {
    Button {
      viewModel.isAddingReward = true
    } label: {
      HStack {
        Theme.Images.add
        Text("Add Reward")
      }
    }
    .buttonStyle(Theme.Styles.borderedProminentButtonStyle)
    .padding(.vertical)
  }
  
  private var deleteClientButton: some View {
    Button {
      viewModel.deleteClient()
      onDismiss()
      dismiss()
    } label: {
      HStack {
        Theme.Images.delete
        Text("Delete Client")
      }
    }
    .buttonStyle(Theme.Styles.borderedProminentButtonStyle)
    .accentColor(Theme.Colors.destructive)
    .padding(.vertical)
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
        Section("Client Details") { // Add section header
          TextField("Name", text: $name)
            .font(Theme.Fonts.body)
            .foregroundColor(Theme.Colors.text)
          
          HStack {
            Theme.Images.phone
            TextField("Phone", text: $phone)
              .font(Theme.Fonts.body)
              .foregroundColor(Theme.Colors.text)
          }
        }
        
        Section("Referral") { // Add section header
          Picker("Referred By", selection: $referrer) {
            Text("None")
              .tag(nil as Client?)
            ForEach(clients) { client in
              Text(client.name)
                .tag(client as Client?)
            }
          }
        }
      }
      .navigationTitle("Add Client")
      .toolbar {
        ToolbarItem(placement: .cancellationAction) {
          Button {
            name = ""
            phone = ""
            referrer = nil
            onSave()
          } label: {
            Text("Cancel")
              .font(Theme.Fonts.button)
              .foregroundColor(Theme.Colors.accent)
          }
        }
        ToolbarItem(placement: .confirmationAction) {
          Button {
            onSave()
          } label: {
            Text("Save")
              .font(Theme.Fonts.button)
              .foregroundColor(Theme.Colors.accent)
          }
        }
      }
    }
  }
}

struct AddRewardForm: View {
  @Binding var notes: String
  @Binding var referralsConsumed: Int
  let maxReferrals: Int
  let onSave: () -> Void
  
  var body: some View {
    NavigationView {
      Form {
        Section {
          HStack {
            Theme.Images.notes
            TextField("Notes", text: $notes)
              .font(Theme.Fonts.body)
              .foregroundColor(Theme.Colors.text)
          }
        }
        
        Section {
          Stepper("Referrals Consumed: \(referralsConsumed)", value: $referralsConsumed, in: 0...maxReferrals)
            .font(Theme.Fonts.body)
            .foregroundColor(Theme.Colors.text)
        }
      }
      .themedForm()
      .navigationTitle("Add Reward")
      .toolbar {
        ToolbarItem(placement: .cancellationAction) {
          Button {
            notes = ""
            referralsConsumed = 0
            onSave()
          } label: {
            Text("Cancel")
              .font(Theme.Fonts.button)
              .foregroundColor(Theme.Colors.accent)
          }
        }
        ToolbarItem(placement: .confirmationAction) {
          Button {
            onSave()
          } label: {
            Text("Save")
              .font(Theme.Fonts.button)
              .foregroundColor(Theme.Colors.accent)
          }
        }
      }
    }
  }
}

#Preview("ClientRewardTestView"){
  ClientRewardTestView(
    viewModel: .init(
      dataService: PreviewDataService()
    )
  )
}

#Preview("ClientDetailView"){
  ClientDetailView(
    viewModel: .init(
      dataService: PreviewDataService(),
      client: PreviewDataService.generateSampleData().first!
    )) {
      
    }
}

#Preview("AddClientForm"){
  AddClientForm(
    name: .constant(""),
    phone: .constant(""),
    referrer: .constant(.mock),
    clients: PreviewDataService.generateSampleData(),
    onSave: { }
  )
  
}
