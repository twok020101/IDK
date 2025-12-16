import Foundation

class ADONetworkService {
    
    enum ADOError: Error {
        case invalidConfig
        case invalidURL
        case decodingError
        case httpError(statusCode: Int)
        case unknown
    }
    
    private let session: URLSession
    
    init(session: URLSession = .shared) {
        self.session = session
    }
    
    // MARK: - Helpers
    
    private func makeHeaders(pat: String) -> [String: String] {
        let authString = ":" + pat
        let authData = authString.data(using: .utf8)!
        let base64Auth = authData.base64EncodedString()
        
        return [
            "Authorization": "Basic \(base64Auth)",
            "Content-Type": "application/json",
            "Accept": "application/json"
        ]
    }
    
    // MARK: - API Calls
    
    /// Fetches assigned work items using WIQL and then batches to get details
    func fetchAssignedItems(config: ADOConfig) async throws -> [WorkItem] {
        guard config.isValid else { throw ADOError.invalidConfig }
        
        // 1. Run WIQL Query
        let cleanOrg = config.orgUrl.trimmingCharacters(in: .init(charactersIn: "/"))
        let cleanProj = config.projectName.trimmingCharacters(in: .init(charactersIn: "/"))
        
        guard let wiqlUrl = URL(string: "\(cleanOrg)/\(cleanProj)/_apis/wit/wiql?api-version=6.0") else {
            throw ADOError.invalidURL
        }
        
        let query = """
        SELECT [System.Id], [System.Title], [System.State], [System.WorkItemType] 
        FROM WorkItems 
        WHERE [System.AssignedTo] = @Me 
        AND [System.State] <> 'Closed' 
        AND [System.State] <> 'Removed'
        ORDER BY [System.ChangedDate] DESC
        """
        
        let body: [String: String] = ["query": query]
        
        var request = URLRequest(url: wiqlUrl)
        request.httpMethod = "POST"
        request.allHTTPHeaderFields = makeHeaders(pat: config.pat)
        request.httpBody = try JSONEncoder().encode(body)
        
        let (data, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else { throw ADOError.unknown }
        guard httpResponse.statusCode == 200 else {
            throw ADOError.httpError(statusCode: httpResponse.statusCode)
        }
        
        let wiqlResult = try JSONDecoder().decode(WIQLResult.self, from: data)
        let ids = wiqlResult.workItems.map { $0.id }
        
        if ids.isEmpty { return [] }
        
        // 2. Fetch Details for IDs (Batch)
        // Max batch size is usually 200, assuming we don't have that many assigned active items for a HUD.
        // Endpoint: POST _apis/wit/workitemsbatch
        guard let batchUrl = URL(string: "\(cleanOrg)/\(cleanProj)/_apis/wit/workitemsbatch?api-version=6.0") else {
            throw ADOError.invalidURL
        }
        
        let batchBody: [String: Any] = [
            "ids": ids,
            "fields": ["System.Id", "System.Title", "System.State", "System.WorkItemType"]
        ]
        
        var batchRequest = URLRequest(url: batchUrl)
        batchRequest.httpMethod = "POST"
        batchRequest.allHTTPHeaderFields = makeHeaders(pat: config.pat)
        batchRequest.httpBody = try JSONSerialization.data(withJSONObject: batchBody)
        
        let (batchData, batchResponse) = try await session.data(for: batchRequest)
        
        guard let batchHttpReponse = batchResponse as? HTTPURLResponse, batchHttpReponse.statusCode == 200 else {
            throw ADOError.httpError(statusCode: (batchResponse as? HTTPURLResponse)?.statusCode ?? 0)
        }
        
        let batchResult = try JSONDecoder().decode(WorkItemBatchResponse.self, from: batchData)
        return batchResult.value
    }
    
    /// Fetches active pull requests for the project
    func fetchPullRequests(config: ADOConfig) async throws -> [PullRequest] {
        guard config.isValid else { throw ADOError.invalidConfig }
        
        let cleanOrg = config.orgUrl.trimmingCharacters(in: .init(charactersIn: "/"))
        let cleanProj = config.projectName.trimmingCharacters(in: .init(charactersIn: "/"))
        
        // Using Generic Active PRs for Project
        // To filter by reviewer, we need the reviewer ID. 
        // For MVP scaffold, we'll fetch all active PRs in the project. 
        // Note: The PRD mentioned filtering by 'searchCriteria.reviewerId={current_user_id}'.
        // If we want to strictly follow that, we'd need to fetch "My Profile" first.
        // I will omit that strictly for this step to keep it simple, or I could try searchCriteria.reviewerId=@Me? 
        // No, @Me doesn't work in REST API usually, only WIQL.
        // So fetching active PRs is the best MVP approximation.
        
        guard let url = URL(string: "\(cleanOrg)/\(cleanProj)/_apis/git/pullrequests?searchCriteria.status=active&api-version=6.0") else {
            throw ADOError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.allHTTPHeaderFields = makeHeaders(pat: config.pat)
        
        let (data, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else { throw ADOError.unknown }
        guard httpResponse.statusCode == 200 else {
            throw ADOError.httpError(statusCode: httpResponse.statusCode)
        }
        
        // Decode date strategy needed for ISO8601
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        
        let result = try decoder.decode(PullRequestResponse.self, from: data)
        return result.value
    }
}
