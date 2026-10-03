import Foundation

/// Fetches/writes USCIS form schemas and the client's own submissions —
/// mirrors adlo-cross's src/hooks/useForms.ts and src/api/endpoints/forms.ts.
/// Unlike adlo-cross (whose Forms feature needs its own separate sign-in,
/// since its main session is still on the old case-estimator backend),
/// this just reuses the app's one existing adlo-portal session — no second
/// auth needed.
struct FormsService {
    private let client: APIClient

    init(client: APIClient = .shared) {
        self.client = client
    }

    func fetchForms() async throws -> FormsListResponse {
        try await client.send(.forms())
    }

    func fetchForm(formId: String) async throws -> FormSchema {
        try await client.send(.form(formId: formId))
    }

    func fetchSubmissions() async throws -> [SubmissionSummary] {
        let response: SubmissionsListResponse = try await client.send(.submissionsList())
        return response.submissions
    }

    func fetchSubmission(key: String) async throws -> SubmissionDetail {
        try await client.send(.submission(key: key))
    }

    func createSubmission(formId: String) async throws -> CreateSubmissionResponse {
        try await client.send(.createSubmission(formId: formId))
    }

    /// `data` should only contain the changed fields — the backend merges
    /// into the existing draft rather than replacing it.
    func saveDraft(key: String, data: FormData) async throws {
        try await client.sendVoid(.saveDraft(key: key, data: data))
    }

    func submitSubmission(key: String) async throws -> SubmitSubmissionResponse {
        try await client.send(.submitSubmission(key: key))
    }
}
