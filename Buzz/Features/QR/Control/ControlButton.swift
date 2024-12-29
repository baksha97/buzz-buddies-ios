//
//  ControlButton.swift
//  Buzz
//
//  Created by Travis Baksh on 12/28/24.
//


import SwiftUINavigation
import SwiftUI
import QRCode
import CasePaths

struct ControlButton<Leading: View, Trailing: View>: View {
  let title: String
  var textColor: Color
  let backgroundColor: Color
  
  @ViewBuilder let leading: Leading
  @ViewBuilder let trailing: Trailing
  let action: () -> Void
  
  var body: some View {
    Button(action: action) {
      HStack {
        leading
        
        Text(title)
          .font(.headline)
          .foregroundColor(textColor)
        
        Spacer()
        
        trailing
          .frame(width: 30, height: 30) // Ensures uniform sizing for trailing content
          .background(
            RoundedRectangle(cornerRadius: 8)
              .fill(backgroundColor)
          )
      }
      .padding()
      .background(
        RoundedRectangle(cornerRadius: 12)
          .fill(backgroundColor.opacity(0.5))
      )
    }
  }
}