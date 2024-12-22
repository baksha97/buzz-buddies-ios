//
//  AddClientForm.swift
//  Buzz
//
//  Created by Travis Baksh on 12/21/24.
//


import SwiftUI

struct AddClientForm: View {
  @Binding var name: String
  @Binding var phone: String
  @Binding var referrer: Client?
  let clients: [Client]
  let onSave: () -> Void
  
  var body: some View {
    NavigationView {
      Form {
                      Section("Client Details") { // Add section header
                          TextField("Name", text: $name)
                              .font(Theme.Fonts.body)
                              .foregroundColor(Theme.Colors.text)

                          HStack {
                              Theme.Images.phone
                              TextField("Phone", text: $phone)
                                  .font(Theme.Fonts.body)
                                  .foregroundColor(Theme.Colors.text)
                          }
                      }

                      Section("Referral") { // Add section header
                          Picker("Referred By", selection: $referrer) {
                              Text("None")
                                  .tag(nil as Client?)
                              ForEach(clients) { client in
                                  Text(client.name)
                                      .tag(client as Client?)
                              }
                          }
                      }
                  }
                  .themedForm()
                  .navigationTitle("Add Client")
      .toolbar {
        ToolbarItem(placement: .cancellationAction) {
          Button {
            name = ""
            phone = ""
            referrer = nil
            onSave()
          } label: {
            Text("Cancel")
              .font(Theme.Fonts.button)
              .foregroundColor(Theme.Colors.accent)
          }
        }
        ToolbarItem(placement: .confirmationAction) {
          Button {
            onSave()
          } label: {
            Text("Save")
              .font(Theme.Fonts.button)
              .foregroundColor(Theme.Colors.accent)
          }
        }
      }
    }
  }
}

#Preview("AddClientForm"){
  AddClientForm(
    name: .constant(""),
    phone: .constant(""),
    referrer: .constant(.mock),
    clients: PreviewDataService.generateSampleData(),
    onSave: { }
  )
  
}
