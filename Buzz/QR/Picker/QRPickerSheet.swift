//
//  QRPickerSheet.swift
//  Buzz
//
//  Created by Travis Baksh on 12/28/24.
//


import SwiftUI
import QRCode

protocol ViewReferencable: Identifiable {
  @MainActor
  var reference: Image { get }
}

struct ImageReferencablePickerSheet2<Item: Identifiable & CaseIterable, ItemReferenceContent: View>: View {
  typealias OnSelect = (Item) -> Void
  let current: Item
  
  let action: OnSelect?
  @ViewBuilder
  let label: (Item) -> ItemReferenceContent
  
  
  private var items: Array<Item> {
    Array(Item.allCases)
  }
  
  var body: some View {
    ScrollView {
      LazyVGrid(columns: [GridItem(.adaptive(minimum: 100))], spacing: 16) {
        ForEach(items) { item in
          Button {
            action?(item)
          } label: {
            EmptyView()
            PickerShapeCell(
              image: label(item).rendered(),
              isSelected: item.id == current.id
            )
          }
        }
        .padding()
      }
    }
  }
}

struct ImageReferencablePickerSheet<Item: Identifiable & ViewReferencable & CaseIterable>: View {
  typealias OnSelect = (Item) -> Void
  let current: Item
  let onSelect: OnSelect?
  private var items: Array<Item> { Array(Item.allCases) }
  
  var body: some View {
    ScrollView {
      LazyVGrid(columns: [GridItem(.adaptive(minimum: 100))], spacing: 16) {
        ForEach(items) { item in
          Button {
            onSelect?(item)
          } label: {
            PickerShapeCell(image: item.reference, isSelected: item.id == current.id)
          }
        }
        .padding()
      }
    }
  }
}

fileprivate struct PickerShapeCell: View {
  let image: Image
  let isSelected: Bool
  
  var body: some View {
    image
      .resizable()
      .scaledToFit()
      .frame(width: 80, height: 80)
//      .cornerRadius(8)
      .overlay(
        RoundedRectangle(cornerRadius: 8)
          .stroke(isSelected ? Color.blue : Color.clear, lineWidth: 2)
      )
  }
}

extension PixelShapeData: ViewReferencable {
  /// Provides an example image for each shape using asset catalog symbols
  var reference: Image {
    switch self {
    case .abstract: Image(.dataAbstract)
    case .arrow: Image(.dataArrow)
    case .blob: Image(.dataBlob)
    case .circle: Image(.dataCircle)
    case .circuit: Image(.dataCircuit)
    case .crt: Image(.dataCrt)
    case .curvePixel: Image(.dataCurvePixel)
    case .donut: Image(.dataDonut)
    case .flower: Image(.dataFlower)
    case .grid2x2: Image(.dataGrid2X2)
    case .grid3x3: Image(.dataGrid3X3)
    case .grid4x4: Image(.dataGrid4X4)
    case .heart: Image(.dataHeart)
    case .horizontal: Image(.dataHorizontal)
    case .pointy: Image(.dataPointy)
    case .razor: Image(.dataRazor)
    case .roundedEndIndent: Image(.dataRoundedEndIndent)
    case .roundedPath: Image(.dataRoundedPath)
    case .roundedRect: Image(.dataRoundedRect)
    case .sharp: Image(.dataSharp)
    case .shiny: Image(.dataShiny)
    case .spikyCircle: Image(.dataSpikyCircle)
    case .square: Image(.dataSquare)
    case .squircle: Image(.dataSquircle)
    case .star: Image(.dataStar)
    case .stitch: Image(.dataStitch)
    case .vertical: Image(.dataVertical)
    case .vortex: Image(.dataVortex)
    case .wave: Image(.dataWave)
    }
  }
}

extension EyeShapeData: ViewReferencable {
  /// Provides an example image for each shape using Swift-generated asset symbols
  var reference: Image {
    switch self {
    case .barsHorizontal: return Image(.eyeBarsHorizontal)
    case .barsVertical: return Image(.eyeBarsVertical)
    case .circle: return Image(.eyeCircle)
    case .cloud: return Image(.eyeCloud)
    case .corneredPixels: return Image(.eyeCorneredPixels)
    case .crt: return Image(.eyeCrt)
    case .dotDragHorizontal: return Image(.eyeDotDragHorizontal)
    case .dotDragVertical: return Image(.eyeDotDragVertical)
    case .edges: return Image(.eyeEdges)
    case .explode: return Image(.eyeExplode)
    case .eye: return Image(.eyeEye)
    case .fireball: return Image(.eyeFireball)
    case .headlight: return Image(.eyeHeadlight)
    case .leaf: return Image(.eyeLeaf)
    case .peacock: return Image(.eyePeacock)
    case .pinch: return Image(.eyePinch)
    case .pixels: return Image(.eyePixels)
    case .roundedOuter: return Image(.eyeRoundedOuter)
    case .roundedPointingIn: return Image(.eyeRoundedPointingIn)
    case .roundedPointingOut: return Image(.eyeRoundedPointingOut)
    case .roundedRect: return Image(.eyeRoundedRect)
    case .shield: return Image(.eyeShield)
    case .spikyCircle: return Image(.eyeSpikyCircle)
    case .square: return Image(.eyeSquare)
    case .squarePeg: return Image(.eyeSquarePeg)
    case .squircle: return Image(.eyeSquircle)
    case .surroundingBars: return Image(.eyeSurroundingBars)
    case .teardrop: return Image(.eyeTeardrop)
    case .ufo: return Image(.eyeUfo)
    case .usePixelShape: return Image(.eyeUsePixelShape)
    }
  }
}

extension CornerShapeData: ViewReferencable {
  var reference: Image {
    
  Text("\(rawValue)")
    .rendered()
  }
}

extension PupilShapeData: ViewReferencable {
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

fileprivate extension View {
  func rendered() -> Image {
//    @Environment(\.displayScale) var displayScale
    let renderer = ImageRenderer(content: self)
//    renderer.scale = displayScale
    let fallback: Image = Image(systemName: "exclamationmark.warninglight.fill")
    return if let image = renderer.uiImage {
      Image(uiImage: image)
    }
    else {
      fallback
    }
  }
}

#Preview("PixelShapeData") {
  ImageReferencablePickerSheet(current: PixelShapeData.abstract) { _ in
   
  }
  
}

#Preview("EyeShapeData") {
  ImageReferencablePickerSheet(current: EyeShapeData.cloud) { _ in
   
  }
}

#Preview("PupilShapeData") {
  ImageReferencablePickerSheet(current: PupilShapeData.barsHorizontal) { _ in
   
  }
}


#Preview("CornerShapeData") {
  ImageReferencablePickerSheet(current: CornerShapeData.subtle) { _ in
   
  }
}
