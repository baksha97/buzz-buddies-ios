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
    }
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
      Images.reward // Use reward emoji
        .font(.largeTitle)
    }
    .padding(.bottom)
  }
  
  private var clientSection: some View {
    VStack(alignment: .leading) {
      HStack {
        Text("Clients")
        Images.client
          .font(.title2)
      }
      .padding([.horizontal, .top])
      
      ForEach(viewModel.clients) { client in
        clientRow(for: client)
      }
      .onDelete(perform: viewModel.deleteClients)
    }
  }
  
  private func clientRow(for client: Client) -> some View {
    NavigationLink(destination: ClientDetailView(viewModel: ClientDetailView.ViewModel(dataService: viewModel.dataService, client: client), onDismiss: viewModel.fetchClients)) {
      HStack {
        Images.client
          .font(.title2)
        Text(client.name)
        Spacer()
        Image(systemName: "chevron.right")
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
        Images.add
        Text("Add Client")
      }
    }
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

