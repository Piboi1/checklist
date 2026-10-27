import Foundation

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

/// The task list is a JSON file in ~/Library/Application Support/Checklist.
enum TodoStore {
    private static var fileURL: URL {
        let fm = FileManager.default
        let folder = fm.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("Checklist", isDirectory: true)
        try? fm.createDirectory(at: folder, withIntermediateDirectories: true)
        return folder.appendingPathComponent("tasks.json")
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

    static func save(_ items: [TodoItem]) {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        guard let data = try? encoder.encode(items) else { return }
        try? data.write(to: fileURL, options: .atomic)
    }

    /// One task per line. Leading bullets, numbers and `[ ]` boxes are stripped,
    /// so a list pasted from Notes or Markdown works as is.
    static func parse(lines text: String) -> [TodoItem] {
        let bullets = #"^\s*([-*•]\s+|\d+[.)]\s+|\[[ xX]?\]\s*)+"#
        return text
            .components(separatedBy: .newlines)
            .map { $0.replacingOccurrences(of: bullets, with: "", options: .regularExpression) }
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }
            .map { TodoItem(title: $0) }
    }
}
