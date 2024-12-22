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

#Preview("ClientDetailView"){
  ClientDetailView(
    viewModel: .init(
      dataService: PreviewDataService(),
      client: PreviewDataService.generateSampleData().first!
    )) {
      
    }
}

