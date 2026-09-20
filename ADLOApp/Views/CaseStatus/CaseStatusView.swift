import SwiftUI

struct CaseStatusView: View {
    @EnvironmentObject private var appState: AppState

    var body: some View {
        NavigationStack {
            List {
                Section {
                    VStack(alignment: .leading, spacing: 6) {
                        Text(appState.caseFile.caseType)
                            .font(.headline)
                        Text("Filed \(appState.caseFile.filedDate.formatted(date: .abbreviated, time: .omitted))")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        Text("Reference: \(appState.caseFile.referenceNumber)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.vertical, 4)
                }

                Section("Timeline") {
                    ForEach(appState.caseFile.milestones) { milestone in
                        HStack(alignment: .top, spacing: 12) {
                            Image(systemName: milestone.isComplete ? "checkmark.circle.fill" : "circle")
                                .foregroundStyle(milestone.isComplete ? .green : .secondary)
                                .font(.title3)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(milestone.title)
                                    .font(.subheadline.weight(milestone.isComplete ? .regular : .semibold))
                                if let date = milestone.date {
                                    Text(date.formatted(date: .abbreviated, time: .omitted))
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            }
                            Spacer()
                        }
                        .padding(.vertical, 4)
                    }
                }
            }
            .navigationTitle("Case Status")
        }
    }
}

#Preview {
    CaseStatusView()
        .environmentObject(AppState())
}
