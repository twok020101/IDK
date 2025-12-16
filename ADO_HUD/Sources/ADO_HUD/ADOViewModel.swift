import Foundation
import Combine
import SwiftUI // For AppStorage if strictly needed, but easier to just read UserDefaults here

@MainActor
class ADOViewModel: ObservableObject {
    @Published var workItems: [WorkItem] = []
    @Published var pullRequests: [PullRequest] = []
    @Published var errorMessage: String?
    @Published var isLoading: Bool = false
    @Published var lastUpdated: Date?
    
    // Dependencies
    private let networkService: ADONetworkService
    
    // Config keys - matching what we will use in SettingsView
    private let kOrgUrl = "ado_orgUrl"
    private let kProjectName = "ado_projectName"
    private let kPat = "ado_pat"
    
    init(networkService: ADONetworkService = ADONetworkService()) {
        self.networkService = networkService
    }
    
    var config: ADOConfig? {
        let org = UserDefaults.standard.string(forKey: kOrgUrl) ?? ""
        let proj = UserDefaults.standard.string(forKey: kProjectName) ?? ""
        let pat = UserDefaults.standard.string(forKey: kPat) ?? ""
        
        // Return nil if incomplete, or just returns struct. 
        // Logic in isValid checks emptiness.
        return ADOConfig(orgUrl: org, projectName: proj, pat: pat)
    }
    
    func refreshData() async {
        guard let currentConfig = config, currentConfig.isValid else {
            errorMessage = "Please configure your ADO details in Settings."
            return
        }
        
        isLoading = true
        errorMessage = nil
        
        do {
            // Use TaskGroup to fetch in parallel
            try await withThrowingTaskGroup(of: Void.self) { group in
                group.addTask {
                    let items = try await self.networkService.fetchAssignedItems(config: currentConfig)
                    await MainActor.run { self.workItems = items }
                }
                
                group.addTask {
                    let prs = try await self.networkService.fetchPullRequests(config: currentConfig)
                    await MainActor.run { self.pullRequests = prs }
                }
                
                try await group.waitForAll()
            }
            
            lastUpdated = Date()
            
        } catch {
            if let adoError = error as? ADONetworkService.ADOError {
                switch adoError {
                case .invalidConfig: errorMessage = "Invalid Configuration."
                case .invalidURL: errorMessage = "Invalid URL constructed."
                case .httpError(let code):
                    if code == 401 || code == 403 {
                        errorMessage = "Authentication Failed. Check PAT."
                    } else {
                        errorMessage = "Server Error: \(code)"
                    }
                default: errorMessage = "Network Error: \(error.localizedDescription)"
                }
            } else {
                errorMessage = "Error: \(error.localizedDescription)"
            }
        }
        
        isLoading = false
    }
    
    func openWorkItem(_ item: WorkItem) {
        if let config = config, let url = item.webUrl(orgUrl: config.orgUrl, projectName: config.projectName) {
            NSWorkspace.shared.open(url)
        }
    }
    
    func openPullRequest(_ pr: PullRequest) {
        if let url = pr.webUrl {
            NSWorkspace.shared.open(url)
        }
    }
    
    func quitApp() {
        NSApplication.shared.terminate(nil)
    }
}
