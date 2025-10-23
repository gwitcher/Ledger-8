//
//  ShowInvoice.swift
//  Ledger 8
//
//  Created by Gabe Witcher on 4/28/25.
//

import SwiftUI
import PDFKit
import os.log

struct ShowInvoice: View {
    @Environment(\.dismiss) var dismiss
    
    let pdfURL: URL
    let pdfTitle: String
    
    @State private var showingShareError = false
    @State private var shareErrorMessage = ""
    @State private var isValidatingFile = true
    @State private var fileExists = false
    
    private let logger = Logger(subsystem: "com.ledger8.invoice", category: "PDFViewer")
  
    var body: some View {
        NavigationStack {
            VStack {
                if isValidatingFile {
                    ProgressView("Loading PDF...")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if fileExists {
                    PDFKitView(url: pdfURL)
                        .scaledToFit()
                } else {
                    ContentUnavailableView(
                        "PDF Not Available",
                        systemImage: "doc.questionmark",
                        description: Text("The PDF file could not be loaded. It may have been moved or deleted.")
                    )
                }
            }
            .toolbar {
                ToolbarItem {
                    ShareLink(item: pdfURL) {
                        Label("Share", systemImage: "square.and.arrow.up")
                    }
                    .disabled(!fileExists)
                }
                
                ToolbarItem(placement: .topBarLeading) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .navigationTitle(pdfTitle)
            .navigationBarTitleDisplayMode(.inline)
            .task {
                await validatePDFFile()
            }
            .alert("Share Error", isPresented: $showingShareError) {
                Button("OK") { }
            } message: {
                Text(shareErrorMessage)
            }
        }
    }
    
    private func validatePDFFile() async {
        isValidatingFile = true
        defer { isValidatingFile = false }
        
        // Check if file exists
        guard FileManager.default.fileExists(atPath: pdfURL.path) else {
            logger.error("PDF file not found: \(pdfURL.path)")
            fileExists = false
            return
        }
        
        // Validate file size
        do {
            let attributes = try FileManager.default.attributesOfItem(atPath: pdfURL.path)
            if let fileSize = attributes[.size] as? Int64 {
                guard fileSize > 0 else {
                    logger.error("PDF file is empty: \(pdfURL.lastPathComponent)")
                    fileExists = false
                    return
                }
                logger.info("PDF file validated: \(pdfURL.lastPathComponent), size: \(fileSize) bytes")
            }
        } catch {
            logger.error("Failed to validate PDF file: \(error.localizedDescription)")
            fileExists = false
            return
        }
        
        fileExists = true
    }
}

struct PDFKitView: UIViewRepresentable {
    let url: URL
    
    @State private var showingLoadError = false
    private let logger = Logger(subsystem: "com.ledger8.invoice", category: "PDFKit")
    
    init(url: URL) {
        self.url = url
    }
    
    func makeUIView(context: Context) -> PDFView {
        let pdfView = PDFView()
        
        // Configure PDF view for better performance and UX
        pdfView.autoScales = true
        pdfView.displayDirection = .horizontal
        pdfView.minScaleFactor = 0.25
        pdfView.maxScaleFactor = 4.0
        pdfView.displayMode = .singlePage
        
        // Load PDF document with error handling
        loadPDFDocument(into: pdfView)
        
        return pdfView
    }
    
    func updateUIView(_ pdfView: PDFView, context: Context) {
        // Reload PDF if URL changes
        if pdfView.document?.documentURL != url {
            loadPDFDocument(into: pdfView)
        }
    }
    
    private func loadPDFDocument(into pdfView: PDFView) {
        DispatchQueue.global(qos: .userInitiated).async {
            let document = PDFDocument(url: self.url)
            
            DispatchQueue.main.async {
                if let document = document {
                    pdfView.document = document
                    self.logger.info("PDF document loaded successfully: \(self.url.lastPathComponent)")
                } else {
                    self.logger.error("Failed to load PDF document: \(self.url.lastPathComponent)")
                    // Could show an error view here
                }
            }
        }
    }
}


//#Preview {
//    ShowInvoice(pdfURL: URL(string: "file:///Users/gabewitcher/Library/Developer/CoreSimulator/Devices/9E2EFB53-705A-4BAE-8085-6377A4C596D5/data/Containers/Data/Application/1F49E395-428A-46BA-AB22-668478B2049C/Documents/Invoice_1_Dude_2025-05-05.pdf")!)
//}
