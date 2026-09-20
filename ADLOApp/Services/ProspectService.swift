import Foundation

/// Fetches a prospect's fee estimate + inquiry status. Mirrors `CaseService`
/// but for `AccountType.prospect` accounts.
struct ProspectService {
    private let client: APIClient

    init(client: APIClient = .shared) {
        self.client = client
    }

    func fetchInquiry() async throws -> InquiryStatus {
        try await client.send(.inquiry())
    }
}
