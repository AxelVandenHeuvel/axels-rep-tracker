import Foundation
import SwiftData
import SwiftUI
import Combine

@MainActor
class CalendarVM: ObservableObject {
    @Published var currentMonth: Date = Date()
    @Published var selectedDate: Date = Date.startOfDay(Date())
    @Published private(set) var weeklyTargets: [WeeklyAttendanceTarget] = []
    @Published private(set) var weeklySummaries: [WeeklyAttendanceSummary] = []
    
    private(set) var modelContext: ModelContext?
    private let weeklyTargetsDefaultsKey = "weeklyAttendanceTargets.v1"
    
    init(modelContext: ModelContext? = nil) {
        self.modelContext = modelContext
        loadWeeklyTargets()
    }
    
    func setModelContext(_ context: ModelContext) {
        self.modelContext = context
        initializeDefaultTargetsIfNeeded()
        refreshWeeklyProgress()
    }
    
    func previousMonth() {
        currentMonth = Date.addMonths(currentMonth, -1)
    }
    
    func nextMonth() {
        currentMonth = Date.addMonths(currentMonth, 1)
    }
    
    func selectDate(_ date: Date) {
        selectedDate = Date.startOfDay(date)
    }
    
    /// Returns all dates in the current month grid
    func daysInCurrentMonth() -> [Date] {
        Date.daysInMonthGrid(for: currentMonth)
    }
    
    struct DayMetadata {
        let hasLoggedSets: Bool
        let templateColorHex: String?
    }
    
    /// Returns metadata for a specific day, including logged sets and template color
    func metadata(for date: Date) -> DayMetadata {
        guard let context = modelContext else {
            return DayMetadata(hasLoggedSets: false, templateColorHex: nil)
        }
        
        let normalizedDate = Date.startOfDay(date)
        let descriptor = FetchDescriptor<WorkoutDay>(
            predicate: #Predicate { $0.date == normalizedDate }
        )
        
        guard
            let workoutDayResult = try? context.fetch(descriptor),
            let workoutDay = workoutDayResult.first
        else {
            return DayMetadata(hasLoggedSets: false, templateColorHex: nil)
        }
        
        let hasSets = workoutDay.movements.contains { !$0.sets.isEmpty }
        
        var colorHex: String?
        if let templateID = workoutDay.appliedTemplateIDs.last {
            let templateDescriptor = FetchDescriptor<WorkoutTemplate>(
                predicate: #Predicate { $0.id == templateID }
            )
            if
                let templates = try? context.fetch(templateDescriptor),
                let template = templates.first
            {
                colorHex = template.colorHex
            }
        }
        
        return DayMetadata(hasLoggedSets: hasSets, templateColorHex: colorHex)
    }
    
    /// Gets or creates a WorkoutDay for the given date
    func getOrCreateWorkoutDay(for date: Date) -> WorkoutDay {
        guard let context = modelContext else {
            fatalError("ModelContext not set")
        }
        
        let normalizedDate = Date.startOfDay(date)
        let descriptor = FetchDescriptor<WorkoutDay>(
            predicate: #Predicate { $0.date == normalizedDate }
        )
        
        if let existing = try? context.fetch(descriptor).first {
            return existing
        }
        
        let newDay = WorkoutDay(date: normalizedDate)
        context.insert(newDay)
        try? context.save()
        return newDay
    }

    // MARK: - Weekly Progress Tracking
    
    struct WeeklyAttendanceTarget: Identifiable, Codable, Equatable {
        var id: UUID
        var templateID: UUID
        var targetCount: Int
        
        init(id: UUID = UUID(), templateID: UUID, targetCount: Int) {
            self.id = id
            self.templateID = templateID
            self.targetCount = targetCount
        }
    }
    
    struct WeeklyAttendanceSummary: Identifiable {
        let id: UUID
        let templateID: UUID
        let templateName: String
        let templateColorHex: String
        let targetCount: Int
        let completedCount: Int
        
        var progress: Double {
            guard targetCount > 0 else { return 0 }
            return min(Double(completedCount) / Double(targetCount), 1.0)
        }
        
        var remainingCount: Int {
            max(targetCount - completedCount, 0)
        }
    }
    
    var isWeeklyProgressConfigured: Bool {
        !weeklyTargets.isEmpty
    }
    
    func updateWeeklyTargets(_ targets: [WeeklyAttendanceTarget]) {
        weeklyTargets = Array(targets.prefix(4))
        saveWeeklyTargets()
        refreshWeeklyProgress()
    }
    
    func loadWeeklyTargets() {
        if
            let data = UserDefaults.standard.data(forKey: weeklyTargetsDefaultsKey),
            let decoded = try? JSONDecoder().decode([WeeklyAttendanceTarget].self, from: data)
        {
            weeklyTargets = decoded
        } else {
            weeklyTargets = []
        }
    }
    
    func refreshWeeklyProgress() {
        guard let context = modelContext else {
            weeklySummaries = []
            return
        }
        
        initializeDefaultTargetsIfNeeded()
        
        guard
            !weeklyTargets.isEmpty,
            let weekInterval = Calendar.current.dateInterval(of: .weekOfYear, for: Date())
        else {
            weeklySummaries = []
            return
        }
        
        let startOfWeek = Date.startOfDay(weekInterval.start)
        let endOfWeek = weekInterval.end
        
        let descriptor = FetchDescriptor<WorkoutDay>(
            predicate: #Predicate { $0.date >= startOfWeek && $0.date < endOfWeek }
        )
        
        let workoutDays = (try? context.fetch(descriptor)) ?? []
        var counts: [UUID: Int] = [:]
        for day in workoutDays {
            for templateID in day.appliedTemplateIDs {
                counts[templateID, default: 0] += 1
            }
        }
        
        let templates = fetchAllTemplates()
        let templatesByID = Dictionary(uniqueKeysWithValues: templates.map { ($0.id, $0) })
        
        var summaries: [WeeklyAttendanceSummary] = []
        var removedTemplateIDs: Set<UUID> = []
        
        for target in weeklyTargets {
            guard let template = templatesByID[target.templateID] else {
                removedTemplateIDs.insert(target.templateID)
                continue
            }
            
            let completed = counts[target.templateID] ?? 0
            summaries.append(
                WeeklyAttendanceSummary(
                    id: target.id,
                    templateID: target.templateID,
                    templateName: template.name,
                    templateColorHex: template.colorHex,
                    targetCount: target.targetCount,
                    completedCount: completed
                )
            )
        }
        
        if !removedTemplateIDs.isEmpty {
            weeklyTargets.removeAll { removedTemplateIDs.contains($0.templateID) }
            saveWeeklyTargets()
        }
        
        weeklySummaries = summaries.sorted { $0.templateName < $1.templateName }
    }
    
    // MARK: - Private Helpers
    
    private func initializeDefaultTargetsIfNeeded() {
        guard weeklyTargets.isEmpty, let _ = modelContext else { return }
        
        let templates = fetchAllTemplates()
        let defaultNames = ["Push", "Pull", "Legs"]
        
        var defaults: [WeeklyAttendanceTarget] = []
        for name in defaultNames {
            if let template = templates.first(where: { $0.name == name }) {
                defaults.append(WeeklyAttendanceTarget(templateID: template.id, targetCount: 2))
            }
        }
        
        if !defaults.isEmpty {
            weeklyTargets = defaults
            saveWeeklyTargets()
        }
    }
    
    private func saveWeeklyTargets() {
        if weeklyTargets.isEmpty {
            UserDefaults.standard.removeObject(forKey: weeklyTargetsDefaultsKey)
        } else if let data = try? JSONEncoder().encode(weeklyTargets) {
            UserDefaults.standard.set(data, forKey: weeklyTargetsDefaultsKey)
        }
    }
    
    private func fetchAllTemplates() -> [WorkoutTemplate] {
        guard let context = modelContext else { return [] }
        let descriptor = FetchDescriptor<WorkoutTemplate>()
        return (try? context.fetch(descriptor)) ?? []
    }
}

