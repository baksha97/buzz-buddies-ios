import SwiftUI
import QRCode

struct EyeShapePickerSheet: View {
  var model: QRMenuModel
  
  var body: some View {
    let shapes = EyeShapeData.allCases
    
    NavigationStack {
      ScrollView {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 100))], spacing: 16) {
          ForEach(shapes.indices, id: \..self) { index in
            Button {
              model.selectedEyeIndex = index
            } label: {
              PickerShapeCell(image: shapes[index].reference, isSelected: model.selectedEyeIndex == index)
            }
          }
        }
        .padding()
      }
      .navigationTitle("Select Eye Shape")
    }
  }
}