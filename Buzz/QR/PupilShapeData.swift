import SwiftUI
import QRCode

enum PupilShapeData: String, CaseIterable {
    case barsHorizontal, barsHorizontalSquare, barsVertical, barsVerticalSquare, blade, blobby
    case circle, cloud, corneredPixels, cross, crossCurved, crt, dotDragHorizontal, dotDragVertical
    case edges, explode, forest, hexagonLeaf, leaf, orbits, pinch, pixels, roundedOuter
    case roundedPointingIn, roundedPointingOut, roundedRect, seal, shield, spikyCircle
    case square, squircle, teardrop, ufo, usePixelShape
    
    func makeShape() -> QRCodePupilShapeGenerator {
        switch self {
        case .barsHorizontal:
            return QRCode.PupilShape.BarsHorizontal()
        case .barsHorizontalSquare:
            return QRCode.PupilShape.SquareBarsHorizontal()
        case .barsVertical:
            return QRCode.PupilShape.BarsVertical()
        case .barsVerticalSquare:
            return QRCode.PupilShape.SquareBarsVertical()
        case .blade:
            return QRCode.PupilShape.Blade()
        case .blobby:
            return QRCode.PupilShape.Blobby()
        case .circle:
            return QRCode.PupilShape.Circle()
        case .cloud:
            return QRCode.PupilShape.Cloud()
        case .corneredPixels:
            return QRCode.PupilShape.CorneredPixels()
        case .cross:
            return QRCode.PupilShape.Cross()
        case .crossCurved:
            return QRCode.PupilShape.CrossCurved()
        case .crt:
            return QRCode.PupilShape.CRT()
        case .dotDragHorizontal:
            return QRCode.PupilShape.DotDragHorizontal()
        case .dotDragVertical:
            return QRCode.PupilShape.DotDragVertical()
        case .edges:
            return QRCode.PupilShape.Edges()
        case .explode:
            return QRCode.PupilShape.Explode()
        case .forest:
            return QRCode.PupilShape.Forest()
        case .hexagonLeaf:
            return QRCode.PupilShape.HexagonLeaf()
        case .leaf:
            return QRCode.PupilShape.Leaf()
        case .orbits:
            return QRCode.PupilShape.Orbits()
        case .pinch:
            return QRCode.PupilShape.Pinch()
        case .pixels:
            return QRCode.PupilShape.Pixels()
        case .roundedOuter:
            return QRCode.PupilShape.RoundedOuter()
        case .roundedPointingIn:
            return QRCode.PupilShape.RoundedPointingIn()
        case .roundedPointingOut:
            return QRCode.PupilShape.RoundedPointingOut()
        case .roundedRect:
            return QRCode.PupilShape.RoundedRect()
        case .seal:
            return QRCode.PupilShape.Seal()
        case .shield:
            return QRCode.PupilShape.Shield()
        case .spikyCircle:
            return QRCode.PupilShape.SpikyCircle()
        case .square:
            return QRCode.PupilShape.Square()
        case .squircle:
            return QRCode.PupilShape.Squircle()
        case .teardrop:
            return QRCode.PupilShape.Teardrop()
        case .ufo:
            return QRCode.PupilShape.UFO()
        case .usePixelShape:
            return QRCode.PupilShape.UsePixelShape()
        }
    }
}