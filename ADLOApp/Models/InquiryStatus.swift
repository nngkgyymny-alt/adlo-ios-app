import Foundation

/// A prospect's fee estimate + intake status. Clients see `CaseFile`/`DocumentItem`
/// instead — see `AccountType`.
struct InquiryStatus: Decodable {
    let status: String
    let caseType: String?
    let feeLow: Double?
    let feeHigh: Double?
    let summary: String?
    let submittedAt: Date?
}
