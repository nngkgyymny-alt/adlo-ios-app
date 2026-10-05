import SwiftUI

/// Browse USCIS forms by category, resume a draft, or start a new one.
/// Mirrors adlo-cross's FormsListScreen — ported here without a second
/// sign-in (see FormsService's doc comment) since this app has only ever
/// had one adlo-portal session.
struct FormsListView: View {
    private enum LoadState {
        case loading
        case loaded
        case failed(String)
    }

    private let service = FormsService()

    @State private var loadState: LoadState = .loading
    @State private var formsList: FormsListResponse?
    @State private var submissions: [SubmissionSummary] = []
    @State private var startingFormId: String?
    @State private var navigationTarget: FormFillTarget?

    var body: some View {
        NavigationStack {
            Group {
                switch loadState {
                case .loading:
                    ProgressView("Loading forms…")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                case .failed(let message):
                    VStack(spacing: 12) {
                        Image(systemName: "exclamationmark.triangle")
                            .font(.largeTitle)
                            .foregroundStyle(.secondary)
                        Text(message)
                            .font(.subheadline)
                            .multilineTextAlignment(.center)
                            .foregroundStyle(.secondary)
                        Button("Try Again") { Task { await load() } }
                            .buttonStyle(.bordered)
                    }
                    .padding()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                case .loaded:
                    content
                }
            }
            .navigationTitle("Forms")
            .sheet(item: $navigationTarget, onDismiss: { Task { await load() } }) { target in
                NavigationStack {
                    FormFillView(key: target.key, formId: target.formId, title: target.title)
                }
            }
        }
        .task { await load() }
    }

    private var inProgress: [SubmissionSummary] {
        submissions.filter { !$0.submittedFinal }
    }

    private var content: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                if !inProgress.isEmpty {
                    Text("Continue a Form")
                        .font(.title3.weight(.bold))
                        .foregroundStyle(Theme.navy)
                    ForEach(inProgress) { submission in
                        SectionCard(title: submission.formName) {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Draft — not yet submitted")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                Button("Continue") {
                                    navigationTarget = FormFillTarget(
                                        key: submission.key,
                                        formId: submission.formId,
                                        title: submission.formName
                                    )
                                }
                                .buttonStyle(.borderedProminent)
                                .tint(Theme.navy)
                            }
                        }
                    }
                }

                Text("Start a New Form")
                    .font(.title3.weight(.bold))
                    .foregroundStyle(Theme.navy)

                if let formsList {
                    ForEach(formsList.categories) { category in
                        let formsInCategory = formsList.forms.filter { $0.category == category.id }
                        if !formsInCategory.isEmpty {
                            Text("\(category.icon) \(category.label.uppercased())")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(.secondary)
                            ForEach(formsInCategory) { form in
                                SectionCard(title: "\(form.id) — \(form.name)") {
                                    VStack(alignment: .leading, spacing: 8) {
                                        Text(form.description)
                                            .font(.subheadline)
                                        Text("\(form.fieldCount.total) fields")
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                        Button {
                                            Task { await startForm(form) }
                                        } label: {
                                            if startingFormId == form.id {
                                                ProgressView().frame(maxWidth: .infinity)
                                            } else {
                                                Text("Start").frame(maxWidth: .infinity)
                                            }
                                        }
                                        .buttonStyle(.borderedProminent)
                                        .tint(Theme.red)
                                        .disabled(startingFormId != nil)
                                    }
                                }
                            }
                        }
                    }
                }
            }
            .padding()
        }
        .refreshable { await load() }
    }

    private func load() async {
        if formsList == nil {
            loadState = .loading
        }
        do {
            async let formsResult = service.fetchForms()
            async let submissionsResult = service.fetchSubmissions()
            formsList = try await formsResult
            submissions = try await submissionsResult
            loadState = .loaded
        } catch {
            loadState = .failed(error.localizedDescription)
        }
    }

    private func startForm(_ form: FormListItem) async {
        startingFormId = form.id
        defer { startingFormId = nil }
        do {
            let result = try await service.createSubmission(formId: form.id)
            navigationTarget = FormFillTarget(key: result.key, formId: result.formId, title: result.formName)
        } catch {
            loadState = .failed(error.localizedDescription)
        }
    }
}

private struct FormFillTarget: Identifiable, Hashable {
    let key: String
    let formId: String
    let title: String
    var id: String { key }
}

#Preview {
    FormsListView()
}
