import SwiftUI
import QRCode

enum EyeShapeData: String, CaseIterable {
    case barsHorizontal, barsVertical, circle, cloud, corneredPixels, crt
    case dotDragHorizontal, dotDragVertical, edges, explode, eye, fireball
    case headlight, leaf, peacock, pinch, pixels, roundedOuter, roundedPointingIn
    case roundedPointingOut, roundedRect, shield, spikyCircle, square, squarePeg
    case squircle, surroundingBars, teardrop, ufo, usePixelShape
    
    func makeShape() -> QRCodeEyeShapeGenerator {
        switch self {
        case .barsHorizontal:
            return QRCode.EyeShape.BarsHorizontal()
        case .barsVertical:
            return QRCode.EyeShape.BarsVertical()
        case .circle:
            return QRCode.EyeShape.Circle()
        case .cloud:
            return QRCode.EyeShape.Cloud()
        case .corneredPixels:
            return QRCode.EyeShape.CorneredPixels()
        case .crt:
            return QRCode.EyeShape.CRT()
        case .dotDragHorizontal:
            return QRCode.EyeShape.DotDragHorizontal()
        case .dotDragVertical:
            return QRCode.EyeShape.DotDragVertical()
        case .edges:
            return QRCode.EyeShape.Edges()
        case .explode:
            return QRCode.EyeShape.Explode()
        case .eye:
            return QRCode.EyeShape.Eye()
        case .fireball:
            return QRCode.EyeShape.Fireball()
        case .headlight:
            return QRCode.EyeShape.Headlight()
        case .leaf:
            return QRCode.EyeShape.Leaf()
        case .peacock:
            return QRCode.EyeShape.Peacock()
        case .pinch:
            return QRCode.EyeShape.Pinch()
        case .pixels:
            return QRCode.EyeShape.Pixels()
        case .roundedOuter:
            return QRCode.EyeShape.RoundedOuter()
        case .roundedPointingIn:
            return QRCode.EyeShape.RoundedPointingIn()
        case .roundedPointingOut:
            return QRCode.EyeShape.RoundedPointingOut()
        case .roundedRect:
            return QRCode.EyeShape.RoundedRect()
        case .shield:
            return QRCode.EyeShape.Shield()
        case .spikyCircle:
            return QRCode.EyeShape.SpikyCircle()
        case .square:
            return QRCode.EyeShape.Square()
        case .squarePeg:
            return QRCode.EyeShape.SquarePeg()
        case .squircle:
            return QRCode.EyeShape.Squircle()
        case .surroundingBars:
            return QRCode.EyeShape.SurroundingBars()
        case .teardrop:
            return QRCode.EyeShape.Teardrop()
        case .ufo:
            return QRCode.EyeShape.UFO()
        case .usePixelShape:
            return QRCode.EyeShape.UsePixelShape()
        }
    }
}