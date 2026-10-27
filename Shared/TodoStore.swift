import Foundation
import WidgetKit

struct TodoItem: Codable, Identifiable, Hashable {
    var id = UUID()
    var title: String
    var isDone = false
    var createdAt = Date()
    var completedAt: Date?
}

extension Array where Element == TodoItem {
    /// Open tasks first (in the order they were added), finished ones last.
    var displayOrdered: [TodoItem] {
        filter { !$0.isDone } + filter(\.isDone)
    }
}

/// Plain JSON file in the App Group container, so the app and the widget
/// extension read and write the same list.
enum TodoStore {
    static let widgetKind = "ChecklistWidget"

    private static var fileURL: URL {
        let fm = FileManager.default
        let base: URL
        if let group = Bundle.main.object(forInfoDictionaryKey: "AppGroupID") as? String,
           let container = fm.containerURL(forSecurityApplicationGroupIdentifier: group) {
            base = container
        } else {
            // Falls back to a per-process folder; the widget will not see this
            // list, so the App Group needs to be set up (see README).
            base = fm.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
                .appendingPathComponent("Checklist", isDirectory: true)
        }
        try? fm.createDirectory(at: base, withIntermediateDirectories: true)
        return base.appendingPathComponent("tasks.json")
    }

    static func load() -> [TodoItem] {
        guard let data = try? Data(contentsOf: fileURL) else { return [] }
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let items = (try? decoder.decode([TodoItem].self, from: data)) ?? []

        // New day: tasks finished before today drop off, unfinished ones carry over.
        let startOfToday = Calendar.current.startOfDay(for: Date())
        return items.filter { item in
            guard item.isDone, let completedAt = item.completedAt else { return true }
            return completedAt >= startOfToday
        }
    }

    private static func save(_ items: [TodoItem]) {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        guard let data = try? encoder.encode(items) else { return }
        try? data.write(to: fileURL, options: .atomic)
        WidgetCenter.shared.reloadTimelines(ofKind: widgetKind)
    }

    private static func mutate(_ body: (inout [TodoItem]) -> Void) {
        var items = load()
        body(&items)
        save(items)
    }

    /// One task per line. Leading bullets, numbers and `[ ]` boxes are stripped,
    /// so a list pasted from Notes or Markdown works as is.
    static func add(lines text: String) {
        let bullets = #"^\s*([-*•]\s+|\d+[.)]\s+|\[[ xX]?\]\s*)+"#
        let titles = text
            .components(separatedBy: .newlines)
            .map { $0.replacingOccurrences(of: bullets, with: "", options: .regularExpression) }
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }
        guard !titles.isEmpty else { return }
        mutate { $0.append(contentsOf: titles.map { TodoItem(title: $0) }) }
    }

    static func toggle(_ id: UUID) {
        mutate { items in
            guard let i = items.firstIndex(where: { $0.id == id }) else { return }
            items[i].isDone.toggle()
            items[i].completedAt = items[i].isDone ? Date() : nil
        }
    }

    static func delete(_ id: UUID) {
        mutate { $0.removeAll { $0.id == id } }
    }

    static func clearCompleted() {
        mutate { $0.removeAll(where: \.isDone) }
    }
}
