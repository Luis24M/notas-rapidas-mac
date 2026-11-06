import NotasCore
import SwiftUI

struct NoteRow: View {
    let note: Note
    let store: NoteStore

    @State private var hovering = false
    @State private var isToggling = false
    @State private var editedText: String?
    @FocusState private var editorFocused: Bool

    private var isCompleted: Bool { note.completedAt != nil }
    private var showsCheckmark: Bool { isCompleted != isToggling }
    private var showsActions: Bool { hovering && editedText == nil && !isToggling }

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Button(action: toggle) {
                Image(systemName: showsCheckmark ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 19, weight: .light))
                    .foregroundStyle(showsCheckmark ? AnyShapeStyle(.tint) : AnyShapeStyle(.tertiary))
                    .contentTransition(.symbolEffect(.replace))
                    .symbolEffect(.bounce, value: showsCheckmark)
                    .contentShape(Circle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel(isCompleted ? "Marcar como pendiente" : "Marcar como hecha")

            VStack(alignment: .leading, spacing: 2) {
                if let editedText {
                    TextField("", text: Binding(get: { editedText }, set: { self.editedText = $0 }), axis: .vertical)
                        .textFieldStyle(.plain)
                        .font(.system(size: 13.5))
                        .focused($editorFocused)
                        .onAppear { editorFocused = true }
                        .onSubmit(commitEdit)
                        .onChange(of: editorFocused) { _, focused in
                            if !focused { commitEdit() }
                        }
                } else {
                    Text(note.text)
                        .font(.system(size: 13.5))
                        .strikethrough(showsCheckmark, color: .secondary)
                        .foregroundStyle(showsCheckmark ? .secondary : .primary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                HStack {
                    Text(timestamp)
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                    Spacer()
                    HStack(spacing: 2) {
                        RowAction("pencil", label: "Editar") { editedText = note.text }
                        RowAction("trash", label: "Borrar") {
                            withAnimation(.snappy) { store.delete(note.id) }
                        }
                    }
                    .opacity(showsActions ? 1 : 0)
                    .allowsHitTesting(showsActions)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 7)
        .background(.primary.opacity(hovering ? 0.06 : 0), in: .rect(cornerRadius: 10))
        .contentShape(Rectangle())
        .onHover { hovering = $0 }
        .animation(.easeOut(duration: 0.12), value: hovering)
    }

    private var timestamp: String {
        let time = note.createdAt.formatted(.dateTime.hour().minute().locale(Locale(identifier: "es")))
        if Calendar.current.isDateInToday(note.createdAt) {
            return "Hoy, \(time)"
        }
        if Calendar.current.isDateInYesterday(note.createdAt) {
            return "Ayer, \(time)"
        }
        return note.createdAt.formatted(.dateTime.day().month(.abbreviated).hour().minute().locale(Locale(identifier: "es")))
    }

    /// Deja ver el check un instante antes de que la nota cambie de sección.
    private func toggle() {
        guard !isToggling else { return }
        withAnimation(.smooth(duration: 0.45)) {
            isToggling = true
        } completion: {
            withAnimation(.snappy) {
                store.toggleCompleted(note.id)
                isToggling = false
            }
        }
    }

    private func commitEdit() {
        guard let editedText else { return }
        store.update(note.id, text: editedText)
        self.editedText = nil
    }
}

private struct RowAction: View {
    let symbol: String
    let label: String
    let action: () -> Void

    init(_ symbol: String, label: String, action: @escaping () -> Void) {
        self.symbol = symbol
        self.label = label
        self.action = action
    }

    var body: some View {
        Button(action: action) {
            Image(systemName: symbol)
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(.secondary)
                .frame(width: 22, height: 16)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(label)
    }
}
