import Foundation
import Observation

public struct Note: Identifiable, Codable, Equatable, Sendable {
    public let id: UUID
    public var text: String
    public let createdAt: Date
    public var completedAt: Date?
}

@MainActor
@Observable
public final class NoteStore {
    public private(set) var notes: [Note]
    public private(set) var saveError: String?

    private let fileURL: URL

    /// Lanza si el archivo existe pero no se puede leer: así nunca se arranca
    /// con una lista vacía que acabe sobrescribiendo las notas del usuario.
    public init(fileURL: URL) throws {
        self.fileURL = fileURL
        if FileManager.default.fileExists(atPath: fileURL.path) {
            notes = try JSONDecoder().decode([Note].self, from: Data(contentsOf: fileURL))
        } else {
            notes = []
        }
    }

    public var pending: [Note] {
        notes.filter { $0.completedAt == nil }.sorted { $0.createdAt > $1.createdAt }
    }

    public var completed: [Note] {
        notes.filter { $0.completedAt != nil }.sorted { $0.completedAt! > $1.completedAt! }
    }

    public func add(_ text: String) {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        notes.append(Note(id: UUID(), text: trimmed, createdAt: .now, completedAt: nil))
        save()
    }

    public func update(_ id: Note.ID, text: String) {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, let index = notes.firstIndex(where: { $0.id == id }) else { return }
        notes[index].text = trimmed
        save()
    }

    public func toggleCompleted(_ id: Note.ID) {
        guard let index = notes.firstIndex(where: { $0.id == id }) else { return }
        notes[index].completedAt = notes[index].completedAt == nil ? .now : nil
        save()
    }

    public func delete(_ id: Note.ID) {
        notes.removeAll { $0.id == id }
        save()
    }

    public func deleteCompleted() {
        notes.removeAll { $0.completedAt != nil }
        save()
    }

    private func save() {
        do {
            let encoder = JSONEncoder()
            encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
            let data = try encoder.encode(notes)
            try FileManager.default.createDirectory(
                at: fileURL.deletingLastPathComponent(),
                withIntermediateDirectories: true
            )
            try data.write(to: fileURL, options: .atomic)
            saveError = nil
        } catch {
            saveError = error.localizedDescription
        }
    }
}
