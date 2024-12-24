import SwiftUI

// MARK: - Theme Protocol
protocol ThemeProtocol: Sendable {
  var colors: ThemeColors { get }
  var typography: ThemeTypography { get }
  var spacing: ThemeSpacing { get }
  var borderRadius: ThemeBorderRadius { get }
  var shadows: ThemeShadows { get }
}

// MARK: - Colors
struct ThemeColors: Equatable {
  // Brand Colors
  let primary: Color
  let secondary: Color
  let accent: Color
  
  // Semantic Colors
  let success: Color
  let warning: Color
  let error: Color
  let info: Color
  
  // Background Colors
  let background: Color
  let surface: Color
  let surfaceSecondary: Color
  
  // Text Colors
  let textPrimary: Color
  let textSecondary: Color
  let textTertiary: Color
  let textOnPrimary: Color
  
  // Border Colors
  let border: Color
  let divider: Color
  
  // States
  let disabled: Color
  let hover: Color
  let pressed: Color
}

// MARK: - Typography
struct ThemeTypography: Equatable {
  struct TextStyle: Equatable {
    let font: Font
    let lineHeight: CGFloat
    let letterSpacing: CGFloat
    let size: CGFloat // Store the size separately for calculations
    
    init(size: CGFloat, weight: Font.Weight, lineHeight: CGFloat, letterSpacing: CGFloat) {
      self.font = .system(size: size, weight: weight)
      self.lineHeight = lineHeight
      self.letterSpacing = letterSpacing
      self.size = size
    }
  }
  
  let displayLarge: TextStyle
  let displayMedium: TextStyle
  let displaySmall: TextStyle
  
  let headingLarge: TextStyle
  let headingMedium: TextStyle
  let headingSmall: TextStyle
  
  let bodyLarge: TextStyle
  let bodyMedium: TextStyle
  let bodySmall: TextStyle
  
  let labelLarge: TextStyle
  let labelMedium: TextStyle
  let labelSmall: TextStyle
}

// MARK: - Spacing
struct ThemeSpacing: Equatable {
  let xxs: CGFloat
  let xs: CGFloat
  let sm: CGFloat
  let md: CGFloat
  let lg: CGFloat
  let xl: CGFloat
  let xxl: CGFloat
  
  // Semantic spacing
  let componentPadding: CGFloat
  let containerPadding: CGFloat
  let contentSpacing: CGFloat
  let sectionSpacing: CGFloat
}

// MARK: - Border Radius
struct ThemeBorderRadius: Equatable {
  let none: CGFloat
  let sm: CGFloat
  let md: CGFloat
  let lg: CGFloat
  let xl: CGFloat
  let full: CGFloat
}

// MARK: - Shadows
struct ThemeShadows: Equatable {
  struct Shadow: Equatable {
    let color: Color
    let radius: CGFloat
    let x: CGFloat
    let y: CGFloat
  }
  
  let sm: Shadow
  let md: Shadow
  let lg: Shadow
}

// MARK: - Theme Implementation
struct AppTheme: ThemeProtocol, Equatable {
  let colors: ThemeColors
  let typography: ThemeTypography
  let spacing: ThemeSpacing
  let borderRadius: ThemeBorderRadius
  let shadows: ThemeShadows
  
  private static let defaultTypography = ThemeTypography(
    displayLarge: ThemeTypography.TextStyle(
      size: 57,
      weight: .bold,
      lineHeight: 64,
      letterSpacing: -0.25
    ),
    displayMedium: ThemeTypography.TextStyle(
      size: 45,
      weight: .bold,
      lineHeight: 52,
      letterSpacing: 0
    ),
    displaySmall: ThemeTypography.TextStyle(
      size: 36,
      weight: .bold,
      lineHeight: 44,
      letterSpacing: 0
    ),
    headingLarge: ThemeTypography.TextStyle(
      size: 32,
      weight: .bold,
      lineHeight: 40,
      letterSpacing: 0
    ),
    headingMedium: ThemeTypography.TextStyle(
      size: 28,
      weight: .semibold,
      lineHeight: 36,
      letterSpacing: 0
    ),
    headingSmall: ThemeTypography.TextStyle(
      size: 24,
      weight: .semibold,
      lineHeight: 32,
      letterSpacing: 0
    ),
    bodyLarge: ThemeTypography.TextStyle(
      size: 16,
      weight: .regular,
      lineHeight: 24,
      letterSpacing: 0.5
    ),
    bodyMedium: ThemeTypography.TextStyle(
      size: 14,
      weight: .regular,
      lineHeight: 20,
      letterSpacing: 0.25
    ),
    bodySmall: ThemeTypography.TextStyle(
      size: 12,
      weight: .regular,
      lineHeight: 16,
      letterSpacing: 0.4
    ),
    labelLarge: ThemeTypography.TextStyle(
      size: 14,
      weight: .medium,
      lineHeight: 20,
      letterSpacing: 0.1
    ),
    labelMedium: ThemeTypography.TextStyle(
      size: 12,
      weight: .medium,
      lineHeight: 16,
      letterSpacing: 0.5
    ),
    labelSmall: ThemeTypography.TextStyle(
      size: 11,
      weight: .medium,
      lineHeight: 16,
      letterSpacing: 0.5
    )
  )
  
  private static let defaultSpacing = ThemeSpacing(
    xxs: 4,
    xs: 8,
    sm: 12,
    md: 16,
    lg: 24,
    xl: 32,
    xxl: 48,
    componentPadding: 16,
    containerPadding: 24,
    contentSpacing: 16,
    sectionSpacing: 32
  )
  
  private static let defaultBorderRadius = ThemeBorderRadius(
    none: 0,
    sm: 4,
    md: 8,
    lg: 12,
    xl: 16,
    full: 9999
  )
  
  static let light = AppTheme(
    colors: ThemeColors(
      primary: Color(.sRGB, red: 0.0, green: 0.47, blue: 1.0, opacity: 1.0),
      secondary: Color(.sRGB, red: 0.235, green: 0.235, blue: 0.235, opacity: 1.0),
      accent: Color(.sRGB, red: 1.0, green: 0.835, blue: 0.0, opacity: 1.0),
      success: Color(.sRGB, red: 0.2, green: 0.8, blue: 0.2, opacity: 1.0),
      warning: Color(.sRGB, red: 1.0, green: 0.6, blue: 0.0, opacity: 1.0),
      error: Color(.sRGB, red: 1.0, green: 0.2, blue: 0.2, opacity: 1.0),
      info: Color(.sRGB, red: 0.0, green: 0.6, blue: 1.0, opacity: 1.0),
      background: Color(.sRGB, red: 0.98, green: 0.98, blue: 0.98, opacity: 1.0),
      surface: Color(.sRGB, red: 1.0, green: 1.0, blue: 1.0, opacity: 1.0),
      surfaceSecondary: Color(.sRGB, red: 0.96, green: 0.96, blue: 0.96, opacity: 1.0),
      textPrimary: Color(.sRGB, red: 0.1, green: 0.1, blue: 0.1, opacity: 1.0),
      textSecondary: Color(.sRGB, red: 0.4, green: 0.4, blue: 0.4, opacity: 1.0),
      textTertiary: Color(.sRGB, red: 0.6, green: 0.6, blue: 0.6, opacity: 1.0),
      textOnPrimary: Color(.sRGB, red: 1.0, green: 1.0, blue: 1.0, opacity: 1.0),
      border: Color(.sRGB, red: 0.9, green: 0.9, blue: 0.9, opacity: 1.0),
      divider: Color(.sRGB, red: 0.95, green: 0.95, blue: 0.95, opacity: 1.0),
      disabled: Color(.sRGB, red: 0.9, green: 0.9, blue: 0.9, opacity: 1.0),
      hover: Color(.sRGB, red: 0.0, green: 0.0, blue: 0.0, opacity: 0.05),
      pressed: Color(.sRGB, red: 0.0, green: 0.0, blue: 0.0, opacity: 0.1)
    ),
    typography: defaultTypography,
    spacing: defaultSpacing,
    borderRadius: defaultBorderRadius,
    shadows: ThemeShadows(
      sm: ThemeShadows.Shadow(
        color: Color.black.opacity(0.1),
        radius: 4,
        x: 0,
        y: 2
      ),
      md: ThemeShadows.Shadow(
        color: Color.black.opacity(0.1),
        radius: 8,
        x: 0,
        y: 4
      ),
      lg: ThemeShadows.Shadow(
        color: Color.black.opacity(0.1),
        radius: 16,
        x: 0,
        y: 8
      )
    )
  )
  
  static let dark = AppTheme(
    colors: ThemeColors(
      primary: Color(.sRGB, red: 0.3, green: 0.65, blue: 1.0, opacity: 1.0),
      secondary: Color(.sRGB, red: 0.8, green: 0.8, blue: 0.8, opacity: 1.0),
      accent: Color(.sRGB, red: 1.0, green: 0.9, blue: 0.4, opacity: 1.0),
      success: Color(.sRGB, red: 0.3, green: 0.85, blue: 0.3, opacity: 1.0),
      warning: Color(.sRGB, red: 1.0, green: 0.7, blue: 0.0, opacity: 1.0),
      error: Color(.sRGB, red: 1.0, green: 0.3, blue: 0.3, opacity: 1.0),
      info: Color(.sRGB, red: 0.3, green: 0.7, blue: 1.0, opacity: 1.0),
      background: Color(.sRGB, red: 0.1, green: 0.1, blue: 0.1, opacity: 1.0),
      surface: Color(.sRGB, red: 0.15, green: 0.15, blue: 0.15, opacity: 1.0),
      surfaceSecondary: Color(.sRGB, red: 0.2, green: 0.2, blue: 0.2, opacity: 1.0),
      textPrimary: Color(.sRGB, red: 1.0, green: 1.0, blue: 1.0, opacity: 1.0),
      textSecondary: Color(.sRGB, red: 0.8, green: 0.8, blue: 0.8, opacity: 1.0),
      textTertiary: Color(.sRGB, red: 0.6, green: 0.6, blue: 0.6, opacity: 1.0),
      textOnPrimary: Color(.sRGB, red: 1.0, green: 1.0, blue: 1.0, opacity: 1.0),
      border: Color(.sRGB, red: 0.3, green: 0.3, blue: 0.3, opacity: 1.0),
      divider: Color(.sRGB, red: 0.25, green: 0.25, blue: 0.25, opacity: 1.0),
      disabled: Color(.sRGB, red: 0.3, green: 0.3, blue: 0.3, opacity: 1.0),
      hover: Color(.sRGB, red: 1.0, green: 1.0, blue: 1.0, opacity: 0.05),
      pressed: Color(.sRGB, red: 1.0, green: 1.0, blue: 1.0, opacity: 0.1)
    ),
    typography: defaultTypography,
    spacing: defaultSpacing,
    borderRadius: defaultBorderRadius,
    shadows: ThemeShadows(
      sm: ThemeShadows.Shadow(
        color: Color.black.opacity(0.3),
        radius: 4,
        x: 0,
        y: 2
      ),
      md: ThemeShadows.Shadow(
        color: Color.black.opacity(0.3),
        radius: 8,
        x: 0,
        y: 4
      ),
      lg: ThemeShadows.Shadow(
        color: Color.black.opacity(0.3),
        radius: 16,
        x: 0,
        y: 8
      )
    )
  )
}

// MARK: - Environment Keys
private struct ThemeEnvironmentKey: EnvironmentKey {
  static let defaultValue: ThemeProtocol = AppTheme.light
}

extension EnvironmentValues {
  var theme: ThemeProtocol {
    get { self[ThemeEnvironmentKey.self] }
    set { self[ThemeEnvironmentKey.self] = newValue }
  }
}

// MARK: - View Extensions
extension View {
  func withTheme(_ theme: ThemeProtocol) -> some View {
    environment(\.theme, theme)
  }
  
  func applyTextStyle(_ style: ThemeTypography.TextStyle) -> some View {
    self.font(style.font)
      .lineSpacing(style.lineHeight - style.size)
      .tracking(style.letterSpacing)
  }
}
fileprivate struct ThemePreview: View {
  @Environment(\.theme) private var theme
  
  var body: some View {
    ScrollView {
      VStack(alignment: .leading, spacing: theme.spacing.xl) {
        colorPalette
        textOnBackgroundPreviews
        typographyPreview
        spacingPreview
        borderRadiusPreview
        shadowsPreview
      }
      .padding(theme.spacing.containerPadding)
    }
    .background(theme.colors.background)
  }
  
  // MARK: - Color Palette
  private var colorPalette: some View {
    VStack(alignment: .leading, spacing: theme.spacing.md) {
      sectionTitle("Color Palette")
      
      Group {
        colorSection("Brand", colors: [
          ("Primary", theme.colors.primary),
          ("Secondary", theme.colors.secondary),
          ("Accent", theme.colors.accent)
        ])
        
        colorSection("Semantic", colors: [
          ("Success", theme.colors.success),
          ("Warning", theme.colors.warning),
          ("Error", theme.colors.error),
          ("Info", theme.colors.info)
        ])
        
        colorSection("Background", colors: [
          ("Background", theme.colors.background),
          ("Surface", theme.colors.surface),
          ("Surface Secondary", theme.colors.surfaceSecondary)
        ])
        
        colorSection("Text", colors: [
          ("Text Primary", theme.colors.textPrimary),
          ("Text Secondary", theme.colors.textSecondary),
          ("Text Tertiary", theme.colors.textTertiary),
          ("Text On Primary", theme.colors.textOnPrimary)
        ])
        
        colorSection("States", colors: [
          ("Disabled", theme.colors.disabled),
          ("Hover", theme.colors.hover),
          ("Pressed", theme.colors.pressed)
        ])
      }
    }
  }
  
  private func colorSection(_ title: String, colors: [(String, Color)]) -> some View {
    VStack(alignment: .leading, spacing: theme.spacing.sm) {
      Text(title)
        .font(.headline)
        .foregroundColor(theme.colors.textSecondary)
      
      ForEach(colors, id: \.0) { name, color in
        colorRow(name, color)
      }
    }
  }
  
  private func colorRow(_ name: String, _ color: Color) -> some View {
    HStack(spacing: theme.spacing.md) {
      RoundedRectangle(cornerRadius: theme.borderRadius.sm)
        .fill(color)
        .frame(width: 60, height: 30)
        .overlay(
          RoundedRectangle(cornerRadius: theme.borderRadius.sm)
            .stroke(theme.colors.border, lineWidth: 1)
        )
      
      Text(name)
        .foregroundColor(theme.colors.textPrimary)
        .font(.system(.body, design: .monospaced))
    }
  }
  
  // MARK: - Text on Background Previews
  private var textOnBackgroundPreviews: some View {
    VStack(alignment: .leading, spacing: theme.spacing.lg) {
      sectionTitle("Text on Backgrounds")
      
      Group {
        textOnBackground(
          "Text on Primary",
          backgroundColor: theme.colors.primary,
          textColors: [
            ("Text On Primary", theme.colors.textOnPrimary),
            ("Text Primary", theme.colors.textPrimary),
            ("Text Secondary", theme.colors.textSecondary)
          ]
        )
        
        textOnBackground(
          "Text on Surface",
          backgroundColor: theme.colors.surface,
          textColors: [
            ("Text Primary", theme.colors.textPrimary),
            ("Text Secondary", theme.colors.textSecondary),
            ("Text Tertiary", theme.colors.textTertiary)
          ]
        )
        
        textOnBackground(
          "Text on Background",
          backgroundColor: theme.colors.background,
          textColors: [
            ("Text Primary", theme.colors.textPrimary),
            ("Text Secondary", theme.colors.textSecondary),
            ("Text Tertiary", theme.colors.textTertiary)
          ]
        )
      }
    }
  }
  
  private func textOnBackground(_ title: String, backgroundColor: Color, textColors: [(String, Color)]) -> some View {
    VStack(alignment: .leading, spacing: theme.spacing.sm) {
      Text(title)
        .font(.headline)
        .foregroundColor(theme.colors.textSecondary)
      
      VStack(alignment: .leading, spacing: theme.spacing.sm) {
        ForEach(textColors, id: \.0) { name, color in
          Text(name)
            .foregroundColor(color)
            .padding(theme.spacing.md)
        }
      }
      .frame(maxWidth: .infinity, alignment: .leading)
      .background(backgroundColor)
      .cornerRadius(theme.borderRadius.md)
    }
  }
  
  // MARK: - Typography Preview
  private var typographyPreview: some View {
    VStack(alignment: .leading, spacing: theme.spacing.lg) {
      sectionTitle("Typography")
      
      Group {
        textStyleSection("Display", styles: [
          ("Display Large", theme.typography.displayLarge),
          ("Display Medium", theme.typography.displayMedium),
          ("Display Small", theme.typography.displaySmall)
        ])
        
        textStyleSection("Heading", styles: [
          ("Heading Large", theme.typography.headingLarge),
          ("Heading Medium", theme.typography.headingMedium),
          ("Heading Small", theme.typography.headingSmall)
        ])
        
        textStyleSection("Body", styles: [
          ("Body Large", theme.typography.bodyLarge),
          ("Body Medium", theme.typography.bodyMedium),
          ("Body Small", theme.typography.bodySmall)
        ])
        
        textStyleSection("Label", styles: [
          ("Label Large", theme.typography.labelLarge),
          ("Label Medium", theme.typography.labelMedium),
          ("Label Small", theme.typography.labelSmall)
        ])
      }
    }
  }
  
  private func textStyleSection(_ title: String, styles: [(String, ThemeTypography.TextStyle)]) -> some View {
    VStack(alignment: .leading, spacing: theme.spacing.sm) {
      Text(title)
        .font(.headline)
        .foregroundColor(theme.colors.textSecondary)
      
      VStack(alignment: .leading, spacing: theme.spacing.sm) {
        ForEach(styles, id: \.0) { name, style in
          VStack(alignment: .leading, spacing: 4) {
            Text(name)
              .applyTextStyle(style)
            
            Text("Size: \(Int(style.size))pt • Line Height: \(Int(style.lineHeight))pt • Spacing: \(style.letterSpacing)pt")
              .font(.caption)
              .foregroundColor(theme.colors.textTertiary)
          }
        }
      }
      .padding(theme.spacing.md)
      .background(theme.colors.surface)
      .cornerRadius(theme.borderRadius.md)
    }
  }
  
  // MARK: - Spacing Preview
  private var spacingPreview: some View {
    VStack(alignment: .leading, spacing: theme.spacing.lg) {
      sectionTitle("Spacing Scale")
      
      VStack(alignment: .leading, spacing: theme.spacing.md) {
        spacingSection("Base Scale", spacings: [
          ("XXS", theme.spacing.xxs),
          ("XS", theme.spacing.xs),
          ("SM", theme.spacing.sm),
          ("MD", theme.spacing.md),
          ("LG", theme.spacing.lg),
          ("XL", theme.spacing.xl),
          ("XXL", theme.spacing.xxl)
        ])
        
        spacingSection("Semantic", spacings: [
          ("Component", theme.spacing.componentPadding),
          ("Container", theme.spacing.containerPadding),
          ("Content", theme.spacing.contentSpacing),
          ("Section", theme.spacing.sectionSpacing)
        ])
      }
    }
  }
  
  private func spacingSection(_ title: String, spacings: [(String, CGFloat)]) -> some View {
    VStack(alignment: .leading, spacing: theme.spacing.sm) {
      Text(title)
        .font(.headline)
        .foregroundColor(theme.colors.textSecondary)
      
      ForEach(spacings, id: \.0) { name, spacing in
        HStack(alignment: .center, spacing: theme.spacing.md) {
          Rectangle()
            .fill(theme.colors.primary)
            .frame(width: spacing, height: 40)
          
          VStack(alignment: .leading) {
            Text(name)
              .foregroundColor(theme.colors.textPrimary)
            Text("\(Int(spacing))pt")
              .font(.caption)
              .foregroundColor(theme.colors.textTertiary)
          }
        }
      }
    }
  }
  
  // Helper Views
  private func sectionTitle(_ title: String) -> some View {
    Text(title)
      .font(.title)
      .foregroundColor(theme.colors.textPrimary)
      .padding(.bottom, theme.spacing.sm)
  }
  
  private var borderRadiusPreview: some View {
    VStack(alignment: .leading, spacing: theme.spacing.md) {
      Text("Border Radius")
        .font(.title)
      
      HStack(spacing: theme.spacing.md) {
        borderRadiusExample("SM", theme.borderRadius.sm)
        borderRadiusExample("MD", theme.borderRadius.md)
        borderRadiusExample("LG", theme.borderRadius.lg)
      }
    }
  }
  
  private func borderRadiusExample(_ label: String, _ radius: CGFloat) -> some View {
    VStack {
      RoundedRectangle(cornerRadius: radius)
        .fill(theme.colors.primary)
        .frame(width: 60, height: 60)
      Text(label)
        .font(.caption)
    }
  }
  
  private var shadowsPreview: some View {
    VStack(alignment: .leading, spacing: theme.spacing.md) {
      Text("Shadows")
        .font(.title)
      
      HStack(spacing: theme.spacing.lg) {
        shadowExample("SM", theme.shadows.sm)
        shadowExample("MD", theme.shadows.md)
        shadowExample("LG", theme.shadows.lg)
      }
    }
  }
  
  private func shadowExample(_ label: String, _ shadow: ThemeShadows.Shadow) -> some View {
    VStack {
      RoundedRectangle(cornerRadius: theme.borderRadius.md)
        .fill(theme.colors.surface)
        .frame(width: 80, height: 80)
        .shadow(
          color: shadow.color,
          radius: shadow.radius,
          x: shadow.x,
          y: shadow.y
        )
      Text(label)
        .font(.caption)
    }
  }
}

// MARK: - Preview Provider
#Preview("Light Theme") {
  ThemePreview()
    .withTheme(AppTheme.light)
}

#Preview("Dark Theme") {
  ThemePreview()
    .withTheme(AppTheme.dark)
    .preferredColorScheme(.dark)
}
