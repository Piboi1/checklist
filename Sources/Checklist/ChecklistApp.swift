import SwiftUI

@main
struct ChecklistApp: App {
    @StateObject private var model = TodoModel()

    var body: some Scene {
        MenuBarExtra {
            PopoverView()
                .environmentObject(model)
        } label: {
            Image(systemName: model.remaining == 0 ? "checkmark.circle" : "checklist")
            if model.remaining > 0 {
                Text("\(model.remaining)")
            }
        }
        .menuBarExtraStyle(.window)
    }
}

@MainActor
final class TodoModel: ObservableObject {
    @Published private(set) var items: [TodoItem] = []

    init() {
        items = TodoStore.load()
    }

    var doneCount: Int { items.filter(\.isDone).count }
    var remaining: Int { items.count - doneCount }
    var isClear: Bool { items.isEmpty || remaining == 0 }

    /// Re-reads the file, which also drops yesterday's finished tasks after midnight.
    func refresh() {
        items = TodoStore.load()
    }

    func add(_ text: String) {
        let new = TodoStore.parse(lines: text)
        guard !new.isEmpty else { return }
        items.append(contentsOf: new)
        TodoStore.save(items)
    }

    func toggle(_ item: TodoItem) {
        guard let i = items.firstIndex(where: { $0.id == item.id }) else { return }
        items[i].isDone.toggle()
        items[i].completedAt = items[i].isDone ? Date() : nil
        TodoStore.save(items)
    }

    func delete(_ item: TodoItem) {
        items.removeAll { $0.id == item.id }
        TodoStore.save(items)
    }

    func clearCompleted() {
        items.removeAll(where: \.isDone)
        TodoStore.save(items)
    }
}
