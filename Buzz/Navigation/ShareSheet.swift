//
//  ShareSheet.swift
//  Buzz
//
//  Created by Travis Baksh on 12/29/24.
//


import SwiftUINavigation
import SwiftUI
import QRCode
import CasePaths

struct ShareSheet: UIViewControllerRepresentable {
  var activityItems: [Any]
  
  func makeUIViewController(context: Context) -> UIActivityViewController {
    let controller = UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
    return controller
  }
  
  func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}