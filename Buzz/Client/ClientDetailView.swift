//
//  ClientDetailView.swift
//  Buzz
//
//  Created by Travis Baksh on 12/21/24.
//


import SwiftUI

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
        Images.phone
        Text("Phone: \(viewModel.client.phoneNumber)")
      }
      HStack {
        Images.referredBy
        Text("Referred by: \(viewModel.client.referredBy?.name ?? "None")")
      }
      HStack {
        Images.referred
        Text("Referred: \(viewModel.client.referred.map { $0.name }.joined(separator: ", "))")
      }
    }
  }
  
  private var rewardsSection: some View {
    VStack(alignment: .leading) {
      HStack {
        Text("Rewards")
        Images.reward // Use reward emoji
          .font(.title2)
      }
      .padding([.horizontal, .top])
      
      ForEach(viewModel.client.rewards) { reward in
        rewardRow(for: reward)
      }
      .onDelete(perform: viewModel.deleteRewards)
    }
  }
  
  private func rewardRow(for reward: Reward) -> some View {
    VStack(alignment: .leading) {
      HStack {
        Images.notes
        Text("Notes: \(reward.notes)")
      }
      Text("Referrals Consumed: \(reward.referralsConsumed)")
    }
    .padding([.horizontal, .bottom])
  }
  
  private var addRewardButton: some View {
    Button {
      viewModel.isAddingReward = true
    } label: {
      HStack {
        Images.add
        Text("Add Reward")
      }
    }
    .padding(.vertical)
  }
  
  private var deleteClientButton: some View {
    Button {
      viewModel.deleteClient()
      onDismiss()
      dismiss()
    } label: {
      HStack {
        Images.delete
        Text("Delete Client")
      }
    }
    .padding(.vertical)
  }
}

#Preview("ClientDetailView"){
  ClientDetailView(
    viewModel: .init(
      dataService: PreviewDataService(),
      client: PreviewDataService.generateSampleData().first!
    )) {
      
    }
}

