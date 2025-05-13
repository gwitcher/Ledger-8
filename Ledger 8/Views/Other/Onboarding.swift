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
    
    let appName = "Gig Tracker"
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
                    companyName
                        .transition(transition)
                case 2:
                    companyContact
                        .transition(transition)
                case 3:
                    companyAddress
                        .transition(transition)
                case 4:
                    bankingInfo
                        .transition(transition)
                    
                default:
                    Text("Default")
                }
            }
            
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
                if onboardingState == 4 {
                    onboardComplete = true
                } else {
                    withAnimation(.spring()){
                        onboardingState += 1
                    }
                    
                }
            }, label: {
                 onboardingState == 4 ? Text("Finish") : Text("Next")
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
        VStack(spacing: 40) {
            Spacer()
            Image(systemName: "music.note.list")
                .resizable()
                .scaledToFit()
                .frame(width: 200, height: 200)
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
            
            TextField("Your Name Here...", text: $userData.userName)
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
    
    
    private var companyName: some View {
        VStack(spacing: 40) {
            Spacer()
            Image(systemName: "building.2")
                .resizable()
                .scaledToFit()
                .frame(width: 200, height: 200)
                .foregroundStyle(.white)
            
            Text("Company Info")
                .font(.largeTitle)
                .fontWeight(.bold)
                .foregroundStyle(.white)
                .minimumScaleFactor(0.5)
                .lineLimit(1)
            
            Text("Enter your company name as you want it to appear on your Invoice:")
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
            Text("\(userData.company.name)")
                .font(.title)
                .fontWeight(.bold)
                .multilineTextAlignment(.leading)
                .minimumScaleFactor(0.5)
                .foregroundStyle(.white)
                .padding()
            
            Text("Enter your company contact info as you want it to appear on your Invoice. If you choose to skip, you can enter it later in the Settings menu.")
                .fontWeight(.bold)
                .foregroundStyle(.white)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            Spacer()
            
            TextField("Company contact", text: $userData.company.contact)
                .font(.headline)
                .frame(height: 55)
                .padding(.horizontal)
                .background(Color.white)
                .cornerRadius(10)
                .padding(.bottom, 40)
            
            //Spacer()
            
            TextField("Email", text: $userData.company.email)
                .font(.headline)
                .frame(height: 55)
                .padding(.horizontal)
                .background(Color.white)
                .cornerRadius(10)
            
            TextField("Phone", text: $userData.company.phone)
                .font(.headline)
                .frame(height: 55)
                .padding(.horizontal)
                .background(Color.white)
                .cornerRadius(10)
            
            
            
            Spacer()
            Spacer()
        }
        .padding()
        
        
    }
    
    private var companyAddress: some View {
        VStack {
            Text("\(userData.company.name)")
                .font(.title)
                .fontWeight(.bold)
                .multilineTextAlignment(.leading)
                .minimumScaleFactor(0.5)
                .foregroundStyle(.white)
                .padding()
            
            Text("Enter your company address info as you want it to appear on your Invoice. If you choose to skip, you can enter it later in the Settings menu.")
                .fontWeight(.bold)
                .foregroundStyle(.white)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            Spacer()
            TextField("Address", text: $userData.company.address)
                .font(.headline)
                .frame(height: 55)
                .padding(.horizontal)
                .background(Color.white)
                .cornerRadius(10)
            
            TextField("Address 2", text: $userData.company.address2)
                .font(.headline)
                .frame(height: 55)
                .padding(.horizontal)
                .background(Color.white)
                .cornerRadius(10)
            
            TextField("City", text: $userData.company.city)
                .font(.headline)
                .frame(height: 55)
                .padding(.horizontal)
                .background(Color.white)
                .cornerRadius(10)
            
            TextField("State", text: $userData.company.state)
                .font(.headline)
                .frame(height: 55)
                .padding(.horizontal)
                .background(Color.white)
                .cornerRadius(10)
            
            TextField("Zip Code", text: $userData.company.zip)
                .font(.headline)
                .frame(height: 55)
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
            Text("\(userData.company.name)")
                .font(.title)
                .fontWeight(.bold)
                .multilineTextAlignment(.leading)
                .minimumScaleFactor(0.5)
                .foregroundStyle(.white)
                .padding()
            
            Text("Enter your company banking info as you want it to appear on your Invoice. If you choose to skip, you can enter it later in the Settings menu.")
                .fontWeight(.bold)
                .foregroundStyle(.white)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            Spacer()
            TextField("Bank Name", text: $userData.bankingInfo.bank)
                .font(.headline)
                .frame(height: 55)
                .padding(.horizontal)
                .background(Color.white)
                .cornerRadius(10)
            
            TextField("Name on Account", text: $userData.bankingInfo.accountName)
                .font(.headline)
                .frame(height: 55)
                .padding(.horizontal)
                .background(Color.white)
                .cornerRadius(10)
            
            TextField("routing Number", text: $userData.bankingInfo.routingNumber)
                .font(.headline)
                .frame(height: 55)
                .padding(.horizontal)
                .background(Color.white)
                .cornerRadius(10)
            
            TextField("Account Number", text: $userData.bankingInfo.accountNumber)
                .font(.headline)
                .frame(height: 55)
                .padding(.horizontal)
                .background(Color.white)
                .cornerRadius(10)
            
            Spacer()
            
            VStack {
                TextField("Zelle", text: $userData.bankingInfo.zelle)
                    .font(.headline)
                    .frame(height: 55)
                    .padding(.horizontal)
                    .background(Color.white)
                    .cornerRadius(10)
                
                TextField("Venmo", text: $userData.bankingInfo.venmo)
                    .font(.headline)
                    .frame(height: 55)
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
}
