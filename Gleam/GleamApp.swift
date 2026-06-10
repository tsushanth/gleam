import SwiftUI
import SwiftData
import FirebaseCore
import FacebookCore

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
        // 1. Firebase — must be first so Analytics is ready before any event fires.
        FirebaseApp.configure()
        FirebaseAnalyticsService.shared.configure()

        // 2. Apple Search Ads attribution token — fetch before ATT prompt so the
        //    token is available regardless of the user's tracking decision.
        AttributionManager.shared.fetchToken()

        // 3. Facebook SDK — initialise before requesting ATT; the SDK will respect
        //    the user's subsequent choice via ATTService.
        ApplicationDelegate.shared.application(
            application,
            didFinishLaunchingWithOptions: launchOptions
        )

        // 4. ATT — request after the first frame renders (ATTService adds a 1 s
        //    delay internally). Facebook auto-event logging is toggled inside
        //    ATTService based on the authorisation result.
        Task {
            await ATTService.shared.requestPermission()
        }

        // StoreKit 2 initialises lazily via StoreKitManager.shared (called from SubscriptionViewModel).
        return true
    }

    // Forward URLs to the Facebook SDK for deep-link and deferred deep-link support.
    func application(
        _ app: UIApplication,
        open url: URL,
        options: [UIApplication.OpenURLOptionsKey: Any] = [:]
    ) -> Bool {
        ApplicationDelegate.shared.application(app, open: url, options: options)
    }
}
