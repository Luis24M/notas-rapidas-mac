import NotasCore
import SwiftUI

private let notesFileURL = URL.applicationSupportDirectory.appending(path: "NotasRapidas/notas.json")

@main
struct NotasRapidasApp: App {
    @State private var loadedStore = Result { try NoteStore(fileURL: notesFileURL) }

    var body: some Scene {
        MenuBarExtra {
            switch loadedStore {
            case .success(let store):
                NotesView(store: store)
            case .failure(let error):
                LoadFailureView(error: error)
            }
        } label: {
            switch loadedStore {
            case .success(let store):
                MenuBarLabel(pendingCount: store.pending.count)
            case .failure:
                Image(systemName: "exclamationmark.triangle")
            }
        }
        .menuBarExtraStyle(.window)
    }
}

private struct MenuBarLabel: View {
    let pendingCount: Int

    var body: some View {
        if pendingCount == 0 {
            Image(systemName: "note.text")
        } else {
            HStack(spacing: 4) {
                Image(systemName: "note.text")
                Text("\(pendingCount)")
            }
        }
    }
}

private struct LoadFailureView: View {
    let error: any Error

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("No se pudieron leer las notas", systemImage: "exclamationmark.triangle.fill")
                .font(.headline)
                .symbolRenderingMode(.multicolor)
            Text(error.localizedDescription)
                .foregroundStyle(.secondary)
            Text("El archivo no se ha tocado: \(notesFileURL.path)")
                .font(.caption)
                .textSelection(.enabled)
            Button("Salir") { NSApplication.shared.terminate(nil) }
        }
        .padding(16)
        .frame(width: 360, alignment: .leading)
    }
}
