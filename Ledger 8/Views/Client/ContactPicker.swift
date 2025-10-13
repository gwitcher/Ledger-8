import SwiftUI
import ContactsUI

/// Example usage: A button that presents the picker and fills out example client fields.
struct ImportClientFromContactView: View {
    @State private var showingContactPicker = false

    // Demo client fields (replace or bind to your view model as needed)
    @State private var firstName = ""
    @State private var lastName = ""
    @State private var email = ""
    @State private var phone = ""
    @State private var address = ""
    @State private var city = ""
    @State private var state = ""
    @State private var zip = ""
    @State private var company = ""
    @State private var contactIdentifier = ""

    var body: some View {
        Form {
            Button("Import from Contacts") {
                showingContactPicker = true
            }
            .sheet(isPresented: $showingContactPicker) {
                ContactPicker { contact in
                    firstName = contact.givenName
                    lastName = contact.familyName
                    email = contact.emailAddresses.first?.value as String? ?? ""
                    phone = contact.phoneNumbers.first?.value.stringValue ?? ""
                    address = contact.postalAddresses.first?.value.street ?? ""
                    city = contact.postalAddresses.first?.value.city ?? ""
                    state = contact.postalAddresses.first?.value.state ?? ""
                    zip = contact.postalAddresses.first?.value.postalCode ?? ""
                    company = contact.organizationName
                    contactIdentifier = contact.identifier
                    showingContactPicker = false
                }
            }

            Section("Preview Imported Fields") {
                TextField("First Name", text: $firstName)
                TextField("Last Name", text: $lastName)
                TextField("Email", text: $email)
                TextField("Phone", text: $phone)
                TextField("Company", text: $company)
                TextField("Address", text: $address)
                TextField("City", text: $city)
                TextField("State", text: $state)
                TextField("Zip", text: $zip)
                // You can show the contactIdentifier if desired
            }
        }
    }
}

#Preview {
    ImportClientFromContactView()
}
