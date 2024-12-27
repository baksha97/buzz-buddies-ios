import SwiftUI
import QRCode

struct ShapePickerSheet<ShapeType: ImageReferenceable>: View {
  @State var model: QRMenuModel
  @Binding var selectedIndex: Int
  let title: String
  
  @Environment(\.dismiss) private var dismiss

  var body: some View {
    VStack {
      Text(title)
        .font(.headline)
        .padding(.top)

      ScrollView(.horizontal, showsIndicators: false) {
        HStack(spacing: 16) {
          ForEach(Array(ShapeType.allCases.enumerated()), id: \.element.id) { index, shape in
            VStack {
              shape.reference
                .resizable()
                .scaledToFit()
                .frame(width: 60, height: 60)
                .background(
                  RoundedRectangle(cornerRadius: 8)
                    .stroke(index == selectedIndex ? Color.accentColor : Color.clear, lineWidth: 2)
                )
              Text(shape.id)
                .font(.caption)
            }
            .onTapGesture {
              selectedIndex = index
              model.generateQRCode()
            }
          }
        }
        .padding()
      }

      Spacer()

      Button("Done") {
        dismiss()
      }
      .buttonStyle(.borderedProminent)
      .padding(.bottom)
    }
    .presentationDetents([.fraction(0.5)])
  }
}