//
//  MainView.swift
//  Ledger 8
//
//  Created by Gabe Witcher on 4/23/25.
//

import SwiftUI


struct MainView: View {
    
    @AppStorage("onboard_complete") var onboardComplete: Bool = false
    
    
    var body: some View {
        ZStack {
            RadialGradient(
                gradient: Gradient(colors: [Color.gradient1, Color.gradient2]),
                center: .top,
                startRadius: 5,
                endRadius: UIScreen.main.bounds.height)
            .ignoresSafeArea()
        
            
            switch onboardComplete {
            case true:
                ContentView()
            case false:
                    Onboarding()
            }
        }
    }
}

#Preview {
    MainView()
}
