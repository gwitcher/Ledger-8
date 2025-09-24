//
//  ItemView2.swift
//  Ledger 8
//
//  Created by Gabe Witcher on 9/23/25.
//

import SwiftUI
import SwiftData
import SwiftUIFontIcon

struct ItemView2: View {
    var item: Item

    var body: some View {
        HStack(spacing: 20){
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(Color.clear)
                .frame(width: 20, height: 35)
                .overlay {
                    FontIcon.text(.awesome5Solid(code: item.icon), fontsize: 20, color: Color.icon)
                }
                Text(item.name)
                    .font(.subheadline)
                    .bold()
                    .lineLimit(3)
                    .minimumScaleFactor(0.7)
            
              Spacer()
            
            
                Text("\(item.itemType.rawValue)")
                    .font(.footnote)
                    .opacity(0.7)
                    .lineLimit(2)
                    .minimumScaleFactor(0.7)
            
            Spacer()
            
            Text("$\(item.fee.formatted(.number.precision(.fractionLength(2))))")
                .font(.subheadline)
                .fontWeight(.heavy)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
        .padding([.top, .bottom], 8)
        //.border(.red)
    }
}

#Preview {
    ItemView2(item: Item(name: "Sample Item",fee: 2000.00))
}
