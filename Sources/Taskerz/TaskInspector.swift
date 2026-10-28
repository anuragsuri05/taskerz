import SwiftUI

struct TaskInspector: View {
    let taskID: UUID
    let onClose: () -> Void

    @EnvironmentObject private var store: TaskStore
    @State private var newTag = ""
    @State private var confirmDelete = false

    private var task: Binding<TaskItem> {
        Binding(
            get: { store.task(taskID) ?? TaskItem(title: "", listID: UUID()) },
            set: { store.update($0) }
        )
    }

    private var dueDate: Binding<Date> {
        Binding(
            get: { task.wrappedValue.dueDate ?? Calendar.current.startOfDay(for: .now) },
            set: { task.wrappedValue.dueDate = $0 }
        )
    }

    private var hasDueDate: Binding<Bool> {
        Binding(
            get: { task.wrappedValue.dueDate != nil },
            set: { on in
                withAnimation(.snappy) {
                    task.wrappedValue.dueDate = on ? Calendar.current.startOfDay(for: .now) : nil
                    if !on { task.wrappedValue.hasDueTime = false }
                }
            }
        )
    }

    private var hasDueTime: Binding<Bool> {
        Binding(
            get: { task.wrappedValue.hasDueTime },
            set: { on in
                withAnimation(.snappy) {
                    var t = task.wrappedValue
                    t.hasDueTime = on
                    if on, let due = t.dueDate, Calendar.current.component(.hour, from: due) == 0 {
                        t.dueDate = Calendar.current.date(bySettingHour: 9, minute: 0, second: 0, of: due)
                    }
                    if !on, let due = t.dueDate { t.dueDate = Calendar.current.startOfDay(for: due) }
                    task.wrappedValue = t
                }
            }
        )
    }

    var body: some View {
        Form {
            Section {
                TextField("Title", text: task.title, axis: .vertical)
                    .font(.system(size: 16, weight: .semibold))
                    .textFieldStyle(.plain)
                    .lineLimit(1...4)
                TextField("Notes", text: task.notes, axis: .vertical)
                    .textFieldStyle(.plain)
                    .foregroundStyle(.secondary)
                    .lineLimit(3...10)
            }

            Section("Status") {
                Picker("Status", selection: task.status) {
                    ForEach(TaskStatus.allCases) { s in
                        Text(s.title).tag(s)
                    }
                }
                .pickerStyle(.segmented)
                .labelsHidden()
            }

            Section("Schedule") {
                Toggle(isOn: hasDueDate) {
                    Label("Due Date", systemImage: "calendar")
                }
                if task.wrappedValue.dueDate != nil {
                    DatePicker("Date", selection: dueDate,
                               displayedComponents: task.wrappedValue.hasDueTime ? [.date, .hourAndMinute] : [.date])
                    Toggle(isOn: hasDueTime) {
                        Label("Time", systemImage: "clock")
                    }
                }
            }

            Section("Organize") {
                Picker(selection: task.priority) {
                    ForEach(Priority.allCases) { p in
                        Text(p == .none ? "None" : "\(p.title)  \(p.marks)").tag(p)
                    }
                } label: {
                    Label("Priority", systemImage: "exclamationmark.circle")
                }

                Picker(selection: task.listID) {
                    ForEach(store.lists) { list in
                        Text(list.name).tag(list.id)
                    }
                } label: {
                    Label("List", systemImage: "list.bullet")
                }
            }

            Section("Tags") {
                if !task.wrappedValue.tags.isEmpty {
                    FlowLayout(spacing: 6) {
                        ForEach(task.wrappedValue.tags, id: \.self) { tag in
                            HStack(spacing: 4) {
                                Text("#\(tag)")
                                Button {
                                    task.wrappedValue.tags.removeAll { $0 == tag }
                                } label: {
                                    Image(systemName: "xmark.circle.fill")
                                }
                                .buttonStyle(.plain)
                                .foregroundStyle(Color.accentColor.opacity(0.7))
                            }
                            .font(.system(size: 12, weight: .medium))
                            .foregroundStyle(Color.accentColor)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(Capsule().fill(Color.accentColor.opacity(0.12)))
                        }
                    }
                    .padding(.vertical, 2)
                }
                TextField("Add Tag", text: $newTag)
                    .textFieldStyle(.plain)
                    .onSubmit(addTag)
                let suggestions = store.allTags.filter { !task.wrappedValue.tags.contains($0) }.prefix(8)
                if !suggestions.isEmpty {
                    FlowLayout(spacing: 6) {
                        ForEach(Array(suggestions), id: \.self) { tag in
                            Button("#\(tag)") { task.wrappedValue.tags.append(tag) }
                                .buttonStyle(.plain)
                                .font(.system(size: 11.5))
                                .foregroundStyle(.secondary)
                                .padding(.horizontal, 7)
                                .padding(.vertical, 2)
                                .background(Capsule().strokeBorder(Color.secondary.opacity(0.3)))
                        }
                    }
                }
            }

            Section {
                LabeledContent("Created", value: task.wrappedValue.createdAt.formatted(date: .abbreviated, time: .shortened))
                LabeledContent("Updated", value: task.wrappedValue.updatedAt.formatted(.relative(presentation: .named)))
                if let done = task.wrappedValue.completedAt {
                    LabeledContent("Completed", value: done.formatted(date: .abbreviated, time: .shortened))
                }
            }
            .font(.system(size: 12))
            .foregroundStyle(.secondary)

            Section {
                Button(role: .destructive) {
                    confirmDelete = true
                } label: {
                    Label("Delete Task", systemImage: "trash")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderless)
                .foregroundStyle(.red)
            }
        }
        .formStyle(.grouped)
        .confirmationDialog("Delete this task?", isPresented: $confirmDelete) {
            Button("Delete", role: .destructive) {
                store.delete([taskID])
                onClose()
            }
        }
    }

    private func addTag() {
        let tags = TaskStore.normalized(newTag.split(separator: " ").map(String.init))
        task.wrappedValue.tags.append(contentsOf: tags.filter { !task.wrappedValue.tags.contains($0) })
        newTag = ""
    }
}
