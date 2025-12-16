import SwiftUI

struct SettingsView: View {
    @AppStorage("ado_orgUrl") private var orgUrl: String = ""
    @AppStorage("ado_projectName") private var projectName: String = ""
    @AppStorage("ado_pat") private var pat: String = ""
    
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        Form {
            Section(header: Text("Azure DevOps Connection")) {
                TextField("Organization URL", text: $orgUrl)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .help("https://dev.azure.com/yourorg")
                
                TextField("Project Name", text: $projectName)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                
                SecureField("Personal Access Token (PAT)", text: $pat)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .help("Create a PAT with Work Items (Read) and Code (Read) scopes.")
            }
            
            Section {
                Text("Note: Ensure your PAT has access to the specified project.")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            HStack {
                Spacer()
                Button("Done") {
                    presentationMode.wrappedValue.dismiss()
                }
            }
        }
        .padding()
        .frame(width: 350)
    }
}
