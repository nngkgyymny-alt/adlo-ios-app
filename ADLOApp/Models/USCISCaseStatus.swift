import Foundation

struct USCISCaseStatusHistoryEntry: Decodable, Identifiable {
    let status: String
    let date: String?
    let description: String?

    var id: String { "\(status)-\(date ?? "")" }
}

struct USCISCaseStatus: Decodable {
    let receiptNumber: String
    let formType: String?
    let submittedDate: String?
    let modifiedDate: String?
    let status: String
    let description: String?
    let history: [USCISCaseStatusHistoryEntry]
}
