import XCTest
@testable import ADLOApp

@MainActor
final class ADLOAppTests: XCTestCase {
    func testLoadCaseDataPopulatesCaseAndDocuments() async {
        let service = FakeCaseService(
            primaryCase: .sample,
            documents: DocumentItem.sampleChecklist
        )
        let state = AppState(caseService: service)

        await state.loadCaseData()

        XCTAssertEqual(state.loadState, .loaded)
        XCTAssertEqual(state.caseFile?.id, CaseFile.sample.id)
        XCTAssertEqual(state.documents.count, DocumentItem.sampleChecklist.count)
    }

    func testLoadCaseDataWithNoCaseReportsFailure() async {
        let service = FakeCaseService(primaryCase: nil, documents: [])
        let state = AppState(caseService: service)

        await state.loadCaseData()

        guard case .failed = state.loadState else {
            return XCTFail("Expected .failed state when no case is linked")
        }
    }

    func testToggleSubmittedFlipsStatusAndCallsService() async {
        let service = FakeCaseService(primaryCase: .sample, documents: DocumentItem.sampleChecklist)
        let state = AppState(caseService: service)
        await state.loadCaseData()

        guard let firstUnsubmitted = state.documents.first(where: { !$0.isSubmitted }) else {
            return XCTFail("Expected at least one unsubmitted document in sample data")
        }

        await state.toggleSubmitted(for: firstUnsubmitted.id)

        XCTAssertTrue(state.documents.first(where: { $0.id == firstUnsubmitted.id })?.isSubmitted ?? false)
        XCTAssertEqual(service.markSubmittedCallCount, 1)
    }

    func testToggleSubmittedRollsBackOnServiceFailure() async {
        let service = FakeCaseService(primaryCase: .sample, documents: DocumentItem.sampleChecklist)
        service.shouldFailMarkSubmitted = true
        let state = AppState(caseService: service)
        await state.loadCaseData()

        guard let firstUnsubmitted = state.documents.first(where: { !$0.isSubmitted }) else {
            return XCTFail("Expected at least one unsubmitted document in sample data")
        }

        await state.toggleSubmitted(for: firstUnsubmitted.id)

        XCTAssertFalse(state.documents.first(where: { $0.id == firstUnsubmitted.id })?.isSubmitted ?? true)
    }

    func testUploadDocumentUpdatesTheMatchingDocument() async throws {
        let service = FakeCaseService(primaryCase: .sample, documents: DocumentItem.sampleChecklist)
        let state = AppState(caseService: service)
        await state.loadCaseData()

        guard let target = state.documents.first(where: { !$0.hasFile }) else {
            return XCTFail("Expected at least one document without a file in sample data")
        }

        try await state.uploadDocument(documentID: target.id, data: Data("fake".utf8), fileName: "id.pdf", mimeType: "application/pdf")

        let updated = state.documents.first(where: { $0.id == target.id })
        XCTAssertEqual(updated?.hasFile, true)
        XCTAssertTrue(updated?.isSubmitted ?? false)
        XCTAssertEqual(service.uploadDocumentCallCount, 1)
    }

    func testFetchDocumentFileReturnsServiceBytes() async throws {
        let service = FakeCaseService(primaryCase: .sample, documents: DocumentItem.sampleChecklist)
        service.fileData = Data("pdf-bytes".utf8)
        let state = AppState(caseService: service)
        await state.loadCaseData()

        let data = try await state.fetchDocumentFile(documentID: DocumentItem.sampleChecklist[0].id)

        XCTAssertEqual(data, Data("pdf-bytes".utf8))
    }
}

private final class FakeCaseService: CaseDataProviding {
    let primaryCase: CaseFile?
    let documents: [DocumentItem]
    var shouldFailMarkSubmitted = false
    var fileData = Data()
    private(set) var markSubmittedCallCount = 0
    private(set) var uploadDocumentCallCount = 0

    init(primaryCase: CaseFile?, documents: [DocumentItem]) {
        self.primaryCase = primaryCase
        self.documents = documents
    }

    func fetchPrimaryCase() async throws -> CaseFile? { primaryCase }

    func fetchDocuments(caseID: String) async throws -> [DocumentItem] { documents }

    func markSubmitted(caseID: String, documentID: String) async throws {
        markSubmittedCallCount += 1
        if shouldFailMarkSubmitted {
            throw APIError.server(status: 500, message: "failed")
        }
    }

    func uploadDocument(caseID: String, documentID: String, fileData: Data, fileName: String, mimeType: String) async throws -> DocumentItem {
        uploadDocumentCallCount += 1
        guard let existing = documents.first(where: { $0.id == documentID }) else {
            throw APIError.server(status: 404, message: "not found")
        }
        return DocumentItem(
            id: existing.id,
            title: existing.title,
            detail: existing.detail,
            isSubmitted: true,
            dueDate: existing.dueDate,
            hasFile: true,
            fileUrl: "/api/portal/cases/\(caseID)/documents/\(documentID)/file"
        )
    }

    func fetchDocumentFile(caseID: String, documentID: String) async throws -> Data {
        fileData
    }
}
