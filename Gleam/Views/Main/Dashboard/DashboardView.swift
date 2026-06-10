import SwiftUI
import SwiftData

struct DashboardView: View {
    @StateObject private var vm = DashboardViewModel()
    @Environment(\.modelContext) private var context
    @Query(sort: \CleaningTask.createdAt) private var allTasks: [CleaningTask]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    HomeHealthGaugeView(score: vm.homeScore)
                        .padding(.top, 8)

                    if !vm.urgentTasks.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Urgent Now")
                                .font(.headline)
                                .padding(.horizontal)

                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 12) {
                                    ForEach(vm.urgentTasks) { task in
                                        UrgentTaskCardView(task: task) {
                                            vm.completeTask(task, context: context)
                                        }
                                    }
                                }
                                .padding(.horizontal)
                            }
                        }
                    }

                    if !vm.todaysFocus.isEmpty {
                        taskSection(title: "Today's Focus", tasks: vm.todaysFocus)
                    }

                    if !vm.comingUp.isEmpty {
                        taskSection(title: "Coming Up", tasks: vm.comingUp)
                    }

                    if vm.urgentTasks.isEmpty && vm.todaysFocus.isEmpty {
                        EmptyStateView(
                            icon: "sparkles",
                            title: "Your home is gleaming!",
                            subtitle: "All tasks are up to date. Check back later."
                        )
                        .padding(.top, 40)
                    }

                    Spacer(minLength: 100)
                }
            }
            .refreshable {
                vm.loadDashboard(tasks: allTasks)
            }
            .navigationTitle("Home")
            .toolbar {
                ToolbarItem(placement: .bottomBar) {
                    QuickCompleteButtonView(urgentTasks: vm.urgentTasks) { task in
                        vm.completeTask(task, context: context)
                    }
                }
            }
            .onChange(of: allTasks) { _, tasks in
                vm.loadDashboard(tasks: tasks)
            }
            .onAppear {
                vm.loadDashboard(tasks: allTasks)
            }
        }
        .overlay {
            if vm.showCompletionAnimation {
                CompletionAnimationView(taskName: vm.lastCompletedTaskName) {
                    vm.showCompletionAnimation = false
                }
            }
        }
    }

    private func taskSection(title: String, tasks: [CleaningTask]) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.headline)
                .padding(.horizontal)

            ForEach(tasks) { task in
                TaskRowView(task: task) {
                    vm.completeTask(task, context: context)
                }
                .padding(.horizontal)
            }
        }
    }
}
