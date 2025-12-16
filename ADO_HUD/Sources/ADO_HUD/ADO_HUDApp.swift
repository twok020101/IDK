import SwiftUI

@main
struct ADO_HUDApp: App {
    @StateObject private var viewModel = ADOViewModel()
    
    var body: some Scene {
        // 1. Menu Bar Extra
        MenuBarExtra("ADO HUD", systemImage: "rectangle.stack") {
            MenuBarView(viewModel: viewModel)
                .onAppear {
                    // Initial fetch when menu opens? 
                    // Or fetch on app launch? 
                    // Usually app launch but keeping it fresh is good.
                    // Let's do nothing onAppear to strict menu style (it rebuilds views).
                    // We can trigger fetch on init of VM or here if empty.
                    if viewModel.lastUpdated == nil {
                        Task { await viewModel.refreshData() }
                    }
                }
        }
        .menuBarExtraStyle(.menu)
        
        // 2. Settings Window
        Window("Settings", id: "settings") {
            SettingsView()
                .frame(minWidth: 300, minHeight: 200)
        }
        .windowResizability(.contentSize)
        // Note: For a pure menu bar app, we might want to hide the distinct app icon in dock
        // but SwiftUI life cycle manages that via Info.plist (LSUIElement).
    }
}
