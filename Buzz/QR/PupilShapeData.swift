import SwiftUI
import QRCode

enum PupilShapeData: String, CaseIterable, ImageReferenceable {

  var id: String { rawValue }
  
  case barsHorizontal = "Bars Horizontal"
  case barsHorizontalSquare = "Bars Horizontal Square"
  case barsVertical = "Bars Vertical"
  case barsVerticalSquare = "Bars Vertical Square"
  case blade = "Blade"
  case blobby = "Blobby"
  case circle = "Circle"
  case cloud = "Cloud"
  case corneredPixels = "Cornered Pixels"
  case cross = "Cross"
  case crossCurved = "Cross Curved"
  case crt = "CRT"
  case dotDragHorizontal = "Dot Drag Horizontal"
  case dotDragVertical = "Dot Drag Vertical"
  case edges = "Edges"
  case explode = "Explode"
  case forest = "Forest"
  case hexagonLeaf = "Hexagon Leaf"
  case leaf = "Leaf"
  case orbits = "Orbits"
  case pinch = "Pinch"
  case pixels = "Pixels"
  case roundedOuter = "Rounded Outer"
  case roundedPointingIn = "Rounded Pointing In"
  case roundedPointingOut = "Rounded Pointing Out"
  case roundedRect = "Rounded Rect"
  case seal = "Seal"
  case shield = "Shield"
  case spikyCircle = "Spiky Circle"
  case square = "Square"
  case squircle = "Squircle"
  case teardrop = "Teardrop"
  case ufo = "UFO"
  case usePixelShape = "Use Pixel Shape"
  
  /// Generates the corresponding QRCode pupil shape
  func makeShape() -> QRCodePupilShapeGenerator {
    switch self {
    case .barsHorizontal: return QRCode.PupilShape.BarsHorizontal()
    case .barsHorizontalSquare: return QRCode.PupilShape.SquareBarsHorizontal()
    case .barsVertical: return QRCode.PupilShape.BarsVertical()
    case .barsVerticalSquare: return QRCode.PupilShape.SquareBarsVertical()
    case .blade: return QRCode.PupilShape.Blade()
    case .blobby: return QRCode.PupilShape.Blobby()
    case .circle: return QRCode.PupilShape.Circle()
    case .cloud: return QRCode.PupilShape.Cloud()
    case .corneredPixels: return QRCode.PupilShape.CorneredPixels()
    case .cross: return QRCode.PupilShape.Cross()
    case .crossCurved: return QRCode.PupilShape.CrossCurved()
    case .crt: return QRCode.PupilShape.CRT()
    case .dotDragHorizontal: return QRCode.PupilShape.DotDragHorizontal()
    case .dotDragVertical: return QRCode.PupilShape.DotDragVertical()
    case .edges: return QRCode.PupilShape.Edges()
    case .explode: return QRCode.PupilShape.Explode()
    case .forest: return QRCode.PupilShape.Forest()
    case .hexagonLeaf: return QRCode.PupilShape.HexagonLeaf()
    case .leaf: return QRCode.PupilShape.Leaf()
    case .orbits: return QRCode.PupilShape.Orbits()
    case .pinch: return QRCode.PupilShape.Pinch()
    case .pixels: return QRCode.PupilShape.Pixels()
    case .roundedOuter: return QRCode.PupilShape.RoundedOuter()
    case .roundedPointingIn: return QRCode.PupilShape.RoundedPointingIn()
    case .roundedPointingOut: return QRCode.PupilShape.RoundedPointingOut()
    case .roundedRect: return QRCode.PupilShape.RoundedRect()
    case .seal: return QRCode.PupilShape.Seal()
    case .shield: return QRCode.PupilShape.Shield()
    case .spikyCircle: return QRCode.PupilShape.SpikyCircle()
    case .square: return QRCode.PupilShape.Square()
    case .squircle: return QRCode.PupilShape.Squircle()
    case .teardrop: return QRCode.PupilShape.Teardrop()
    case .ufo: return QRCode.PupilShape.UFO()
    case .usePixelShape: return QRCode.PupilShape.UsePixelShape()
    }
  }
  
  /// Provides an example image for each shape using Swift-generated asset symbols
  var reference: Image {
    switch self {
    case .barsHorizontal: return Image(.pupilBarsHorizontal)
    case .barsHorizontalSquare: return Image(.pupilBarsHorizontalSquare)
    case .barsVertical: return Image(.pupilBarsVertical)
    case .barsVerticalSquare: return Image(.pupilBarsVerticalSquare)
    case .blade: return Image(.pupilBlade)
    case .blobby: return Image(.pupilBlobby)
    case .circle: return Image(.pupilCircle)
    case .cloud: return Image(.pupilCloud)
    case .corneredPixels: return Image(.pupilCorneredPixels)
    case .cross: return Image(.pupilCross)
    case .crossCurved: return Image(.pupilCrossCurved)
    case .crt: return Image(.pupilCrt)
    case .dotDragHorizontal: return Image(.pupilDotDragHorizontal)
    case .dotDragVertical: return Image(.pupilDotDragVertical)
    case .edges: return Image(.pupilEdges)
    case .explode: return Image(.pupilExplode)
    case .forest: return Image(.pupilForest)
    case .hexagonLeaf: return Image(.pupilHexagonLeaf)
    case .leaf: return Image(.pupilLeaf)
    case .orbits: return Image(.pupilOrbits)
    case .pinch: return Image(.pupilPinch)
    case .pixels: return Image(.pupilPixels)
    case .roundedOuter: return Image(.pupilRoundedOuter)
    case .roundedPointingIn: return Image(.pupilRoundedPointingIn)
    case .roundedPointingOut: return Image(.pupilRoundedPointingOut)
    case .roundedRect: return Image(.pupilRoundedRect)
    case .seal: return Image(.pupilSeal)
    case .shield: return Image(.pupilShield)
    case .spikyCircle: return Image(.pupilSpikyCircle)
    case .square: return Image(.pupilSquare)
    case .squircle: return Image(.pupilSquircle)
    case .teardrop: return Image(.pupilTeardrop)
    case .ufo: return Image(.pupilUfo)
    case .usePixelShape: return Image(.pupilUsePixelShape)
    }
  }
}

struct PupilShapeView: View {
  let shape: PupilShapeData
  
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
      ForEach(PupilShapeData.allCases, id: \.self) { shape in
        PupilShapeView(shape: shape)
      }
    }
  }
}
