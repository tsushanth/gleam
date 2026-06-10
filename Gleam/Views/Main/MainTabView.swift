import SwiftUI
import SwiftData

struct MainTabView: View {
    @ObservedObject private var router = AppRouter.shared
    @Query(sort: \CleaningTask.createdAt) private var allTasks: [CleaningTask]

    private var urgentCount: Int {
        allTasks.filter { $0.isActive && $0.dirtinessLevel == .urgent }.count
    }

    var body: some View {
        TabView(selection: $router.selectedTab) {
            DashboardView()
                .tabItem { Label("Home", systemImage: "house.fill") }
                .tag(0)

            RoomsView()
                .tabItem { Label("Rooms", systemImage: "square.grid.2x2") }
                .tag(1)

            TasksView()
                .tabItem { Label("Tasks", systemImage: "checkmark.circle") }
                .badge(urgentCount > 0 ? urgentCount : 0)
                .tag(2)

            GleamProgressView()
                .tabItem { Label("Progress", systemImage: "chart.bar") }
                .tag(3)

            SettingsView()
                .tabItem { Label("Settings", systemImage: "gearshape") }
                .tag(4)
        }
        .sheet(isPresented: $router.showPaywall) {
            PaywallView(trigger: router.paywallTrigger)
        }
    }
}
