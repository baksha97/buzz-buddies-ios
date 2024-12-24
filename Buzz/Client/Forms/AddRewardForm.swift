import SwiftUI

struct AddRewardForm: View {
  @Environment(\.theme) private var theme
  @Environment(\.dismiss) private var dismiss
  
  @Binding var notes: String
  @Binding var referralsConsumed: Int
  let maxReferrals: Int
  let onSave: () -> Void
  
  var body: some View {
    NavigationView {
      VStack(spacing: theme.spacing.lg) {
        VStack(spacing: theme.spacing.md) {
          BuzzUI.Text("Notes", style: .headingSmall)
          
          BuzzUI.TextField(
            "Enter notes",
            text: $notes,
            icon: Image(systemName: "note.text")
          )
        }
        
        VStack(spacing: theme.spacing.md) {
          BuzzUI.Text("Referrals", style: .headingSmall)
          
          BuzzUI.Card {
            VStack(spacing: theme.spacing.sm) {
              HStack {
                BuzzUI.Text("Referrals Consumed", style: .bodyLarge)
                Spacer()
                BuzzUI.Text("\(referralsConsumed)", style: .bodyLarge)
              }
              
              HStack(spacing: theme.spacing.md) {
                BuzzUI.Button("−", style: .secondary) {
                  if referralsConsumed > 0 {
                    referralsConsumed -= 1
                  }
                }
                .disabled(referralsConsumed <= 0)
                
                BuzzUI.Button("+", style: .secondary) {
                  if referralsConsumed < maxReferrals {
                    referralsConsumed += 1
                  }
                }
                .disabled(referralsConsumed >= maxReferrals)
              }
            }
          }
        }
        
        Spacer()
      }
      .padding(theme.spacing.lg)
      .background(theme.colors.background)
      .navigationBarTitleDisplayMode(.inline)
      .toolbar {
        ToolbarItem(placement: .principal) {
          BuzzUI.Text("Add Reward", style: .headingMedium)
        }
        
        ToolbarItem(placement: .cancellationAction) {
          BuzzUI.Button("Cancel", style: .tertiary) {
            notes = ""
            referralsConsumed = 0
            dismiss()
          }
        }
        
        ToolbarItem(placement: .confirmationAction) {
          BuzzUI.Button("Save", style: .primary) {
            onSave()
          }
        }
      }
    }
  }
}

#Preview("AddRewardForm") {
  AddRewardForm(
    notes: .constant(""),
    referralsConsumed: .constant(0),
    maxReferrals: 3,
    onSave: { }
  )
  .withTheme(AppTheme.light)
}

#Preview("AddRewardForm - Dark") {
  AddRewardForm(
    notes: .constant(""),
    referralsConsumed: .constant(0),
    maxReferrals: 3,
    onSave: { }
  )
  .withTheme(AppTheme.dark)
  .preferredColorScheme(.dark)
}
