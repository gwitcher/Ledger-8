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
    
    
    
    var body: some View {
        ZStack {
            //Content
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
            
            VStack{
                Spacer()
                bottomButtons
            }
            .padding(30)
            
            
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
            //            if onboardingState > 1 {
            //
            //                Button("Back") {
            //                    withAnimation(.spring()){
            //                        onboardingState -= 1
            //                    }
            //
            //                }
            //                .font(.headline)
            //                .foregroundStyle(.blue)
            //                .frame(minHeight: 55)
            //                .frame(maxWidth: .infinity)
            //                .background(Color.white)
            //                .cornerRadius(10)
            //
            //            }
            
            Button(action: {
                if onboardingState == 7 {
                    onboardComplete = true
                } else {
                    withAnimation(.spring()){
                        onboardingState += 1
                    }
                    
                }
            }, label: {
                onboardingState == 7 ? Text("Finish") : Text("Next")
            })
            .font(.headline)
            .foregroundStyle(.blue)
            .frame(minHeight: 55)
            .frame(maxWidth: .infinity)
            .background(Color.white)
            .cornerRadius(10)
            
            
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
                    .font(.headline)
                    .frame(height: textFrameHeight)
                    .padding(.horizontal)
                    .background(Color.white)
                    .cornerRadius(10)
                    
                
                TextField("Last Name", text: $userData.userLastName)
                    .font(.headline)
                    .frame(height: textFrameHeight)
                    .padding(.horizontal)
                    .background(Color.white)
                    .cornerRadius(10)
            }
            
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
                //Image(systemName: "arrow.right")
                    .font(.headline)
                    .foregroundStyle(.white)
                    .frame(minHeight: 55)
                    .frame(maxWidth: 55)
                //.background(Color.white)
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
                .foregroundStyle(.white)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            Spacer()
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
            //.font(.caption)
                .fontWeight(.medium)
                .foregroundStyle(.white)
                .multilineTextAlignment(.center)
            
            TextField("Your Company Name Here...", text: $userData.company.name)
                .font(.headline)
                .frame(height: 55)
                .padding(.horizontal)
                .background(Color.white)
                .cornerRadius(10)
            
            Spacer()
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
            
            //            Text("Enter your company contact info as you want it to appear on your Invoice.")
            //                .font(.subheadline)
            //                .fontWeight(.bold)
            //                .foregroundStyle(.white)
            //                .multilineTextAlignment(.center)
            //                .padding(.horizontal)
            
            Spacer()
            
            TextField("Company contact", text: $userData.company.contact)
                .font(.headline)
                .frame(height: textFrameHeight)
                .padding(.horizontal)
                .background(Color.white)
                .cornerRadius(10)
            //.padding(.bottom, 20)
            
            //Spacer()
            
            TextField("Email", text: $userData.company.email)
                .font(.headline)
                .frame(height: textFrameHeight)
                .padding(.horizontal)
                .background(Color.white)
                .cornerRadius(10)
            
            TextField("Phone", text: $userData.company.phone)
                .font(.headline)
                .frame(height: textFrameHeight)
                .padding(.horizontal)
                .background(Color.white)
                .cornerRadius(10)
            
            
            
            Spacer()
            Spacer()
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
            
            //            Text("Enter your company address info as you want it to appear on your Invoice. If you choose to skip, you can enter it later in the Settings menu.")
            //                .font(.subheadline)
            //                .fontWeight(.bold)
            //                .foregroundStyle(.white)
            //                .multilineTextAlignment(.center)
            //                .padding(.horizontal)
            
            Spacer()
            TextField("Address", text: $userData.company.address)
                .font(.headline)
                .frame(height: textFrameHeight)
                .padding(.horizontal)
                .background(Color.white)
                .cornerRadius(10)
            
            TextField("Address 2", text: $userData.company.address2)
                .font(.headline)
                .frame(height: textFrameHeight)
                .padding(.horizontal)
                .background(Color.white)
                .cornerRadius(10)
            
            TextField("City", text: $userData.company.city)
                .font(.headline)
                .frame(height: textFrameHeight)
                .padding(.horizontal)
                .background(Color.white)
                .cornerRadius(10)
            
            TextField("State", text: $userData.company.state)
                .font(.headline)
                .frame(height: textFrameHeight)
                .padding(.horizontal)
                .background(Color.white)
                .cornerRadius(10)
            
            TextField("Zip Code", text: $userData.company.zip)
                .font(.headline)
                .frame(height: textFrameHeight)
                .padding(.horizontal)
                .background(Color.white)
                .cornerRadius(10)
            
            Spacer()
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
            
            
            Text("Banking Info")
                .font(.title)
                .fontWeight(.bold)
                .multilineTextAlignment(.center)
                .minimumScaleFactor(0.5)
                .foregroundStyle(.white)
                .padding(.bottom)
            
            //            Text("Enter your company banking info as you want it to appear on your Invoice. If you choose to skip, you can enter it later in the Settings menu.")
            //                .font(.subheadline)
            //                .fontWeight(.bold)
            //                .foregroundStyle(.white)
            //                .multilineTextAlignment(.center)
            //                .padding(.horizontal)
            
            Spacer()
            TextField("Bank Name", text: $userData.bankingInfo.bank)
                .font(.headline)
                .frame(height: textFrameHeight)
                .padding(.horizontal)
                .background(Color.white)
                .cornerRadius(10)
            
            TextField("Name on Account", text: $userData.bankingInfo.accountName)
                .font(.headline)
                .frame(height: textFrameHeight)
                .padding(.horizontal)
                .background(Color.white)
                .cornerRadius(10)
            
            TextField("routing Number", text: $userData.bankingInfo.routingNumber)
                .font(.headline)
                .frame(height: textFrameHeight)
                .padding(.horizontal)
                .background(Color.white)
                .cornerRadius(10)
            
            TextField("Account Number", text: $userData.bankingInfo.accountNumber)
                .font(.headline)
                .frame(height: textFrameHeight)
                .padding(.horizontal)
                .background(Color.white)
                .cornerRadius(10)
            
            Spacer()
            
//            VStack {
//                TextField("Zelle", text: $userData.bankingInfo.zelle)
//                    .font(.headline)
//                    .frame(height: textFrameHeight)
//                    .padding(.horizontal)
//                    .background(Color.white)
//                    .cornerRadius(10)
//                
//                TextField("Venmo", text: $userData.bankingInfo.venmo)
//                    .font(.headline)
//                    .frame(height: textFrameHeight)
//                    .padding(.horizontal)
//                    .background(Color.white)
//                    .cornerRadius(10)
//            }
            .padding(.bottom)
            
            Spacer()
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
            
            //            Text("Enter your company banking info as you want it to appear on your Invoice. If you choose to skip, you can enter it later in the Settings menu.")
            //                .font(.subheadline)
            //                .fontWeight(.bold)
            //                .foregroundStyle(.white)
            //                .multilineTextAlignment(.center)
            //                .padding(.horizontal)
            
            Spacer()
            
            VStack {
                TextField("Zelle", text: $userData.bankingInfo.zelle)
                    .font(.headline)
                    .frame(height: textFrameHeight)
                    .padding(.horizontal)
                    .background(Color.white)
                    .cornerRadius(10)
                
                TextField("Venmo", text: $userData.bankingInfo.venmo)
                    .font(.headline)
                    .frame(height: textFrameHeight)
                    .padding(.horizontal)
                    .background(Color.white)
                    .cornerRadius(10)
            }
            .padding(.bottom)
            
            Spacer()
            Spacer()
        }
        .padding(20)
    }
    
    private var invoiceNumberAddToCal: some View {
        
        VStack{
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
                    //.padding(.horizontal)
                
                TextField("Beginning Invoice Number", value: $initialInvoiceNumber, format: .number)
                    .font(.headline)
                    .frame(height: textFrameHeight)
                    .padding(.horizontal)
                    .background(Color.white)
                    .cornerRadius(10)
                    .padding(.bottom)
                
                Text("Add projects to iCal:")
                    .font(.subheadline)
                    .fontWeight(.bold)
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.leading)
                    .padding(.top)
                    
                    
                
                Toggle(isOn: $userData.addToCalendar) {
                    HStack{
                        Image(systemName: "calendar.badge.plus")
                            .tint(userData.addToCalendar ? Color.gray : Color.green)
                        
                        Spacer()
                        
                        //Text("\(userData.addToCalendar ? Text("On") : Text("Off"))")
                    }
                }
                .font(.headline)
                .frame(height: textFrameHeight)
                .padding(.horizontal)
                .background(Color.white)
                .cornerRadius(10)
            }
            
            Spacer()
            Spacer()
        }
        
        
    }
    
    
}


