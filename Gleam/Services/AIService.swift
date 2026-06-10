import Foundation

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
    private let baseURL = "https://api.your-backend.com/gleam"

    func generateRoutine(profile: HomeProfile) async throws -> [AIGeneratedTask] {
        guard let url = URL(string: "\(baseURL)/generate-routine") else {
            throw URLError(.badURL)
        }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONEncoder().encode(profile)
        request.timeoutInterval = 60

        let (data, response) = try await URLSession.shared.data(for: request)
        guard (response as? HTTPURLResponse)?.statusCode == 200 else {
            throw URLError(.badServerResponse)
        }
        return try JSONDecoder().decode([AIGeneratedTask].self, from: data)
    }

    func generateFallbackRoutine(for profile: HomeProfile) -> [AIGeneratedTask] {
        var tasks: [AIGeneratedTask] = []
        for room in profile.rooms {
            let defaultTasks = defaultTasksForRoom(room)
            tasks.append(contentsOf: defaultTasks)
        }
        return tasks
    }

    private func defaultTasksForRoom(_ roomName: String) -> [AIGeneratedTask] {
        switch roomName.lowercased() {
        case "kitchen":
            return [
                AIGeneratedTask(id: UUID(), roomName: roomName, name: "Wipe counters", frequencyDays: 2, estimatedMinutes: 5),
                AIGeneratedTask(id: UUID(), roomName: roomName, name: "Clean stovetop", frequencyDays: 7, estimatedMinutes: 10),
                AIGeneratedTask(id: UUID(), roomName: roomName, name: "Mop floor", frequencyDays: 14, estimatedMinutes: 15),
                AIGeneratedTask(id: UUID(), roomName: roomName, name: "Clean fridge", frequencyDays: 30, estimatedMinutes: 20)
            ]
        case "bathroom":
            return [
                AIGeneratedTask(id: UUID(), roomName: roomName, name: "Scrub toilet", frequencyDays: 7, estimatedMinutes: 10),
                AIGeneratedTask(id: UUID(), roomName: roomName, name: "Wipe sink", frequencyDays: 3, estimatedMinutes: 5),
                AIGeneratedTask(id: UUID(), roomName: roomName, name: "Clean shower", frequencyDays: 14, estimatedMinutes: 15),
                AIGeneratedTask(id: UUID(), roomName: roomName, name: "Mop floor", frequencyDays: 7, estimatedMinutes: 10)
            ]
        case "bedroom":
            return [
                AIGeneratedTask(id: UUID(), roomName: roomName, name: "Change bed sheets", frequencyDays: 14, estimatedMinutes: 10),
                AIGeneratedTask(id: UUID(), roomName: roomName, name: "Dust surfaces", frequencyDays: 14, estimatedMinutes: 10),
                AIGeneratedTask(id: UUID(), roomName: roomName, name: "Vacuum floor", frequencyDays: 14, estimatedMinutes: 15)
            ]
        case "living room":
            return [
                AIGeneratedTask(id: UUID(), roomName: roomName, name: "Vacuum", frequencyDays: 7, estimatedMinutes: 15),
                AIGeneratedTask(id: UUID(), roomName: roomName, name: "Dust shelves", frequencyDays: 14, estimatedMinutes: 10),
                AIGeneratedTask(id: UUID(), roomName: roomName, name: "Wipe windows", frequencyDays: 30, estimatedMinutes: 15)
            ]
        default:
            return [
                AIGeneratedTask(id: UUID(), roomName: roomName, name: "General cleaning", frequencyDays: 14, estimatedMinutes: 15)
            ]
        }
    }
}
