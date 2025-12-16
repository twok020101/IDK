import SwiftUI

struct MenuBarView: View {
    @ObservedObject var viewModel: ADOViewModel
    @Environment(\.openWindow) var openWindow
    
    var body: some View {
        // App Header
        Text("ADO HUD")
            .font(.headline)
        
        Divider()
        
        // Actions
        Button("Refresh") {
            Task {
                await viewModel.refreshData()
            }
        }
        .keyboardShortcut("r", modifiers: .command)
        .disabled(viewModel.isLoading)
        
        if let lastUpdated = viewModel.lastUpdated {
            Text("Updated: \(lastUpdated.formatted(date: .omitted, time: .shortened))")
                .font(.caption)
        }
        
        Divider()
        
        // Status / Error
        if viewModel.isLoading {
            Text("Loading data...")
        } else if let error = viewModel.errorMessage {
            Text("Error: \(error)")
                .foregroundColor(.red)
        }
        
        // Pull Requests Section
        if !viewModel.pullRequests.isEmpty {
            Text("🔥 PRs Needing Review")
                .font(.caption)
            
            ForEach(viewModel.pullRequests) { pr in
                Button {
                    viewModel.openPullRequest(pr)
                } label: {
                    Text("\(pr.title) (\(pr.createdBy.displayName))")
                }
            }
            Divider()
        } else if !viewModel.isLoading && viewModel.errorMessage == nil {
            Text("No Active PRs")
            Divider()
        }
        
        // Work Items Section
        if !viewModel.workItems.isEmpty {
            Text("📌 My Tasks")
                .font(.caption)
            
            ForEach(viewModel.workItems) { item in
                Button {
                    viewModel.openWorkItem(item)
                } label: {
                    // Title + ID
                    Text("\(item.fields.title) [\(item.id)]")
                }
            }
            Divider()
        } else if !viewModel.isLoading && viewModel.errorMessage == nil {
            Text("No Assigned Tasks")
            Divider()
        }
        
        // Footer: Settings & Quit
        Button("Settings...") {
            openWindow(id: "settings")
        }
        .keyboardShortcut(",", modifiers: .command)
        
        Divider()
        
        Button("Quit ADO HUD") {
            viewModel.quitApp()
        }
        .keyboardShortcut("q", modifiers: .command)
    }
}
