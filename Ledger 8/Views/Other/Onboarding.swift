//
//  OnboardingUserName.swift
//  Ledger 8
//
//  Created by Gabe Witcher on 5/11/25.
//

import SwiftUI

struct Onboarding: View {
    @Environment(\.modelContext) var modelContext
    
    @AppStorage("onboard_complete") var onboardComplete: Bool = false
    @AppStorage("userData") var userData = UserData()
    @AppStorage("InitialInvoiceNumber") var initialInvoiceNumber = 0
    
    
    let appName = "Gig Tracker"
    let textFrameHeight: CGFloat = 50
    let transition: AnyTransition = .asymmetric(
        insertion: .move(edge: .trailing),
        removal: .move(edge: .leading)
    )
    
    @State private var onboardingState: Int = 0
    
    @FocusState private var clientField: clientField?
    @FocusState private var userField: userField?
    @FocusState private var bankField: bankField?
    
    
    var body: some View {
        ZStack {
            VStack{
                
                Spacer()
                Spacer()
                
                ZStack {
                    switch onboardingState {
                    case 0:
                        welcomeSection
                            .transition(transition)
                    case 1:
                        InvoiceSetup
                            .transition(transition)
                    case 2:
                        companyName
                            .transition(transition)
                    case 3:
                        companyContact
                            .transition(transition)
                    case 4:
                        companyAddress
                            .transition(transition)
                    case 5:
                        bankingInfo
                            .transition(transition)
                        
                    case 6:
                        appInfo
                            .transition(transition)
                        
                    case 7:
                        invoiceNumberAddToCal
                            .transition(transition)
                    default:
                        Text("")
                    }
                    
                }
                .padding()
                
                
                Spacer()
                bottomButtons
                    .padding(.horizontal, 30)
            }
            // .padding(30)
        }
    }
}

#Preview {
    NavigationStack {
        Onboarding()
            .background(Color.green)
    }
}

//MARK: Components

extension Onboarding {
    
    
    private var bottomButtons: some View {
        
        HStack{
            Text(onboardingState == 7 ? "Finish" : "Next")
                .font(.headline)
                .foregroundStyle(.blue)
                .frame(minHeight: 55)
                .frame(maxWidth: .infinity)
                .background(Color.white)
                .cornerRadius(10)
                .onTapGesture {
                    if onboardingState == 7 {
                        onboardComplete = true
                    } else {
                        withAnimation(.spring()){
                            onboardingState += 1
                        }
                        
                    }
                }
        }
    }
    
    
    private var welcomeSection: some View {
        VStack(spacing: 30) {
            Spacer()
            Image(systemName: "music.note.list")
                .resizable()
                .scaledToFit()
                .frame(width: 230, height: 220)
                .foregroundStyle(.white)
            
            Text("Welcome to Gig Tracker")
                .font(.largeTitle)
                .fontWeight(.bold)
                .foregroundStyle(.white)
                .minimumScaleFactor(0.5)
                .lineLimit(1)
            
            Text("Please enter your name to get started:")
            //.font(.caption)
                .fontWeight(.medium)
                .foregroundStyle(.white)
            
            Group {
                TextField("First Name", text: $userData.userFirstName)
                    
                    .focused($userField, equals: .firstName)
                    .submitLabel(.next)
                    .onSubmit {
                        userField = .lastName
                    }
                
                
                TextField("Last Name", text: $userData.userLastName)
                    .focused($userField, equals: .lastName)
            }
            .font(.headline)
            .frame(height: textFrameHeight)
            .padding(.horizontal)
            .foregroundStyle(.black)
            .background(Color.white)
            .cornerRadius(10)
            
            
            Spacer()
            Spacer()
            
        }
        .padding(30)
    }
    
    private var InvoiceSetup: some View {
        
        VStack {
            HStack{
                Spacer()
                Text("Skip")
                    .font(.headline)
                    .frame(minHeight: 55)
                    .frame(maxWidth: 55)
                
                    .cornerRadius(10)
            }
            .onTapGesture {
                onboardComplete = true
            }
            
            
            Spacer()
            
            Text("Hi \(userData.userFirstName)")
                .font(.largeTitle)
                .fontWeight(.bold)
                .multilineTextAlignment(.center)
                .minimumScaleFactor(0.5)
                .foregroundStyle(.white)
                .padding()
            
            
            Text("Press 'Next' to set up Invoicing. If you choose to skip, you can set up Invoicing later from the Settings menu.")
                .font(.subheadline)
                .fontWeight(.bold)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            Spacer()
        }
        .foregroundStyle(.white)
        .multilineTextAlignment(.center)
        
        
    }
    
    
    private var companyName: some View {
        VStack(spacing: 40) {
            Spacer()
            Image(systemName: "building.2")
                .resizable()
                .scaledToFit()
                .frame(width: 200, height: 200)
                .foregroundStyle(.white)
            
            Text("Company Name")
                .font(.largeTitle)
                .fontWeight(.bold)
                .foregroundStyle(.white)
                .minimumScaleFactor(0.5)
                .lineLimit(1)
            
            Text("Enter your company name as you would like it to appear on your Invoices:")
                .fontWeight(.medium)
                .foregroundStyle(.white)
                .multilineTextAlignment(.center)
            
            TextField("Your Company Name Here...", text: $userData.company.name)
                .font(.headline)
                .frame(height: 55)
                .padding(.horizontal)
                .foregroundStyle(.black)
                .background(Color.white)
                .cornerRadius(10)
            
            Spacer()
        
        }
        .padding(30)
    }
    
    private var companyContact: some View {
        VStack {
            Image(systemName: "person.crop.circle")
                .resizable()
                .scaledToFit()
                .frame(width: 200, height: 180)
                .foregroundStyle(.white)
            Spacer()
            
            Text("\(userData.company.name)")
                .font(.title)
                .fontWeight(.bold)
                .multilineTextAlignment(.center)
                .minimumScaleFactor(0.5)
                .foregroundStyle(.white)
            
            Text("Contact Info")
                .font(.title)
                .fontWeight(.bold)
                .multilineTextAlignment(.center)
                .minimumScaleFactor(0.5)
                .foregroundStyle(.white)
                .padding(.bottom)
            
            
            Spacer()
            
            Group {
                TextField("Company contact", text: $userData.company.contact)
                    .focused($clientField, equals: .contact)
                    .submitLabel(.next)
                    .onSubmit {
                        clientField = .email
                    }
                
                
                TextField("Email", text: $userData.company.email)
                    .focused($clientField, equals: .email)
                    .submitLabel(.next)
                    .onSubmit {
                        clientField = .phone
                    }
                
                TextField("Phone", text: $userData.company.phone)
                    .focused($clientField, equals: .phone)
            }
            .frame(height: textFrameHeight)
            .font(.headline)
            .padding(.horizontal)
            .foregroundStyle(.black)
            .background(Color.white)
            .cornerRadius(10)
            
            Spacer()
        }
        .padding()
        
        
    }
    
    private var companyAddress: some View {
        VStack {
            
            Image(systemName: "envelope.open")
                .resizable()
                .scaledToFit()
                .frame(width: 200, height: 150)
                .foregroundStyle(.white)
            Spacer()
            
            Text("\(userData.company.name)")
                .font(.title)
                .fontWeight(.bold)
                .multilineTextAlignment(.center)
                .minimumScaleFactor(0.5)
                .foregroundStyle(.white)
            
            
            Text("Address")
                .font(.title)
                .fontWeight(.bold)
                .multilineTextAlignment(.center)
                .minimumScaleFactor(0.5)
                .foregroundStyle(.white)
                .padding(.bottom)
            
            Spacer()
            
            Group {
                TextField("Address", text: $userData.company.address)
                    .focused($clientField, equals: .address)
                    .submitLabel(.next)
                    .onSubmit {
                        clientField = .address2
                    }
                
                
                
                TextField("Address 2", text: $userData.company.address2)
                    .focused($clientField, equals: .address2)
                    .submitLabel(.next)
                    .onSubmit {
                        clientField = .city
                    }
                
                TextField("City", text: $userData.company.city)
                    .focused($clientField, equals: .city)
                    .submitLabel(.next)
                    .onSubmit {
                        clientField = .state
                    }
                
                TextField("State", text: $userData.company.state)
                    .focused($clientField, equals: .state)
                    .submitLabel(.next)
                    .onSubmit {
                        clientField = .zip
                    }
                
                TextField("Zip Code", text: $userData.company.zip)
                    .focused($clientField, equals: .zip)
            }
            .frame(height: textFrameHeight)
            .font(.headline)
            .padding(.horizontal)
            .foregroundStyle(.black)
            .background(Color.white)
            .cornerRadius(10)
         
            Spacer()
        }
        .padding()
    }
    
    private var bankingInfo: some View {
        VStack {
            Image(systemName: "building.columns.circle")
                .resizable()
                .scaledToFit()
                .frame(width: 200, height: 150)
                .foregroundStyle(.white)
            
            Spacer()
            
            Text("\(userData.company.name)")
                .font(.title)
                .fontWeight(.bold)
                .multilineTextAlignment(.center)
                .minimumScaleFactor(0.5)
                .foregroundStyle(.white)
            
            Text("Direct Deposit Info")
                .font(.title)
                .fontWeight(.bold)
                .multilineTextAlignment(.center)
                .minimumScaleFactor(0.5)
                .foregroundStyle(.white)
                .padding(.bottom)
            
            Spacer()
            
            Group {
                TextField("Bank Name", text: $userData.bankingInfo.bank)
                    .focused($bankField, equals: .bank)
                    .submitLabel(.next)
                    .onSubmit {
                        bankField = .accountName
                    }
                
                TextField("Name on Account", text: $userData.bankingInfo.accountName)
                    .focused($bankField, equals: .accountName)
                    .submitLabel(.next)
                    .onSubmit {
                        bankField = .routing
                    }
                
                TextField("routing Number", text: $userData.bankingInfo.routingNumber)
                    .focused($bankField, equals: .routing)
                    .submitLabel(.next)
                    .onSubmit {
                        bankField = .account
                    }
                
                TextField("Account Number", text: $userData.bankingInfo.accountNumber)
                    .focused($bankField, equals: .account)
            }
            .frame(height: textFrameHeight)
            .font(.headline)
            .padding(.horizontal)
            .foregroundStyle(.black)
            .background(Color.white)
            .cornerRadius(10)
            
            Spacer()
            
                .padding(.bottom)
            
            Spacer()
        }
        .padding(20)
    }
    
    private var appInfo: some View {
        VStack {
            Image(systemName: "building.columns.circle")
                .resizable()
                .scaledToFit()
                .frame(width: 200, height: 150)
                .foregroundStyle(.white)
            
            Spacer()
            
            Text("\(userData.company.name)")
                .font(.title)
                .fontWeight(.bold)
                .multilineTextAlignment(.center)
                .minimumScaleFactor(0.5)
                .foregroundStyle(.white)
            
            
            Text("Financial Apps")
                .font(.title)
                .fontWeight(.bold)
                .multilineTextAlignment(.center)
                .minimumScaleFactor(0.5)
                .foregroundStyle(.white)
                .padding(.bottom)
            
            
            Spacer()
            
            Group {
                TextField("Zelle", text: $userData.bankingInfo.zelle)
                    .focused($bankField, equals: .zelle)
                    .submitLabel(.next)
                    .onSubmit {
                        bankField = .venmo
                    }
                
                TextField("Venmo", text: $userData.bankingInfo.venmo)
                    .focused($bankField, equals: .venmo)
            }
            .frame(height: textFrameHeight)
            .font(.headline)
            .padding(.horizontal)
            .foregroundStyle(.black)
            .background(Color.white)
            .cornerRadius(10)
            .padding(.bottom)
            
            //Spacer()
            Spacer()
        }
        .padding(20)
    }
    
    private var invoiceNumberAddToCal: some View {
        
        VStack{
            Image(systemName: "pencil.and.list.clipboard")
                .resizable()
                .scaledToFit()
                .frame(width: 200, height: 150)
                .foregroundStyle(.white)
            
            Spacer()
            
            Text("\(userData.company.name)")
                .font(.largeTitle)
                .fontWeight(.bold)
                .multilineTextAlignment(.center)
                .minimumScaleFactor(0.5)
                .foregroundStyle(.white)
            
            Spacer()
            
            VStack(alignment: .leading){
                Text("Enter the invoice number you would like to begin with:")
                    .font(.subheadline)
                    .fontWeight(.bold)
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.leading)
                
                TextField("Beginning Invoice Number", value: $initialInvoiceNumber, format: .number.grouping(.never))
                    .font(.headline)
                    .frame(height: textFrameHeight)
                    .padding(.horizontal)
                    .foregroundStyle(.black)
                    .background(Color.white)
                    .cornerRadius(10)
                    .padding(.bottom)
                
                //                Text("Add projects to iCal:")
                //                    .font(.subheadline)
                //                    .fontWeight(.bold)
                //                    .foregroundStyle(.white)
                //                    .multilineTextAlignment(.leading)
                //                    .padding(.top)
                //
                //
                //
                //                Toggle(isOn: $userData.addToCalendar) {
                //                    HStack{
                //                        Image(systemName: "calendar.badge.plus")
                //                            .foregroundStyle(userData.addToCalendar ? Color.black : Color.gray)
                //
                //                        Spacer()
                //
                //                    }
                //                }
                //                .font(.headline)
                //                .frame(height: textFrameHeight)
                //                .padding(.horizontal)
                //                .background(Color.white)
                //                .cornerRadius(10)
            }
            
            //Spacer()
            Spacer()
        }
        
    }
}


