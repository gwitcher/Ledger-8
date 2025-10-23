//
//  AddInvoiceView.swift
//  Ledger 8
//
//  Created by Gabe Witcher on 4/24/25.
//

import SwiftUI
import SwiftData

struct AddInvoiceView: View {
    @Environment(\.modelContext) var modelContext
    @Query private var projects: [Project]
    
    var project: Project
    @AppStorage("InitialInvoiceNumber") var initialInvoiceNumber = -1
    
    // Invoice generation manager
    @State private var invoiceManager = InvoiceGenerationManager()
    @State private var showingErrorAlert = false
    @State private var errorAlertMessage = ""
    
    var body: some View {
        let nextInvoiceNumber = project.nextInvoiceNumber(projects: projects, defaultInvoiceNumber: initialInvoiceNumber)
        
        Button {
            Task {
                await generateInvoice(invoiceNumber: nextInvoiceNumber)
            }
        } label: {
            HStack {
                if invoiceManager.isGenerating {
                    ProgressView()
                        .scaleEffect(0.8)
                } else {
                    Image(systemName: "plus.circle.fill")
                        .foregroundStyle(.green)
                }
                Text(invoiceManager.isGenerating ? "Generating..." : "Add Invoice")
                    .tint(.primary)
            }
        }
        .disabled(invoiceManager.isGenerating)
        .onAppear {
            invoiceManager.updateModelContext(modelContext)
        }
        .alert("Invoice Generation Failed", isPresented: $showingErrorAlert) {
            Button("OK") { }
        } message: {
            Text(errorAlertMessage)
        }
    }
    
    @MainActor
    private func generateInvoice(invoiceNumber: Int) async {
        guard let invoice = await invoiceManager.generateInvoice(for: project, invoiceNumber: invoiceNumber) else {
            handleInvoiceGenerationError()
            return
        }
        
        // Success - save the invoice
        saveInvoice(newInvoice: invoice)
        print("✅ Invoice generated successfully: \(invoice.name)")
    }
    
    private func handleInvoiceGenerationError() {
        if let errorMessage = invoiceManager.errorMessage {
            // Provide user-friendly error messages with actionable advice
            switch true {
            case errorMessage.contains("invalid") || errorMessage.contains("incomplete"):
                errorAlertMessage = generateDetailedValidationMessage()
                
            case errorMessage.contains("storage") || errorMessage.contains("space"):
                errorAlertMessage = """
                Not enough storage space to generate the invoice PDF.
                
                Please free up some space on your device and try again.
                """
                
            case errorMessage.contains("PDF") || errorMessage.contains("rendering"):
                errorAlertMessage = """
                Failed to create the invoice PDF.
                
                This may be a temporary issue. Please try again in a moment.
                """
                
            default:
                errorAlertMessage = """
                Unable to generate invoice: \(errorMessage)
                
                Please check your project information and try again.
                """
            }
        } else {
            errorAlertMessage = generateDetailedValidationMessage()
        }
        
        showingErrorAlert = true
        print("😡 Invoice generation failed: \(invoiceManager.errorMessage ?? "Unknown error")")
    }
    
    private func generateDetailedValidationMessage() -> String {
        var issues: [String] = []
        
        // Check company data
        let userData: UserData
        if let userDataString = UserDefaults.standard.string(forKey: "userData"),
           let loadedUserData = UserData(rawValue: userDataString) {
            userData = loadedUserData
        } else {
            userData = UserData()
        }
        
        let company = userData.company
        if company.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && 
           company.contact.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            issues.append("• Company information: Enter either a Company Name OR Contact Person name in Settings")
        }
        
        // Check project items
        if let items = project.items {
            if items.isEmpty {
                issues.append("• Project items: Add at least one service item with a fee")
            } else {
                let total = project.calculateFeeTotal(items: items)
                if total < 0 {
                    issues.append("• Project total: Total amount cannot be negative (currently $\(String(format: "%.2f", total)))")
                }
            }
        } else {
            issues.append("• Project items: Add at least one service item with a fee")
        }
        
        // Check project basic info
        if project.projectName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            issues.append("• Project name: Enter a project name")
        }
        
        let baseMessage = "Cannot generate invoice. Please fix these issues:"
        
        if issues.isEmpty {
            return """
            Unable to generate invoice due to validation error.
            
            Please ensure:
            • Company Name OR Contact Person is set in Settings
            • Project has a name
            • Project has at least one item with a fee
            • Total amount is not negative
            """
        } else {
            return baseMessage + "\n\n" + issues.joined(separator: "\n")
        }
    }
    
    private func saveInvoice(newInvoice: Invoice) {
        project.invoice = newInvoice
        
        do {
            try modelContext.save()
            print("✅ Invoice saved to database")
        } catch {
            print("😡 ERROR: Cannot save invoice to database: \(error)")
            errorAlertMessage = "Invoice was generated but couldn't be saved. Please try again."
            showingErrorAlert = true
        }
    }
}

#Preview {
    AddInvoiceView(project: Project())
}
