//
//  InvoiceIconPreviewOptions.swift
//  Ledger 8
//
//  Preview options for invoice icon placement
//

import SwiftUI

struct InvoiceIconPreviewOptions: View {
    let sampleProject = ProjectSample()
    
    var body: some View {
        ScrollView {
            VStack(spacing: 30) {
                Text("Invoice Icon Placement Options")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .padding()
                
                // Option 1: Next to main icon
                VStack(alignment: .leading, spacing: 8) {
                    Text("Option 1: Next to Main Icon")
                        .font(.headline)
                    
                    ProjectRowOption1(project: sampleProject, hasInvoice: true)
                    ProjectRowOption1(project: sampleProject, hasInvoice: false)
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(12)
                
                // Option 2: In trailing section, top
                VStack(alignment: .leading, spacing: 8) {
                    Text("Option 2: Trailing Section Top")
                        .font(.headline)
                    
                    ProjectRowOption2(project: sampleProject, hasInvoice: true)
                    ProjectRowOption2(project: sampleProject, hasInvoice: false)
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(12)
                
                // Option 3: In trailing section, bottom
                VStack(alignment: .leading, spacing: 8) {
                    Text("Option 3: Trailing Section Bottom")
                        .font(.headline)
                    
                    ProjectRowOption3(project: sampleProject, hasInvoice: true)
                    ProjectRowOption3(project: sampleProject, hasInvoice: false)
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(12)
                
                // Option 4: Small icon in client name area
                VStack(alignment: .leading, spacing: 8) {
                    Text("Option 4: With Client Name")
                        .font(.headline)
                    
                    ProjectRowOption4(project: sampleProject, hasInvoice: true)
                    ProjectRowOption4(project: sampleProject, hasInvoice: false)
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(12)
                
                // Option 5: Replace items count when invoiced
                VStack(alignment: .leading, spacing: 8) {
                    Text("Option 5: Replace Items Count")
                        .font(.headline)
                    
                    ProjectRowOption5(project: sampleProject, hasInvoice: true)
                    ProjectRowOption5(project: sampleProject, hasInvoice: false)
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(12)
                
                // Option 6: Icon to the left of items
                VStack(alignment: .leading, spacing: 8) {
                    Text("Option 6: Left of Items Count")
                        .font(.headline)
                    
                    ProjectRowOption6(project: sampleProject, hasInvoice: true)
                    ProjectRowOption6(project: sampleProject, hasInvoice: false)
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(12)
            }
            .padding()
        }
        .navigationTitle("Invoice Icon Options")
    }
}

// Sample project data for previews
struct ProjectSample {
    let projectName = "Album Recording"
    let clientName = "The Test Band"
    let artist = "Rock Group"
    let startDate = Date()
    let feeTotal = 850.0
    let mediaType = "Recording"
    let itemsCount = 3
    let status = Status.delivered // Assuming delivered status
}

// Option 1: Next to main icon
struct ProjectRowOption1: View {
    let project: ProjectSample
    let hasInvoice: Bool
    
    var body: some View {
        HStack(spacing: 20) {
            // Icon section with invoice indicator
            HStack(spacing: 8) {
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(Color.blue.opacity(0.6))
                    .frame(width: 44, height: 44)
                    .overlay {
                        Image(systemName: "folder.fill")
                            .font(.title2)
                            .foregroundColor(.white)
                    }
                
                // Invoice icon next to main icon
                if hasInvoice {
                    Image(systemName: "doc.text")
                        .font(.caption)
                        .foregroundColor(.primary)
                }
            }
            
            VStack(alignment: .leading, spacing: 6) {
                Text(project.clientName)
                    .font(.subheadline)
                    .foregroundStyle(.primary)
                    .bold()
                    .lineLimit(1)
                
                Text(project.projectName)
                    .font(.footnote)
                    .foregroundStyle(.primary)
                    .opacity(0.7)
                    .lineLimit(1)
                
                Text(project.startDate.formatted(date: .abbreviated, time: .omitted))
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 6) {
                Text(project.feeTotal.formatted(.currency(code: "USD")))
                    .font(.subheadline)
                    .foregroundStyle(.red) // Delivered status color
                    .bold()
                    .lineLimit(1)
                
                Text(project.mediaType)
                    .font(.footnote)
                    .foregroundStyle(.primary)
                    .opacity(0.7)
                    .lineLimit(1)
                
                Text("^[\(project.itemsCount) Items](inflect: true)")
                    .font(.footnote)
                    .foregroundColor(.secondary)
            }
        }
        .padding([.top, .bottom], 6)
    }
}

// Option 2: Trailing section top
struct ProjectRowOption2: View {
    let project: ProjectSample
    let hasInvoice: Bool
    
    var body: some View {
        HStack(spacing: 20) {
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(Color.blue.opacity(0.6))
                .frame(width: 44, height: 44)
                .overlay {
                    Image(systemName: "folder.fill")
                        .font(.title2)
                        .foregroundColor(.white)
                }
            
            VStack(alignment: .leading, spacing: 6) {
                Text(project.clientName)
                    .font(.subheadline)
                    .foregroundStyle(.primary)
                    .bold()
                    .lineLimit(1)
                
                Text(project.projectName)
                    .font(.footnote)
                    .foregroundStyle(.primary)
                    .opacity(0.7)
                    .lineLimit(1)
                
                Text(project.startDate.formatted(date: .abbreviated, time: .omitted))
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 6) {
                HStack(spacing: 6) {
                    if hasInvoice {
                        Image(systemName: "doc.text.fill")
                            .font(.caption)
                            .foregroundColor(.primary)
                    }
                    Text(project.feeTotal.formatted(.currency(code: "USD")))
                        .font(.subheadline)
                        .foregroundStyle(.red)
                        .bold()
                        .lineLimit(1)
                }
                
                Text(project.mediaType)
                    .font(.footnote)
                    .foregroundStyle(.primary)
                    .opacity(0.7)
                    .lineLimit(1)
                
                Text("^[\(project.itemsCount) Items](inflect: true)")
                    .font(.footnote)
                    .foregroundColor(.secondary)
            }
        }
        .padding([.top, .bottom], 6)
    }
}

// Option 3: Trailing section bottom
struct ProjectRowOption3: View {
    let project: ProjectSample
    let hasInvoice: Bool
    
    var body: some View {
        HStack(spacing: 20) {
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(Color.blue.opacity(0.6))
                .frame(width: 44, height: 44)
                .overlay {
                    Image(systemName: "folder.fill")
                        .font(.title2)
                        .foregroundColor(.white)
                }
            
            VStack(alignment: .leading, spacing: 6) {
                Text(project.clientName)
                    .font(.subheadline)
                    .foregroundStyle(.primary)
                    .bold()
                    .lineLimit(1)
                
                Text(project.projectName)
                    .font(.footnote)
                    .foregroundStyle(.primary)
                    .opacity(0.7)
                    .lineLimit(1)
                
                Text(project.startDate.formatted(date: .abbreviated, time: .omitted))
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 6) {
                Text(project.feeTotal.formatted(.currency(code: "USD")))
                    .font(.subheadline)
                    .foregroundStyle(.red)
                    .bold()
                    .lineLimit(1)
                
                Text(project.mediaType)
                    .font(.footnote)
                    .foregroundStyle(.primary)
                    .opacity(0.7)
                    .lineLimit(1)
                
                HStack(spacing: 4) {
                    Text("^[\(project.itemsCount) Items](inflect: true)")
                        .font(.footnote)
                        .foregroundColor(.secondary)
                    
                    if hasInvoice {
                        Image(systemName: "doc.circle")
                            .font(.caption)
                            .foregroundColor(.primary)
                    }
                }
            }
        }
        .padding([.top, .bottom], 6)
    }
}

// Option 4: With client name
struct ProjectRowOption4: View {
    let project: ProjectSample
    let hasInvoice: Bool
    
    var body: some View {
        HStack(spacing: 20) {
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(Color.blue.opacity(0.6))
                .frame(width: 44, height: 44)
                .overlay {
                    Image(systemName: "folder.fill")
                        .font(.title2)
                        .foregroundColor(.white)
                }
            
            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 6) {
                    Text(project.clientName)
                        .font(.subheadline)
                        .foregroundStyle(.primary)
                        .bold()
                        .lineLimit(1)
                    
                    if hasInvoice {
                        Image(systemName: "doc.text")
                            .font(.caption2)
                            .foregroundColor(.primary)
                    }
                }
                
                Text(project.projectName)
                    .font(.footnote)
                    .foregroundStyle(.primary)
                    .opacity(0.7)
                    .lineLimit(1)
                
                Text(project.startDate.formatted(date: .abbreviated, time: .omitted))
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 6) {
                Text(project.feeTotal.formatted(.currency(code: "USD")))
                    .font(.subheadline)
                    .foregroundStyle(.red)
                    .bold()
                    .lineLimit(1)
                
                Text(project.mediaType)
                    .font(.footnote)
                    .foregroundStyle(.primary)
                    .opacity(0.7)
                    .lineLimit(1)
                
                Text("^[\(project.itemsCount) Items](inflect: true)")
                    .font(.footnote)
                    .foregroundColor(.secondary)
            }
        }
        .padding([.top, .bottom], 6)
    }
}

// Option 5: Replace items count
struct ProjectRowOption5: View {
    let project: ProjectSample
    let hasInvoice: Bool
    
    var body: some View {
        HStack(spacing: 20) {
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(Color.blue.opacity(0.6))
                .frame(width: 44, height: 44)
                .overlay {
                    Image(systemName: "folder.fill")
                        .font(.title2)
                        .foregroundColor(.white)
                }
            
            VStack(alignment: .leading, spacing: 6) {
                Text(project.clientName)
                    .font(.subheadline)
                    .foregroundStyle(.primary)
                    .bold()
                    .lineLimit(1)
                
                Text(project.projectName)
                    .font(.footnote)
                    .foregroundStyle(.primary)
                    .opacity(0.7)
                    .lineLimit(1)
                
                Text(project.startDate.formatted(date: .abbreviated, time: .omitted))
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 6) {
                Text(project.feeTotal.formatted(.currency(code: "USD")))
                    .font(.subheadline)
                    .foregroundStyle(.red)
                    .bold()
                    .lineLimit(1)
                
                Text(project.mediaType)
                    .font(.footnote)
                    .foregroundStyle(.primary)
                    .opacity(0.7)
                    .lineLimit(1)
                
                // Replace items count with invoice indicator when present
                if hasInvoice {
                    HStack(spacing: 4) {
                        Image(systemName: "doc.text.fill")
                            .font(.caption)
                            .foregroundColor(.primary)
                        Text("Invoice")
                            .font(.footnote)
                            .foregroundColor(.primary)
                    }
                } else {
                    Text("^[\(project.itemsCount) Items](inflect: true)")
                        .font(.footnote)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding([.top, .bottom], 6)
    }
}

// Option 6: Icon to the left of items
struct ProjectRowOption6: View {
    let project: ProjectSample
    let hasInvoice: Bool
    
    var body: some View {
        HStack(spacing: 20) {
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(Color.blue.opacity(0.6))
                .frame(width: 44, height: 44)
                .overlay {
                    Image(systemName: "folder.fill")
                        .font(.title2)
                        .foregroundColor(.white)
                }
            
            VStack(alignment: .leading, spacing: 6) {
                Text(project.clientName)
                    .font(.subheadline)
                    .foregroundStyle(.primary)
                    .bold()
                    .lineLimit(1)
                
                Text(project.projectName)
                    .font(.footnote)
                    .foregroundStyle(.primary)
                    .opacity(0.7)
                    .lineLimit(1)
                
                Text(project.startDate.formatted(date: .abbreviated, time: .omitted))
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 6) {
                Text(project.feeTotal.formatted(.currency(code: "USD")))
                    .font(.subheadline)
                    .foregroundStyle(.red)
                    .bold()
                    .lineLimit(1)
                
                Text(project.mediaType)
                    .font(.footnote)
                    .foregroundStyle(.primary)
                    .opacity(0.7)
                    .lineLimit(1)
                
                HStack(spacing: 4) {
                    if hasInvoice {
                        Image(systemName: "doc.text")
                            .font(.caption)
                            .foregroundColor(.primary)
                    }
                    Text("^[\(project.itemsCount) Items](inflect: true)")
                        .font(.footnote)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding([.top, .bottom], 6)
    }
}

#Preview("Option 1: Next to Icon") {
    VStack(spacing: 16) {
        ProjectRowOption1(project: ProjectSample(), hasInvoice: true)
        ProjectRowOption1(project: ProjectSample(), hasInvoice: false)
    }
    .padding()
}

#Preview("Option 2: Trailing Top") {
    VStack(spacing: 16) {
        ProjectRowOption2(project: ProjectSample(), hasInvoice: true)
        ProjectRowOption2(project: ProjectSample(), hasInvoice: false)
    }
    .padding()
}

#Preview("Option 3: Trailing Bottom") {
    VStack(spacing: 16) {
        ProjectRowOption3(project: ProjectSample(), hasInvoice: true)
        ProjectRowOption3(project: ProjectSample(), hasInvoice: false)
    }
    .padding()
}

#Preview("Option 4: With Client") {
    VStack(spacing: 16) {
        ProjectRowOption4(project: ProjectSample(), hasInvoice: true)
        ProjectRowOption4(project: ProjectSample(), hasInvoice: false)
    }
    .padding()
}

#Preview("Option 5: Replace Items") {
    VStack(spacing: 16) {
        ProjectRowOption5(project: ProjectSample(), hasInvoice: true)
        ProjectRowOption5(project: ProjectSample(), hasInvoice: false)
    }
    .padding()
}

#Preview("Option 6: Left of Items") {
    VStack(spacing: 16) {
        ProjectRowOption6(project: ProjectSample(), hasInvoice: true)
        ProjectRowOption6(project: ProjectSample(), hasInvoice: false)
    }
    .padding()
}

#Preview("All Options") {
    InvoiceIconPreviewOptions()
}