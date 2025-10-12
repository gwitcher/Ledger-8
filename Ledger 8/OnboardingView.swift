import SwiftUI

struct OnboardingView: View {
    @AppStorage("didCompleteOnboarding") private var didCompleteOnboarding = false
    @AppStorage("startingInvoiceNumber") private var savedInvoiceNumber: Int = 0
    @AppStorage("userProfile") private var userProfileRawValue: String = "{}"

    @State private var step: Step = .welcome

    @State private var firstName: String = ""
    @State private var lastName: String = ""
    @State private var company: String = ""
    @State private var startingInvoiceNumber: String = ""

    @FocusState private var focusField: FocusField?

    enum Step: Int, CaseIterable {
        case welcome, profile, invoice, done
    }
    enum FocusField: Hashable {
        case firstName, lastName, company, invoice
    }

    private var canGoNext: Bool {
        switch step {
        case .profile:
            return !firstName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ||
                   !lastName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ||
                   !company.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        default:
            return true
        }
    }

    // Load and save UserData through AppStorage
    private var userData: UserData {
        get { UserData(rawValue: userProfileRawValue) ?? UserData() }
        set { userProfileRawValue = newValue.rawValue }
    }

    var body: some View {
        VStack {
            Spacer()
            ProgressView(value: Double(step.rawValue), total: Double(Step.allCases.count - 1))
                .accentColor(.accentColor)
                .scaleEffect(x: 1, y: 1.6, anchor: .center)
                .padding(.bottom, 12)

            Group {
                switch step {
                case .welcome:
                    welcomeStep
                        .transition(.opacity)
                case .profile:
                    profileStep
                        .transition(.move(edge: .trailing))
                case .invoice:
                    invoiceStep
                        .transition(.move(edge: .trailing))
                case .done:
                    doneStep
                        .transition(.scale)
                }
            }
            .animation(.easeInOut(duration: 0.3), value: step)

            Spacer()

            HStack {
                if step != .welcome {
                    Button("Back") {
                        withAnimation { step = Step(rawValue: step.rawValue - 1)! }
                    }
                    .padding()
                    .accessibilityLabel("Back")
                }
                Spacer()
                if step != .done {
                    Button(invoiceNextButtonLabel) {
                        handleInvoiceStepAdvance()
                    }
                    .disabled(step == .profile && !canGoNext)
                    .padding()
                    .accessibilityLabel(invoiceNextButtonLabel)
                }
            }
        }
        .padding()
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                focusIfNeeded()
            }
        }
        .onChange(of: step) { _, _ in
            focusIfNeeded()
        }
    }

    // MARK: - Step Views

    private var welcomeStep: some View {
        VStack(spacing: 24) {
            Image(systemName: "music.note.list")
                .resizable()
                .scaledToFit()
                .frame(width: 100, height: 90)
                .foregroundColor(.accentColor)
                .accessibilityHidden(true)
            Text("Welcome to Ledger 8!")
                .font(.largeTitle)
                .fontWeight(.bold)
            Text("Track your gigs, clients, and invoices with ease.")
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
        }
        .accessibilityElement(children: .combine)
    }

    private var profileStep: some View {
        VStack(spacing: 16) {
            Text("Let's get to know you")
                .font(.title2).bold()
            TextField("First Name", text: $firstName)
                .textFieldStyle(.roundedBorder)
                .padding(.horizontal)
                .focused($focusField, equals: .firstName)
                .submitLabel(.next)
                .onSubmit {
                    focusField = .lastName
                }
                .accessibilityLabel("First Name")
            TextField("Last Name", text: $lastName)
                .textFieldStyle(.roundedBorder)
                .padding(.horizontal)
                .focused($focusField, equals: .lastName)
                .submitLabel(.next)
                .onSubmit {
                    focusField = .company
                }
                .accessibilityLabel("Last Name")
            TextField("Company Name (optional)", text: $company)
                .textFieldStyle(.roundedBorder)
                .padding(.horizontal)
                .focused($focusField, equals: .company)
                .submitLabel(.done)
                .onSubmit {
                    if canGoNext { goToNextStep() }
                }
                .accessibilityLabel("Company Name")
        }
    }

    private var invoiceStep: some View {
        VStack(spacing: 16) {
            Text("Set a Starting Invoice Number")
                .font(.title2)
                .bold()
            Text("You can skip this step and set it later in Settings.")
                .font(.caption)
                .foregroundColor(.secondary)
            TextField("Starting Invoice Number", text: $startingInvoiceNumber)
                .textFieldStyle(.roundedBorder)
                .keyboardType(.numberPad)
                .padding(.horizontal)
                .focused($focusField, equals: .invoice)
                .submitLabel(.done)
                .onSubmit {
                    handleInvoiceStepAdvance()
                }
                .accessibilityLabel("Starting Invoice Number")
        }
    }

    private var doneStep: some View {
        VStack(spacing: 24) {
            Image(systemName: "checkmark.seal.fill")
                .resizable()
                .scaledToFit()
                .frame(width: 80, height: 80)
                .foregroundColor(.green)
                .accessibilityHidden(true)
            Text("You're Ready!")
                .font(.title).bold()
            Text("Let's add your first project.")
                .font(.headline)
            Button(action: {
                didCompleteOnboarding = true
                // Save profile info to AppStorage
                var newUserData = UserData()
                newUserData.userFirstName = firstName
                newUserData.userLastName = lastName
                newUserData.company.name = company
                userProfileRawValue = newUserData.rawValue

                UINotificationFeedbackGenerator().notificationOccurred(.success)
            }) {
                Text("Get Started")
            }
            .buttonStyle(.borderedProminent)
            .padding(.top)
            .accessibilityLabel("Get Started")
        }
    }

    // MARK: - Button label logic for invoice step
    private var invoiceNextButtonLabel: String {
        if step == .invoice {
            return startingInvoiceNumber.trimmingCharacters(in: .whitespaces).isEmpty ? "Skip" : "Next"
        } else {
            return "Next"
        }
    }

    // MARK: - Handle next step and save invoice number
    private func handleInvoiceStepAdvance() {
        if step == .invoice, let value = Int(startingInvoiceNumber.trimmingCharacters(in: .whitespaces)), value > 0 {
            savedInvoiceNumber = value
        }
        goToNextStep()
    }

    private func goToNextStep() {
        if step.rawValue + 1 < Step.allCases.count {
            withAnimation {
                step = Step(rawValue: step.rawValue + 1)!
            }
        }
    }

    // MARK: - Auto-focus logic
    private func focusIfNeeded() {
        switch step {
        case .profile:
            focusField = .firstName
        case .invoice:
            focusField = .invoice
        default:
            focusField = nil
        }
    }
}

#Preview {
    OnboardingView()
}
