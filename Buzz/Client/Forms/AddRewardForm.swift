//
//  AddRewardForm.swift
//  Buzz
//
//  Created by Travis Baksh on 12/21/24.
//


import SwiftUI

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

#Preview("AddRewardForm"){
  AddRewardForm(
    notes: .constant(""),
    referralsConsumed: .constant(0),
    maxReferrals: 3,
    onSave: { }
  )
  
}
