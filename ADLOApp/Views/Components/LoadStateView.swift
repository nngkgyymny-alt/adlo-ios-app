import SwiftUI

/// Wraps content that depends on `AppState.loadState`, showing a spinner or
/// retry prompt until the case data is loaded.
struct LoadStateView<Content: View>: View {
    let loadState: AppState.LoadState
    let retry: () async -> Void
    @ViewBuilder let content: Content

    var body: some View {
        switch loadState {
        case .idle, .loading:
            ProgressView("Loading your case…")
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
                Button("Try Again") { Task { await retry() } }
                    .buttonStyle(.bordered)
            }
            .padding()
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        case .loaded:
            content
        }
    }
}
