import SwiftUI
import QRCode

/// A picker view that turns a generic Item into an image to be selected.
/// Allows dynamic drawing of items as custom SwiftUI views for a picker menu
struct ViewReferenceablePickerSheet<Item: Identifiable & CaseIterable, ItemReferenceContent: View>: View {
  let current: Item
  let action: ((Item) -> Void)?
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

fileprivate struct PickerShapeCell: View {
  let image: Image
  let isSelected: Bool
  
  var body: some View {
    image
      .resizable()
      .scaledToFit()
      .frame(width: 80, height: 80)
      .overlay(
        RoundedRectangle(cornerRadius: 8)
          .stroke(isSelected ? Color.blue : Color.clear, lineWidth: 2)
      )
  }
}

fileprivate extension View {
  func rendered() -> Image {
    let renderer = ImageRenderer(content: self)
    let fallback: Image = Image(systemName: "exclamationmark.warninglight.fill")
    return if let image = renderer.uiImage {
      Image(uiImage: image)
    }
    else {
      fallback
    }
  }
}

fileprivate enum SomeEnum: String, Identifiable, CaseIterable {
  var id: String { rawValue }
  case case1, case2
}

#Preview {
  @Previewable
  @State
  var current = SomeEnum.case1
  ViewReferenceablePickerSheet(
    current: current,
    action: { current = $0 },
    label: { item in
      VStack {
        Text("This is: \(item)")
        Text(".. as a button!")
      }
    }
  )
}
