import XCTest
@testable import ADLOApp

final class ADLOAppTests: XCTestCase {
    func testOutstandingDocumentsCount() {
        let state = AppState()
        let submittedCount = state.documents.filter(\.isSubmitted).count
        XCTAssertEqual(state.outstandingDocumentsCount, state.documents.count - submittedCount)
    }

    func testToggleSubmittedFlipsStatus() {
        let state = AppState()
        guard let first = state.documents.first else {
            return XCTFail("Expected sample documents")
        }
        let originalStatus = first.isSubmitted
        state.toggleSubmitted(for: first.id)
        XCTAssertEqual(state.documents.first?.isSubmitted, !originalStatus)
    }
}
