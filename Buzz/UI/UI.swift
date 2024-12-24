import SwiftUI

// MARK: - BuzzUI Namespace
enum BuzzUI {
  // MARK: - Text Component
  struct Text: View {
    @Environment(\.theme) private var theme
    let content: String
    let style: TextStyle
    let color: Color?
    
    enum TextStyle {
      case displayLarge
      case displayMedium
      case displaySmall
      case headingLarge
      case headingMedium
      case headingSmall
      case bodyLarge
      case bodyMedium
      case bodySmall
      case labelLarge
      case labelMedium
      case labelSmall
    }
    
    init(_ content: String, style: TextStyle = .bodyMedium, color: Color? = nil) {
      self.content = content
      self.style = style
      self.color = color
    }
    
    var body: some View {
      SwiftUI.Text(content)
        .applyTextStyle(textStyle)
        .foregroundColor(color ?? textColor)
    }
    
    private var textStyle: ThemeTypography.TextStyle {
      switch style {
      case .displayLarge: return theme.typography.displayLarge
      case .displayMedium: return theme.typography.displayMedium
      case .displaySmall: return theme.typography.displaySmall
      case .headingLarge: return theme.typography.headingLarge
      case .headingMedium: return theme.typography.headingMedium
      case .headingSmall: return theme.typography.headingSmall
      case .bodyLarge: return theme.typography.bodyLarge
      case .bodyMedium: return theme.typography.bodyMedium
      case .bodySmall: return theme.typography.bodySmall
      case .labelLarge: return theme.typography.labelLarge
      case .labelMedium: return theme.typography.labelMedium
      case .labelSmall: return theme.typography.labelSmall
      }
    }
    
    private var textColor: Color {
      switch style {
      case .displayLarge, .displayMedium, .displaySmall,
          .headingLarge, .headingMedium, .headingSmall:
        return theme.colors.textPrimary
      case .bodyLarge, .bodyMedium, .bodySmall:
        return theme.colors.textPrimary
      case .labelLarge, .labelMedium, .labelSmall:
        return theme.colors.textPrimary
      }
    }
  }
  
  // MARK: - Button Component
  struct Button: View {
    @Environment(\.theme) private var theme
    @Environment(\.isEnabled) private var isEnabled
    
    let title: String
    let action: () -> Void
    let style: ButtonStyle
    let size: ButtonSize
    let icon: Image?
    
    enum ButtonStyle {
      case primary
      case secondary
      case tertiary
      case destructive
    }
    
    enum ButtonSize {
      case small
      case medium
      case large
    }
    
    init(
      _ title: String,
      style: ButtonStyle = .primary,
      size: ButtonSize = .medium,
      icon: Image? = nil,
      action: @escaping () -> Void
    ) {
      self.title = title
      self.style = style
      self.size = size
      self.icon = icon
      self.action = action
    }
    
    var body: some View {
      SwiftUI.Button(action: action) {
        HStack(spacing: theme.spacing.xs) {
          if let icon = icon {
            icon
              .resizable()
              .aspectRatio(contentMode: .fit)
              .frame(height: iconSize)
          }
          
          Text(title, style: textStyle)
        }
        .frame(maxWidth: size == .large ? .infinity : nil)
        .padding(.horizontal, horizontalPadding)
        .padding(.vertical, verticalPadding)
        .background(backgroundColor)
        .foregroundColor(foregroundColor)
        .cornerRadius(theme.borderRadius.md)
        .overlay(
          RoundedRectangle(cornerRadius: theme.borderRadius.md)
            .stroke(borderColor, lineWidth: borderWidth)
        )
        .shadow(
          color: shadowColor,
          radius: theme.shadows.sm.radius,
          x: theme.shadows.sm.x,
          y: theme.shadows.sm.y
        )
      }
      .disabled(!isEnabled)
    }
    
    private var textStyle: Text.TextStyle {
      switch size {
      case .small: return .labelMedium
      case .medium: return .labelLarge
      case .large: return .bodyLarge
      }
    }
    
    private var iconSize: CGFloat {
      switch size {
      case .small: return 14
      case .medium: return 16
      case .large: return 18
      }
    }
    
    private var horizontalPadding: CGFloat {
      switch size {
      case .small: return theme.spacing.sm
      case .medium: return theme.spacing.md
      case .large: return theme.spacing.lg
      }
    }
    
    private var verticalPadding: CGFloat {
      switch size {
      case .small: return theme.spacing.xs
      case .medium: return theme.spacing.sm
      case .large: return theme.spacing.md
      }
    }
    
    private var backgroundColor: Color {
      guard isEnabled else { return theme.colors.disabled }
      
      switch style {
      case .primary: return theme.colors.primary
      case .secondary: return theme.colors.surface
      case .tertiary: return .clear
      case .destructive: return theme.colors.error
      }
    }
    
    private var foregroundColor: Color {
      guard isEnabled else { return theme.colors.textTertiary }
      
      switch style {
      case .primary: return theme.colors.textOnPrimary
      case .secondary: return theme.colors.textPrimary
      case .tertiary: return theme.colors.primary
      case .destructive: return .white
      }
    }
    
    private var borderColor: Color {
      guard isEnabled else { return theme.colors.disabled }
      
      switch style {
      case .primary: return .clear
      case .secondary: return theme.colors.border
      case .tertiary: return .clear
      case .destructive: return .clear
      }
    }
    
    private var borderWidth: CGFloat {
      switch style {
      case .secondary: return 1
      default: return 0
      }
    }
    
    private var shadowColor: Color {
      guard isEnabled else { return .clear }
      
      switch style {
      case .primary: return theme.colors.primary.opacity(0.3)
      case .secondary: return theme.shadows.sm.color
      case .tertiary: return .clear
      case .destructive: return theme.colors.error.opacity(0.3)
      }
    }
  }
  
  // MARK: - Card Component
  struct Card<Content: View>: View {
    @Environment(\.theme) private var theme
    
    let content: Content
    let style: CardStyle
    
    enum CardStyle {
      case elevated
      case outlined
      case filled
    }
    
    init(style: CardStyle = .elevated, @ViewBuilder content: () -> Content) {
      self.style = style
      self.content = content()
    }
    
    var body: some View {
      content
        .padding(theme.spacing.lg)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(backgroundColor)
        .cornerRadius(theme.borderRadius.lg)
        .overlay(
          RoundedRectangle(cornerRadius: theme.borderRadius.lg)
            .stroke(borderColor, lineWidth: borderWidth)
        )
        .shadow(
          color: shadowColor,
          radius: shadowRadius,
          x: theme.shadows.md.x,
          y: theme.shadows.md.y
        )
    }
    
    private var backgroundColor: Color {
      switch style {
      case .elevated, .outlined: return theme.colors.surface
      case .filled: return theme.colors.surfaceSecondary
      }
    }
    
    private var borderColor: Color {
      switch style {
      case .outlined: return theme.colors.border
      default: return .clear
      }
    }
    
    private var borderWidth: CGFloat {
      switch style {
      case .outlined: return 1
      default: return 0
      }
    }
    
    private var shadowColor: Color {
      switch style {
      case .elevated: return theme.shadows.md.color
      default: return .clear
      }
    }
    
    private var shadowRadius: CGFloat {
      switch style {
      case .elevated: return theme.shadows.md.radius
      default: return 0
      }
    }
  }
  
  // MARK: - Input Components
  struct TextField: View {
    @Environment(\.theme) private var theme
    @Binding var text: String
    
    let placeholder: String
    let icon: Image?
    let errorMessage: String?
    let isSecure: Bool
    
    init(
      _ placeholder: String,
      text: Binding<String>,
      icon: Image? = nil,
      errorMessage: String? = nil,
      isSecure: Bool = false
    ) {
      self.placeholder = placeholder
      self._text = text
      self.icon = icon
      self.errorMessage = errorMessage
      self.isSecure = isSecure
    }
    
    var body: some View {
      VStack(alignment: .leading, spacing: theme.spacing.xxs) {
        HStack(spacing: theme.spacing.sm) {
          if let icon = icon {
            icon
              .foregroundColor(theme.colors.textSecondary)
          }
          
          if isSecure {
            SecureField(placeholder, text: $text)
          } else {
            SwiftUI.TextField(placeholder, text: $text)
          }
        }
        .padding(theme.spacing.md)
        .background(theme.colors.surface)
        .cornerRadius(theme.borderRadius.md)
        .overlay(
          RoundedRectangle(cornerRadius: theme.borderRadius.md)
            .stroke(borderColor, lineWidth: 1)
        )
        
        if let error = errorMessage {
          Text(error, style: .labelSmall, color: theme.colors.error)
        }
      }
    }
    
    private var borderColor: Color {
      if let _ = errorMessage {
        return theme.colors.error
      }
      return theme.colors.border
    }
  }
  
  // MARK: - List Components
  struct ListItem<Leading, Trailing>: View where Leading: View, Trailing: View {
    @Environment(\.theme) private var theme
    
    let title: String
    let subtitle: String?
    @ViewBuilder
    let leading: Leading
    @ViewBuilder
    let trailing: Trailing
    
    public var body: some View {
      HStack(spacing: theme.spacing.md) {
        leading
        
        VStack(alignment: .leading, spacing: theme.spacing.xxs) {
          Text(title, style: .bodyLarge)
          if let subtitle = subtitle {
            Text(subtitle, style: .bodySmall)
          }
        }
        
        if trailing is EmptyView {
          Spacer()
        }
        
        trailing
      }
      .padding(theme.spacing.md)
      .frame(maxWidth: .infinity, alignment: .leading)
      .background(theme.colors.surface)
      .cornerRadius(theme.borderRadius.md)
    }
  }
  
  
  
  
  // MARK: - Badge Component
  struct Badge: View {
    @Environment(\.theme) private var theme
    
    let text: String
    let style: BadgeStyle
    
    enum BadgeStyle {
      case info
      case success
      case warning
      case error
    }
    
    init(_ text: String, style: BadgeStyle = .info) {
      self.text = text
      self.style = style
    }
    
    var body: some View {
      Text(text, style: .labelSmall)
        .padding(.horizontal, theme.spacing.sm)
        .padding(.vertical, theme.spacing.xxs)
        .background(backgroundColor.opacity(0.5))
        .foregroundColor(backgroundColor)
        .cornerRadius(theme.borderRadius.full)
    }
    
    private var backgroundColor: Color {
      switch style {
      case .info: return theme.colors.info
      case .success: return theme.colors.success
      case .warning: return theme.colors.warning
      case .error: return theme.colors.error
      }
    }
  }
  
  // MARK: - Toggle Component
  struct Toggle: View {
    @Environment(\.theme) private var theme
    @Binding var isOn: Bool
    
    let label: String
    
    init(_ label: String, isOn: Binding<Bool>) {
      self.label = label
      self._isOn = isOn
    }
    
    var body: some View {
      SwiftUI.Toggle(label, isOn: $isOn)
        .toggleStyle(CustomToggleStyle())
    }
    
    private struct CustomToggleStyle: ToggleStyle {
      @Environment(\.theme) private var theme
      
      func makeBody(configuration: Configuration) -> some View {
        HStack {
          configuration.label
            .foregroundColor(theme.colors.textPrimary)
          
          Spacer()
          
          RoundedRectangle(cornerRadius: theme.borderRadius.full)
            .fill(configuration.isOn ? theme.colors.primary : theme.colors.disabled)
            .frame(width: 50, height: 30)
            .overlay(
              Circle()
                .fill(.white)
                .padding(4)
                .offset(x: configuration.isOn ? 10 : -10)
            )
            .animation(.spring(), value: configuration.isOn)
            .onTapGesture {
              configuration.isOn.toggle()
            }
        }
      }
    }
  }
}

// MARK: - Preview Provider
struct BuzzUIPreview: View {
  @State private var text = ""
  @State private var password = ""
  @State private var isToggleOn = false
  
  var body: some View {
    ScrollView {
      VStack(spacing: 40) {
        textStyles
        buttonStyles
        cardStyles
        inputStyles
        listStyles
        badgeStyles
        toggleStyles
      }
      .padding(24)
    }
    .frame(maxHeight: 700)
    .background(Color(.systemBackground))
  }
  
  // Text Styles Section
  private var textStyles: some View {
    VStack(alignment: .leading, spacing: 24) {
      BuzzUI.Text("Typography", style: .displaySmall)
      
      VStack(alignment: .leading, spacing: 16) {
        BuzzUI.Text("Display Large", style: .displayLarge)
        BuzzUI.Text("Display Medium", style: .displayMedium)
        BuzzUI.Text("Display Small", style: .displaySmall)
        BuzzUI.Text("Heading Large", style: .headingLarge)
        BuzzUI.Text("Heading Medium", style: .headingMedium)
        BuzzUI.Text("Heading Small", style: .headingSmall)
        BuzzUI.Text("Body Large", style: .bodyLarge)
        BuzzUI.Text("Body Medium", style: .bodyMedium)
        BuzzUI.Text("Body Small", style: .bodySmall)
        BuzzUI.Text("Label Large", style: .labelLarge)
        BuzzUI.Text("Label Medium", style: .labelMedium)
        BuzzUI.Text("Label Small", style: .labelSmall)
      }
    }
  }
  
  // Button Styles Section
  private var buttonStyles: some View {
    VStack(alignment: .leading, spacing: 24) {
      BuzzUI.Text("Buttons", style: .displaySmall)
      
      VStack(alignment: .leading, spacing: 16) {
        Group {
          BuzzUI.Button("Primary Button", style: .primary) {}
          BuzzUI.Button("Secondary Button", style: .secondary) {}
          BuzzUI.Button("Tertiary Button", style: .tertiary) {}
          BuzzUI.Button("Destructive Button", style: .destructive) {}
          BuzzUI.Button("Icon Button", style: .primary, icon: Image(systemName: "star.fill")) {}
        }
      }
    }
  }
  
  // Card Styles Section
  private var cardStyles: some View {
    VStack(alignment: .leading, spacing: 24) {
      BuzzUI.Text("Cards", style: .displaySmall)
      
      VStack(spacing: 16) {
        BuzzUI.Card(style: .elevated) {
          cardContent("Elevated Card")
        }
        
        BuzzUI.Card(style: .outlined) {
          cardContent("Outlined Card")
        }
        
        BuzzUI.Card(style: .filled) {
          cardContent("Filled Card")
        }
      }
    }
  }
  
  private func cardContent(_ title: String) -> some View {
    VStack(alignment: .leading, spacing: 8) {
      BuzzUI.Text(title, style: .headingMedium)
      BuzzUI.Text("This is example content that shows how the card looks with multiple lines of text and different styles.", style: .bodyMedium)
      BuzzUI.Button("Card Action", style: .primary, size: .small) {}
    }
  }
  
  // Input Styles Section
  private var inputStyles: some View {
    VStack(alignment: .leading, spacing: 24) {
      BuzzUI.Text("Inputs", style: .displaySmall)
      
      VStack(spacing: 16) {
        BuzzUI.TextField(
          "Basic Input",
          text: $text
        )
        
        BuzzUI.TextField(
          "With Icon",
          text: $text,
          icon: Image(systemName: "envelope")
        )
        
        BuzzUI.TextField(
          "With Error",
          text: $text,
          errorMessage: "This field is required"
        )
        
        BuzzUI.TextField(
          "Password",
          text: $password,
          icon: Image(systemName: "lock"),
          isSecure: true
        )
      }
    }
  }
  
  // List Styles Section
  private var listStyles: some View {
    VStack(alignment: .leading, spacing: 24) {
      BuzzUI.Text("List Items", style: .displaySmall)
      
      VStack(spacing: 16) {
        BuzzUI.ListItem(
          title: "Basic List Item",
          subtitle: "Supporting text"
        )
        
        BuzzUI.ListItem(
          title: "With Leading Icon",
          subtitle: "And subtitle",
          leading: { Image(systemName: "star.fill") }
        )
        
        BuzzUI.ListItem(
          title: "With Trailing Button",
          subtitle: "And subtitle",
          trailing: {
            BuzzUI.Button("Action", style: .primary, size: .small) {}
          }
        )
        
        BuzzUI.ListItem(
          title: "Complete List Item",
          subtitle: "With all elements",
          leading: {  Image(systemName: "person.fill") },
          trailing: {
            BuzzUI.Button("View", style: .secondary, size: .small) {
            }
          }
        )
      }
    }
  }
  
  // Badge Styles Section
  private var badgeStyles: some View {
    VStack(alignment: .leading, spacing: 24) {
      BuzzUI.Text("Badges", style: .displaySmall)
      
      HStack(spacing: 16) {
        BuzzUI.Badge("Info", style: .info)
        BuzzUI.Badge("Success", style: .success)
        BuzzUI.Badge("Warning", style: .warning)
        BuzzUI.Badge("Error", style: .error)
      }
    }
  }
  
  // Toggle Styles Section
  private var toggleStyles: some View {
    VStack(alignment: .leading, spacing: 24) {
      BuzzUI.Text("Toggles", style: .displaySmall)
      
      VStack(spacing: 16) {
        BuzzUI.Toggle("Basic Toggle", isOn: $isToggleOn)
      }
    }
  }
}

extension BuzzUI.ListItem where Leading == EmptyView, Trailing == EmptyView {
  init(title: String, subtitle: String? = nil) {
    self.init(
      title: title,
      subtitle: subtitle,
      leading: { EmptyView() },
      trailing: { EmptyView() }
    )
  }
}

extension BuzzUI.ListItem where Leading == EmptyView {
  init(
    title: String,
    subtitle: String? = nil,
    @ViewBuilder trailing: () -> Trailing
  ) {
    self.init(
      title: title,
      subtitle: subtitle,
      leading: { EmptyView() },
      trailing: trailing
    )
  }
}

extension BuzzUI.ListItem where Trailing == EmptyView {
  init(
    title: String,
    subtitle: String? = nil,
    @ViewBuilder leading: () -> Leading
  ) {
    self.init(
      title: title,
      subtitle: subtitle,
      leading: leading,
      trailing: { EmptyView() }
    )
  }
}

#Preview("BuzzUI Components - Light") {
  BuzzUIPreview()
    .withTheme(AppTheme.light)
}

#Preview("BuzzUI Components - Dark") {
  BuzzUIPreview()
    .withTheme(AppTheme.dark)
    .preferredColorScheme(.dark)
}
