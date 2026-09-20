import Foundation
import Combine

final class AppState: ObservableObject {
    @Published var clientFirstName: String = "Client"
    @Published var caseFile: CaseFile = .sample
    @Published var documents: [DocumentItem] = DocumentItem.sampleChecklist

    var outstandingDocumentsCount: Int {
        documents.filter { !$0.isSubmitted }.count
    }

    func toggleSubmitted(for documentID: UUID) {
        guard let index = documents.firstIndex(where: { $0.id == documentID }) else { return }
        documents[index].isSubmitted.toggle()
    }
}
