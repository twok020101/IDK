import Foundation

/// Configuration for Azure DevOps connection
struct ADOConfig: Codable, Equatable {
    var orgUrl: String
    var projectName: String
    var pat: String
    
    var isValid: Bool {
        !orgUrl.isEmpty && !projectName.isEmpty && !pat.isEmpty
    }
}

/// Represents a single Work Item from ADO
struct WorkItem: Decodable, Identifiable {
    let id: Int
    let fields: Fields
    let url: String // API URL
    
    // Computed helper for the web URL (not exact, but commonly constructed)
    func webUrl(orgUrl: String, projectName: String) -> URL? {
        // Construct standard ADO edit URL: https://dev.azure.com/{org}/{project}/_workitems/edit/{id}
        // Ensuring orgUrl doesn't end with slash, but safe to handle
        let cleanOrg = orgUrl.trimmingCharacters(in: .init(charactersIn: "/"))
        let cleanProj = projectName.trimmingCharacters(in: .init(charactersIn: "/"))
        return URL(string: "\(cleanOrg)/\(cleanProj)/_workitems/edit/\(id)")
    }
    
    struct Fields: Decodable {
        let title: String
        let state: String
        let workItemType: String
        
        enum CodingKeys: String, CodingKey {
            case title = "System.Title"
            case state = "System.State"
            case workItemType = "System.WorkItemType"
        }
    }
}

/// Response wrapper for WIQL query
struct WIQLResponse: Decodable {
    let workItems: [WorkItem]
    
    // Note: WIQL often returns a flat list of {id, url} first, 
    // but if we Expand Fields it comes in 'workItems'.
    // If we use the simple WIQL endpoint, it returns `workItems` as [{id, url}].
    // Then we might need to fetch details. 
    // However, the prompt WIQL implies we want the fields IN the response.
    // *Correction*: The standard WIQL endpoint `POST _apis/wit/wiql` actually ONLY returns ID and URL refs.
    // It DOES NOT return fields directly in the list usually, unless specified lightly, but standard practice
    // is WIQL -> Get IDs -> Get WorkItems Batch.
    // BUT checking the prompt constraints: "Create struct WorkItem decoding the JSON response from ADO WIQL API."
    // and "The WIQL Query: SELECT [System.Id], [System.Title]..."
    // If the user intends for us to use the WIQL result directly, we might be assuming the WIQL return format contains fields.
    // *Actually*, standard ADO WIQL response `workItems` array contains `{ id, url }`.
    // Then you have to call `GET _apis/wit/workitems?ids=...`
    // OR use the `reporting/workitemrevisions`? No.
    // *Decision*: I will implement the NetworkService to do the "Get IDs then Get Details" flow transparently, 
    // OR check if I can assume the WIQL returns data (it usually doesn't).
    // Wait, the user prompt says: "Create struct WorkItem decoding the JSON response from ADO WIQL API."
    // This implies the WIQL response *is* the WorkItem list. 
    // I will stick to the standard: WIQL returns IDs. I'll make `WorkItemReference` for WIQL and `WorkItem` for full details.
    // HOWEVER, for simplicity in a HUD, let's see if we can get fields. 
    // Actually, let's stick to the safest path: Fetch WIQL -> Get IDs -> Fetch Details (Batch).
    // I'll define `WorkItemReference` inside `ADONetworkService` or here.
}

struct WorkItemReference: Decodable {
    let id: Int
    let url: String
}

struct WIQLResult: Decodable {
    let workItems: [WorkItemReference]
}

struct WorkItemBatchResponse: Decodable {
    let value: [WorkItem]
    // The batch endpoint returns `value` array of WorkItems with fields.
}

/// Represents a Pull Request from ADO
struct PullRequest: Decodable, Identifiable {
    let pullRequestId: Int
    let title: String
    let creationDate: Date
    let repository: Repository
    let createdBy: CreatedBy
    let url: String // API URL
    // Web URL is usually usually provided as `remoteUrl` in repository or constructed.
    // Actually PR object usually has `webUrl` in `_links` maybe? or we construct it.
    // Let's look for `webUrl` in JSON if possible, otherwise construct.
    // ADO PR JSON usually has `url` (api) and `_links` -> `web` -> `href`.
    
    var id: Int { pullRequestId }
    
    struct Repository: Decodable {
        let name: String
        let webUrl: String
    }
    
    struct CreatedBy: Decodable {
        let displayName: String
    }
    
    // Helper to get web URL
    var webUrl: URL? {
        // The repository.webUrl is "https://dev.azure.com/org/proj/_git/repo"
        // PR url is ".../pullrequest/123"
        return URL(string: "\(repository.webUrl)/pullrequest/\(pullRequestId)")
    }
}

struct PullRequestResponse: Decodable {
    let value: [PullRequest]
}
