import Foundation

/// USCIS case status lookup — available to any signed-in account, client
/// or prospect, since a receipt number isn't tied to whether its holder
/// has retained ADLO. There's no EOIR equivalent here: EOIR has no public
/// API, only the lookup website at acis.eoir.justice.gov — see
/// FirmContact.eoirStatusURL, which the app links out to directly instead.
struct CaseStatusLookupService {
    private let client: APIClient

    init(client: APIClient = .shared) {
        self.client = client
    }

    func fetchStatus(receiptNumber: String) async throws -> USCISCaseStatus {
        try await client.send(.uscisStatus(receiptNumber: receiptNumber))
    }
}
