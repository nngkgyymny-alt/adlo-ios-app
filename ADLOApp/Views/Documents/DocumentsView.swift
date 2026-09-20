import SwiftUI

struct DocumentsView: View {
    @EnvironmentObject private var appState: AppState

    var body: some View {
        NavigationStack {
            LoadStateView(loadState: appState.loadState, retry: appState.loadCaseData) {
                List {
                    ForEach(appState.documents) { document in
                        Button {
                            Task { await appState.toggleSubmitted(for: document.id) }
                        } label: {
                            HStack(alignment: .top, spacing: 12) {
                                Image(systemName: document.isSubmitted ? "checkmark.circle.fill" : "circle")
                                    .foregroundStyle(document.isSubmitted ? .green : .secondary)
                                    .font(.title3)
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(document.title)
                                        .font(.subheadline.weight(.semibold))
                                        .foregroundStyle(.primary)
                                    Text(document.detail)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                    if !document.isSubmitted, let dueDate = document.dueDate {
                                        Text("Due \(dueDate.formatted(date: .abbreviated, time: .omitted))")
                                            .font(.caption2.weight(.semibold))
                                            .foregroundStyle(Theme.warning)
                                    }
                                }
                                Spacer()
                            }
                            .padding(.vertical, 4)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .navigationTitle("Documents")
        }
    }
}

#Preview {
    DocumentsView()
        .environmentObject(AppState())
}
