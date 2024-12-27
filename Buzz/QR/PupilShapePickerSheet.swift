import SwiftUI
import QRCode

struct PupilShapePickerSheet: View {
  var model: QRMenuModel
  
  var body: some View {
    let shapes = PupilShapeData.allCases
    
    NavigationStack {
      ScrollView {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 100))], spacing: 16) {
          ForEach(shapes.indices, id: \..self) { index in
            Button {
              model.selectedPupilIndex = index
            } label: {
              PickerShapeCell(image: shapes[index].reference, isSelected: model.selectedPupilIndex == index)
            }
          }
        }
        .padding()
      }
      .navigationTitle("Select Pupil Shape")
    }
  }
}