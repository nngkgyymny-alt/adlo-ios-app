import Foundation

protocol CaseDataProviding {
    func fetchPrimaryCase() async throws -> CaseFile?
    func fetchDocuments(caseID: String) async throws -> [DocumentItem]
    func markSubmitted(caseID: String, documentID: String) async throws
}

/// Fetches the signed-in client's case and document data from the ADLO API.
struct CaseService: CaseDataProviding {
    private let client: APIClient

    init(client: APIClient = .shared) {
        self.client = client
    }

    /// The backend returns every case the client has visibility into; the app
    /// currently shows the first (primary) one. Revisit if multi-case clients
    /// need a picker.
    func fetchPrimaryCase() async throws -> CaseFile? {
        let cases: [CaseFile] = try await client.send(.cases())
        return cases.first
    }

    func fetchDocuments(caseID: String) async throws -> [DocumentItem] {
        try await client.send(.documents(caseID: caseID))
    }

    func markSubmitted(caseID: String, documentID: String) async throws {
        try await client.sendVoid(.markDocumentSubmitted(caseID: caseID, documentID: documentID))
    }
}
