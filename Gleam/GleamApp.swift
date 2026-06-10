import SwiftUI
import SwiftData
import FirebaseCore

@main
struct GleamApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    @StateObject private var subscriptionVM = SubscriptionViewModel()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .modelContainer(gleamModelContainer)
                .environmentObject(subscriptionVM)
        }
    }
}

private let gleamModelContainer: ModelContainer = {
    let schema = Schema([
        Home.self,
        Room.self,
        CleaningTask.self,
        CompletionLog.self,
        HouseholdMember.self
    ])
    let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
    do {
        return try ModelContainer(for: schema, configurations: config)
    } catch {
        fatalError("Failed to create ModelContainer: \(error)")
    }
}()

final class AppDelegate: NSObject, UIApplicationDelegate {
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        FirebaseApp.configure()
        FirebaseAnalyticsService.shared.configure()
        // StoreKit 2 initialises lazily via StoreKitManager.shared (called from SubscriptionViewModel)
        return true
    }
}
