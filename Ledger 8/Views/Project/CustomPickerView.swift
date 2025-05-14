//
//  customPickerTest.swift
//  Ledger 8
//
//  Created by Gabe Witcher on 5/13/25.
//

import SwiftUI


struct CustomPickerView: View {
    
    @Binding var sortSelection: Status
    
    
    var body: some View {
        
        HStack(spacing: 0) {
            ForEach(Status.allCases) { status in
                Text(status.rawValue)
                    .padding(.vertical, 10)
                    .frame(width: 100)
                    .foregroundStyle(sortSelection == status ? .white : .black )
                    .bold(sortSelection == status)
                    .background {
                        ZStack {
                            if sortSelection == status {
                                Capsule()
                                    .foregroundStyle(Color.secondary)
                                //.frame(height: 1)
                                    //.offset(y:15)
                            }
                        }
                        .animation(.easeInOut(duration: 0.03), value: sortSelection)
                    }
                    .contentShape(.rect)
                    .onTapGesture {
                        sortSelection = status
                    }
            }
            
        }
        .padding(5)
        .background(.primary.opacity(0.06), in: .capsule)
        
    }
}
//#Preview {
//    CustomPicker(sortSelection: Status.open)
//}
