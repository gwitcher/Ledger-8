//
//  OnboardingUserName.swift
//  Ledger 8
//
//  Created by Gabe Witcher on 5/11/25.
//

import SwiftUI

struct Onboarding: View {
    
    @AppStorage("onboard_complete") var onboardComplete: Bool = false
    
    let appName = "Gig Tracker"
    
    @State private var user = UserData()
    @State private var onboardingState: Int = 0
    
    var body: some View {
        ZStack {
            //TODO: Content
            ZStack {
                switch onboardingState {
                case 0:
                    welcomeSection
                case 1:
                    companyName
                case 2:
                    companyContact
                case 3:
                    companyAddress
                case 4:
                    bankingInfo
                    
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
            if onboardingState > 1 {
                
                Button("Back") {
                    onboardingState -= 1
                }
                .font(.headline)
                .foregroundStyle(.blue)
                .frame(minHeight: 55)
                .frame(maxWidth: .infinity)
                .background(Color.white)
                .cornerRadius(10)
                
            }
            
            Button(action: {
                if onboardingState == 4 {
                    onboardComplete = true
                } else { onboardingState += 1
                }
            }, label: {
                 onboardingState == 4 ? Text("Finish") : Text("Continue")
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
            
            TextField("Your Name Here...", text: $user.userName)
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
            
            TextField("Your Company Name Here...", text: $user.company.name)
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
            Text("\(user.company.name)")
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
            
            TextField("Company contact", text: $user.company.contact)
                .font(.headline)
                .frame(height: 55)
                .padding(.horizontal)
                .background(Color.white)
                .cornerRadius(10)
                .padding(.bottom, 40)
            
            //Spacer()
            
            TextField("Email", text: $user.company.email)
                .font(.headline)
                .frame(height: 55)
                .padding(.horizontal)
                .background(Color.white)
                .cornerRadius(10)
            
            TextField("Phone", text: $user.company.phone)
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
            Text("\(user.company.name)")
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
            TextField("Address", text: $user.company.address)
                .font(.headline)
                .frame(height: 55)
                .padding(.horizontal)
                .background(Color.white)
                .cornerRadius(10)
            
            TextField("Address 2", text: $user.company.address2)
                .font(.headline)
                .frame(height: 55)
                .padding(.horizontal)
                .background(Color.white)
                .cornerRadius(10)
            
            TextField("City", text: $user.company.city)
                .font(.headline)
                .frame(height: 55)
                .padding(.horizontal)
                .background(Color.white)
                .cornerRadius(10)
            
            TextField("State", text: $user.company.state)
                .font(.headline)
                .frame(height: 55)
                .padding(.horizontal)
                .background(Color.white)
                .cornerRadius(10)
            
            TextField("Zip Code", text: $user.company.zip)
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
            Text("\(user.company.name)")
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
            TextField("Bank Name", text: $user.bankingInfo.bank)
                .font(.headline)
                .frame(height: 55)
                .padding(.horizontal)
                .background(Color.white)
                .cornerRadius(10)
            
            TextField("Name on Account", text: $user.bankingInfo.accountName)
                .font(.headline)
                .frame(height: 55)
                .padding(.horizontal)
                .background(Color.white)
                .cornerRadius(10)
            
            TextField("routing Number", text: $user.bankingInfo.routingNumber)
                .font(.headline)
                .frame(height: 55)
                .padding(.horizontal)
                .background(Color.white)
                .cornerRadius(10)
            
            TextField("Account Number", text: $user.bankingInfo.accountNumber)
                .font(.headline)
                .frame(height: 55)
                .padding(.horizontal)
                .background(Color.white)
                .cornerRadius(10)
            
            Spacer()
            
            VStack {
                TextField("Zelle", text: $user.bankingInfo.zelle)
                    .font(.headline)
                    .frame(height: 55)
                    .padding(.horizontal)
                    .background(Color.white)
                    .cornerRadius(10)
                
                TextField("Venmo", text: $user.bankingInfo.venmo)
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
