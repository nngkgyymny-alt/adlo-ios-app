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
}

private final class FakeCaseService: CaseDataProviding {
    let primaryCase: CaseFile?
    let documents: [DocumentItem]
    var shouldFailMarkSubmitted = false
    private(set) var markSubmittedCallCount = 0

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
}
