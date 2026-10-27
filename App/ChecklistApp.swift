import AppKit
import SwiftUI

final class AppDelegate: NSObject, NSApplicationDelegate {
    // Closing the window quits, so tapping + on the widget always relaunches it.
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool { true }
}

@main
struct ChecklistApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var delegate
    @StateObject private var model = TodoModel()

    var body: some Scene {
        Window("Checklist", id: "main") {
            ContentView()
                .environmentObject(model)
                .frame(minWidth: 340, minHeight: 440)
                .preferredColorScheme(.dark)
                .onOpenURL { _ in
                    // checklist://add, from the + button on the widget.
                    model.focusTick += 1
                    NSApp.activate()
                }
        }
        .defaultSize(width: 380, height: 520)
    }
}

@MainActor
final class TodoModel: ObservableObject {
    @Published var items: [TodoItem] = []
    @Published var focusTick = 0

    private var timer: Timer?

    init() {
        reload()
        // Picks up check-offs made on the widget.
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            Task { @MainActor in self?.reload() }
        }
    }

    func reload() {
        let loaded = TodoStore.load()
        if loaded != items { items = loaded }
    }

    func add(_ text: String) {
        TodoStore.add(lines: text)
        reload()
    }

    func toggle(_ item: TodoItem) {
        TodoStore.toggle(item.id)
        reload()
    }

    func delete(_ item: TodoItem) {
        TodoStore.delete(item.id)
        reload()
    }

    func clearCompleted() {
        TodoStore.clearCompleted()
        reload()
    }
}
