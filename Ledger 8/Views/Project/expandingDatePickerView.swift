//
//  expandingDatePickerView.swift
//  Ledger 8
//
//  Created by Gabe Witcher on 10/7/25.
//

import SwiftUI
import SwiftData

struct expandingDatePickerView: View {
    
    @Binding  var startDate: Date
    @Binding  var endDate: Date
    @State private var isAllDay: Bool = false
    @State private var showStartDatePicker = false
    @State private var showStartTimePicker = false
    @State private var showEndDatePicker = false
    @State private var showEndTimePicker = false
    @State private var name = ""
    
    @FocusState private var focusField: ProjectField?
    
    var body: some View {
        
        Group {
            
            //Toggle("All Day", isOn: $isAllDay)
              
            HStack {
                //Spacer()
                Text("Start")
                    .foregroundStyle(.secondary)
                    .onTapGesture {
                        withAnimation(.easeInOut(duration: 0.2)){
                            if showStartTimePicker && !showStartDatePicker {
                                showStartTimePicker = false
                                showStartDatePicker = false
                            } else {
                                showStartDatePicker.toggle()
                            }
                        }
                    }
                
                Spacer()
                
                Button("\(startDate.formatted(date: .abbreviated, time: .omitted))") {
                    withAnimation(.easeInOut(duration: 0.2)){
                        if showStartTimePicker {
                            showStartTimePicker = false
                        }
                        showStartDatePicker.toggle()
                    }
                }
                .buttonStyle(.bordered)
                .foregroundStyle(.primary)
                
                Button("\(startDate.formatted(date: .omitted, time: .shortened))") {
                    withAnimation(.easeInOut(duration: 0.2)){
                        if showStartDatePicker {
                            showStartDatePicker = false
                        }
                        showStartTimePicker.toggle()
                    }
                }
                .buttonStyle(.bordered)
                .foregroundStyle(.primary)
            }
            
            if showStartDatePicker {
                    DatePicker("Start", selection: $startDate, displayedComponents: .date)
                        .datePickerStyle(.graphical)
                        .focused($focusField, equals: .startDate)
            }
            
            if showStartTimePicker {
                DatePicker("Start", selection: $startDate, displayedComponents: .hourAndMinute)
                    .datePickerStyle(.wheel)
                    .focused($focusField, equals: .startDate)
                       
            }
            
            HStack {
                //Spacer()
                Text("End")
                    .foregroundStyle(.secondary)
                    .onTapGesture {
                        withAnimation(.easeInOut(duration: 0.2)){
                            if showEndTimePicker && !showEndDatePicker {
                                showEndTimePicker = false
                                showEndDatePicker = false
                            } else {
                                showEndDatePicker.toggle()
                            }
                        }
                    }
                
                Spacer()
                
                Button("\(endDate.formatted(date: .abbreviated, time: .omitted))") {
                    withAnimation(.easeInOut(duration: 0.2)){
                        if showEndTimePicker {
                            showEndTimePicker = false
                        }
                        showEndDatePicker.toggle()
                    }
                }
                .buttonStyle(.bordered)
                .foregroundStyle(.primary)
                
                Button("\(endDate.formatted(date: .omitted, time: .shortened))") {
                    withAnimation(.easeInOut(duration: 0.2)){
                        if showEndDatePicker {
                            showEndDatePicker = false
                        }
                        showEndTimePicker.toggle()
                    }
                }
                .buttonStyle(.bordered)
                .foregroundStyle(.primary)
            }
            
            if showEndDatePicker {
                    DatePicker("", selection: $endDate, displayedComponents: .date)
                        .datePickerStyle(.graphical)
                        .focused($focusField, equals: .startDate)
            }
            
            if showEndTimePicker {
                DatePicker("", selection: $startDate, displayedComponents: .hourAndMinute)
                    .datePickerStyle(.wheel)
                    .focused($focusField, equals: .startDate)
                       
            }
            
//            TextField("Name", text: $name)
//                .focused($focusField, equals: .artist)
            
        }
        .onChange(of: focusField) { oldValue, newValue in
            if newValue != .startDate{
               
                    showStartDatePicker = false
                    showStartTimePicker = false
                
            }
        }
        
    }
}

//#Preview {
//    expandingDatePickerView()
//}
