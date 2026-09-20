import Foundation

@MainActor
final class AppState: ObservableObject {
    enum LoadState: Equatable {
        case idle
        case loading
        case loaded
        case failed(String)
    }

    @Published var clientFirstName: String = ""
    /// Drives which contact email `ContactView` shows — `FirmContact` has a
    /// different address per track (new/potential vs. existing clients).
    @Published var accountType: AccountType = .prospect
    @Published var caseFile: CaseFile?
    @Published var documents: [DocumentItem] = []
    @Published private(set) var loadState: LoadState = .idle

    private let caseService: CaseDataProviding

    init(caseService: CaseDataProviding = CaseService()) {
        self.caseService = caseService
    }

    var outstandingDocumentsCount: Int {
        documents.filter { !$0.isSubmitted }.count
    }

    func configure(for user: ClientUser) {
        clientFirstName = user.firstName
        accountType = user.accountType
    }

    func loadCaseData() async {
        loadState = .loading
        do {
            guard let activeCase = try await caseService.fetchPrimaryCase() else {
                loadState = .failed("No case is linked to your account yet. Please contact our office.")
                return
            }
            caseFile = activeCase
            documents = try await caseService.fetchDocuments(caseID: activeCase.id)
            loadState = .loaded
        } catch {
            loadState = .failed(error.localizedDescription)
        }
    }

    func toggleSubmitted(for documentID: String) async {
        guard let caseFile, let index = documents.firstIndex(where: { $0.id == documentID }) else { return }
        let previousValue = documents[index].isSubmitted
        documents[index].isSubmitted.toggle()

        // Only the client-submitted -> submitted transition round-trips to the
        // server today; un-marking is local-only until the backend supports it.
        guard !previousValue else { return }
        do {
            try await caseService.markSubmitted(caseID: caseFile.id, documentID: documentID)
        } catch {
            documents[index].isSubmitted = previousValue
        }
    }

    /// Uploading a file IS the submission — mirrors the backend's
    /// `attachDocumentFile`, which also marks the item submitted.
    func uploadDocument(documentID: String, data: Data, fileName: String, mimeType: String) async throws {
        guard let caseFile else {
            throw AppStateError(errorDescription: "No case is linked to your account yet.")
        }
        let updated = try await caseService.uploadDocument(
            caseID: caseFile.id,
            documentID: documentID,
            fileData: data,
            fileName: fileName,
            mimeType: mimeType
        )
        if let index = documents.firstIndex(where: { $0.id == documentID }) {
            documents[index] = updated
        }
    }

    func fetchDocumentFile(documentID: String) async throws -> Data {
        guard let caseFile else {
            throw AppStateError(errorDescription: "No case is linked to your account yet.")
        }
        return try await caseService.fetchDocumentFile(caseID: caseFile.id, documentID: documentID)
    }
}

private struct AppStateError: LocalizedError {
    let errorDescription: String?
}
