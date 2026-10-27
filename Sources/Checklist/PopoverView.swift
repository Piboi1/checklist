import AppKit
import SwiftUI

// MARK: - Theme

private enum Theme {
    static let mint = LinearGradient(
        colors: [Color(hex: 0xA6F28B), Color(hex: 0x5EEAD4)],
        startPoint: .leading, endPoint: .trailing
    )
    static let mintSolid = Color(hex: 0x7CF0B0)
    static let amber = LinearGradient(
        colors: [Color(hex: 0xFFE8A3), Color(hex: 0xFFB23E)],
        startPoint: .top, endPoint: .bottom
    )
    static let ember = Color(hex: 0xF0501F)
}

private extension Color {
    init(hex: UInt32) {
        self.init(
            red: Double((hex >> 16) & 0xFF) / 255,
            green: Double((hex >> 8) & 0xFF) / 255,
            blue: Double(hex & 0xFF) / 255
        )
    }
}

// MARK: - Popover

struct PopoverView: View {
    @EnvironmentObject private var model: TodoModel
    @State private var draft = ""
    @FocusState private var focused: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            header

            if model.isClear {
                ClearHero(total: model.items.count)
            } else {
                SegmentBar(done: model.doneCount, total: model.items.count)
                taskList
            }

            inputRow
        }
        .padding(18)
        .frame(width: 340)
        .background {
            if model.isClear {
                SunsetBackground()
            } else {
                NightBackground()
            }
        }
        .preferredColorScheme(.dark)
        .onAppear { focused = true }
        .onReceive(NotificationCenter.default.publisher(for: NSWindow.didBecomeKeyNotification)) { _ in
            model.refresh()
            focused = true
        }
    }

    private var header: some View {
        HStack(alignment: .firstTextBaseline) {
            VStack(alignment: .leading, spacing: 2) {
                Text("TODAY")
                    .font(.system(size: 10, weight: .semibold))
                    .tracking(1.2)
                    .foregroundStyle(Color.white.opacity(0.55))
                Text(model.items.isEmpty ? "Nothing yet" : "\(model.doneCount)/\(model.items.count) done")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(.white)
            }
            Spacer()
            Menu {
                Button("Clear completed") { model.clearCompleted() }
                    .disabled(model.doneCount == 0)
                Divider()
                Button("Quit Checklist") { NSApplication.shared.terminate(nil) }
                    .keyboardShortcut("q")
            } label: {
                Image(systemName: "ellipsis.circle")
                    .font(.system(size: 16))
                    .foregroundStyle(Color.white.opacity(0.6))
            }
            .menuStyle(.borderlessButton)
            .menuIndicator(.hidden)
            .fixedSize()
        }
    }

    private var taskList: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 4) {
                ForEach(model.items.displayOrdered) { item in
                    TaskRow(
                        item: item,
                        onToggle: { model.toggle(item) },
                        onDelete: { model.delete(item) }
                    )
                }
            }
        }
        .frame(maxHeight: 300)
        .scrollIndicators(.never)
    }

    private var inputRow: some View {
        HStack(spacing: 8) {
            TextField("Add a task, press return", text: $draft)
                .textFieldStyle(.plain)
                .font(.system(size: 13))
                .focused($focused)
                .onSubmit {
                    model.add(draft)
                    draft = ""
                    focused = true
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 9)
                .background(RoundedRectangle(cornerRadius: 12).fill(Color.white.opacity(0.09)))

            Button {
                if let text = NSPasteboard.general.string(forType: .string) {
                    model.add(text)
                }
            } label: {
                Image(systemName: "doc.on.clipboard")
                    .font(.system(size: 13))
                    .foregroundStyle(Color.white.opacity(0.7))
                    .frame(width: 34, height: 34)
                    .background(Circle().fill(Color.white.opacity(0.09)))
            }
            .buttonStyle(.plain)
            .help("Add every line on the clipboard as a task")
        }
    }
}

// MARK: - Rows and progress

private struct TaskRow: View {
    let item: TodoItem
    let onToggle: () -> Void
    let onDelete: () -> Void
    @State private var hovering = false

    var body: some View {
        HStack(spacing: 10) {
            Button(action: onToggle) {
                Image(systemName: item.isDone ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 18))
                    .foregroundStyle(item.isDone ? Theme.mintSolid : Color.white.opacity(0.45))
            }
            .buttonStyle(.plain)

            Text(item.title)
                .font(.system(size: 14, weight: .medium))
                .strikethrough(item.isDone)
                .foregroundStyle(Color.white.opacity(item.isDone ? 0.35 : 0.92))
                .lineLimit(2)
                .frame(maxWidth: .infinity, alignment: .leading)
                .contentShape(Rectangle())
                .onTapGesture(perform: onToggle)

            Button(action: onDelete) {
                Image(systemName: "xmark")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(Color.white.opacity(0.4))
            }
            .buttonStyle(.plain)
            .opacity(hovering ? 1 : 0)
        }
        .padding(.vertical, 3)
        .onHover { hovering = $0 }
    }
}

/// One block per task (capped at 12), filled as tasks get done.
private struct SegmentBar: View {
    let done: Int
    let total: Int

    var body: some View {
        let segments = max(1, min(total, 12))
        let filled = Int((Double(done) / Double(max(total, 1)) * Double(segments)).rounded())

        HStack(spacing: 3) {
            ForEach(0..<segments, id: \.self) { index in
                RoundedRectangle(cornerRadius: 2.5)
                    .fill(index < filled ? AnyShapeStyle(Theme.mint) : AnyShapeStyle(Color.white.opacity(0.1)))
                    .frame(height: 8)
            }
        }
    }
}

// MARK: - Empty / all done

private let clockFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateFormat = "HH:mm"
    return formatter
}()

private struct ClearHero: View {
    let total: Int

    var body: some View {
        TimelineView(.periodic(from: .now, by: 1)) { context in
            VStack(spacing: 4) {
                Text(clockFormatter.string(from: context.date))
                    .font(.system(size: 84, weight: .ultraLight))
                    .monospacedDigit()
                    .foregroundStyle(Theme.amber)
                    .shadow(color: Theme.ember.opacity(0.55), radius: 14)

                Text(total == 0 ? "Nothing on the list" : "All \(total) done")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(.white)
                Text(total == 0 ? "Add a task to plan your day" : "Enjoy the quiet")
                    .font(.system(size: 12))
                    .foregroundStyle(Color.white.opacity(0.65))

                DayDashes(date: context.date)
                    .padding(.top, 18)
            }
            .frame(maxWidth: .infinity)
            .padding(.top, 8)
        }
    }
}

/// 24 dashes, one per hour, lit up to the current hour.
private struct DayDashes: View {
    let date: Date

    var body: some View {
        let startOfDay = Calendar.current.startOfDay(for: date)
        let lit = Int(date.timeIntervalSince(startOfDay) / 86_400 * 24)

        HStack(spacing: 3) {
            ForEach(0..<24, id: \.self) { hour in
                Capsule()
                    .fill(hour < lit ? Theme.ember : Color.white.opacity(0.22))
                    .frame(height: 4)
            }
        }
    }
}

// MARK: - Backgrounds

/// Dark navy with a soft mint glow.
private struct NightBackground: View {
    var body: some View {
        ZStack {
            Color(hex: 0x0B1018)
            RadialGradient(
                colors: [Color(hex: 0x5EEAD4).opacity(0.16), .clear],
                center: .topTrailing, startRadius: 0, endRadius: 260
            )
        }
    }
}

/// Dusk sky with a low sun.
private struct SunsetBackground: View {
    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color(hex: 0x120912), Color(hex: 0x2B0F12)],
                startPoint: .top, endPoint: .bottom
            )
            RadialGradient(
                colors: [
                    Color(hex: 0xFFC44D).opacity(0.95),
                    Color(hex: 0xF0782A).opacity(0.7),
                    Color(hex: 0x9B2A1A).opacity(0.35),
                    .clear,
                ],
                center: UnitPoint(x: 0.5, y: 0.4), startRadius: 4, endRadius: 230
            )
        }
    }
}
