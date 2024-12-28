import SwiftUI

extension ViewReferenceablePickerSheet {
  init(current: Item, action: ((Item) -> Void)? = nil)
  where Item: ImageReferenceable, ItemReferenceContent == Image
  {
    self.current = current
    self.action = action
    self.label = { $0.reference }
  }
}

#Preview("PixelShapeData") {
  ViewReferenceablePickerSheet(current: PixelShapeData.abstract) { _ in
   
  }
  
}

#Preview("EyeShapeData") {
  ViewReferenceablePickerSheet(current: EyeShapeData.cloud) { _ in
   
  }
}

#Preview("PupilShapeData") {
  ViewReferenceablePickerSheet(current: PupilShapeData.barsHorizontal) { _ in
   
  }
}
