//
//  addClientButtonView.swift
//  Ledger 8
//
//  Created by Gabe Witcher on 10/7/25.
//

import SwiftUI

struct addClientButtonView: View {
    var body: some View {
        HStack {
            Image(systemName: "plus.circle.fill")
                .foregroundColor(.green)
            Text("Add Client")
                .foregroundStyle(.primary)
              
        }
    }
}

#Preview {
    addClientButtonView()
}
