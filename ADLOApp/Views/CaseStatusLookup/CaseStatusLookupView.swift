import SwiftUI

/// Available to both clients and prospects (see RootTabView/ProspectTabView) —
/// a USCIS receipt number isn't tied to whether its holder has retained ADLO.
/// Pushed via NavigationLink from an existing NavigationStack (CaseStatusView,
/// ProspectStatusView) — does not wrap itself in another NavigationStack.
struct CaseStatusLookupView: View {
    @Environment(\.openURL) private var openURL
    @State private var receiptNumber = ""
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var result: USCISCaseStatus?
    @FocusState private var isReceiptFieldFocused: Bool

    private let service = CaseStatusLookupService()

    private var canSubmit: Bool {
        !receiptNumber.trimmingCharacters(in: .whitespaces).isEmpty && !isLoading
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                SectionCard(title: "Check Your USCIS Case Status") {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Enter your 13-character receipt number (e.g. IOE1234567890).")
                            .font(.caption)
                            .foregroundStyle(.secondary)

                        TextField("Receipt Number", text: $receiptNumber)
                            .textInputAutocapitalization(.characters)
                            .autocorrectionDisabled()
                            .focused($isReceiptFieldFocused)
                            .submitLabel(.search)
                            .onSubmit { submit() }
                            .textFieldStyle(.roundedBorder)

                        if let errorMessage {
                            Text(errorMessage)
                                .font(.footnote)
                                .foregroundStyle(.red)
                        }

                        Button(action: submit) {
                            if isLoading {
                                ProgressView().frame(maxWidth: .infinity)
                            } else {
                                Text("Check Status").frame(maxWidth: .infinity)
                            }
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(Theme.navy)
                        .disabled(!canSubmit)
                    }
                }

                if let result {
                    resultCard(for: result)
                }

                SectionCard(title: "Immigration Court (EOIR) Case") {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("EOIR doesn't offer status checks in-app — look up your immigration court case directly on the official government site using your A-Number.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Button {
                            if let url = URL(string: FirmContact.eoirStatusURL) {
                                openURL(url)
                            }
                        } label: {
                            Text("Check EOIR Status").frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.bordered)
                        .tint(Theme.navy)
                    }
                }
            }
            .padding()
        }
        .background(Theme.background)
        .navigationTitle("Check Status")
    }

    private func resultCard(for status: USCISCaseStatus) -> some View {
        SectionCard(title: "Receipt \(status.receiptNumber)") {
            VStack(alignment: .leading, spacing: 8) {
                Text(status.status)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Theme.navy)
                if let description = status.description {
                    Text(description)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                if let formType = status.formType {
                    Text("Form: \(formType)")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }

                if !status.history.isEmpty {
                    Divider().padding(.vertical, 4)
                    Text("History")
                        .font(.caption.weight(.semibold))
                    ForEach(status.history) { entry in
                        VStack(alignment: .leading, spacing: 2) {
                            HStack {
                                Text(entry.status)
                                    .font(.caption.weight(.medium))
                                Spacer()
                                if let date = entry.date {
                                    Text(date)
                                        .font(.caption2)
                                        .foregroundStyle(.secondary)
                                }
                            }
                            if let description = entry.description {
                                Text(description)
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .padding(.vertical, 2)
                    }
                }
            }
        }
    }

    private func submit() {
        guard canSubmit else { return }
        isReceiptFieldFocused = false
        errorMessage = nil
        result = nil
        isLoading = true
        Task {
            defer { isLoading = false }
            do {
                result = try await service.fetchStatus(receiptNumber: receiptNumber)
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }
}

#Preview {
    NavigationStack {
        CaseStatusLookupView()
    }
}
