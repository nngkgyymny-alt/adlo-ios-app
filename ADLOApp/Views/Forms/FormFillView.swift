import SwiftUI

/// Fills out one USCIS form's fields, autosaving as the client types, and
/// submits to the attorney when done. Mirrors adlo-cross's FormFillScreen /
/// the web portal's FormFillClient.tsx.
struct FormFillView: View {
    let key: String
    let formId: String
    let title: String

    private enum LoadState {
        case loading
        case loaded
        case failed(String)
    }

    private let service = FormsService()
    private static let autosaveDelayNanoseconds: UInt64 = 1_500_000_000

    @State private var loadState: LoadState = .loading
    @State private var schema: FormSchema?
    @State private var data: FormData = [:]
    @State private var pendingChanges: FormData = [:]
    /// Only the debounce wait — cancelling this on a new keystroke never
    /// cancels an already-in-flight save, since the save lives in `saveTask`.
    @State private var debounceTask: Task<Void, Never>?
    /// The in-flight (or queued) autosave chain. Each new flush awaits the
    /// previous one first, so saves land in order and none get cancelled
    /// out from under a successful write.
    @State private var saveTask: Task<Void, Never>?
    @State private var submitError = ""
    @State private var isSubmitting = false
    @State private var submittedFinal = false
    @State private var showSubmittedConfirmation = false
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        Group {
            switch loadState {
            case .loading:
                ProgressView("Loading…")
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
                form
            }
        }
        .navigationTitle(title)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Close") { dismiss() }
            }
        }
        .task { await load() }
        .onDisappear { flushPendingChangesOnDisappear() }
        .alert("Submitted", isPresented: $showSubmittedConfirmation) {
            Button("OK") { dismiss() }
        } message: {
            Text("Your form has been sent to your attorney.")
        }
    }

    private var form: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                if let schema {
                    ForEach(schema.sections.filter { matchesConditional($0.conditional, data) }) { section in
                        SectionCard(title: section.title) {
                            VStack(alignment: .leading, spacing: 4) {
                                if let hint = section.hint {
                                    Text(hint)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                                ForEach(section.fields.filter { matchesConditional($0.conditional, data) }) { field in
                                    FormFieldInputView(
                                        field: field,
                                        value: data[field.id],
                                        onChange: { handleFieldChange(field.id, $0) }
                                    )
                                }
                            }
                        }
                    }
                }

                if !submitError.isEmpty {
                    Text(submitError)
                        .font(.footnote)
                        .foregroundStyle(.red)
                }

                Button(action: { Task { await submit() } }) {
                    if isSubmitting {
                        ProgressView().frame(maxWidth: .infinity)
                    } else {
                        Text(submittedFinal ? "Re-send to My Attorney" : "Submit to My Attorney")
                            .frame(maxWidth: .infinity)
                    }
                }
                .buttonStyle(.borderedProminent)
                .tint(Theme.red)
                .disabled(isSubmitting)

                Text("Your progress saves automatically as you go — you can come back and finish later.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
            }
            .padding()
        }
    }

    private func load() async {
        loadState = .loading
        do {
            async let schemaResult = service.fetchForm(formId: formId)
            async let submissionResult = service.fetchSubmission(key: key)
            schema = try await schemaResult
            let submission = try await submissionResult
            data = submission.data
            submittedFinal = submission.submittedFinal ?? false
            loadState = .loaded
        } catch {
            loadState = .failed(error.localizedDescription)
        }
    }

    private func handleFieldChange(_ fieldId: String, _ value: FormFieldValue) {
        data[fieldId] = value
        pendingChanges[fieldId] = value

        debounceTask?.cancel()
        debounceTask = Task {
            try? await Task.sleep(nanoseconds: Self.autosaveDelayNanoseconds)
            guard !Task.isCancelled else { return }
            flushPendingChanges()
        }
    }

    /// Synchronous: captures and clears `pendingChanges`, then chains the
    /// actual network call onto `saveTask` so a later call here never
    /// cancels a save already in flight — only `debounceTask` (the wait)
    /// gets cancelled on new keystrokes.
    private func flushPendingChanges() {
        guard !pendingChanges.isEmpty else { return }
        let changes = pendingChanges
        pendingChanges = [:]
        let previousSave = saveTask
        saveTask = Task {
            _ = await previousSave?.value
            try? await service.saveDraft(key: key, data: changes)
        }
    }

    /// `onDisappear` can't `await` — this flushes whatever didn't make it
    /// through the debounce timer (best-effort, fire-and-forget), mirroring
    /// the web/RN versions' unmount-time flush.
    private func flushPendingChangesOnDisappear() {
        debounceTask?.cancel()
        flushPendingChanges()
    }

    private func submit() async {
        submitError = ""
        isSubmitting = true
        defer { isSubmitting = false }

        debounceTask?.cancel()
        flushPendingChanges()
        do {
            await saveTask?.value
            _ = try await service.submitSubmission(key: key)
            submittedFinal = true
            showSubmittedConfirmation = true
        } catch {
            submitError = error.localizedDescription
        }
    }
}

#Preview {
    NavigationStack {
        FormFillView(key: "submission:preview", formId: "I-130", title: "I-130")
    }
}
