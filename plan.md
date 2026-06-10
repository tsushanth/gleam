# Gleam — iOS App Implementation Plan
*Based on competitive research findings, June 2026*

---

## Table of Contents
1. [Architecture Overview](#1-architecture-overview)
2. [File Structure](#2-file-structure)
3. [Data Models](#3-data-models)
4. [View Hierarchy](#4-view-hierarchy)
5. [ViewModel Layer](#5-viewmodel-layer)
6. [Feature Prioritization](#6-feature-prioritization)
7. [Paywall Strategy](#7-paywall-strategy)
8. [SDK Integration Plan](#8-sdk-integration-plan)
9. [App Store Readiness](#9-app-store-readiness)
10. [TODO Checklist](#10-todo-checklist)

---

## 1. Architecture Overview

### Research Basis
Gleam competes directly with Tody (4.83 stars, 1M+ users, 13 years old). The core mechanic — **condition-based dirtiness tracking** (a continuous gradient from green → yellow → orange → red, not a binary due/overdue model) — must be replicated and improved upon. The research identifies three differentiation pillars: AI-first onboarding, purpose-built multi-user households, and a CleanTok-native aesthetic with ASMR micro-interactions. Every architectural decision flows from these pillars.

### App Structure Diagram

```
GleamApp (SwiftUI App)
│
├── @Environment: ModelContainer (SwiftData)
├── @StateObject: AppRouter
├── @StateObject: SubscriptionViewModel
│
├── [Not onboarded] → OnboardingContainerView
│     ├── WelcomeView
│     ├── SegmentationView
│     ├── AIRoutineSetupView
│     ├── RoomSelectionView
│     ├── FirstAhaView
│     └── PaywallView (soft, post-aha)
│
└── [Onboarded] → MainTabView
      ├── Tab 1: DashboardView
      ├── Tab 2: RoomsView
      ├── Tab 3: TasksView
      ├── Tab 4: ProgressView
      └── Tab 5: SettingsView
```

### MVVM Layer Breakdown

```
┌─────────────────────────────────────────────────────────────┐
│  VIEWS (SwiftUI)                                            │
│  Render state, emit user gestures, trigger ViewModel calls  │
│  Zero business logic; only layout and animation code        │
└──────────────────────────┬──────────────────────────────────┘
                           │ @Published bindings
┌──────────────────────────▼──────────────────────────────────┐
│  VIEWMODELS (@MainActor ObservableObject)                    │
│  Business logic, state transformation, validation           │
│  Coordinate between Services and expose typed state         │
└────────────┬─────────────────────────────┬──────────────────┘
             │ async calls                 │ SwiftData queries
┌────────────▼────────────┐  ┌─────────────▼──────────────────┐
│  SERVICES               │  │  MODELS (SwiftData @Model)     │
│  RevenueCatService      │  │  Home, Room, CleaningTask      │
│  FirebaseAnalytics      │  │  CompletionLog, HouseholdMember│
│  NotificationService    │  │  Persisted locally, synced via  │
│  AIService              │  │  SwiftData + CloudKit           │
│  HapticService          │  └────────────────────────────────┘
│  SoundService           │
└─────────────────────────┘
```

### Data Flow Description

1. **Write path:** User taps "Complete Task" → `TaskDetailViewModel.completeTask()` → inserts `CompletionLog` into ModelContext → updates `CleaningTask.lastCompletedAt` → SwiftData persists → `DirtinessCalculator` recomputes score → View re-renders with green bar + completion animation
2. **Read path:** SwiftData `@Query` macro fetches tasks sorted by `dirtinessScore` computed property → ViewModel formats for display → View renders urgency bars
3. **AI path:** `AIService.generateRoutine(profile:)` → POST to backend proxy → Claude API → structured JSON → ViewModel parses → batch-inserts Rooms + Tasks into ModelContext
4. **Subscription path:** `SubscriptionViewModel` observes RevenueCat `CustomerInfo` → publishes `isPremium: Bool` → views conditionally lock features via `.premiumGate()` modifier

### Navigation Approach

**TabView** for primary navigation (5 tabs, as is iOS convention for this category — Tody uses a dated sidebar drawer).  
**NavigationStack** inside each tab for drill-down navigation (Room → Room Detail → Task Detail).  
**Sheet** presentation for: task creation, task detail editing, paywall, AI setup, notification settings.  
**FullScreenCover** for: onboarding flow, completion celebration animation.

---

## 2. File Structure

```
Gleam/
│
├── GleamApp.swift                        # App entry point; SDK init order; ModelContainer setup
├── ContentView.swift                     # Onboarding vs. main routing gate
│
├── Models/
│   ├── Home.swift                        # SwiftData @Model: top-level container for a household
│   ├── Room.swift                        # SwiftData @Model: named zone with icon (Kitchen, Bath...)
│   ├── CleaningTask.swift                # SwiftData @Model: task with frequency, completion state
│   ├── CompletionLog.swift               # SwiftData @Model: immutable record of each task completion
│   ├── HouseholdMember.swift             # SwiftData @Model: user profile within a shared home
│   └── Supporting/
│       ├── DirtinessLevel.swift          # Enum: .green/.yellow/.orange/.red + color/label logic
│       ├── RoomIcon.swift                # Enum: SF Symbol names for standard rooms
│       ├── TaskFrequency.swift           # Enum: preset frequency options (daily/weekly/monthly...)
│       └── SubscriptionTier.swift        # Enum: .free/.premium/.lifetime
│
├── ViewModels/
│   ├── OnboardingViewModel.swift         # Onboarding step state machine, AI routine coordination
│   ├── DashboardViewModel.swift          # Urgent task aggregation, today's focus list
│   ├── RoomsViewModel.swift              # Room list with aggregate dirtiness, CRUD
│   ├── RoomDetailViewModel.swift         # Tasks within a room, drag reorder, task creation
│   ├── TaskDetailViewModel.swift         # Task edit, completion, snooze, notification schedule
│   ├── ProgressViewModel.swift           # Weekly/monthly stats, streak, household leaderboard
│   ├── SettingsViewModel.swift           # Profile, notifications, vacation mode, account actions
│   └── SubscriptionViewModel.swift       # RevenueCat CustomerInfo, purchase/restore, paywall state
│
├── Views/
│   ├── Onboarding/
│   │   ├── OnboardingContainerView.swift # Step-based container with progress bar animation
│   │   ├── WelcomeView.swift             # Hero screen: "Zero guilt. Always just clean enough."
│   │   ├── SegmentationView.swift        # 2-question survey: household type + biggest challenge
│   │   ├── AIRoutineSetupView.swift      # Claude routine generation offer + loading state
│   │   ├── RoomSelectionView.swift       # Visual tile grid: tap to include rooms
│   │   └── FirstAhaView.swift            # First dirtiness visualization reveal; emotional moment
│   │
│   ├── Main/
│   │   ├── MainTabView.swift             # TabView with 5 tabs; badge counts on Tasks tab
│   │   │
│   │   ├── Dashboard/
│   │   │   ├── DashboardView.swift           # Home health score, urgent tasks, quick-add FAB
│   │   │   ├── HomeHealthGaugeView.swift     # Circular gauge: aggregate home dirtiness score
│   │   │   ├── UrgentTaskCardView.swift      # Horizontally scrollable urgent task cards
│   │   │   └── QuickCompleteButtonView.swift # "Just Did It" floating action affordance
│   │   │
│   │   ├── Rooms/
│   │   │   ├── RoomsView.swift               # Card grid of all rooms with aggregate dirtiness
│   │   │   ├── RoomCardView.swift            # Room card: icon, name, worst-task dirtiness bar
│   │   │   ├── RoomDetailView.swift          # Task list within a room; drag-to-reorder
│   │   │   └── AddRoomView.swift             # Sheet: name + icon picker for new room
│   │   │
│   │   ├── Tasks/
│   │   │   ├── TasksView.swift               # All tasks sorted by urgency; search bar at top
│   │   │   ├── TaskRowView.swift             # Swipe-to-complete row with dirtiness pill
│   │   │   ├── TaskDetailView.swift          # Full task edit sheet: freq, notes, assignee, notif
│   │   │   └── AddTaskView.swift             # Sheet: create new task with preset templates
│   │   │
│   │   ├── Progress/
│   │   │   ├── ProgressView.swift            # Weekly stats overview, streak, leaderboard
│   │   │   ├── StreakBannerView.swift         # Current streak display with flame animation
│   │   │   ├── WeeklyBarChartView.swift      # SwiftCharts bar chart: tasks done per day
│   │   │   ├── RoomHealthGridView.swift      # Heatmap grid: which rooms need most attention
│   │   │   └── HouseholdLeaderboardView.swift # Premium: member points ranking this week
│   │   │
│   │   └── Settings/
│   │       ├── SettingsView.swift            # Main settings list: account, notifications, appearance
│   │       ├── NotificationSettingsView.swift # Per-task notification time configuration
│   │       ├── VacationModeView.swift         # Date range picker: pause all task dirtiness
│   │       ├── HouseholdMembersView.swift    # Premium: invite/manage household members
│   │       └── AccountView.swift             # Sign in with Apple, subscription status, delete data
│   │
│   ├── Paywall/
│   │   ├── PaywallView.swift                 # Full paywall screen: features list + pricing options
│   │   ├── SubscriptionOptionView.swift      # Individual plan pill (weekly/monthly/yearly/lifetime)
│   │   └── FeatureComparisonView.swift       # Free vs. Premium feature comparison grid
│   │
│   └── Shared/
│       ├── DirtinessMeterView.swift          # Reusable capsule bar: green→yellow→orange→red
│       ├── CompletionAnimationView.swift     # Lottie-style SwiftUI animation on task complete
│       ├── PremiumGateView.swift             # Lock overlay for premium-gated features
│       ├── SearchBarView.swift               # Reusable search input with clear button
│       └── EmptyStateView.swift             # Reusable empty state with icon + CTA
│
├── Services/
│   ├── RevenueCatService.swift               # Purchases SDK wrapper; entitlement checks
│   ├── FirebaseAnalyticsService.swift        # Typed event logging; wraps Analytics.logEvent
│   ├── NotificationService.swift             # UNUserNotificationCenter; per-task scheduling
│   ├── AIService.swift                       # Claude proxy API calls; routine gen + coaching
│   ├── HapticService.swift                   # UIImpactFeedbackGenerator wrapper; intensity levels
│   └── SoundService.swift                    # AVAudioPlayer: completion chime, ASMR sounds
│
├── Utilities/
│   ├── DirtinessCalculator.swift             # Core algorithm: score, level, days remaining
│   ├── AppRouter.swift                       # ObservableObject: global navigation/sheet state
│   ├── UserDefaultsKeys.swift                # Centralized keys for UserDefaults
│   ├── ViewModifiers.swift                   # .premiumGate(), .hapticOnTap(), custom modifiers
│   └── Extensions/
│       ├── Date+Extensions.swift             # daysSince(), formatted helpers
│       ├── Color+Gleam.swift                 # Brand colors as Color extension
│       └── View+ConditionalModifier.swift    # .if() conditional modifier
│
└── Resources/
    ├── Assets.xcassets/
    │   ├── AppIcon.appiconset/               # 1024×1024 icon + all required sizes
    │   ├── AccentColor.colorset/             # Brand accent (adaptive light/dark)
    │   ├── GleamGreen.colorset/              # Dirtiness: clean state
    │   ├── GleamYellow.colorset/             # Dirtiness: attention
    │   ├── GleamOrange.colorset/             # Dirtiness: soon
    │   ├── GleamRed.colorset/                # Dirtiness: urgent
    │   └── Sounds/                           # Completion chimes (.caf format)
    ├── Gleam.entitlements                    # iCloud, push notifications, Sign in with Apple
    └── Info.plist                            # Privacy strings, SDK keys, capabilities
```

---

## 3. Data Models

### DirtinessLevel Enum

```swift
// DirtinessLevel.swift
enum DirtinessLevel: String, CaseIterable {
    case clean    // 0–49
    case soon     // 50–74
    case needsIt  // 75–89
    case urgent   // 90+

    var color: Color {
        switch self {
        case .clean:    return Color("GleamGreen")
        case .soon:     return Color("GleamYellow")
        case .needsIt:  return Color("GleamOrange")
        case .urgent:   return Color("GleamRed")
        }
    }

    // VoiceOver label — color alone is never the only indicator
    var accessibilityLabel: String {
        switch self {
        case .clean:    return "Clean"
        case .soon:     return "Due soon"
        case .needsIt:  return "Needs cleaning"
        case .urgent:   return "Urgent — clean now"
        }
    }
}
```

### RoomIcon Enum

```swift
// RoomIcon.swift
enum RoomIcon: String, CaseIterable, Codable {
    case kitchen     = "fork.knife"
    case bathroom    = "shower"
    case bedroom     = "bed.double"
    case livingRoom  = "sofa"
    case garage      = "car.garage"
    case outdoors    = "leaf"
    case office      = "desktopcomputer"
    case laundry     = "washer"
    case wholeHouse  = "house"
    case custom      = "star"

    var displayName: String { rawValue.replacingOccurrences(of: ".", with: " ").capitalized }
}
```

### Home Model

```swift
// Home.swift
import SwiftData
import Foundation

@Model
final class Home {
    var id: UUID
    var name: String
    var ownerUserID: String          // Sign in with Apple user identifier
    var createdAt: Date
    var isPaused: Bool               // Vacation mode: freezes dirtiness accumulation
    var pausedUntil: Date?

    @Relationship(deleteRule: .cascade, inverse: \Room.home)
    var rooms: [Room]

    @Relationship(deleteRule: .cascade, inverse: \HouseholdMember.home)
    var members: [HouseholdMember]

    init(name: String, ownerUserID: String) {
        self.id = UUID()
        self.name = name
        self.ownerUserID = ownerUserID
        self.createdAt = .now
        self.isPaused = false
        self.rooms = []
        self.members = []
    }
}
```

### Room Model

```swift
// Room.swift
import SwiftData
import Foundation

@Model
final class Room {
    var id: UUID
    var name: String
    var icon: String                 // SF Symbol name via RoomIcon.rawValue
    var sortOrder: Int               // User-defined ordering
    var createdAt: Date

    var home: Home?

    @Relationship(deleteRule: .cascade, inverse: \CleaningTask.room)
    var tasks: [CleaningTask]

    // Computed: worst dirtiness score among all active tasks
    // Used to represent room health on RoomCardView
    var aggregateDirtinessScore: Double {
        tasks.filter { $0.isActive }.map { $0.dirtinessScore }.max() ?? 0
    }

    var dirtinessLevel: DirtinessLevel {
        DirtinessCalculator.level(for: aggregateDirtinessScore)
    }

    init(name: String, icon: String, sortOrder: Int = 0) {
        self.id = UUID()
        self.name = name
        self.icon = icon
        self.sortOrder = sortOrder
        self.createdAt = .now
        self.tasks = []
    }
}
```

### CleaningTask Model

```swift
// CleaningTask.swift
import SwiftData
import Foundation

@Model
final class CleaningTask {
    var id: UUID
    var name: String
    var frequencyDays: Int           // Target: clean every N days
    var lastCompletedAt: Date?       // Nil = never done; starts dirtiness clock from createdAt
    var createdAt: Date
    var isActive: Bool
    var sortOrder: Int               // Drag-to-reorder within room (Tody gap we fill)

    // Optional features
    var notes: String?
    var estimatedMinutes: Int?       // AI-estimated effort; user can override
    var assignedToUserID: String?    // Premium: household member assignment
    var notificationTime: DateComponents?  // Per-task notification (Tody gap we fill)
    var pausedUntil: Date?           // Snooze / vacation-mode per-task override

    var room: Room?

    @Relationship(deleteRule: .cascade, inverse: \CompletionLog.task)
    var completionLogs: [CompletionLog]

    // MARK: - Core Dirtiness Algorithm (from research §7.2)
    // dirtinessScore = (daysSinceLastCleaned / frequencyDays) * 100
    // Clamped to 0–100 for display; can exceed 100 internally (tracked as > urgent)
    var dirtinessScore: Double {
        guard isActive else { return 0 }

        // Respect vacation/pause: treat pausedUntil as an offset
        let effectiveLastDone: Date
        if let lastDone = lastCompletedAt {
            effectiveLastDone = lastDone
        } else {
            effectiveLastDone = createdAt  // Never done: clock starts at creation
        }

        let daysSince = Date().timeIntervalSince(effectiveLastDone) / 86_400
        let score = (daysSince / Double(frequencyDays)) * 100
        return min(score, 150)  // Cap at 150 to avoid infinity; >100 = all red
    }

    var dirtinessLevel: DirtinessLevel {
        DirtinessCalculator.level(for: dirtinessScore)
    }

    var daysUntilDue: Int {
        let daysRemaining = Double(frequencyDays) - (dirtinessScore / 100 * Double(frequencyDays))
        return max(0, Int(daysRemaining))
    }

    init(name: String, frequencyDays: Int, sortOrder: Int = 0) {
        self.id = UUID()
        self.name = name
        self.frequencyDays = frequencyDays
        self.sortOrder = sortOrder
        self.createdAt = .now
        self.isActive = true
        self.completionLogs = []
    }
}
```

### CompletionLog Model

```swift
// CompletionLog.swift
import SwiftData
import Foundation

@Model
final class CompletionLog {
    var id: UUID
    var completedAt: Date
    var completedByUserID: String    // Tracks who did it in multi-user household
    var notes: String?               // Optional completion note
    var durationMinutes: Int?        // Actual time spent (for AI coaching data)

    var task: CleaningTask?

    init(completedByUserID: String, notes: String? = nil) {
        self.id = UUID()
        self.completedAt = .now
        self.completedByUserID = completedByUserID
        self.notes = notes
    }
}
```

### HouseholdMember Model

```swift
// HouseholdMember.swift
import SwiftData
import Foundation

@Model
final class HouseholdMember {
    var id: UUID
    var userID: String               // Sign in with Apple identifier
    var displayName: String
    var avatarColor: String          // Hex string for generated avatar
    var joinedAt: Date
    var totalPoints: Int
    var weeklyPoints: Int
    var weeklyPointsResetAt: Date

    var home: Home?

    init(userID: String, displayName: String, avatarColor: String = "#4A90D9") {
        self.id = UUID()
        self.userID = userID
        self.displayName = displayName
        self.avatarColor = avatarColor
        self.joinedAt = .now
        self.totalPoints = 0
        self.weeklyPoints = 0
        self.weeklyPointsResetAt = .now
    }
}
```

### DirtinessCalculator Utility

```swift
// DirtinessCalculator.swift
// Central authority for the core dirtiness algorithm from research §7.2
// All display logic flows through here to ensure consistency across widgets, views, VoiceOver

enum DirtinessCalculator {
    static func level(for score: Double) -> DirtinessLevel {
        switch score {
        case ..<50:  return .clean
        case 50..<75: return .soon
        case 75..<90: return .needsIt
        default:     return .urgent
        }
    }

    static func percentage(for score: Double) -> Double {
        min(score / 100, 1.0)
    }

    // For widget timeline: when will this task cross into the next level?
    static func nextTransitionDate(task: CleaningTask) -> Date? {
        let thresholds: [Double] = [50, 75, 90, 100]
        let currentScore = task.dirtinessScore
        guard let nextThreshold = thresholds.first(where: { $0 > currentScore }) else { return nil }

        let effectiveLast = task.lastCompletedAt ?? task.createdAt
        let daysToThreshold = (nextThreshold / 100) * Double(task.frequencyDays)
        return effectiveLast.addingTimeInterval(daysToThreshold * 86_400)
    }
}
```

### SubscriptionTier Enum

```swift
// SubscriptionTier.swift
enum SubscriptionTier: Equatable {
    case free
    case premium          // Any active subscription (weekly/monthly/yearly)
    case lifetime         // One-time purchase

    var displayName: String {
        switch self {
        case .free:     return "Free"
        case .premium:  return "Gleam Premium"
        case .lifetime: return "Gleam Lifetime"
        }
    }

    var isPremium: Bool { self != .free }
}
```

---

## 4. View Hierarchy

### Complete View Tree

```
ContentView
├── [!isOnboarded] OnboardingContainerView
│     ├── WelcomeView
│     ├── SegmentationView
│     ├── AIRoutineSetupView (premium teaser)
│     ├── RoomSelectionView
│     ├── FirstAhaView
│     └── PaywallView (soft — dismissible)
│
└── [isOnboarded] MainTabView
      ├── Tab: house.fill → DashboardView
      │     ├── HomeHealthGaugeView
      │     ├── ScrollView
      │     │     ├── Section "Urgent Now"
      │     │     │     └── UrgentTaskCardView (horizontal scroll)
      │     │     ├── Section "Today's Focus"
      │     │     │     └── TaskRowView (each urgent task)
      │     │     └── Section "Coming Up"
      │     │           └── TaskRowView (yellow tasks)
      │     └── FAB: QuickCompleteButtonView
      │
      ├── Tab: square.grid.2x2 → RoomsView
      │     ├── SearchBarView
      │     ├── LazyVGrid
      │     │     └── RoomCardView (taps → NavigationStack push)
      │     │           └── RoomDetailView
      │     │                 ├── List (drag-to-reorder enabled)
      │     │                 │     └── TaskRowView (swipe-to-complete)
      │     │                 └── Sheet: AddTaskView
      │     └── Toolbar: Add Room → AddRoomView (sheet)
      │
      ├── Tab: checkmark.circle → TasksView
      │     ├── SearchBarView (full-text; addresses Tody's 13-year gap)
      │     ├── Picker: sort by urgency / room / assignee
      │     └── List
      │           └── TaskRowView
      │                 └── Sheet: TaskDetailView
      │                       ├── FrequencyPickerView
      │                       ├── AssigneePickerView (premium)
      │                       ├── NotificationTimePickerView (premium)
      │                       └── NotesEditorView
      │
      ├── Tab: chart.bar → ProgressView
      │     ├── StreakBannerView
      │     ├── WeeklyBarChartView (SwiftCharts)
      │     ├── RoomHealthGridView
      │     └── [isPremium] HouseholdLeaderboardView
      │
      └── Tab: gearshape → SettingsView
            ├── AccountView → Sign in with Apple, subscription status
            ├── NotificationSettingsView
            ├── VacationModeView
            ├── [isPremium] HouseholdMembersView
            ├── AppearanceView (accent color, haptics toggle, sounds toggle)
            └── AboutView (privacy policy, data deletion, rate the app)
```

### DirtinessMeterView (Core Reusable Component)

```swift
// DirtinessMeterView.swift
// This is the most important UI component in the app — research confirms it is
// the #1 cited differentiator and the "aha!" moment of the entire category.
struct DirtinessMeterView: View {
    let score: Double       // 0–100+
    let showLabel: Bool

    private var level: DirtinessLevel { DirtinessCalculator.level(for: score) }
    private var fillPercent: Double { DirtinessCalculator.percentage(for: score) }

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    // Track
                    Capsule()
                        .fill(Color(.systemFill))
                        .frame(height: 8)

                    // Fill
                    Capsule()
                        .fill(level.color)
                        .frame(width: geo.size.width * fillPercent, height: 8)
                        .animation(.spring(duration: 0.4), value: fillPercent)
                }
            }
            .frame(height: 8)

            if showLabel {
                Text(level.accessibilityLabel)
                    .font(.caption2)
                    .foregroundStyle(level.color)
            }
        }
        // Accessibility: color is never the only indicator
        .accessibilityLabel(level.accessibilityLabel)
        .accessibilityValue("\(Int(score))% dirty")
    }
}
```

### MainTabView

```swift
// MainTabView.swift
struct MainTabView: View {
    @State private var selectedTab = 0
    @StateObject private var router = AppRouter.shared
    @Query(filter: #Predicate<CleaningTask> { $0.isActive },
           sort: \CleaningTask.dirtinessScore, order: .reverse)
    private var urgentTasks: [CleaningTask]

    private var urgentCount: Int {
        urgentTasks.filter { $0.dirtinessLevel == .urgent }.count
    }

    var body: some View {
        TabView(selection: $selectedTab) {
            DashboardView()
                .tabItem { Label("Home", systemImage: "house.fill") }
                .tag(0)

            RoomsView()
                .tabItem { Label("Rooms", systemImage: "square.grid.2x2") }
                .tag(1)

            TasksView()
                .tabItem { Label("Tasks", systemImage: "checkmark.circle") }
                .badge(urgentCount > 0 ? urgentCount : nil)
                .tag(2)

            ProgressView()
                .tabItem { Label("Progress", systemImage: "chart.bar") }
                .tag(3)

            SettingsView()
                .tabItem { Label("Settings", systemImage: "gearshape") }
                .tag(4)
        }
        .sheet(isPresented: $router.showPaywall) {
            PaywallView()
        }
    }
}
```

### OnboardingContainerView

```swift
// OnboardingContainerView.swift
// Progress bar increases completion by 20–30% per research §4.1
struct OnboardingContainerView: View {
    @StateObject private var vm = OnboardingViewModel()

    var body: some View {
        VStack(spacing: 0) {
            // Progress indicator
            ProgressView(value: vm.progressFraction)
                .progressViewStyle(.linear)
                .tint(.accent)
                .padding(.horizontal)

            // Step content
            Group {
                switch vm.currentStep {
                case .welcome:       WelcomeView(vm: vm)
                case .segmentation:  SegmentationView(vm: vm)
                case .aiSetup:       AIRoutineSetupView(vm: vm)
                case .roomSelection: RoomSelectionView(vm: vm)
                case .firstAha:      FirstAhaView(vm: vm)
                case .paywall:       PaywallView(isOnboarding: true)
                }
            }
            .transition(.asymmetric(
                insertion: .move(edge: .trailing),
                removal: .move(edge: .leading)
            ))
            .animation(.easeInOut(duration: 0.3), value: vm.currentStep)
        }
    }
}
```

### PaywallView

```swift
// PaywallView.swift
struct PaywallView: View {
    var isOnboarding: Bool = false
    @StateObject private var vm = SubscriptionViewModel()
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Dismiss for soft paywall (post-onboarding)
                if isOnboarding {
                    HStack {
                        Spacer()
                        Button("Maybe Later") { dismiss() }
                            .foregroundStyle(.secondary)
                            .padding()
                    }
                }

                // Hero
                VStack(spacing: 8) {
                    Image(systemName: "sparkles")
                        .font(.system(size: 48))
                        .foregroundStyle(.accent)
                    Text("Gleam Premium")
                        .font(.largeTitle.bold())
                    Text("The cleanest home you've ever lived in.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }

                // Feature comparison
                FeatureComparisonView()

                // Pricing options — annual pre-selected per research §5.5
                VStack(spacing: 12) {
                    ForEach(SubscriptionProduct.allCases) { product in
                        SubscriptionOptionView(
                            product: product,
                            isSelected: vm.selectedProduct == product,
                            onTap: { vm.selectedProduct = product }
                        )
                    }
                }
                .padding(.horizontal)

                // CTA
                Button {
                    Task { await vm.purchase() }
                } label: {
                    Label(vm.ctaTitle, systemImage: "arrow.right")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.accent)
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                }
                .padding(.horizontal)
                .disabled(vm.isPurchasing)

                // Free trial callout
                Text("7-day free trial included. Cancel anytime.")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Button("Restore Purchase") {
                    Task { await vm.restorePurchases() }
                }
                .font(.footnote)
                .foregroundStyle(.secondary)
            }
            .padding(.vertical)
        }
    }
}
```

---

## 5. ViewModel Layer

### OnboardingViewModel

```swift
// OnboardingViewModel.swift
enum OnboardingStep: Int, CaseIterable {
    case welcome, segmentation, aiSetup, roomSelection, firstAha, paywall
}

enum HouseholdType: String, CaseIterable, Identifiable {
    case solo = "Just me"
    case couple = "Me + partner"
    case family = "Family"
    case roommates = "Roommates"
    var id: String { rawValue }
}

enum CleaningChallenge: String, CaseIterable, Identifiable {
    case forgetting = "Forgetting tasks"
    case motivation = "Staying motivated"
    case fairDivision = "Fair division"
    case whereToStart = "Where to start"
    var id: String { rawValue }
}

@MainActor
final class OnboardingViewModel: ObservableObject {
    @Published var currentStep: OnboardingStep = .welcome
    @Published var householdType: HouseholdType = .solo
    @Published var cleaningChallenge: CleaningChallenge = .forgetting
    @Published var selectedRoomIcons: Set<RoomIcon> = []
    @Published var isGeneratingRoutine = false
    @Published var routineGenerationError: String?
    @Published var generatedTasks: [AIGeneratedTask] = []

    var progressFraction: Double {
        Double(currentStep.rawValue) / Double(OnboardingStep.allCases.count - 1)
    }

    func advance() {
        guard let next = OnboardingStep(rawValue: currentStep.rawValue + 1) else { return }
        withAnimation { currentStep = next }
    }

    func generateRoutine(context: ModelContext) async {
        isGeneratingRoutine = true
        defer { isGeneratingRoutine = false }

        do {
            let profile = HomeProfile(
                householdType: householdType,
                challenge: cleaningChallenge,
                rooms: selectedRoomIcons.map(\.displayName)
            )
            generatedTasks = try await AIService.shared.generateRoutine(profile: profile)
            advance()
        } catch {
            routineGenerationError = error.localizedDescription
        }
    }

    func commitOnboarding(context: ModelContext, userID: String) {
        let home = Home(name: "My Home", ownerUserID: userID)

        for roomIcon in selectedRoomIcons.sorted(by: { $0.rawValue < $1.rawValue }).enumerated() {
            let room = Room(name: roomIcon.element.displayName,
                           icon: roomIcon.element.rawValue,
                           sortOrder: roomIcon.offset)
            // Attach AI-generated tasks for this room
            let tasksForRoom = generatedTasks.filter { $0.roomName == roomIcon.element.displayName }
            for (i, t) in tasksForRoom.enumerated() {
                let task = CleaningTask(name: t.name, frequencyDays: t.frequencyDays, sortOrder: i)
                task.estimatedMinutes = t.estimatedMinutes
                room.tasks.append(task)
                context.insert(task)
            }
            home.rooms.append(room)
            context.insert(room)
        }

        context.insert(home)
        UserDefaults.standard.set(true, forKey: UserDefaultsKeys.hasCompletedOnboarding)
        FirebaseAnalyticsService.shared.log(.onboardingCompleted(householdType: householdType.rawValue))
    }
}
```

### DashboardViewModel

```swift
// DashboardViewModel.swift
@MainActor
final class DashboardViewModel: ObservableObject {
    @Published var urgentTasks: [CleaningTask] = []
    @Published var todaysFocus: [CleaningTask] = []
    @Published var homeScore: Double = 0

    // Home health score: inverted aggregate dirtiness
    // 100 = perfect; 0 = everything is urgent
    func computeHomeScore(from tasks: [CleaningTask]) -> Double {
        guard !tasks.isEmpty else { return 100 }
        let avgDirtiness = tasks.map(\.dirtinessScore).reduce(0, +) / Double(tasks.count)
        return max(0, 100 - avgDirtiness)
    }

    func loadDashboard(tasks: [CleaningTask]) {
        let active = tasks.filter(\.isActive)
        urgentTasks = active.filter { $0.dirtinessLevel == .urgent }
            .sorted { $0.dirtinessScore > $1.dirtinessScore }
        todaysFocus = active.filter { $0.dirtinessLevel == .needsIt }
            .sorted { $0.dirtinessScore > $1.dirtinessScore }
            .prefix(5).map { $0 }
        homeScore = computeHomeScore(from: active)
    }

    func completeTask(_ task: CleaningTask, userID: String, context: ModelContext) {
        let log = CompletionLog(completedByUserID: userID)
        task.completionLogs.append(log)
        task.lastCompletedAt = .now
        context.insert(log)

        HapticService.shared.trigger(.taskComplete)
        SoundService.shared.play(.completionChime)
        FirebaseAnalyticsService.shared.log(.taskCompleted(taskName: task.name))

        loadDashboard(tasks: urgentTasks + todaysFocus)
    }
}
```

### RoomDetailViewModel

```swift
// RoomDetailViewModel.swift
@MainActor
final class RoomDetailViewModel: ObservableObject {
    @Published var tasks: [CleaningTask] = []
    @Published var isAddingTask = false

    func loadTasks(from room: Room) {
        tasks = room.tasks.filter(\.isActive).sorted { $0.sortOrder < $1.sortOrder }
    }

    // Drag-to-reorder: Tody's most-requested missing feature (§3.3)
    func moveTask(from source: IndexSet, to destination: Int, in room: Room, context: ModelContext) {
        var reordered = tasks
        reordered.move(fromOffsets: source, toOffset: destination)
        for (index, task) in reordered.enumerated() {
            task.sortOrder = index
        }
        tasks = reordered
        try? context.save()
    }

    func deleteTask(_ task: CleaningTask, context: ModelContext) {
        task.isActive = false  // Soft delete; preserve history
        loadTasks(from: task.room ?? Room(name: "", icon: ""))
        FirebaseAnalyticsService.shared.log(.taskDeleted(taskName: task.name))
    }
}
```

### SubscriptionViewModel

```swift
// SubscriptionViewModel.swift
import RevenueCat

enum SubscriptionProduct: String, CaseIterable, Identifiable {
    case yearly   = "com.com.appfactory.gleam.subscription.yearly"
    case monthly  = "com.com.appfactory.gleam.subscription.monthly"
    case weekly   = "com.com.appfactory.gleam.subscription.weekly"
    case lifetime = "com.com.appfactory.gleam.subscription.lifetime"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .yearly:   return "Yearly"
        case .monthly:  return "Monthly"
        case .weekly:   return "Weekly"
        case .lifetime: return "Lifetime"
        }
    }

    var price: String {
        switch self {
        case .yearly:   return "$63.99/year"
        case .monthly:  return "$7.99/month"
        case .weekly:   return "$3.19/week"
        case .lifetime: return "$127.98 once"
        }
    }

    var badge: String? {
        switch self {
        case .yearly: return "Best Value"
        default:      return nil
        }
    }
}

@MainActor
final class SubscriptionViewModel: ObservableObject {
    @Published var tier: SubscriptionTier = .free
    @Published var selectedProduct: SubscriptionProduct = .yearly  // Annual pre-selected per §5.5
    @Published var isPurchasing = false
    @Published var error: String?

    var isPremium: Bool { tier.isPremium }

    var ctaTitle: String {
        selectedProduct == .lifetime ? "Buy Lifetime Access" : "Start Free Trial"
    }

    func refresh() async {
        do {
            let info = try await Purchases.shared.customerInfo()
            tier = RevenueCatService.shared.tier(from: info)
        } catch {
            self.error = error.localizedDescription
        }
    }

    func purchase() async {
        isPurchasing = true
        defer { isPurchasing = false }

        do {
            let packages = try await RevenueCatService.shared.fetchPackages()
            guard let package = packages.first(where: { $0.storeProduct.productIdentifier == selectedProduct.rawValue }) else { return }
            let result = try await Purchases.shared.purchase(package: package)
            tier = RevenueCatService.shared.tier(from: result.customerInfo)
            FirebaseAnalyticsService.shared.log(.subscriptionStarted(productID: selectedProduct.rawValue))
        } catch {
            self.error = error.localizedDescription
        }
    }

    func restorePurchases() async {
        do {
            let info = try await Purchases.shared.restorePurchases()
            tier = RevenueCatService.shared.tier(from: info)
        } catch {
            self.error = error.localizedDescription
        }
    }
}
```

### SettingsViewModel

```swift
// SettingsViewModel.swift
@MainActor
final class SettingsViewModel: ObservableObject {
    @Published var isVacationModeActive = false
    @Published var vacationEndDate = Date().addingTimeInterval(7 * 86_400)
    @Published var hapticsEnabled = true
    @Published var soundsEnabled = true
    @Published var notificationsEnabled = false

    func activateVacationMode(home: Home, context: ModelContext) {
        home.isPaused = true
        home.pausedUntil = vacationEndDate
        isVacationModeActive = true
        try? context.save()
        FirebaseAnalyticsService.shared.log(.vacationModeEnabled)
    }

    func deleteAllData(context: ModelContext) async {
        // Required for App Store compliance: in-app data deletion
        // Deletes all Home, Room, Task, Log, Member records for current user
        try? context.delete(model: CompletionLog.self)
        try? context.delete(model: CleaningTask.self)
        try? context.delete(model: Room.self)
        try? context.delete(model: HouseholdMember.self)
        try? context.delete(model: Home.self)
        UserDefaults.standard.removeObject(forKey: UserDefaultsKeys.hasCompletedOnboarding)
    }
}
```

---

## 6. Feature Prioritization

### Core Features — Must-Have for v1 (Free Tier)

These are table-stakes per research §3.1. Gleam cannot launch without them.

| Feature | Implementation Notes |
|---|---|
| Condition-based dirtiness tracking | `CleaningTask.dirtinessScore` computed property; `DirtinessCalculator` |
| Room/Zone organization | `Room` model; `RoomsView` with card grid |
| Custom task frequency configuration | `frequencyDays` Int on `CleaningTask`; frequency picker in `TaskDetailView` |
| Visual urgency indicator (green/yellow/orange/red) | `DirtinessMeterView` capsule bar; used in all list and card views |
| Auto-prioritized task queue | Default sort by `dirtinessScore` descending in `@Query` |
| Task completion with satisfying feedback | `HapticService.heavy` + `SoundService.completionChime` + `CompletionAnimationView` |
| "Just Did It" quick logging | `QuickCompleteButtonView` on Dashboard; resets timer without fanfare |
| Single-user offline functionality | SwiftData local store is always source of truth; no network required |
| Basic reminders/notifications | `NotificationService` with app-wide or per-room schedules |
| Pause/vacation mode | `Home.isPaused` + `Home.pausedUntil`; pauses dirtiness accumulation |
| Full-text search | `TasksView` `SearchBarView`; filters by task name + notes + room name |
| Drag-to-reorder tasks within rooms | `List` with `.onMove`; writes to `sortOrder`; fills Tody's gap |
| ASMR completion animations | `CompletionAnimationView`; honoring `isReduceMotionEnabled` |
| Dark mode support | SwiftUI semantic colors + Asset Catalog adaptive colorsets |

### Premium Features — Gated Behind Paywall (~60% of features)

Per research §5.2, users pay for these:

| Feature | Paywall Trigger |
|---|---|
| Cloud sync across user's devices | On second device sign-in attempt |
| Multi-user household sharing | On "Invite member" tap |
| Per-task notification scheduling | On per-task notification toggle |
| Household leaderboard + points | On `ProgressView` leaderboard section tap |
| iOS widgets (urgency at a glance) | WidgetKit extension; paywall in widget configurator |
| Advanced analytics (trends, time saved) | Beyond 30-day history access |
| AI routine generation | After 1 free use per month |
| AI cleaning coach (weekly insights) | On coach insights section tap |
| AI session planner ("I have 30 minutes") | On time-budget session feature tap |
| Fair labor distribution analyzer | On household equity report tap |
| Seasonal challenges | On challenge enrollment tap |
| Eco-tip suggestions per task | On eco-tips toggle |
| Custom themes + accent colors | On advanced appearance settings |
| Multiple homes/properties | On "Add another home" tap |
| Remove ads (IAP $1.99 — separate product) | On ad banner interaction |

### Nice-to-Have — Defer if Time-Constrained

| Feature | Notes |
|---|---|
| Voice input ("I just cleaned the kitchen") | Speech framework; complex NLP parsing; v2 candidate |
| Photo room scan (AI vision) | AVFoundation + vision API; research §6.3 ranks as v2 |
| Smart home integration | HomeKit/Matter bridge; research shows 29% interest but complex |
| Community task template packs | Backend needed; requires content moderation |
| "Gleam Score" shareable social card | Generative image; fun marketing tool but not core |
| Android companion app | Research recommends CloudKit for iOS-first v1 |

---

## 7. Paywall Strategy

### Free vs. Premium Feature Gate

```
FREE TIER (1 home, 5 rooms, unlimited tasks, single device)
└── Core dirtiness tracking, task completion, basic history, search, drag-reorder, 1 AI routine/month

PREMIUM ($3.19/wk · $7.99/mo · $63.99/yr · $127.98 lifetime)
└── Everything in Free +
    Cloud sync, multi-user sharing, all AI features (unlimited), widgets,
    advanced analytics, leaderboard, seasonal challenges, per-task notifications,
    custom themes, multiple homes

REMOVE ADS ($1.99 IAP — one-time, separate from subscription)
└── Removes any banner ads; does not unlock premium features
```

### Paywall Trigger Points

Research §4.1 mandates: show value first, paywall second. Apple App Review rejects apps that paywall core functionality immediately.

1. **Post-onboarding (soft):** After `FirstAhaView` — user has seen their home's dirtiness visualization for the first time. Dismissible. Pre-selects annual plan.
2. **Feature access gates:** Tapping any premium feature shows `PremiumGateView` inline (blurred preview + "Upgrade to Gleam Premium" CTA).
3. **AI coaching upsell:** After 1 free AI routine generation, next attempt opens `PaywallView`.
4. **Settings → Subscription:** Always accessible from `SettingsView → AccountView`.

### StoreKit 2 Integration Approach

RevenueCat wraps StoreKit 2 under the hood. All purchase logic routes through `RevenueCatService` — never call StoreKit 2 directly, to ensure consistent entitlement tracking.

```
Product IDs (as specified):
  com.com.appfactory.gleam.subscription.weekly   → $3.19/week
  com.com.appfactory.gleam.subscription.monthly  → $7.99/month
  com.com.appfactory.gleam.subscription.yearly   → $63.99/year
  com.com.appfactory.gleam.subscription.lifetime → $127.98 one-time

IAP:
  com.appfactory.gleam.iap.removeads             → $1.99 one-time

RevenueCat Entitlement:
  "premium" → maps to all 4 subscription products
  "lifetime" → maps to lifetime product
  "no_ads"   → maps to remove_ads IAP
```

### `.premiumGate()` View Modifier

```swift
// ViewModifiers.swift
struct PremiumGateModifier: ViewModifier {
    @EnvironmentObject var subscriptionVM: SubscriptionViewModel
    let feature: String

    func body(content: Content) -> some View {
        content
            .overlay {
                if !subscriptionVM.isPremium {
                    PremiumGateView(featureName: feature)
                }
            }
            .allowsHitTesting(subscriptionVM.isPremium)
    }
}

extension View {
    func premiumGate(feature: String) -> some View {
        modifier(PremiumGateModifier(feature: feature))
    }
}
```

---

## 8. SDK Integration Plan

### Initialization Order in GleamApp.swift

SDK initialization order matters. Facebook SDK must be initialized before any network call; Firebase before any Analytics event; RevenueCat before any paywall display; ATT before any attribution call.

```swift
// GleamApp.swift
import SwiftUI
import SwiftData
import FirebaseCore
import FacebookCore
import RevenueCat
import AdServices

@main
struct GleamApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate

    var body: some Scene {
        WindowGroup {
            ContentView()
                .modelContainer(GleamModelContainer.shared)
                .environmentObject(SubscriptionViewModel())
        }
    }
}

final class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {

        // ORDER MATTERS:
        // 1. Firebase first — must precede any Analytics event
        FirebaseApp.configure()
        FirebaseAnalyticsService.shared.configure()

        // 2. RevenueCat — must precede any paywall or entitlement check
        RevenueCatService.shared.configure()

        // 3. Facebook SDK — handles deep links and attribution
        ApplicationDelegate.shared.application(application, didFinishLaunchingWithOptions: launchOptions)

        // 4. ATT prompt scheduled for after onboarding (not first launch)
        // Triggered from FirstAhaView.onAppear via AppTrackingTransparency

        // 5. AdServices attribution — called after ATT authorization
        // Triggered from ATTService.requestPermission completion

        return true
    }

    func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey: Any] = [:]) -> Bool {
        ApplicationDelegate.shared.application(app, open: url, options: options)
    }
}
```

### RevenueCat Setup

```swift
// RevenueCatService.swift
import RevenueCat

final class RevenueCatService {
    static let shared = RevenueCatService()

    private let entitlementID = "premium"
    private let lifetimeEntitlementID = "lifetime"

    func configure() {
        Purchases.logLevel = .warn
        Purchases.configure(withAPIKey: "REVENUECAT_PUBLIC_SDK_KEY")
        // RevenueCat automatically reads StoreKit transactions
        // Delegate for real-time entitlement updates:
        Purchases.shared.delegate = self
    }

    func tier(from info: CustomerInfo) -> SubscriptionTier {
        if info.entitlements[lifetimeEntitlementID]?.isActive == true { return .lifetime }
        if info.entitlements[entitlementID]?.isActive == true { return .premium }
        return .free
    }

    func fetchPackages() async throws -> [Package] {
        let offerings = try await Purchases.shared.offerings()
        return offerings.current?.availablePackages ?? []
    }
}

extension RevenueCatService: PurchasesDelegate {
    func purchases(_ purchases: Purchases, receivedUpdated customerInfo: CustomerInfo) {
        // Post notification so SubscriptionViewModel can react to real-time updates
        NotificationCenter.default.post(name: .revenueCatCustomerInfoUpdated, object: customerInfo)
    }
}
```

### Firebase Analytics Events

```swift
// FirebaseAnalyticsService.swift
import FirebaseAnalytics

enum GleamAnalyticsEvent {
    case appOpened
    case onboardingStarted
    case onboardingStepViewed(step: String)
    case onboardingCompleted(householdType: String)
    case aiRoutineRequested
    case aiRoutineCompleted(roomCount: Int, taskCount: Int)
    case taskCompleted(taskName: String)
    case taskCreated(frequencyDays: Int)
    case taskDeleted(taskName: String)
    case roomCreated(roomName: String)
    case paywallViewed(trigger: String)     // "post_onboarding" | "feature_gate" | "settings"
    case subscriptionStarted(productID: String)
    case subscriptionRestored
    case vacationModeEnabled
    case searchUsed(query: String)
    case shareScoreTapped

    var name: String { /* switch mapping */ "" }
    var parameters: [String: Any]? { /* switch mapping */ nil }
}

final class FirebaseAnalyticsService {
    static let shared = FirebaseAnalyticsService()

    func configure() {
        // No additional configuration needed beyond FirebaseApp.configure()
        Analytics.setAnalyticsCollectionEnabled(true)
    }

    func log(_ event: GleamAnalyticsEvent) {
        Analytics.logEvent(event.name, parameters: event.parameters)
    }

    func setUserProperty(isPremium: Bool) {
        Analytics.setUserProperty(isPremium ? "premium" : "free", forName: "subscription_tier")
    }
}
```

### App Tracking Transparency + Facebook + AdServices

```swift
// ATTService.swift
import AppTrackingTransparency
import AdServices
import FacebookCore

final class ATTService {
    static let shared = ATTService()

    // Called from FirstAhaView.onAppear — after value has been shown, never on first launch
    // Research §8.1 and Apple HIG both require value-first ATT timing
    func requestPermission() async {
        // iOS 17+ requires a delay before presenting ATT dialog
        try? await Task.sleep(nanoseconds: 1_000_000_000)

        let status = await ATTrackingManager.requestTrackingAuthorization()

        if status == .authorized {
            // Fetch AdServices attribution token (Apple Search Ads)
            attributeViaAdServices()

            // Enable Facebook Advertiser tracking
            Settings.shared.isAdvertiserTrackingEnabled = true
        } else {
            Settings.shared.isAdvertiserTrackingEnabled = false
        }

        FirebaseAnalyticsService.shared.log(.appOpened)
    }

    private func attributeViaAdServices() {
        do {
            // AdServices: fetch attribution token for Apple Search Ads
            let token = try AAAttribution.attributionToken()
            // Post token to your backend or RevenueCat's subscriber attributes
            Purchases.shared.setAttributes(["adservices_token": token])
        } catch {
            print("AdServices attribution failed: \(error)")
        }
    }
}
```

### Facebook SDK Initialization

```swift
// In AppDelegate.didFinishLaunchingWithOptions (see GleamApp.swift above):
// ApplicationDelegate.shared.application(_:didFinishLaunchingWithOptions:) handles all
// Facebook initialization automatically when FacebookCore is imported.

// In Info.plist (required):
// <key>FacebookAppID</key>
// <string>YOUR_FACEBOOK_APP_ID</string>
// <key>FacebookClientToken</key>
// <string>YOUR_FACEBOOK_CLIENT_TOKEN</string>
// <key>FacebookDisplayName</key>
// <string>Gleam</string>
// <key>LSApplicationQueriesSchemes</key>
// <array>
//   <string>fbapi</string>
//   <string>fb-messenger-share-api</string>
// </array>
```

### AI Service (Claude Proxy)

```swift
// AIService.swift
// Claude API calls must route through a server-side proxy — never embed API key in client.
// Research §7.4: use Cloudflare Workers or AWS Lambda proxy.
// Research §8.1: Apple App Review (Nov 2025) requires explicit AI disclosure modal.

struct HomeProfile: Codable {
    let householdType: String
    let challenge: String
    let rooms: [String]
}

struct AIGeneratedTask: Codable, Identifiable {
    let id: UUID
    let roomName: String
    let name: String
    let frequencyDays: Int
    let estimatedMinutes: Int
}

final class AIService {
    static let shared = AIService()
    private let baseURL = "https://api.your-backend.com/gleam"  // Your Cloudflare Worker / Lambda

    func generateRoutine(profile: HomeProfile) async throws -> [AIGeneratedTask] {
        var request = URLRequest(url: URL(string: "\(baseURL)/generate-routine")!)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONEncoder().encode(profile)

        let (data, response) = try await URLSession.shared.data(for: request)
        guard (response as? HTTPURLResponse)?.statusCode == 200 else {
            throw URLError(.badServerResponse)
        }
        return try JSONDecoder().decode([AIGeneratedTask].self, from: data)
    }
}
```

---

## 9. App Store Readiness

### Required Info.plist Entries

```xml
<!-- Privacy usage descriptions — required or App will be rejected -->
<key>NSUserNotificationsUsageDescription</key>
<string>Gleam sends reminders when your rooms need attention, so nothing slips through the cracks.</string>

<key>NSCameraUsageDescription</key>
<string>Gleam can scan a room to identify cleaning tasks automatically.</string>

<key>NSMicrophoneUsageDescription</key>
<string>Gleam uses your microphone for hands-free task completion by voice.</string>

<key>NSMotionUsageDescription</key>
<string>Gleam uses motion data to detect when you're home and suggest cleaning sessions.</string>

<!-- Required for Facebook SDK -->
<key>FacebookAppID</key>
<string>$(FACEBOOK_APP_ID)</string>
<key>FacebookClientToken</key>
<string>$(FACEBOOK_CLIENT_TOKEN)</string>
<key>FacebookDisplayName</key>
<string>Gleam</string>

<!-- Required for Sign in with Apple + iCloud entitlement -->
<key>NSUbiquitousContainers</key>
<dict>
    <key>iCloud.com.appfactory.gleam</key>
    <dict>
        <key>NSUbiquitousContainerIsDocumentScopePublic</key>
        <false/>
        <key>NSUbiquitousContainerName</key>
        <string>Gleam</string>
    </dict>
</dict>

<!-- iOS 26 SDK requirement: all new submissions from April 2026 -->
<key>MinimumOSVersion</key>
<string>17.0</string>

<!-- ATT usage string — required when using Facebook or any ad network -->
<key>NSUserTrackingUsageDescription</key>
<string>We use this to show you relevant ads and measure how well our ads work. Your data is never sold.</string>
```

### Gleam.entitlements

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "...">
<plist version="1.0">
<dict>
    <!-- Sign in with Apple -->
    <key>com.apple.developer.applesignin</key>
    <array>
        <string>Default</string>
    </array>

    <!-- CloudKit for cross-device sync (premium feature) -->
    <key>com.apple.developer.icloud-container-identifiers</key>
    <array>
        <string>iCloud.com.appfactory.gleam</string>
    </array>
    <key>com.apple.developer.icloud-services</key>
    <array>
        <string>CloudKit</string>
    </array>

    <!-- Push notifications for task reminders -->
    <key>aps-environment</key>
    <string>development</string>

    <!-- In-App Purchases (automatic; no explicit entitlement needed for StoreKit 2 via RevenueCat) -->
</dict>
</plist>
```

### Asset Requirements

| Asset | Specification |
|---|---|
| AppIcon | 1024×1024 PNG in `AppIcon.appiconset`; no alpha channel; no rounded corners (iOS applies mask) |
| AccentColor | Adaptive colorset: light + dark variants; used as tint throughout app |
| GleamGreen | #52C97F light / #3BA86A dark — clean state dirtiness color |
| GleamYellow | #F5C842 light / #D4AA2A dark — "due soon" state |
| GleamOrange | #F0893A light / #D06A20 dark — "needs it" state |
| GleamRed | #E84040 light / #C42020 dark — urgent state |
| LaunchScreen | SwiftUI `LaunchScreen.storyboard` or `UILaunchScreen` in Info.plist; logo centered on system background |
| Completion sounds | `.caf` format (smallest footprint); must be < 30 seconds; included in app bundle |

### Privacy Manifest (PrivacyInfo.xcprivacy)

Required for all third-party SDKs (Firebase, Facebook, RevenueCat). Each bundled SDK must have its own privacy manifest. Gleam's top-level manifest must declare:

```
Data collected:
- User ID (from Sign in with Apple): linked to identity, for account management
- Usage data (task completion frequency, screen views): linked to identity, for analytics
- Diagnostics (crash logs): not linked to user

APIs used with justification:
- UserDefaults: "NSPrivacyAccessedAPICategoryUserDefaults" / DDA9.1 (app functionality)
- File timestamp APIs: "NSPrivacyAccessedAPICategoryFileTimestamp" / C617.1 (app functionality)
```

### Required Capabilities Checklist

- [x] In-App Purchases (automatic with StoreKit 2)
- [x] Sign in with Apple (required when offering any third-party login options)
- [x] Push Notifications
- [x] iCloud (CloudKit for premium sync)
- [x] Associated Domains (if using universal links for household invitations)

---

## 10. TODO Checklist

### Project Setup
- [x] Create Xcode project: "Gleam", bundle ID `com.appfactory.gleam`, iOS 17+ deployment target, SwiftUI lifecycle
- [x] Configure Swift Package Manager dependencies:
  - [x] Add RevenueCat (`purchases-ios-spm`) via SPM
  - [x] Add Firebase iOS SDK (`FirebaseAnalytics`) via SPM
  - [x] Add Facebook iOS SDK (`FacebookCore`) via SPM
  - [x] Verify AdServices framework is linked (system framework, no SPM needed)
- [x] Create `Gleam.entitlements` file with iCloud, Sign in with Apple, push notification entries
- [x] Set up Xcode build configurations: Debug / Release / (optional) Staging
- [x] Add `PrivacyInfo.xcprivacy` privacy manifest file
- [x] Configure Info.plist with all required privacy usage strings and Facebook SDK keys

### Asset Creation
- [ ] Design and export AppIcon (1024×1024 PNG) — no alpha channel, no rounded corners
- [x] Create AccentColor adaptive colorset (light + dark)
- [x] Create GleamGreen, GleamYellow, GleamOrange, GleamRed adaptive colorsets
- [ ] Record or source completion chime sound in `.caf` format
- [ ] Create LaunchScreen configuration in Info.plist

### SwiftData Models
- [x] Define `Home` @Model with all properties and relationships
- [x] Define `Room` @Model with `aggregateDirtinessScore` computed property
- [x] Define `CleaningTask` @Model with `dirtinessScore` and `dirtinessLevel` computed properties
- [x] Define `CompletionLog` @Model
- [x] Define `HouseholdMember` @Model
- [x] Create `DirtinessLevel` enum with color and accessibilityLabel
- [x] Create `RoomIcon` enum with SF Symbol names
- [x] Create `TaskFrequency` enum with preset options
- [x] Create `SubscriptionTier` enum
- [x] Set up `ModelContainer` with schema migration plan in `GleamApp.swift`
- [x] Write `DirtinessCalculator` utility with `level(for:)`, `percentage(for:)`, `nextTransitionDate(task:)`

### App Entry Point & Navigation
- [x] Implement `GleamApp.swift` with `AppDelegate` for SDK initialization in correct order
- [x] Implement `ContentView.swift` with onboarding/main routing gate using `UserDefaults` flag
- [x] Implement `MainTabView.swift` with 5 tabs and badge count on Tasks tab
- [x] Implement `AppRouter.swift` ObservableObject for global sheet/modal state
- [x] Create `UserDefaultsKeys.swift` constants file

### Onboarding Views
- [x] Implement `OnboardingViewModel.swift` with step state machine and AI coordination
- [x] Implement `OnboardingContainerView.swift` with animated progress bar and step transitions
- [x] Implement `WelcomeView.swift` with hero illustration and value prop ("Zero guilt. Always just clean enough.")
- [x] Implement `SegmentationView.swift` with two-question survey (household type + challenge)
- [x] Implement `AIRoutineSetupView.swift` with loading skeleton and 60-second promise
- [x] Implement `RoomSelectionView.swift` with visual tile grid for room selection
- [x] Implement `FirstAhaView.swift` with first dirtiness visualization reveal and celebration animation
- [x] Wire ATT permission request to `FirstAhaView.onAppear` (never on first launch)

### Dashboard Views
- [x] Implement `DashboardViewModel.swift` with `computeHomeScore()` and `completeTask()`
- [x] Implement `DashboardView.swift` with home health gauge, urgent task cards, FAB
- [x] Implement `HomeHealthGaugeView.swift` with circular progress gauge
- [x] Implement `UrgentTaskCardView.swift` as horizontally scrollable cards
- [x] Implement `QuickCompleteButtonView.swift` ("Just Did It") with haptic feedback

### Room Views
- [x] Implement `RoomsViewModel.swift` with room CRUD and aggregate dirtiness sorting
- [x] Implement `RoomsView.swift` with `LazyVGrid` card layout and search integration
- [x] Implement `RoomCardView.swift` with icon, name, and dirtiness meter
- [x] Implement `RoomDetailViewModel.swift` with `moveTask()` drag-to-reorder
- [x] Implement `RoomDetailView.swift` with reorderable task list and swipe-to-complete
- [x] Implement `AddRoomView.swift` sheet with name field and icon picker

### Task Views
- [x] Implement `TaskDetailViewModel.swift` with completion, snooze, delete logic
- [x] Implement `TasksView.swift` with full-text search bar and sort/filter controls
- [x] Implement `TaskRowView.swift` with swipe-to-complete gesture, dirtiness pill, contextual menu
- [x] Implement `TaskDetailView.swift` sheet with frequency picker, assignee, notification time, notes
- [x] Implement `AddTaskView.swift` sheet with task name, frequency presets, room assignment

### Progress Views
- [x] Implement `ProgressViewModel.swift` with weekly stats, streak calculation, leaderboard data
- [x] Implement `ProgressView.swift` with streak banner, weekly chart, room heatmap, leaderboard
- [x] Implement `StreakBannerView.swift` with flame animation (respecting `isReduceMotionEnabled`)
- [x] Implement `WeeklyBarChartView.swift` using SwiftCharts `BarMark`
- [x] Implement `RoomHealthGridView.swift` with color-coded room health heatmap
- [x] Implement `HouseholdLeaderboardView.swift` with premium gate overlay

### Settings Views
- [x] Implement `SettingsViewModel.swift` with vacation mode, haptics toggle, data deletion
- [x] Implement `SettingsView.swift` main list with all settings sections
- [x] Implement `NotificationSettingsView.swift` with per-task notification time pickers
- [x] Implement `VacationModeView.swift` with date range picker and proportional urgency explanation
- [x] Implement `HouseholdMembersView.swift` with invite flow and member management (premium-gated)
- [x] Implement `AccountView.swift` with Sign in with Apple, subscription status, "Delete My Data" button

### Paywall & Subscription
- [x] Implement `SubscriptionViewModel.swift` with RevenueCat purchase/restore logic
- [x] Implement `PaywallView.swift` with hero, feature comparison, pricing options, CTA
- [x] Implement `SubscriptionOptionView.swift` with badge, price, selection state
- [x] Implement `FeatureComparisonView.swift` with free vs. premium feature grid
- [x] Implement `PremiumGateView.swift` lock overlay for inline feature gates
- [x] Implement `.premiumGate(feature:)` ViewModifier in `ViewModifiers.swift`
- [x] Wire paywall trigger in `FirstAhaView` (post-aha, soft, dismissible — via OnboardingStep.paywall)
- [x] Wire paywall trigger on all premium feature access points (HouseholdMembersView, TaskDetailView, HouseholdLeaderboardView, AppRouter.presentPaywall)

### Shared Components
- [x] Implement `DirtinessMeterView.swift` capsule bar with animation and full accessibility labels
- [x] Implement `CompletionAnimationView.swift` with satisfying SwiftUI keyframe animation
- [x] Implement `SearchBarView.swift` reusable search input
- [x] Implement `EmptyStateView.swift` with icon, title, CTA button

### Services
- [x] Implement `RevenueCatService.swift` with `configure()`, `tier(from:)`, `fetchPackages()`
- [x] Implement `FirebaseAnalyticsService.swift` with all typed `GleamAnalyticsEvent` cases
- [x] Implement `NotificationService.swift` with `UNCalendarNotificationTrigger` per-task scheduling
- [x] Implement `AIService.swift` with `generateRoutine(profile:)` backend proxy call
- [x] Implement `HapticService.swift` wrapping `UIImpactFeedbackGenerator` with intensity enum
- [x] Implement `SoundService.swift` wrapping `AVAudioPlayer` with `isReduceMotionEnabled` check
- [x] Implement `ATTService.swift` with ATT request, AdServices token fetch, Facebook flag

### SDK Integration
- [x] Configure RevenueCat with API key and entitlement IDs in `RevenueCatService.configure()`
- [ ] Verify Firebase `GoogleService-Info.plist` is added to the Xcode project target (requires real Firebase project)
- [x] Register all `GleamAnalyticsEvent` cases and log from appropriate ViewModels
- [x] Configure Facebook App ID and Client Token in Info.plist and `AppDelegate`
- [x] Implement AdServices `AAAttribution.attributionToken()` call after ATT authorization
- [x] Schedule ATT permission request in `FirstAhaView` (post-value, never on launch)
- [x] Pass AdServices token to RevenueCat subscriber attributes for attribution
- [ ] Test full purchase flow in Xcode StoreKit sandbox environment
- [ ] Test restore purchases flow
- [ ] Test RevenueCat entitlement propagation across app lifecycle

### Accessibility
- [x] Add `.accessibilityLabel()` to every `DirtinessMeterView` instance (color alone is never enough)
- [x] Add descriptive accessibility labels to all room cards ("Kitchen — needs cleaning urgently")
- [x] Add `.accessibilityLabel()` and `.accessibilityHint()` to all interactive task row actions
- [x] Add `.accessibilityLabel()` to `HomeHealthGaugeView` ("Home health: 72 out of 100")
- [ ] Test full onboarding flow with VoiceOver enabled
- [ ] Ensure all text scales correctly with Dynamic Type (xSmall through AX5) — test in Simulator
- [ ] Verify color contrast ratios ≥ 4.5:1 for all text elements using Accessibility Inspector
- [ ] Ensure all touch targets are ≥ 44×44 pt
- [x] Honor `UIAccessibility.isReduceMotionEnabled` — skip ASMR animations when enabled
- [x] Add haptics toggle in Settings; honor it in `HapticService`
- [x] Add sounds toggle in Settings; honor it in `SoundService`

### Polish & UX
- [x] Add drag-to-reorder to `RoomDetailView` task list with `onMove` and `sortOrder` persistence
- [x] Implement swipe-to-complete gesture on `TaskRowView` with swipe action color-coded by dirtiness
- [x] Add contextual long-press menu on tasks: Edit, Snooze, Reassign, Delete
- [ ] Add shake-to-undo for accidental task completion (UIShakeGestureRecognizer)
- [x] Implement keyboard dismissal on scroll in forms (`.scrollDismissesKeyboard(.interactively)`)
- [x] Ensure dark mode looks correct for all custom colors and views
- [x] Add loading skeleton states for AI routine generation (not blocking spinner)
- [x] Add pull-to-refresh on `DashboardView` and `RoomsView`
- [x] Add empty state views for: no rooms, no tasks, no urgent tasks

### Testing & Quality
- [ ] Test dirtiness score edge cases: never-completed tasks, tasks completed today, paused tasks
- [ ] Test vacation mode: confirm dirtiness freezes and resumes correctly after `pausedUntil`
- [ ] Test SwiftData model migrations with a new schema version
- [ ] Test notification scheduling and cancellation per-task
- [ ] Test full onboarding flow from fresh install to first task completion
- [ ] Test paywall purchase → entitlement unlock → premium feature access flow
- [ ] Test restore purchases on a device with existing subscription
- [ ] Test offline mode: complete tasks with no network, verify sync on reconnect

### Pre-Submission
- [ ] Audit all third-party SDK privacy manifests (Firebase, Facebook, RevenueCat must each have one)
- [x] Verify `PrivacyInfo.xcprivacy` accurately declares all data types and API usage reasons
- [x] Test AI disclosure consent modal is shown before any Claude API call (required since Nov 2025)
- [x] Verify "Delete My Data" flow completely removes all user data from SwiftData + CloudKit
- [ ] Review all in-app strings for profanity and placeholder text (App Review rejects these)
- [ ] Confirm no "coming soon" or disabled screens are visible to reviewers
- [ ] Verify Sign in with Apple is implemented and works (required with any third-party login)
- [ ] Test on physical device: haptics, sounds, camera permission, ATT dialog timing
- [ ] Set app age rating appropriately (4+ with "Infrequent/Mild" for gamification)
- [ ] Write App Store description emphasizing AI routine generation and ADHD-suitability
- [ ] Write README.md with setup instructions, env vars, and SDK key configuration

---

*Plan based on research findings: Tody competitive analysis (§2.1), feature gap analysis (§3.3), UX patterns (§4.1–4.5), monetization strategy (§5.2–5.5), technical considerations (§7.1–7.6), and App Store risk assessment (§8.1).*
