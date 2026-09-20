import Foundation

struct DocumentItem: Identifiable {
    let id: UUID
    let title: String
    let detail: String
    var isSubmitted: Bool
    let dueDate: Date?
}

extension DocumentItem {
    static let sampleChecklist: [DocumentItem] = [
        DocumentItem(id: UUID(), title: "Valid Passport (all pages)", detail: "Clear copy of every page, including blank ones.", isSubmitted: true, dueDate: nil),
        DocumentItem(id: UUID(), title: "Marriage Certificate", detail: "Certified copy with English translation if needed.", isSubmitted: true, dueDate: nil),
        DocumentItem(id: UUID(), title: "Proof of Joint Residence", detail: "Lease, utility bills, or joint bank statements.", isSubmitted: false, dueDate: Calendar.current.date(byAdding: .day, value: 10, to: .now)),
        DocumentItem(id: UUID(), title: "Medical Exam (Form I-693)", detail: "Must be completed by a USCIS-approved civil surgeon.", isSubmitted: false, dueDate: Calendar.current.date(byAdding: .day, value: 21, to: .now)),
        DocumentItem(id: UUID(), title: "Affidavit of Support (I-864)", detail: "Sponsor's most recent tax return and W-2s.", isSubmitted: false, dueDate: Calendar.current.date(byAdding: .day, value: 30, to: .now))
    ]
}
