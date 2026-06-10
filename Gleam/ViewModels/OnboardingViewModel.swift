import SwiftUI
import SwiftData

enum OnboardingStep: Int, CaseIterable {
    case welcome, segmentation, aiSetup, roomSelection, firstAha, paywall
}

enum HouseholdType: String, CaseIterable, Identifiable {
    case solo       = "Just me"
    case couple     = "Me + partner"
    case family     = "Family"
    case roommates  = "Roommates"
    var id: String { rawValue }
}

enum CleaningChallenge: String, CaseIterable, Identifiable {
    case forgetting    = "Forgetting tasks"
    case motivation    = "Staying motivated"
    case fairDivision  = "Fair division"
    case whereToStart  = "Where to start"
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
        withAnimation(.easeInOut(duration: 0.3)) {
            currentStep = next
        }
    }

    func generateRoutine(context: ModelContext) async {
        isGeneratingRoutine = true
        defer { isGeneratingRoutine = false }

        let profile = HomeProfile(
            householdType: householdType.rawValue,
            challenge: cleaningChallenge.rawValue,
            rooms: selectedRoomIcons.map(\.displayName)
        )

        do {
            FirebaseAnalyticsService.shared.log(.aiRoutineRequested)
            generatedTasks = try await AIService.shared.generateRoutine(profile: profile)
            FirebaseAnalyticsService.shared.log(.aiRoutineCompleted(
                roomCount: selectedRoomIcons.count,
                taskCount: generatedTasks.count
            ))
        } catch {
            generatedTasks = AIService.shared.generateFallbackRoutine(for: profile)
            routineGenerationError = nil
        }
        advance()
    }

    func commitOnboarding(context: ModelContext, userID: String) {
        let home = Home(name: "My Home", ownerUserID: userID)

        for (offset, roomIcon) in selectedRoomIcons.sorted(by: { $0.rawValue < $1.rawValue }).enumerated() {
            let room = Room(name: roomIcon.displayName, icon: roomIcon.rawValue, sortOrder: offset)
            let tasksForRoom = generatedTasks.filter { $0.roomName == roomIcon.displayName }
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
        UserDefaults.standard.set(userID, forKey: UserDefaultsKeys.currentUserID)
        FirebaseAnalyticsService.shared.log(.onboardingCompleted(householdType: householdType.rawValue))
    }
}
