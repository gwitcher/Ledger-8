//
//  WebkitPdfView.swift
//  Ledger 8
//
//  Created by Gabe Witcher on 5/6/25.
//

import SwiftUI
import WebKit

struct WebkitPdfView: View {
    @Environment(\.dismiss) var dismiss
    
    let pdfURL: URL
    let pdfTitle: String
    

    var body: some View {
        WebView(request: URLRequest(url: pdfURL))
    }

}
struct WebView: UIViewRepresentable {
    let request: URLRequest

    func makeUIView(context: Context) -> WKWebView {
        let webView = WKWebView()
        return webView
    }

    func updateUIView(_ uiView: WKWebView, context: Context) {
         uiView.load(request)
    }

}

//#Preview {
//    WebkitPdfView()
//}
