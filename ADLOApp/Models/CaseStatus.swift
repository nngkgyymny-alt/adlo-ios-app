import Foundation

struct CaseFile: Identifiable {
    let id: UUID
    let caseType: String
    let referenceNumber: String
    let currentStage: String
    let filedDate: Date
    let milestones: [CaseMilestone]
}

struct CaseMilestone: Identifiable {
    let id: UUID
    let title: String
    let date: Date?
    let isComplete: Bool
}

extension CaseFile {
    static let sample = CaseFile(
        id: UUID(),
        caseType: "Family-Based Green Card (I-130/I-485)",
        referenceNumber: "ADL-2026-0142",
        currentStage: "Awaiting Biometrics Appointment",
        filedDate: Calendar.current.date(byAdding: .month, value: -4, to: .now) ?? .now,
        milestones: [
            CaseMilestone(id: UUID(), title: "Retainer Signed", date: Calendar.current.date(byAdding: .month, value: -4, to: .now), isComplete: true),
            CaseMilestone(id: UUID(), title: "Petition Filed (I-130)", date: Calendar.current.date(byAdding: .month, value: -3, to: .now), isComplete: true),
            CaseMilestone(id: UUID(), title: "Receipt Notice Received", date: Calendar.current.date(byAdding: .month, value: -3, to: .now), isComplete: true),
            CaseMilestone(id: UUID(), title: "Biometrics Appointment", date: nil, isComplete: false),
            CaseMilestone(id: UUID(), title: "Interview Scheduled", date: nil, isComplete: false),
            CaseMilestone(id: UUID(), title: "Decision", date: nil, isComplete: false)
        ]
    )
}
