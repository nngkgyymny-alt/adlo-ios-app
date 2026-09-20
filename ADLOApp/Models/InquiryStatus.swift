import Foundation

/// A prospect's intake status + linked Lawmatics contact info (if any).
/// Clients see `CaseFile`/`DocumentItem` instead — see `AccountType`.
struct InquiryStatus: Decodable {
    let status: String
    let caseType: String?
    let summary: String?
    let hasLawmaticsContact: Bool
}
