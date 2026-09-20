import Foundation

struct DocumentItem: Identifiable, Decodable {
    let id: String
    let title: String
    let detail: String
    var isSubmitted: Bool
    let dueDate: Date?
    var hasFile: Bool
    var fileUrl: String?

    init(id: String, title: String, detail: String, isSubmitted: Bool, dueDate: Date?, hasFile: Bool = false, fileUrl: String? = nil) {
        self.id = id
        self.title = title
        self.detail = detail
        self.isSubmitted = isSubmitted
        self.dueDate = dueDate
        self.hasFile = hasFile
        self.fileUrl = fileUrl
    }

    // Custom decoding so `has_file`/`file_url` default gracefully rather than
    // failing to decode entirely if the backend response ever lags behind.
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        title = try container.decode(String.self, forKey: .title)
        detail = try container.decode(String.self, forKey: .detail)
        isSubmitted = try container.decode(Bool.self, forKey: .isSubmitted)
        dueDate = try container.decodeIfPresent(Date.self, forKey: .dueDate)
        hasFile = try container.decodeIfPresent(Bool.self, forKey: .hasFile) ?? false
        fileUrl = try container.decodeIfPresent(String.self, forKey: .fileUrl)
    }
}

extension DocumentItem {
    static let sampleChecklist: [DocumentItem] = [
        DocumentItem(id: "1", title: "Valid Passport (all pages)", detail: "Clear copy of every page, including blank ones.", isSubmitted: true, dueDate: nil, hasFile: true, fileUrl: "/api/portal/cases/case_123/documents/1/file"),
        DocumentItem(id: "2", title: "Marriage Certificate", detail: "Certified copy with English translation if needed.", isSubmitted: true, dueDate: nil, hasFile: true, fileUrl: "/api/portal/cases/case_123/documents/2/file"),
        DocumentItem(id: "3", title: "Proof of Joint Residence", detail: "Lease, utility bills, or joint bank statements.", isSubmitted: false, dueDate: Calendar.current.date(byAdding: .day, value: 10, to: .now)),
        DocumentItem(id: "4", title: "Medical Exam (Form I-693)", detail: "Must be completed by a USCIS-approved civil surgeon.", isSubmitted: false, dueDate: Calendar.current.date(byAdding: .day, value: 21, to: .now)),
        DocumentItem(id: "5", title: "Affidavit of Support (I-864)", detail: "Sponsor's most recent tax return and W-2s.", isSubmitted: false, dueDate: Calendar.current.date(byAdding: .day, value: 30, to: .now))
    ]
}
