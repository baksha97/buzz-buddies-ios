import SwiftUI
import QRCode

enum PixelShapeData: String, CaseIterable {
  case abstract = "Abstract"
  case arrow = "Arrow"
  case blob = "Blob"
  case circle = "Circle"
  case circuit = "Circuit"
  case crt = "CRT"
  case curvePixel = "Curve Pixel"
  case donut = "Donut"
  case flower = "Flower"
  case grid2x2 = "Grid 2x2"
  case grid3x3 = "Grid 3x3"
  case grid4x4 = "Grid 4x4"
  case heart = "Heart"
  case horizontal = "Horizontal"
  case pointy = "Pointy"
  case razor = "Razor"
  case roundedEndIndent = "Rounded End Indent"
  case roundedPath = "Rounded Path"
  case roundedRect = "Rounded Rect"
  case sharp = "Sharp"
  case shiny = "Shiny"
  case spikyCircle = "Spiky Circle"
  case square = "Square"
  case squircle = "Squircle"
  case star = "Star"
  case stitch = "Stitch"
  case vertical = "Vertical"
  case vortex = "Vortex"
  case wave = "Wave"
  
  /// Generates the corresponding QRCode shape
  func makeShape() -> QRCodePixelShapeGenerator {
    switch self {
    case .abstract: return QRCode.PixelShape.Abstract()
    case .arrow: return QRCode.PixelShape.Arrow()
    case .blob: return QRCode.PixelShape.Blob()
    case .circle: return QRCode.PixelShape.Circle()
    case .circuit: return QRCode.PixelShape.Circuit()
    case .crt: return QRCode.PixelShape.CRT()
    case .curvePixel: return QRCode.PixelShape.CurvePixel()
    case .donut: return QRCode.PixelShape.Donut()
    case .flower: return QRCode.PixelShape.Flower()
    case .grid2x2: return QRCode.PixelShape.Grid2x2()
    case .grid3x3: return QRCode.PixelShape.Grid3x3()
    case .grid4x4: return QRCode.PixelShape.Grid4x4()
    case .heart: return QRCode.PixelShape.Heart()
    case .horizontal: return QRCode.PixelShape.Horizontal()
    case .pointy: return QRCode.PixelShape.Pointy()
    case .razor: return QRCode.PixelShape.Razor()
    case .roundedEndIndent: return QRCode.PixelShape.RoundedEndIndent()
    case .roundedPath: return QRCode.PixelShape.RoundedPath()
    case .roundedRect: return QRCode.PixelShape.RoundedRect()
    case .sharp: return QRCode.PixelShape.Sharp()
    case .shiny: return QRCode.PixelShape.Shiny()
    case .spikyCircle: return QRCode.PixelShape.SpikyCircle()
    case .square: return QRCode.PixelShape.Square()
    case .squircle: return QRCode.PixelShape.Squircle()
    case .star: return QRCode.PixelShape.Star()
    case .stitch: return QRCode.PixelShape.Stitch()
    case .vertical: return QRCode.PixelShape.Vertical()
    case .vortex: return QRCode.PixelShape.Vortex()
    case .wave: return QRCode.PixelShape.Wave()
    }
  }
  
  /// Provides an example image for each shape
  var example: Image {
    Image("data_\(self.imageName)", bundle: .main)
  }
  
  /// Returns the image name for asset catalog
  private var imageName: String {
    switch self {
    case .curvePixel: return "curvePixel"
    case .grid2x2: return "grid2x2"
    case .grid3x3: return "grid3x3"
    case .grid4x4: return "grid4x4"
    case .roundedEndIndent: return "roundedEndIndent"
    case .roundedPath: return "roundedPath"
    case .roundedRect: return "roundedRect"
    case .spikyCircle: return "spikyCircle"
    default: return self.rawValue.lowercased()
    }
  }
}
