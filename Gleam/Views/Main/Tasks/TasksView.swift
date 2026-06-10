import SwiftUI
import SwiftData

struct TasksView: View {
    @State private var searchText = ""
    @State private var sortOrder = SortOrder.urgency
    @Query(sort: \CleaningTask.createdAt) private var allTasks: [CleaningTask]
    @Environment(\.modelContext) private var context

    enum SortOrder: String, CaseIterable, Identifiable {
        case urgency = "Urgency"
        case room = "Room"
        case name = "Name"
        var id: String { rawValue }
    }

    private var filteredTasks: [CleaningTask] {
        let active = allTasks.filter(\.isActive)
        let searched: [CleaningTask]

        if searchText.isEmpty {
            searched = active
        } else {
            searched = active.filter { task in
                task.name.localizedCaseInsensitiveContains(searchText) ||
                (task.notes?.localizedCaseInsensitiveContains(searchText) ?? false) ||
                (task.room?.name.localizedCaseInsensitiveContains(searchText) ?? false)
            }
        }

        switch sortOrder {
        case .urgency:
            return searched.sorted { $0.dirtinessScore > $1.dirtinessScore }
        case .room:
            return searched.sorted { ($0.room?.name ?? "") < ($1.room?.name ?? "") }
        case .name:
            return searched.sorted { $0.name < $1.name }
        }
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                SearchBarView(text: $searchText, placeholder: "Search tasks")
                    .padding(.horizontal)
                    .padding(.vertical, 8)
                    .onChange(of: searchText) { _, query in
                        if !query.isEmpty {
                            FirebaseAnalyticsService.shared.log(.searchUsed(query: query))
                        }
                    }

                Picker("Sort by", selection: $sortOrder) {
                    ForEach(SortOrder.allCases) { order in
                        Text(order.rawValue).tag(order)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)
                .padding(.bottom, 8)

                if filteredTasks.isEmpty {
                    Spacer()
                    if searchText.isEmpty {
                        EmptyStateView(
                            icon: "checkmark.circle",
                            title: "No tasks yet",
                            subtitle: "Add rooms and tasks to start tracking your home's cleanliness."
                        )
                    } else {
                        EmptyStateView(
                            icon: "magnifyingglass",
                            title: "No results",
                            subtitle: "Try searching for a different task or room name."
                        )
                    }
                    Spacer()
                } else {
                    List {
                        ForEach(filteredTasks) { task in
                            TaskRowView(task: task) {
                                completeTask(task)
                            }
                            .listRowInsets(EdgeInsets(top: 4, leading: 16, bottom: 4, trailing: 16))
                            .listRowBackground(Color.clear)
                            .listRowSeparator(.hidden)
                        }
                    }
                    .listStyle(.plain)
                }
            }
            .navigationTitle("Tasks")
        }
    }

    private func completeTask(_ task: CleaningTask) {
        let userID = UserDefaults.standard.string(forKey: UserDefaultsKeys.currentUserID) ?? "local"
        let log = CompletionLog(completedByUserID: userID)
        task.completionLogs.append(log)
        task.lastCompletedAt = .now
        context.insert(log)
        HapticService.shared.trigger(.taskComplete)
        SoundService.shared.play(.completionChime)
        FirebaseAnalyticsService.shared.log(.taskCompleted(taskName: task.name))
        try? context.save()
    }
}
