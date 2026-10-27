import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var model: TodoModel
    @State private var draft = ""
    @State private var bulkText = ""
    @State private var bulkMode = false
    @FocusState private var fieldFocused: Bool

    private var doneCount: Int { model.items.filter(\.isDone).count }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            header
            addArea
            taskList
            if doneCount > 0 {
                Button("Clear completed") { model.clearCompleted() }
                    .buttonStyle(.plain)
                    .font(.system(size: 12))
                    .foregroundStyle(Color.white.opacity(0.5))
            }
        }
        .padding(20)
        .background(Color(red: 0.043, green: 0.063, blue: 0.094))
        .onAppear { fieldFocused = true }
        .onChange(of: model.focusTick) { _, _ in
            bulkMode = false
            fieldFocused = true
        }
    }

    private var header: some View {
        HStack(alignment: .firstTextBaseline) {
            VStack(alignment: .leading, spacing: 2) {
                Text("TODAY")
                    .font(.system(size: 11, weight: .semibold))
                    .tracking(1.2)
                    .foregroundStyle(Color.white.opacity(0.5))
                Text(model.items.isEmpty ? "Nothing yet" : "\(doneCount)/\(model.items.count) done")
                    .font(.system(size: 24, weight: .semibold))
            }
            Spacer()
            Button {
                bulkMode.toggle()
            } label: {
                Image(systemName: bulkMode ? "text.cursor" : "text.append")
            }
            .buttonStyle(.plain)
            .help(bulkMode ? "Add one task at a time" : "Paste a whole list")
        }
    }

    @ViewBuilder
    private var addArea: some View {
        if bulkMode {
            VStack(alignment: .trailing, spacing: 8) {
                TextEditor(text: $bulkText)
                    .font(.system(size: 13))
                    .scrollContentBackground(.hidden)
                    .padding(8)
                    .frame(height: 120)
                    .background(RoundedRectangle(cornerRadius: 10).fill(Color.white.opacity(0.07)))
                Button("Add all (⌘↩)") {
                    model.add(bulkText)
                    bulkText = ""
                    bulkMode = false
                }
                .keyboardShortcut(.return, modifiers: .command)
                .disabled(bulkText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
        } else {
            TextField("Add a task, press return", text: $draft)
                .textFieldStyle(.plain)
                .font(.system(size: 14))
                .focused($fieldFocused)
                .padding(10)
                .background(RoundedRectangle(cornerRadius: 10).fill(Color.white.opacity(0.07)))
                .onSubmit {
                    model.add(draft)
                    draft = ""
                    fieldFocused = true
                }
        }
    }

    private var taskList: some View {
        List {
            ForEach(model.items.displayOrdered) { item in
                HStack(spacing: 10) {
                    Button { model.toggle(item) } label: {
                        Image(systemName: item.isDone ? "checkmark.circle.fill" : "circle")
                            .font(.system(size: 17))
                            .foregroundStyle(item.isDone ? Color(red: 0.49, green: 0.94, blue: 0.69) : Color.white.opacity(0.45))
                    }
                    .buttonStyle(.plain)

                    Text(item.title)
                        .strikethrough(item.isDone)
                        .foregroundStyle(Color.white.opacity(item.isDone ? 0.35 : 0.92))

                    Spacer()

                    Button { model.delete(item) } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundStyle(Color.white.opacity(0.3))
                    }
                    .buttonStyle(.plain)
                }
                .padding(.vertical, 4)
                .listRowSeparator(.hidden)
                .listRowBackground(Color.clear)
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
    }
}
