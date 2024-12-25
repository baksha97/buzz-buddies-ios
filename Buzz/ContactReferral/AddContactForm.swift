import SwiftUI
import Dependencies

// MARK: - Form Models
struct AddContactFormModel {
  let givenName: String
  let familyName: String
  let phoneNumber: String
  let referredBy: Contact?
}

struct AddContactFormState {
  var givenName = ""
  var familyName = ""
  var phoneNumber = ""
  var referredBy: Contact? = nil
  
  var givenNameError: String? {
    if givenName.isEmpty {
      return "First name is required"
    }
    return nil
  }
  
  var phoneNumberError: String? {
    // Basic US phone validation (XXX-XXX-XXXX or similar)
    let phoneRegex = #"^\(?\d{3}\)?[-.\s]?\d{3}[-.\s]?\d{4}$"#
    if phoneNumber.isEmpty {
      return "Phone number is required"
    }
    if (phoneNumber.range(of: phoneRegex, options: .regularExpression) == nil) {
      return "Please enter a valid US phone number"
    }
    return nil
  }
  
  var isValid: Bool {
    givenNameError == nil && phoneNumberError == nil
  }
}

struct AddContactModal: View {
  @Environment(\.theme) private var theme
  @Environment(\.dismiss) private var dismiss
  
  @State private var formState = AddContactFormState()
  @State private var errorMessage: String? = nil
  
  // Sample referral data - replace with real data
  @State private var referralOptions: [Contact] = []
  
  
  @Dependency(\.contactReferralClient.fetchContacts)
  var fetchContacts
  
  @Dependency(\.contactReferralClient.addContact)
  var addContact
  
  
  var body: some View {
    NavigationView {
      ScrollView {
        VStack(spacing: theme.spacing.xl) {
          // Personal Details Card
          BuzzUI.Card {
            VStack(alignment: .leading, spacing: theme.spacing.lg) {
              BuzzUI.Text("Personal Details", style: .headingSmall)
              
              VStack(spacing: theme.spacing.md) {
                BuzzUI.TextField(
                  "First Name",
                  text: $formState.givenName,
                  icon: Image(systemName: "person"),
                  errorMessage: formState.givenNameError
                )
                
                BuzzUI.TextField(
                  "Last Name",
                  text: $formState.familyName,
                  icon: Image(systemName: "person")
                )
              }
            }
          }
          
          // Contact Info Card
          BuzzUI.Card {
            VStack(alignment: .leading, spacing: theme.spacing.lg) {
              BuzzUI.Text("Contact Information", style: .headingSmall)
              FormPhoneField(
                phoneNumber: $formState.phoneNumber,
                errorMessage: formState.phoneNumberError
              )
            }
          }
          
          // Referral Card
          BuzzUI.Card {
            VStack(alignment: .leading, spacing: theme.spacing.lg) {
              BuzzUI.Text("Referral Information", style: .headingSmall)
              
              Menu {
                Button("None") {
                  formState.referredBy = nil
                }
                ForEach(referralOptions) { contact in
                  Button(contact.fullName) {
                    formState.referredBy = contact
                  }
                }
              } label: {
                HStack {
                  Image(systemName: "person.2")
                    .foregroundColor(theme.colors.textSecondary)
                  
                  BuzzUI.Text(
                    formState.referredBy?.fullName ?? "Select Referrer",
                    style: .bodyMedium,
                    color: formState.referredBy == nil ? theme.colors.textTertiary : theme.colors.textPrimary
                  )
                  
                  Spacer()
                  
                  Image(systemName: "chevron.down")
                    .foregroundColor(theme.colors.textSecondary)
                }
                .padding(theme.spacing.md)
                .background(theme.colors.surface)
                .cornerRadius(theme.borderRadius.md)
                .overlay(
                  RoundedRectangle(cornerRadius: theme.borderRadius.md)
                    .stroke(theme.colors.border, lineWidth: 1)
                )
              }
            }
          }
        }
        .padding(theme.spacing.lg)
      }
      .background(theme.colors.background)
      .navigationBarTitleDisplayMode(.inline)
      .navigationTitle("Add Contact")
      .toolbar {
        ToolbarItem(placement: .cancellationAction) {
          BuzzUI.Button("Cancel", style: .tertiary) {
            dismiss()
          }
        }
        
        ToolbarItem(placement: .confirmationAction) {
          BuzzUI.Button("Save", style: .primary) {
            saveContact()
          }
          .disabled(!formState.isValid)
        }
      }
    }.task {
      do {
        referralOptions = try await fetchContacts()
      }
      catch {
        errorMessage = error.localizedDescription
      }
    }
      
  }
  
  private func saveContact() {
    Task {
      try await addContact(
        Contact(
          givenName: formState.givenName,
          familyName: formState.familyName,
          phoneNumbers: [formState.phoneNumber]
        )
      )
    }
    dismiss()
  }
}

struct FormPhoneField: View {
    @Environment(\.theme) private var theme
    @Binding var phoneNumber: String
    let errorMessage: String?
    
    @State private var displayText: String = ""
    
    var body: some View {
        BuzzUI.TextField(
            "Phone Number",
            text: $displayText,
            icon: Image(systemName: "phone"),
            errorMessage: errorMessage
        )
        .onAppear {
            displayText = formatForDisplay(phoneNumber)
        }
        .onChange(of: displayText) { _, newValue in
            let filtered = newValue.filter { $0.isNumber }
            phoneNumber = filtered.prefix(10).description
            displayText = formatForDisplay(phoneNumber)
        }
    }
    
    private func formatForDisplay(_ numbers: String) -> String {
        let cleaned = numbers.filter { $0.isNumber }
        switch cleaned.count {
        case 0: return ""
        case 1...3: return cleaned
        case 4...6:
            return cleaned.prefix(3) + "-" + cleaned.dropFirst(3)
        case 7...10:
            return cleaned.prefix(3) + "-" + cleaned.dropFirst(3).prefix(3) + "-" + cleaned.dropFirst(6)
        default: return cleaned
        }
    }
}

#Preview("Add Contact - Light") {
  AddContactModal()
    .withTheme(AppTheme.light)
}

#Preview("Add Contact - Dark") {
  AddContactModal()
    .withTheme(AppTheme.dark)
    .preferredColorScheme(.dark)
}
