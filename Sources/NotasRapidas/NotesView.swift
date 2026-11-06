import NotasCore
import ServiceManagement
import SwiftUI

struct NotesView: View {
    let store: NoteStore

    @State private var draft = ""
    @State private var showsCompleted = false
    @State private var loginItemError: String?
    @FocusState private var inputFocused: Bool

    private var trimmedDraftIsEmpty: Bool {
        draft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            header
            input

            if let saveError = store.saveError {
                ErrorText("No se pudo guardar: \(saveError)")
            }
            if let loginItemError {
                ErrorText(loginItemError)
            }

            ScrollView {
                VStack(alignment: .leading, spacing: 2) {
                    if store.notes.isEmpty {
                        EmptyState()
                    }
                    ForEach(store.pending) { note in
                        NoteRow(note: note, store: store)
                            .transition(.opacity.combined(with: .scale(scale: 0.96, anchor: .top)))
                    }
                    if !store.completed.isEmpty {
                        completedSection
                    }
                }
            }
            .scrollBounceBehavior(.basedOnSize)
            .frame(maxHeight: 420)
            .fixedSize(horizontal: false, vertical: true)
        }
        .padding(14)
        .frame(width: 360)
        .tint(.orange)
        // La ventana de MenuBarExtra se reutiliza entre aperturas, así que onAppear
        // no basta para dejar el cursor listo cada vez que se abre.
        .onReceive(NotificationCenter.default.publisher(for: NSWindow.didBecomeKeyNotification)) { _ in
            inputFocused = true
        }
    }

    private var header: some View {
        HStack(alignment: .center, spacing: 10) {
            VStack(alignment: .leading, spacing: 1) {
                TimelineView(.everyMinute) { context in
                    Text(longDate(context.date))
                        .font(.caption.weight(.medium))
                        .foregroundStyle(.secondary)
                }
                Text(summary)
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .contentTransition(.numericText(value: Double(store.pending.count)))
            }
            Spacer()
            if !store.notes.isEmpty {
                ProgressRing(progress: Double(store.completed.count) / Double(store.notes.count))
            }
            OptionsMenu(error: $loginItemError)
        }
        .padding(.horizontal, 4)
    }

    private func longDate(_ date: Date) -> String {
        let formatted = date.formatted(.dateTime.weekday(.wide).day().month(.wide).locale(Locale(identifier: "es")))
        return formatted.prefix(1).uppercased() + formatted.dropFirst()
    }

    private var summary: String {
        switch store.pending.count {
        case 0: "Todo al día"
        case 1: "1 pendiente"
        case let count: "\(count) pendientes"
        }
    }

    private var input: some View {
        HStack(spacing: 8) {
            Image(systemName: "plus")
                .fontWeight(.semibold)
                .foregroundStyle(.secondary)
            TextField("Nueva nota", text: $draft, axis: .vertical)
                .lineLimit(1...4)
                .textFieldStyle(.plain)
                .font(.system(size: 14))
                .focused($inputFocused)
                .onSubmit(addDraft)
            if !trimmedDraftIsEmpty {
                Button(action: addDraft) {
                    Image(systemName: "arrow.up.circle.fill")
                        .font(.system(size: 20))
                        .foregroundStyle(.tint)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Añadir nota")
                .transition(.scale.combined(with: .opacity))
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 9)
        .glassEffect(.regular.interactive(), in: .rect(cornerRadius: 14))
        .animation(.snappy, value: trimmedDraftIsEmpty)
    }

    private func addDraft() {
        withAnimation(.spring(duration: 0.35, bounce: 0.25)) {
            store.add(draft)
        }
        draft = ""
    }

    private var completedSection: some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack {
                Button {
                    withAnimation(.snappy) { showsCompleted.toggle() }
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "chevron.right")
                            .font(.caption2.weight(.bold))
                            .rotationEffect(.degrees(showsCompleted ? 90 : 0))
                        Text("Hechas")
                        Text("\(store.completed.count)")
                            .monospacedDigit()
                            .contentTransition(.numericText())
                            .foregroundStyle(.tertiary)
                    }
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                Spacer()
                if showsCompleted {
                    Button("Borrar") {
                        withAnimation(.snappy) { store.deleteCompleted() }
                    }
                    .buttonStyle(.plain)
                    .foregroundStyle(.tint)
                    .transition(.opacity)
                }
            }
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(.secondary)
            .padding(.horizontal, 8)
            .padding(.top, 10)
            .padding(.bottom, 4)

            if showsCompleted {
                ForEach(store.completed) { note in
                    NoteRow(note: note, store: store)
                        .transition(.opacity.combined(with: .scale(scale: 0.96, anchor: .top)))
                }
            }
        }
    }
}

private struct ErrorText: View {
    let message: String

    init(_ message: String) {
        self.message = message
    }

    var body: some View {
        Label(message, systemImage: "exclamationmark.triangle.fill")
            .font(.caption)
            .foregroundStyle(.red)
            .padding(.horizontal, 4)
    }
}

private struct EmptyState: View {
    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: "checkmark.seal.fill")
                .font(.system(size: 36))
                .foregroundStyle(.tint)
                .symbolRenderingMode(.hierarchical)
                .padding(.bottom, 4)
            Text("Nada que recordar")
                .font(.headline)
            Text("Lo que anotes aparecerá aquí.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 24)
    }
}

private struct ProgressRing: View {
    let progress: Double

    var body: some View {
        ZStack {
            Circle()
                .stroke(.quaternary, lineWidth: 4)
            Circle()
                .trim(from: 0, to: progress)
                .stroke(.tint, style: StrokeStyle(lineWidth: 4, lineCap: .round))
                .rotationEffect(.degrees(-90))
        }
        .frame(width: 24, height: 24)
        .animation(.spring(duration: 0.5), value: progress)
        .accessibilityLabel("Hechas: \(Int(progress * 100)) %")
    }
}

private struct OptionsMenu: View {
    @Binding var error: String?

    @State private var opensAtLogin = SMAppService.mainApp.status == .enabled

    var body: some View {
        Menu {
            Toggle("Abrir al iniciar sesión", isOn: Binding(get: { opensAtLogin }, set: setOpensAtLogin))
            Divider()
            Button("Salir") { NSApplication.shared.terminate(nil) }
                .keyboardShortcut("q")
        } label: {
            Image(systemName: "ellipsis")
                .frame(width: 28, height: 28)
                .contentShape(Circle())
        }
        .menuStyle(.button)
        .menuIndicator(.hidden)
        .buttonStyle(.plain)
        .glassEffect(.regular.interactive(), in: .circle)
        .accessibilityLabel("Opciones")
    }

    private func setOpensAtLogin(_ enabled: Bool) {
        do {
            if enabled {
                try SMAppService.mainApp.register()
            } else {
                try SMAppService.mainApp.unregister()
            }
            error = nil
        } catch {
            self.error = error.localizedDescription
        }
        opensAtLogin = SMAppService.mainApp.status == .enabled
    }
}
