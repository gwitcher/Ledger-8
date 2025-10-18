import SwiftUI

/// Custom color palette for a finance-themed onboarding view.
struct GradientOnboardingColors {
    // Cool, subtle background: white → mint green
    let backgroundGradient = LinearGradient(
        gradient: Gradient(colors: [
            Color.white,
            Color(red: 0.91, green: 0.98, blue: 0.95) // Mint/turquoise-tint
        ]),
        startPoint: .top, endPoint: .bottom)
    // Trusted finance green accent (used for icons/buttons)
    let accent = Color(red: 0.18, green: 0.66, blue: 0.51) // Mint/emerald
    // Deep navy for serious, pro titles
    let title = Color(red: 0.10, green: 0.18, blue: 0.24)
    // Muted blue-gray for subtitles
    let subtitle = Color(red: 0.41, green: 0.54, blue: 0.60)
    // Crisp white field backgrounds
    let fieldBackground = Color.white
    // Accent for button background
    let button = Color(red: 0.18, green: 0.66, blue: 0.51)
    // White text for buttons
    let buttonText = Color.white
}

// (the rest of your file remains the same)
/// Main immersive gradient onboarding view.
struct OnboardingGradientView: View {
    enum Step: Int, CaseIterable {
        case welcome, profile, invoice, done
        
        var title: String {
            switch self {
            case .welcome: "Welcome!"
            case .profile: "Who are you?"
            case .invoice: "Invoice Number"
            case .done:    "All Set"
            }
        }
        var subtitle: String {
            switch self {
            case .welcome: "Ledger 8 helps you organize all your gigs and payments easily."
            case .profile: "Tell us your name and company."
            case .invoice: "Choose a starting invoice number (optional)."
            case .done:    "You're ready to go!"
            }
        }
        var image: String {
            switch self {
            case .welcome: "music.quarternote.3"
            case .profile: "person.crop.circle.badge.plus"
            case .invoice: "number"
            case .done:    "checkmark.circle.fill"
            }
        }
    }
    
    @State private var step: Step = .welcome
    @State private var firstName = ""
    @State private var lastName = ""
    @State private var company = ""
    @State private var startingInvoiceNumber = ""
    @State private var didComplete = false
    
    let colors = GradientOnboardingColors()
    
    private var canGoNext: Bool {
        switch step {
        case .profile:
            let hasName = !firstName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ||
                          !lastName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            return hasName
        default:
            return true
        }
    }
    
    var body: some View {
        ZStack {
            colors.backgroundGradient.ignoresSafeArea()
            VStack(spacing: 0) {
                // Progress Circle
                HStack {
                    ForEach(Step.allCases, id: \.self) { s in
                        Circle()
                            .fill(s == step ? colors.accent : colors.title.opacity(0.12))
                            .frame(width: 12, height: 12)
                    }
                }
                .padding(.top, 28)
                .padding(.bottom, 20)
                
                Spacer(minLength: 0)
                
                // Illustration
                Image(systemName: step.image)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 90, height: 90)
                    .foregroundColor(colors.accent)
                    .padding(.bottom, 8)
                
                // Titles
                VStack(alignment: .leading, spacing: 6) {
                    Text(step.title)
                        .font(.largeTitle).fontWeight(.bold)
                        .foregroundColor(colors.title)
                    Text(step.subtitle)
                        .font(.title3)
                        .foregroundColor(colors.subtitle)
                        .padding(.bottom, 4)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 32)
                .padding(.bottom, 18)
                
                // Content
                stepContent
                    .padding(.horizontal, 32)
                
                Spacer()
                
                // Navigation Button(s)
                VStack(spacing: 10) {
                    if step != .done {
                        Button(action: nextStep) {
                            Text(nextButtonLabel)
                                .fontWeight(.semibold)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14)
                                .background((step == .profile && !canGoNext) ? colors.button.opacity(0.5) : colors.button)
                                .foregroundColor(colors.buttonText)
                                .cornerRadius(16)
                                .shadow(color: colors.accent.opacity(0.13), radius: 8, y: 2)
                        }
                        .disabled(step == .profile && !canGoNext)
                    }
                    if step.rawValue > 0 && step != .done {
                        Button("Back", action: previousStep)
                            .font(.subheadline)
                            .foregroundStyle(colors.subtitle)
                    }
                }
                .padding(.horizontal, 32)
                .padding(.bottom, 40)
            }
            .animation(.easeInOut(duration: 0.3), value: step)
        }
        .previewDisplayName("Finance-Themed Onboarding")
    }
    
    @ViewBuilder
    private var stepContent: some View {
        switch step {
        case .welcome:
            Spacer().frame(height: 10)
        case .profile:
            VStack(spacing: 14) {
                CustomField(text: $firstName, placeholder: "First Name", colors: colors)
                CustomField(text: $lastName, placeholder: "Last Name", colors: colors)
                CustomField(text: $company, placeholder: "Company (optional)", colors: colors)
            }
            .padding(.top, 12)
        case .invoice:
            CustomField(text: $startingInvoiceNumber, placeholder: "Starting Invoice Number", colors: colors)
        case .done:
            Button("Get Started") {
                didComplete = true
                // Completion logic here
            }
            .font(.headline)
            .frame(maxWidth: .infinity)
            .padding()
            .background(colors.accent)
            .foregroundColor(colors.buttonText)
            .cornerRadius(16)
            .shadow(radius: 3, y: 2)
        }
    }
    
    private var nextButtonLabel: String {
        step == .invoice && startingInvoiceNumber.trimmingCharacters(in: .whitespaces).isEmpty ? "Skip" : "Next"
    }
    
    private func nextStep() {
        if step.rawValue + 1 < Step.allCases.count {
            step = Step(rawValue: step.rawValue + 1)!
        }
    }
    private func previousStep() {
        if step.rawValue > 0 {
            step = Step(rawValue: step.rawValue - 1)!
        }
    }
}

/// A reusable, stylized field for this onboarding.
fileprivate struct CustomField: View {
    @Binding var text: String
    let placeholder: String
    let colors: GradientOnboardingColors
    var body: some View {
        TextField(placeholder, text: $text)
            .disableAutocorrection(true)
            .textInputAutocapitalization(.words)
            .foregroundColor(colors.title)
            .padding()
            .background(colors.fieldBackground)
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(colors.subtitle.opacity(0.17), lineWidth: 1)
            )
    }
}

#Preview {
    OnboardingGradientView()
}
