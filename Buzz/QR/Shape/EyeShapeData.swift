import SwiftUI
import QRCode

enum EyeShapeData: String, CaseIterable {
  var id: String { rawValue }
  
  case barsHorizontal = "Bars Horizontal"
  case barsVertical = "Bars Vertical"
  case circle = "Circle"
  case cloud = "Cloud"
  case corneredPixels = "Cornered Pixels"
  case crt = "CRT"
  case dotDragHorizontal = "Dot Drag Horizontal"
  case dotDragVertical = "Dot Drag Vertical"
  case edges = "Edges"
  case explode = "Explode"
  case eye = "Eye"
  case fireball = "Fireball"
  case headlight = "Headlight"
  case leaf = "Leaf"
  case peacock = "Peacock"
  case pinch = "Pinch"
  case pixels = "Pixels"
  case roundedOuter = "Rounded Outer"
  case roundedPointingIn = "Rounded Pointing In"
  case roundedPointingOut = "Rounded Pointing Out"
  case roundedRect = "Rounded Rect"
  case shield = "Shield"
  case spikyCircle = "Spiky Circle"
  case square = "Square"
  case squarePeg = "Square Peg"
  case squircle = "Squircle"
  case surroundingBars = "Surrounding Bars"
  case teardrop = "Teardrop"
  case ufo = "UFO"
  case usePixelShape = "Use Pixel Shape"
  
  /// Generates the corresponding QRCode eye shape
  var generator: QRCodeEyeShapeGenerator {
    switch self {
    case .barsHorizontal: return QRCode.EyeShape.BarsHorizontal()
    case .barsVertical: return QRCode.EyeShape.BarsVertical()
    case .circle: return QRCode.EyeShape.Circle()
    case .cloud: return QRCode.EyeShape.Cloud()
    case .corneredPixels: return QRCode.EyeShape.CorneredPixels()
    case .crt: return QRCode.EyeShape.CRT()
    case .dotDragHorizontal: return QRCode.EyeShape.DotDragHorizontal()
    case .dotDragVertical: return QRCode.EyeShape.DotDragVertical()
    case .edges: return QRCode.EyeShape.Edges()
    case .explode: return QRCode.EyeShape.Explode()
    case .eye: return QRCode.EyeShape.Eye()
    case .fireball: return QRCode.EyeShape.Fireball()
    case .headlight: return QRCode.EyeShape.Headlight()
    case .leaf: return QRCode.EyeShape.Leaf()
    case .peacock: return QRCode.EyeShape.Peacock()
    case .pinch: return QRCode.EyeShape.Pinch()
    case .pixels: return QRCode.EyeShape.Pixels()
    case .roundedOuter: return QRCode.EyeShape.RoundedOuter()
    case .roundedPointingIn: return QRCode.EyeShape.RoundedPointingIn()
    case .roundedPointingOut: return QRCode.EyeShape.RoundedPointingOut()
    case .roundedRect: return QRCode.EyeShape.RoundedRect()
    case .shield: return QRCode.EyeShape.Shield()
    case .spikyCircle: return QRCode.EyeShape.SpikyCircle()
    case .square: return QRCode.EyeShape.Square()
    case .squarePeg: return QRCode.EyeShape.SquarePeg()
    case .squircle: return QRCode.EyeShape.Squircle()
    case .surroundingBars: return QRCode.EyeShape.SurroundingBars()
    case .teardrop: return QRCode.EyeShape.Teardrop()
    case .ufo: return QRCode.EyeShape.UFO()
    case .usePixelShape: return QRCode.EyeShape.UsePixelShape()
    }
  }
  

}


struct EyeShapeView: View {
  let shape: EyeShapeData
  
  var body: some View {
    VStack {
      shape
        .reference
        .resizable()
        .scaledToFit()
        .frame(width: 100, height: 100)
      
      Text(shape.rawValue)
        .font(.headline)
    }
  }
}

#Preview {
  ScrollView {
    LazyVGrid(columns: [GridItem(.adaptive(minimum: 120))]) {
      ForEach(EyeShapeData.allCases, id: \.self) { shape in
        EyeShapeView(shape: shape)
      }
    }
  }
}
