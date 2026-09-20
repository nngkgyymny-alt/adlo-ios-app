import Foundation

struct CaseFile: Identifiable, Decodable {
    let id: String
    let caseType: String
    let referenceNumber: String
    let currentStage: String
    let filedDate: Date
    let milestones: [CaseMilestone]
}

struct CaseMilestone: Identifiable, Decodable {
    let id: String
    let title: String
    let date: Date?
    let isComplete: Bool
}

extension CaseFile {
    static let sample = CaseFile(
        id: "sample",
        caseType: "Family-Based Green Card (I-130/I-485)",
        referenceNumber: "ADL-2026-0142",
        currentStage: "Awaiting Biometrics Appointment",
        filedDate: Calendar.current.date(byAdding: .month, value: -4, to: .now) ?? .now,
        milestones: [
            CaseMilestone(id: "1", title: "Retainer Signed", date: Calendar.current.date(byAdding: .month, value: -4, to: .now), isComplete: true),
            CaseMilestone(id: "2", title: "Petition Filed (I-130)", date: Calendar.current.date(byAdding: .month, value: -3, to: .now), isComplete: true),
            CaseMilestone(id: "3", title: "Receipt Notice Received", date: Calendar.current.date(byAdding: .month, value: -3, to: .now), isComplete: true),
            CaseMilestone(id: "4", title: "Biometrics Appointment", date: nil, isComplete: false),
            CaseMilestone(id: "5", title: "Interview Scheduled", date: nil, isComplete: false),
            CaseMilestone(id: "6", title: "Decision", date: nil, isComplete: false)
        ]
    )
}
