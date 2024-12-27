import SwiftUI

struct QRCodeCustomizerView: View {
    // MARK: - Properties
    @State private var backgroundColor: Color = Color.cyan
    @State private var qrImage: String = "QR_PLACEHOLDER" // Replace with actual asset name
    
    // Action Buttons
    let floatingActions: [(title: String, icon: String)] = [
        ("Delete", "trash"),
        ("Randomize", "shuffle"),
        ("Export", "arrow.up")
    ]
    
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
                        ControlButton(title: "Color", icon: "circle.fill") {
                            // Action for Color
                        }
                        ControlButton(title: "Logo", icon: "star.fill") {
                            // Action for Logo
                        }
                        ControlButton(title: "Border", icon: "square.on.square") {
                            // Action for Border
                        }
                        ControlButton(title: "Corners", icon: "square") {
                            // Action for Corners
                        }
                        ControlButton(title: "Pixels", icon: "circle.grid.2x2") {
                            // Action for Pixels
                        }
                        ControlButton(title: "Pupils", icon: "eye.fill") {
                            // Action for Pupils
                        }
                        ControlButton(title: "Eyes", icon: "eye.circle") {
                            // Action for Eyes
                        }
                    }
                    .padding()
                }
                
                Spacer()
            }
            
            // Floating Action Buttons
            HStack(spacing: 40) {
                ForEach(floatingActions, id: \.title) { action in
                    Button(action: {
                        // Handle Action
                    }) {
                        VStack {
                            Image(systemName: action.icon)
                                .font(.title)
                            Text(action.title)
                                .font(.caption)
                        }
                        .padding()
                        .background(backgroundColor.opacity(0.8))
                        .clipShape(Circle())
                        .shadow(radius: 4)
                    }
                }
            }
            .padding(.bottom, 30)
            .frame(maxHeight: .infinity, alignment: .bottom)
        }
    }
}

// MARK: - Control Button Component
struct ControlButton: View {
    var title: String
    var icon: String
    var action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                Text(title)
                    .font(.headline)
                Spacer()
                Image(systemName: icon)
                    .font(.headline)
            }
            .padding()
            .frame(maxWidth: .infinity)
            .background(RoundedRectangle(cornerRadius: 12).fill(Color.white.opacity(0.2)))
        }
    }
}

// MARK: - Preview
struct QRCodeCustomizerView_Previews: PreviewProvider {
    static var previews: some View {
        QRCodeCustomizerView()
    }
}
