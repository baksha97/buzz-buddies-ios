// MARK: - AvatarView
import SwiftUI

struct AvatarView: View {
  @Environment(\.theme) private var theme
  let avatarData: Data?
  let size: CGFloat
  
  var body: some View {
    Group {
      if let avatarData = avatarData, let uiImage = UIImage(data: avatarData) {
        Image(uiImage: uiImage)
          .resizable()
      } else {
        Image(systemName: "person.crop.circle")
          .resizable()
          .foregroundColor(theme.colors.textSecondary)
      }
    }
    .aspectRatio(contentMode: .fill)
    .frame(width: size, height: size)
    .clipShape(Circle())
    .shadow(color: theme.shadows.md.color, radius: theme.shadows.md.radius)
  }
}

// MARK: - AvatarListItem
struct AvatarListItem: View {
  @Environment(\.theme) private var theme
  let contact: Contact
  let avatarSize: CGFloat
  let buttonTitle: String?
  let buttonAction: (() -> Void)?
  
  var body: some View {
    BuzzUI.ListItem(
      title: contact.fullName,
      subtitle: contact.phoneNumbers.first ?? "No phone number",
      leading: {
        AvatarView(avatarData: contact.avatarData, size: avatarSize)
      },
      trailing: {
        if let buttonTitle = buttonTitle, let buttonAction = buttonAction {
          BuzzUI.Button(buttonTitle, style: .secondary, size: .small, action: buttonAction)
        }
      }
    )
    .background(theme.colors.surfaceSecondary)
    .cornerRadius(theme.borderRadius.md)
  }
}

// MARK: - ContactHeaderView
struct ContactHeaderView: View {
  @Environment(\.theme) private var theme
  let contact: Contact
  
  var body: some View {
    BuzzUI.Card(style: .elevated) {
      HStack(spacing: theme.spacing.md) {
        AvatarView(avatarData: contact.avatarData, size: 64)
        
        VStack(alignment: .leading, spacing: theme.spacing.xxs) {
          BuzzUI.Text(contact.fullName, style: .headingMedium)
          BuzzUI.Text(contact.phoneNumbers.first ?? "No phone number", style: .bodySmall, color: theme.colors.textSecondary)
        }
        Spacer()
      }
    }
  }
}

// MARK: - ReferrerCard
struct ReferrerCard: View {
  let contact: Contact
  let onTap: () -> Void
  
  var body: some View {
    AvatarListItem(
      contact: contact,
      avatarSize: 40,
      buttonTitle: "View",
      buttonAction: onTap
    )
  }
}

// MARK: - ReferredContactsList
struct ReferredContactsList: View {
  let contacts: [Contact]
  let onContactTap: (Contact) -> Void
  
  var body: some View {
    VStack(spacing: 8) {
      ForEach(contacts) { contact in
        AvatarListItem(
          contact: contact,
          avatarSize: 40,
          buttonTitle: "View",
          buttonAction: { onContactTap(contact) }
        )
      }
    }
  }
}

// MARK: - EmptyStateView
struct EmptyStateView: View {
  @Environment(\.theme) private var theme
  let message: String
  let icon: Image?
  
  var body: some View {
    VStack(spacing: theme.spacing.md) {
      icon?
        .resizable()
        .frame(width: 64, height: 64)
        .foregroundColor(theme.colors.textSecondary)
      BuzzUI.Text(message, style: .bodyMedium, color: theme.colors.textSecondary)
    }
    .frame(maxWidth: .infinity)
    .padding(theme.spacing.lg)
    .background(theme.colors.surfaceSecondary)
    .cornerRadius(theme.borderRadius.md)
  }
}

// MARK: - ReferralDetailsView
struct ReferralDetailsView: View {
  @Environment(\.theme) private var theme
  let contact: Contact
  let referredBy: Contact?
  let referredContacts: [Contact]
  let onReferrerTap: (Contact) -> Void
  let onReferredContactTap: (Contact) -> Void
  let onAddReferral: () -> Void
  
  var body: some View {
    ScrollView {
      VStack(spacing: theme.spacing.lg) {
        ContactHeaderView(contact: contact)
        
        SectionHeader(title: "Referred By")
        if let referrer = referredBy {
          ReferrerCard(contact: referrer, onTap: { onReferrerTap(referrer) })
        } else {
          EmptyStateView(
            message: "No one has referred this contact yet.",
            icon: Image(systemName: "person.fill.questionmark")
          )
        }
        
        SectionHeader(title: "Referred Contacts")
        if referredContacts.isEmpty {
          EmptyStateView(
            message: "This contact hasn't referred anyone yet.",
            icon: Image(systemName: "person.3.fill")
          )
        } else {
          ReferredContactsList(
            contacts: referredContacts,
            onContactTap: onReferredContactTap
          )
        }
      }
      .padding(theme.spacing.containerPadding)
    }
    .background(theme.colors.background)
    .navigationTitle(contact.fullName)
    .navigationBarTitleDisplayMode(.inline)
    .toolbar {
      ToolbarItem(placement: .bottomBar) {
        FloatingActionButton(
          icon: Image(systemName: "plus"),
          action: onAddReferral
        )
      }
    }
  }
}

// MARK: - SectionHeader
struct SectionHeader: View {
  @Environment(\.theme) private var theme
  let title: String
  
  var body: some View {
    BuzzUI.Text(title, style: .headingSmall)
      .padding(.bottom, theme.spacing.sm)
  }
}

// MARK: - FloatingActionButton
struct FloatingActionButton: View {
  @Environment(\.theme) private var theme
  let icon: Image
  let action: () -> Void
  
  var body: some View {
    Button(action: action) {
      icon
        .resizable()
        .frame(width: 24, height: 24)
        .foregroundColor(theme.colors.textOnPrimary)
        .padding()
        .background(theme.colors.primary)
        .clipShape(Circle())
        .shadow(color: theme.shadows.lg.color, radius: theme.shadows.lg.radius)
    }
    .buttonStyle(PlainButtonStyle())
    .padding(theme.spacing.lg)
    .position(x: UIScreen.main.bounds.width - 50, y: UIScreen.main.bounds.height - 100)
  }
}

#Preview {
  ReferralDetailsView(
    contact: .mock,
    referredBy: .mock,
    referredContacts: [.mock, .mock],
    onReferrerTap: { _ in },
    onReferredContactTap: { _ in },
    onAddReferral: {}
  )
  .withTheme(AppTheme.light)
}
