import Foundation

struct DocumentItem: Identifiable, Decodable {
    let id: String
    let title: String
    let detail: String
    var isSubmitted: Bool
    let dueDate: Date?
}

extension DocumentItem {
    static let sampleChecklist: [DocumentItem] = [
        DocumentItem(id: "1", title: "Valid Passport (all pages)", detail: "Clear copy of every page, including blank ones.", isSubmitted: true, dueDate: nil),
        DocumentItem(id: "2", title: "Marriage Certificate", detail: "Certified copy with English translation if needed.", isSubmitted: true, dueDate: nil),
        DocumentItem(id: "3", title: "Proof of Joint Residence", detail: "Lease, utility bills, or joint bank statements.", isSubmitted: false, dueDate: Calendar.current.date(byAdding: .day, value: 10, to: .now)),
        DocumentItem(id: "4", title: "Medical Exam (Form I-693)", detail: "Must be completed by a USCIS-approved civil surgeon.", isSubmitted: false, dueDate: Calendar.current.date(byAdding: .day, value: 21, to: .now)),
        DocumentItem(id: "5", title: "Affidavit of Support (I-864)", detail: "Sponsor's most recent tax return and W-2s.", isSubmitted: false, dueDate: Calendar.current.date(byAdding: .day, value: 30, to: .now))
    ]
}
