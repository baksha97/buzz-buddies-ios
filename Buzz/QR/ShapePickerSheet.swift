//
//  ShapePickerSheet.swift
//  Buzz
//
//  Created by Travis Baksh on 12/26/24.
//


import SwiftUI
import QRCode

extension CGColor {
  static let black = CGColor(red: 0, green: 0, blue: 0, alpha: 1)
}



protocol ImageReferenceable: CaseIterable, Identifiable {
  var id: String { get }
  var reference: Image { get }
}

//
//// MARK: - Shape Picker Sheet
//
//struct ShapePickerSheet<ShapeType: ImageReferenceable>: View {
//  @Binding var selectedIndex: Int
//  let title: String
//  
//  var body: some View {
//    NavigationStack {
//      List {
//        ForEach(ShapeType.allCases.indices, id: \.self) { index in
//          Button {
//            selectedIndex = index
//          } label: {
//            HStack {
//              Text(ShapeType.allCases[index].name)
//              Spacer()
//              if selectedIndex == index {
//                Image(systemName: "checkmark")
//              }
//            }
//          }
//        }
//      }
//      .navigationTitle(title)
//      .toolbar {
//        ToolbarItem(placement: .confirmationAction) {
//          Button("Done") {
//            // Dismiss logic (handled by SwiftUI sheet)
//          }
//        }
//      }
//    }
//  }
//}
