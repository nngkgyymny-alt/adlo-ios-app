import QuickLook
import SwiftUI
import UniformTypeIdentifiers

struct DocumentsView: View {
    @EnvironmentObject private var appState: AppState

    @State private var uploadTargetID: String?
    @State private var isPickingFile = false
    @State private var busyDocumentID: String?
    @State private var quickLookURL: URL?
    @State private var errorMessage: String?

    var body: some View {
        NavigationStack {
            LoadStateView(loadState: appState.loadState, retry: appState.loadCaseData) {
                List {
                    ForEach(appState.documents) { document in
                        documentRow(document)
                    }
                }
            }
            .navigationTitle("Documents")
        }
        .fileImporter(
            isPresented: $isPickingFile,
            allowedContentTypes: [.pdf, .jpeg, .png, .heic, .heif],
            onCompletion: handlePickedFile
        )
        .quickLookPreview($quickLookURL)
        .alert("Couldn't complete that", isPresented: Binding(get: { errorMessage != nil }, set: { if !$0 { errorMessage = nil } })) {
            Button("OK") { errorMessage = nil }
        } message: {
            Text(errorMessage ?? "")
        }
    }

    @ViewBuilder
    private func documentRow(_ document: DocumentItem) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Button {
                Task { await appState.toggleSubmitted(for: document.id) }
            } label: {
                Image(systemName: document.isSubmitted ? "checkmark.circle.fill" : "circle")
                    .foregroundStyle(document.isSubmitted ? .green : .secondary)
                    .font(.title3)
            }
            .buttonStyle(.plain)

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

            fileControl(for: document)
        }
        .padding(.vertical, 4)
    }

    @ViewBuilder
    private func fileControl(for document: DocumentItem) -> some View {
        if busyDocumentID == document.id {
            ProgressView()
        } else if document.hasFile {
            Button {
                Task { await viewFile(for: document) }
            } label: {
                Image(systemName: "doc.text.magnifyingglass")
            }
            .buttonStyle(.plain)
            .tint(Theme.teal)
        } else {
            Button {
                uploadTargetID = document.id
                isPickingFile = true
            } label: {
                Image(systemName: "square.and.arrow.up")
            }
            .buttonStyle(.plain)
            .tint(Theme.accent)
        }
    }

    private func handlePickedFile(_ result: Result<URL, Error>) {
        guard let documentID = uploadTargetID else { return }
        uploadTargetID = nil
        switch result {
        case .failure(let error):
            errorMessage = error.localizedDescription
        case .success(let url):
            Task { await upload(fileURL: url, documentID: documentID) }
        }
    }

    private func upload(fileURL: URL, documentID: String) async {
        let didAccess = fileURL.startAccessingSecurityScopedResource()
        defer { if didAccess { fileURL.stopAccessingSecurityScopedResource() } }

        busyDocumentID = documentID
        defer { busyDocumentID = nil }

        do {
            let data = try Data(contentsOf: fileURL)
            try await appState.uploadDocument(
                documentID: documentID,
                data: data,
                fileName: fileURL.lastPathComponent,
                mimeType: mimeType(for: fileURL)
            )
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func viewFile(for document: DocumentItem) async {
        busyDocumentID = document.id
        defer { busyDocumentID = nil }

        do {
            let data = try await appState.fetchDocumentFile(documentID: document.id)
            let tempURL = FileManager.default.temporaryDirectory
                .appendingPathComponent(document.id)
                .appendingPathExtension(fileExtension(for: data))
            try data.write(to: tempURL, options: .atomic)
            quickLookURL = tempURL
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func mimeType(for url: URL) -> String {
        switch url.pathExtension.lowercased() {
        case "pdf": return "application/pdf"
        case "png": return "image/png"
        case "heic": return "image/heic"
        case "heif": return "image/heif"
        default: return "image/jpeg"
        }
    }

    /// QuickLook picks its viewer from the file extension, not the bytes, so
    /// we sniff the PDF magic number rather than trust anything from the server.
    private func fileExtension(for data: Data) -> String {
        let pdfMagicNumber: [UInt8] = [0x25, 0x50, 0x44, 0x46]
        return data.starts(with: pdfMagicNumber) ? "pdf" : "jpg"
    }
}

#Preview {
    DocumentsView()
        .environmentObject(AppState())
}
