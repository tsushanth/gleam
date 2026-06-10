import SwiftUI
import SwiftData

struct RoomDetailView: View {
    let room: Room
    @StateObject private var vm = RoomDetailViewModel()
    @Environment(\.modelContext) private var context

    var body: some View {
        Group {
            if vm.tasks.isEmpty {
                EmptyStateView(
                    icon: "checkmark.circle",
                    title: "No tasks yet",
                    subtitle: "Add tasks to track what needs cleaning in \(room.name).",
                    ctaTitle: "Add Task",
                    ctaAction: { vm.isAddingTask = true }
                )
            } else {
                List {
                    ForEach(vm.tasks) { task in
                        TaskRowView(task: task) {
                            vm.completeTask(task, context: context)
                        }
                        .listRowInsets(EdgeInsets(top: 4, leading: 16, bottom: 4, trailing: 16))
                        .listRowBackground(Color.clear)
                        .listRowSeparator(.hidden)
                    }
                    .onMove { source, dest in
                        vm.moveTask(from: source, to: dest, in: room, context: context)
                    }
                    .onDelete { indices in
                        for index in indices {
                            vm.deleteTask(vm.tasks[index], context: context)
                        }
                    }
                }
                .listStyle(.plain)
                .environment(\.editMode, .constant(.active))
            }
        }
        .navigationTitle(room.name)
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    vm.isAddingTask = true
                } label: {
                    Image(systemName: "plus")
                }
                .accessibilityLabel("Add task to \(room.name)")
            }
        }
        .sheet(isPresented: $vm.isAddingTask) {
            AddTaskView(room: room)
        }
        .onAppear { vm.loadTasks(from: room) }
        .onChange(of: room.tasks) { _, _ in vm.loadTasks(from: room) }
    }
}
