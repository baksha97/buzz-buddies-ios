import SwiftUI
import QRCode

class QRCodeEditorModel: ObservableObject {
    @Published var urlText: String = ""
    @Published var foregroundColor: Color = .black
    
    // Some shape selections.
    // Use the library’s built-in shapes or just pick a few for a demo:
    @Published var selectedEyeShape: QRCodeEyeShape = QRCode.EyeShape.Square()
    @Published var selectedPupilShape: QRCodePupilShape? = nil  // nil means use whatever the eye shape’s pupil shape is
    @Published var selectedPixelShape: QRCodePixelShape = QRCode.PixelShape.Square()
    
    // Whether to show “offPixels,” “border,” or a “logo,” etc.
    @Published var showOffPixels = false
    @Published var borderWidth: CGFloat = 0
    @Published var selectedLogo: UIImage? = nil
    
    /// The actual QRCode.Document that reflects all the above settings.
    /// You can expose this as a computed property:
    var qrDocument: QRCode.Document {
        // Create a Document with the user’s text. High error correction if you plan on adding a big logo.
        let doc = QRCode.Document(utf8String: urlText, errorCorrection: .high)
        
        // 1) Color / background
        doc.design.style.background = QRCode.FillStyle.Solid(.white)  // or transparent, etc.
        doc.design.style.onPixels = QRCode.FillStyle.Solid(foregroundColor.cgColor ?? CGColor.black)

        // 2) Set shapes
        doc.design.shape.eye = selectedEyeShape
        if let pupil = selectedPupilShape {
            doc.design.shape.pupil = pupil
        }
        doc.design.shape.onPixels = selectedPixelShape
        
        // 3) Off-pixels (optional)
        if showOffPixels {
            // Just do a different shape or color. Something subtle:
            doc.design.shape.offPixels = QRCode.PixelShape.Circle(insetFraction: 0.3)
            doc.design.style.offPixels = QRCode.FillStyle.Solid(CGColor(gray: 0.8, alpha: 0.3))
        } else {
            // Remove the off-pixels shape so it doesn’t render them
            doc.design.shape.offPixels = nil
            doc.design.style.offPixels = nil
        }
        
        // 4) Add a "border" by setting an extra quiet zone if desired
        if borderWidth > 0 {
            doc.design.additionalQuietZonePixels = Int(borderWidth)
        } else {
            doc.design.additionalQuietZonePixels = 0
        }
        
        // 5) Add a logo if chosen
        if let logo = selectedLogo?.cgImage {
            // Easiest method: use the “masking” approach so the middle of the code is forcibly blanked out
            let logoTemplate = QRCode.LogoTemplate(logoImage: logo)
            doc.logoTemplate = logoTemplate
        } else {
            doc.logoTemplate = nil
        }
        
        return doc
    }
    
    // Quick utility for randomizing shapes or color
    func randomize() {
        let shapes: [QRCodePixelShape] = [
            QRCode.PixelShape.Square(),
            QRCode.PixelShape.Circle(),
            QRCode.PixelShape.RoundedPath(cornerRadiusFraction: 0.8),
            QRCode.PixelShape.Vertical(insetFraction: 0.2),
            QRCode.PixelShape.Wave()
        ]
        
        let eyeShapes: [QRCodeEyeShape] = [
            QRCode.EyeShape.Square(),
            QRCode.EyeShape.Circle(),
            QRCode.EyeShape.Leaf(),
            QRCode.EyeShape.Teardrop(),
            QRCode.EyeShape.RoundedRect()
        ]
        
        self.selectedPixelShape = shapes.randomElement() ?? QRCode.PixelShape.Square()
        self.selectedEyeShape   = eyeShapes.randomElement() ?? QRCode.EyeShape.Square()
        
        // Random color
        let randColor = Color(
            red:   Double.random(in: 0...1),
            green: Double.random(in: 0...1),
            blue:  Double.random(in: 0...1)
        )
        self.foregroundColor = randColor
        
        // Toggle other settings
        self.showOffPixels = Bool.random()
        self.borderWidth = [0, 2, 4, 8].randomElement() ?? 0
    }
}
