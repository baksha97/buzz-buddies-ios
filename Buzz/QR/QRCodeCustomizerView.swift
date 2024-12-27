import SwiftUI

struct QRCodeCustomizerView: View {
  // MARK: - Properties
  @State private var backgroundColor: Color = Color.cyan
  @State private var qrImage: String = "QR_PLACEHOLDER" // Replace with actual asset name
  
  var buttonTextColor: Color {
    return backgroundColor.accessibleTextColor
  }
  
  var body: some View {
    ZStack {
      // Background Color
      backgroundColor
        .edgesIgnoringSafeArea(.all)
      
      VStack {
        Spacer()
        
        // QR Code Image
        Image(qrImage)
          .resizable()
          .scaledToFit()
          .frame(width: 250, height: 250)
          .padding()
          .background(RoundedRectangle(cornerRadius: 20).fill(backgroundColor.opacity(0.3)))
        
        Spacer()
        
        // Control List
        ScrollView {
          VStack(spacing: 12) {
            // Custom Inline Color Picker Button
            InlineCustomColorPickerButton(
              title: "Color",
              selectedColor: $backgroundColor,
              textColor: buttonTextColor
            )
            
            ControlButton(title: "Logo", icon: "star.fill", textColor: buttonTextColor) {
              // Action for Logo
            }
            ControlButton(title: "Border", icon: "square.on.square", textColor: buttonTextColor) {
              // Action for Border
            }
            ControlButton(title: "Corners", icon: "square", textColor: buttonTextColor) {
              // Action for Corners
            }
            ControlButton(title: "Pixels", icon: "circle.grid.2x2", textColor: buttonTextColor) {
              // Action for Pixels
            }
            ControlButton(title: "Pupils", icon: "eye.fill", textColor: buttonTextColor) {
              // Action for Pupils
            }
            ControlButton(title: "Eyes", icon: "eye.circle", textColor: buttonTextColor) {
              // Action for Eyes
            }
          }
          .padding()
        }
        
        Spacer()
      }
    }
  }
}

extension QRCodeCustomizerView {
  
  // MARK: - Inline Custom Color Picker Button
  struct InlineCustomColorPickerButton: View {
    var title: String
    @Binding var selectedColor: Color
    var textColor: Color
    
    var body: some View {
      HStack {
        Text(title)
          .font(.headline)
          .foregroundColor(textColor)
        Spacer()
        ZStack {
          // Custom Visual Representation (Circle Fill Icon)
          Circle()
            .fill(selectedColor)
            .frame(width: 30, height: 30)
            .overlay(
              Circle()
                .stroke(textColor.opacity(0.5), lineWidth: 1)
            )
          
          // Invisible ColorPicker that passes touch events
          ColorPicker("", selection: $selectedColor)
            .labelsHidden()
            .opacity(0.02) // Make it nearly invisible
            .frame(width: 30, height: 30)
            .allowsHitTesting(true) // Ensures taps go to ColorPicker
        }
      }
      .padding()
      .frame(maxWidth: .infinity)
      .background(RoundedRectangle(cornerRadius: 12).fill(Color.white.opacity(0.2)))
    }
  }
  
  // MARK: - Control Button Component
  struct ControlButton: View {
    var title: String
    var icon: String
    var textColor: Color
    var action: () -> Void
    
    var body: some View {
      Button(action: action) {
        HStack {
          Text(title)
            .font(.headline)
            .foregroundColor(textColor)
          Spacer()
          Image(systemName: icon)
            .font(.headline)
            .foregroundColor(textColor)
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(RoundedRectangle(cornerRadius: 12).fill(Color.white.opacity(0.2)))
      }
    }
  }
  
  // MARK: - Color Extension for Optimal Text Contrast
//  extension Color {
//    /// Determine the most readable text color based on luminance.
//    var accessibleTextColor: Color {
//      let components = UIColor(self).cgColor.components ?? [0, 0, 0, 1]
//      let red = components[0]
//      let green = components[1]
//      let blue = components[2]
//      
//      // Calculate luminance using WCAG formula
//      let luminance = (0.2126 * red + 0.7152 * green + 0.0722 * blue)
//      
//      // Adjust contrast ratio for readability
//      if luminance > 0.5 {
//        // Light background → Return a darker shade based on background
//        return Color.black.opacity(0.7)
//      } else {
//        // Dark background → Return a lighter shade based on background
//        return Color.white.opacity(0.9)
//      }
//    }
//  }
}

// MARK: - Preview
#Preview {
  QRCodeCustomizerView()
}
