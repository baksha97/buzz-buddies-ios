import SwiftUI

// MARK: - Theme

struct Theme {
    struct Colors {
        static let primary = Color.blue // Example primary color
        static let secondary = Color.gray // Example secondary color
        static let background = Color(UIColor.systemBackground) // Adapts to light/dark mode
        static let text = Color(UIColor.label) // Adapts to light/dark mode
        static let accent = Color.accentColor // Default accent color
        static let destructive = Color.red
        
        // Custom color palette
        static let midnightBlue = Color(red: 0.0, green: 0.2, blue: 0.4)
        static let lightGray = Color(red: 0.9, green: 0.9, blue: 0.9)
        static let darkGray = Color(red: 0.4, green: 0.4, blue: 0.4)
    }

    struct Fonts {
        static let title = Font.largeTitle.bold()
        static let headline = Font.headline
        static let body = Font.body
        static let caption = Font.caption
        static let button = Font.body.bold()
    }

    struct Styles {
      @MainActor static let borderedProminentButtonStyle = BorderedProminentButtonStyle()
      @MainActor static let borderedButtonStyle = BorderedButtonStyle()
      @MainActor static let borderlessButtonStyle = BorderlessButtonStyle()
    }

  struct Images {
         static let add = Image(systemName: "plus")
         static let delete = Image(systemName: "trash")
         static let edit = Image(systemName: "pencil")
         static let checkmark = Image(systemName: "checkmark")
         static let client = Image(systemName: "person.crop.circle.fill") // Built-in client emoji
         static let reward = Image(systemName: "gift.fill") // Built-in reward emoji
         static let phone = Image(systemName: "phone.fill")
         static let referred = Image(systemName: "person.2.fill")
         static let referredBy = Image(systemName: "arrow.turn.up.left")
         static let notes = Image(systemName: "note.text")
     }
}

// MARK: - View Modifiers

struct ThemedForm: ViewModifier {
    func body(content: Content) -> some View {
        content
        .scrollContentBackground(.hidden)
        .background(Theme.Colors.background)
    }
}

struct ThemedList: ViewModifier {
    func body(content: Content) -> some View {
        List {
            content
        }
        .listStyle(.insetGrouped)
        .scrollContentBackground(.hidden)
        .background(Theme.Colors.background)
    }
}

struct ThemedNavigationView: ViewModifier {
    func body(content: Content) -> some View {
        NavigationView {
            content
        }
    }
}

struct ThemedVStack: ViewModifier {
    func body(content: Content) -> some View {
        VStack {
            content
        }
        .padding()
        .background(Theme.Colors.background)
    }
}

struct ThemedNavigationTitle: ViewModifier {
    let title: String

    func body(content: Content) -> some View {
        content
            .navigationTitle(title)
            .font(Theme.Fonts.headline)
    }
}

struct ThemedSectionHeader: ViewModifier {
    let title: String

    func body(content: Content) -> some View {
        content
            .font(Theme.Fonts.headline)
            .foregroundColor(Theme.Colors.secondary)
            .textCase(nil)
    }
}

extension View {
    func themedForm() -> some View {
        self.modifier(ThemedForm())
    }

    func themedList() -> some View {
        self.modifier(ThemedList())
    }
    
    func themedNavigationView() -> some View {
        self.modifier(ThemedNavigationView())
    }

    func themedVStack() -> some View {
        self.modifier(ThemedVStack())
    }

    func themedNavigationTitle(_ title: String) -> some View {
        self.modifier(ThemedNavigationTitle(title: title))
    }

    func themedSectionHeader(_ title: String) -> some View {
        self.modifier(ThemedSectionHeader(title: title))
    }
}
