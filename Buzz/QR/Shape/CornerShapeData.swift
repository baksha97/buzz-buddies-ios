import Foundation

enum CornerShapeData: Double, Identifiable, CaseIterable {
  case none = 0
  case subtle = 5
  case rounded = 12
//    case circle = 24
  
  var id: String {
    "\(rawValue)"
  }
}
