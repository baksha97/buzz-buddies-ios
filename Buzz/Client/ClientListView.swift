import SwiftUI

// MARK: - Views

struct ClientListView: View {
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


#Preview("ClientListView"){
  ClientListView(
    viewModel: .init(
      dataService: PreviewDataService()
    )
  )
}

