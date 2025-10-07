//
//  ItemEntryView.swift
//  Ledger 7
//
//  Created by Gabe Witcher on 3/30/25.
//

import SwiftUI
import SwiftData
import SwiftUIFontIcon


struct ItemView: View {
    
    var item: Item

    var body: some View {
        VStack(alignment: .leading) {
            HStack(spacing: 20){
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(Color.clear)
                    .frame(width: 44, height: 35)
                    .overlay {
                        FontIcon.text(.awesome5Solid(code: item.icon), fontsize: 25, color: Color.itemIcon)
                    }
                VStack(alignment: .leading, spacing: 6) {
                    
                    Text(item.name)
                        .font(.subheadline)
                        .bold()
                        .lineLimit(1)
                    
                    Text("\(item.itemType.rawValue)")
                        .font(.footnote)
                        .opacity(0.7)
                        .lineLimit(1)
                }
                Spacer()
                
                Text("$\(item.fee.formatted(.number.precision(.fractionLength(2))))")
                    .font(.subheadline)
                    .fontWeight(.heavy)
                    .lineLimit(1)
            }
            
            
            if item.notes != "" {
                Text("* Note: \(item.notes)")
                    .font(.footnote)
                    .fontWeight(.thin)
                    .padding(.leading, 64)
                    //.opacity(0.7)
            }
            
        }
        .padding([.top, .bottom], 8)
    }
}

#Preview {
    ItemView(item: Item(name: "Sample Item",fee: 200.00))
}
