import SwiftUI
import SwiftData

@main
struct RepTrackApp: App {
    @StateObject private var themeManager = ThemeManager.shared
    
    var body: some Scene {
        WindowGroup {
            RootTabView()
                .environmentObject(themeManager)
                .accentColor(AppColors.accent)
                .preferredColorScheme(AppColors.isDarkMode ? .dark : .light)
                .background(AppColors.background)
                .environment(\.colorScheme, AppColors.isDarkMode ? .dark : .light)
        }
        .modelContainer(Self.container)
    }
    
    // Create and configure the model container
    static let container: ModelContainer = {
        let schema = Schema([Movement.self, WorkoutDay.self, WorkoutMovement.self, SetEntry.self, WorkoutTemplate.self])
        let storeURL = URL.applicationSupportDirectory.appending(component: "RepTrack.store")
        let configuration = ModelConfiguration(schema: schema, url: storeURL)
        let fileManager = FileManager.default
        let directoryURL = storeURL.deletingLastPathComponent()
        
        if !fileManager.fileExists(atPath: directoryURL.path) {
            try? fileManager.createDirectory(at: directoryURL, withIntermediateDirectories: true)
        }
        
        do {
            let container = try ModelContainer(for: schema, configurations: [configuration])
            // Seed data on first launch (DEBUG only)
            SeedDataService.seedIfNeeded(modelContext: container.mainContext)
            return container
        } catch {
            try? fileManager.removeItem(at: storeURL)
            do {
                let container = try ModelContainer(for: schema, configurations: [configuration])
                SeedDataService.seedIfNeeded(modelContext: container.mainContext)
                return container
            } catch {
                fatalError("Failed to create model container: \(error)")
            }
        }
    }()
}

