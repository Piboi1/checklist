import AppIntents
import SwiftUI
import WidgetKit

// MARK: - Timeline

struct ChecklistEntry: TimelineEntry {
    let date: Date
    let items: [TodoItem]

    var doneCount: Int { items.filter(\.isDone).count }
    var isClear: Bool { items.isEmpty || doneCount == items.count }
}

struct Provider: TimelineProvider {
    func placeholder(in context: Context) -> ChecklistEntry {
        ChecklistEntry(date: .now, items: TodoItem.samples)
    }

    func getSnapshot(in context: Context, completion: @escaping (ChecklistEntry) -> Void) {
        let items = context.isPreview ? TodoItem.samples : TodoStore.load()
        completion(ChecklistEntry(date: .now, items: items))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<ChecklistEntry>) -> Void) {
        let items = TodoStore.load()
        let now = Date()

        if items.isEmpty || items.allSatisfy(\.isDone) {
            // The empty state shows a clock, so give it one entry per minute.
            let start = Calendar.current.dateInterval(of: .minute, for: now)?.start ?? now
            let entries = (0..<60).map {
                ChecklistEntry(date: start.addingTimeInterval(Double($0) * 60), items: items)
            }
            completion(Timeline(entries: entries, policy: .atEnd))
        } else {
            let entry = ChecklistEntry(date: now, items: items)
            completion(Timeline(entries: [entry], policy: .after(now.addingTimeInterval(30 * 60))))
        }
    }
}

// MARK: - Widget

@main
struct ChecklistWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: TodoStore.widgetKind, provider: Provider()) { entry in
            ChecklistWidgetView(entry: entry)
        }
        .configurationDisplayName("Checklist")
        .description("Today's tasks. Tap a circle to check it off, tap + to add more.")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
    }
}

struct ChecklistWidgetView: View {
    let entry: ChecklistEntry

    var body: some View {
        if entry.isClear {
            ClearView(entry: entry)
                .containerBackground(for: .widget) { SunsetBackground() }
        } else {
            TaskListView(entry: entry)
                .containerBackground(for: .widget) { NightBackground() }
        }
    }
}

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

private let addURL = URL(string: "checklist://add")!

private struct AddLink: View {
    var body: some View {
        Link(destination: addURL) {
            Image(systemName: "plus")
                .font(.system(size: 11, weight: .bold))
                .foregroundStyle(.white)
                .frame(width: 22, height: 22)
                .background(Circle().fill(Color.white.opacity(0.16)))
        }
    }
}

// MARK: - Backgrounds

/// Dark navy with a soft mint glow, like the "Main Goal" card.
private struct NightBackground: View {
    var body: some View {
        ZStack {
            Color(hex: 0x0B1018)
            RadialGradient(
                colors: [Color(hex: 0x5EEAD4).opacity(0.16), .clear],
                center: .topTrailing, startRadius: 0, endRadius: 220
            )
        }
    }
}

/// Dusk sky with a low sun, like the "Sleep" card.
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
                center: UnitPoint(x: 0.5, y: 0.55), startRadius: 4, endRadius: 170
            )
        }
    }
}

// MARK: - Task list

private struct TaskListView: View {
    @Environment(\.widgetFamily) private var family
    let entry: ChecklistEntry

    private var rowLimit: Int {
        switch family {
        case .systemSmall: return 3
        case .systemMedium: return 4
        default: return 9
        }
    }

    var body: some View {
        let ordered = entry.items.displayOrdered
        let visible = Array(ordered.prefix(rowLimit))
        let hidden = ordered.count - visible.count

        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .firstTextBaseline) {
                VStack(alignment: .leading, spacing: 1) {
                    Text("TODAY")
                        .font(.system(size: 10, weight: .semibold))
                        .tracking(1)
                        .foregroundStyle(Color.white.opacity(0.5))
                    Text("\(entry.doneCount)/\(entry.items.count) done")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(.white)
                }
                Spacer()
                AddLink()
            }

            SegmentBar(done: entry.doneCount, total: entry.items.count)

            VStack(alignment: .leading, spacing: 5) {
                ForEach(visible) { item in
                    TaskRow(item: item)
                }
                if hidden > 0 {
                    Text("+\(hidden) more")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(Color.white.opacity(0.4))
                        .padding(.leading, 23)
                }
            }
            Spacer(minLength: 0)
        }
    }
}

private struct TaskRow: View {
    let item: TodoItem

    var body: some View {
        Button(intent: ToggleTaskIntent(taskID: item.id)) {
            HStack(spacing: 8) {
                Image(systemName: item.isDone ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 15))
                    .foregroundStyle(item.isDone ? Theme.mintSolid : Color.white.opacity(0.45))
                Text(item.title)
                    .font(.system(size: 13, weight: .medium))
                    .strikethrough(item.isDone)
                    .foregroundStyle(Color.white.opacity(item.isDone ? 0.35 : 0.92))
                    .lineLimit(1)
                Spacer(minLength: 0)
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
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

private struct ClearView: View {
    @Environment(\.widgetFamily) private var family
    let entry: ChecklistEntry

    private static let clock: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter
    }()

    private var timeSize: CGFloat {
        switch family {
        case .systemSmall: return 46
        case .systemMedium: return 68
        default: return 92
        }
    }

    private var headline: String {
        entry.items.isEmpty ? "Nothing on the list" : "All \(entry.items.count) done"
    }

    private var subline: String {
        entry.items.isEmpty ? "Tap + to plan your day" : "Enjoy the quiet"
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text("TODAY")
                    .font(.system(size: 10, weight: .semibold))
                    .tracking(1)
                    .foregroundStyle(Color.white.opacity(0.6))
                Spacer()
                AddLink()
            }

            Spacer(minLength: 0)

            Text(Self.clock.string(from: entry.date))
                .font(.system(size: timeSize, weight: .ultraLight))
                .monospacedDigit()
                .lineLimit(1)
                .minimumScaleFactor(0.5)
                .foregroundStyle(Theme.amber)
                .shadow(color: Theme.ember.opacity(0.55), radius: 14)

            Text(headline)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(.white)
            Text(subline)
                .font(.system(size: 11))
                .foregroundStyle(Color.white.opacity(0.6))

            Spacer(minLength: 0)

            DayDashes(date: entry.date)
        }
    }
}

/// 24 dashes, one per hour, lit up to the current hour.
private struct DayDashes: View {
    let date: Date

    var body: some View {
        let startOfDay = Calendar.current.startOfDay(for: date)
        let fraction = date.timeIntervalSince(startOfDay) / 86_400
        let lit = Int(fraction * 24)

        HStack(spacing: 2.5) {
            ForEach(0..<24, id: \.self) { hour in
                Capsule()
                    .fill(hour < lit ? Theme.ember : Color.white.opacity(0.22))
                    .frame(height: 4)
            }
        }
        .padding(.horizontal, 2)
    }
}

// MARK: - Previews

extension TodoItem {
    static let samples: [TodoItem] = [
        TodoItem(title: "Ship the prototype v2.0", isDone: true),
        TodoItem(title: "Reply to Olivia"),
        TodoItem(title: "Review the project brief"),
        TodoItem(title: "Book flights to LAX"),
        TodoItem(title: "30 min workout"),
    ]
}

#Preview("Tasks", as: .systemMedium) {
    ChecklistWidget()
} timeline: {
    ChecklistEntry(date: .now, items: TodoItem.samples)
}

#Preview("Empty", as: .systemSmall) {
    ChecklistWidget()
} timeline: {
    ChecklistEntry(date: .now, items: [])
}
