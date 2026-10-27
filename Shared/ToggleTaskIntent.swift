import AppIntents

/// Runs when a checkbox is tapped on the widget. Compiled into both targets
/// so the widget can reference it.
struct ToggleTaskIntent: AppIntent {
    static let title: LocalizedStringResource = "Toggle Task"

    @Parameter(title: "Task ID")
    var taskID: String

    init() {}

    init(taskID: UUID) {
        self.taskID = taskID.uuidString
    }

    func perform() async throws -> some IntentResult {
        if let id = UUID(uuidString: taskID) {
            TodoStore.toggle(id)
        }
        return .result()
    }
}
