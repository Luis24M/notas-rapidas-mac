import Foundation
import Testing
@testable import NotasCore

@MainActor
struct NoteStoreTests {
    let fileURL = FileManager.default.temporaryDirectory
        .appending(path: UUID().uuidString)
        .appending(path: "notas.json")

    @Test func notesSurviveReopening() throws {
        let store = try NoteStore(fileURL: fileURL)
        store.add("Llamar a Ana")
        store.add("Enviar factura")
        store.toggleCompleted(store.pending[0].id)

        let reopened = try NoteStore(fileURL: fileURL)
        #expect(reopened.notes == store.notes)
        #expect(reopened.pending.map(\.text) == ["Llamar a Ana"])
        #expect(reopened.completed.map(\.text) == ["Enviar factura"])
    }

    @Test func blankNotesAreIgnoredAndTextIsTrimmed() throws {
        let store = try NoteStore(fileURL: fileURL)
        store.add("  \n ")
        #expect(store.notes.isEmpty)

        store.add("  hola \n")
        #expect(store.notes.map(\.text) == ["hola"])
    }

    @Test func pendingShowsNewestFirst() throws {
        let earlier = Date(timeIntervalSince1970: 1_000)
        let later = Date(timeIntervalSince1970: 2_000)
        try write([
            Note(id: UUID(), text: "antigua", createdAt: earlier, completedAt: nil),
            Note(id: UUID(), text: "nueva", createdAt: later, completedAt: nil),
        ])

        let store = try NoteStore(fileURL: fileURL)
        #expect(store.pending.map(\.text) == ["nueva", "antigua"])
    }

    @Test func togglingTwiceReturnsNoteToPending() throws {
        let store = try NoteStore(fileURL: fileURL)
        store.add("tarea")
        let id = try #require(store.notes.first).id

        store.toggleCompleted(id)
        #expect(store.pending.isEmpty)

        store.toggleCompleted(id)
        #expect(store.pending.map(\.id) == [id])
        #expect(store.completed.isEmpty)
    }

    @Test func updateChangesTextButRejectsBlank() throws {
        let store = try NoteStore(fileURL: fileURL)
        store.add("original")
        let id = try #require(store.notes.first).id

        store.update(id, text: "   ")
        #expect(store.notes.map(\.text) == ["original"])

        store.update(id, text: " corregida ")
        #expect(try NoteStore(fileURL: fileURL).notes.map(\.text) == ["corregida"])
    }

    @Test func deleteCompletedKeepsPending() throws {
        let store = try NoteStore(fileURL: fileURL)
        store.add("queda")
        store.add("se va")
        store.toggleCompleted(store.pending[0].id)

        store.deleteCompleted()

        #expect(try NoteStore(fileURL: fileURL).notes.map(\.text) == ["queda"])
    }

    @Test func deleteRemovesOnlyThatNote() throws {
        let store = try NoteStore(fileURL: fileURL)
        store.add("queda")
        store.add("se va")

        store.delete(store.pending[0].id)

        #expect(try NoteStore(fileURL: fileURL).notes.map(\.text) == ["queda"])
    }

    @Test func unreadableFileThrowsAndStaysIntact() throws {
        try FileManager.default.createDirectory(at: fileURL.deletingLastPathComponent(), withIntermediateDirectories: true)
        let corrupt = Data("esto no es json".utf8)
        try corrupt.write(to: fileURL)

        #expect(throws: (any Error).self) { try NoteStore(fileURL: fileURL) }
        #expect(try Data(contentsOf: fileURL) == corrupt)
    }

    @Test func failedSaveIsReportedAndClearedByNextSuccessfulSave() throws {
        let store = try NoteStore(fileURL: fileURL)
        let directory = fileURL.deletingLastPathComponent()
        try Data().write(to: directory)

        store.add("no se guarda")
        #expect(store.saveError != nil)

        try FileManager.default.removeItem(at: directory)
        store.add("sí se guarda")
        #expect(store.saveError == nil)
        #expect(try NoteStore(fileURL: fileURL).notes.count == 2)
    }

    private func write(_ notes: [Note]) throws {
        try FileManager.default.createDirectory(at: fileURL.deletingLastPathComponent(), withIntermediateDirectories: true)
        try JSONEncoder().encode(notes).write(to: fileURL)
    }
}
