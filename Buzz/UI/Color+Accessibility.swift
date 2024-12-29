import SwiftUI

extension Color {
  var accessibleTextColor: Color {
    let components = UIColor(self).cgColor.components ?? [0, 0, 0, 1]
    let red = components[0]
    let green = components[1]
    let blue = components[2]
    
    let luminance = (0.2126 * red + 0.7152 * green + 0.0722 * blue)
    
    return luminance > 0.5 ? Color.black.opacity(0.7) : Color.white.opacity(0.9)
  }
}
