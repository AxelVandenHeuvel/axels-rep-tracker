import SwiftUI
import SwiftData

struct CalendarView: View {
    @Environment(\.modelContext) private var modelContext
    @StateObject private var viewModel = CalendarVM()
    @State private var selectedDate: Date?
    @State private var showingWorkoutDay = false
    @State private var refreshTrigger = UUID()
    @State private var showingWeeklyProgressSetup = false
    @State private var showingThemePicker = false
    
    private let weekdays = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    MonthHeaderView(
                        month: viewModel.currentMonth,
                        onPrevious: { viewModel.previousMonth() },
                        onNext: { viewModel.nextMonth() }
                    )
                    .padding(.top)
                    
                    // Weekday headers
                    HStack {
                        ForEach(weekdays, id: \.self) { weekday in
                            Text(weekday)
                                .font(.caption)
                                .fontWeight(.medium)
                                .foregroundColor(AppColors.textSecondary)
                                .frame(maxWidth: .infinity)
                        }
                    }
                    .padding(.horizontal)
                    
                    // Calendar grid
                    let days = viewModel.daysInCurrentMonth()
                    let calendar = Calendar.current
                    let currentMonth = calendar.component(.month, from: viewModel.currentMonth)
                    
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 7), spacing: 8) {
                        ForEach(days, id: \.self) { date in
                            let isCurrentMonth = calendar.component(.month, from: date) == currentMonth
                            let isToday = Date.isSameDay(date, Date())
                            let metadata = viewModel.metadata(for: date)
                            let templateColor = metadata.templateColorHex.flatMap { Color(hex: $0) }
                            
                            DayCellView(
                                date: date,
                                isToday: isToday,
                                hasLoggedSets: metadata.hasLoggedSets,
                                templateColor: templateColor,
                                isCurrentMonth: isCurrentMonth,
                                onTap: {
                                    selectedDate = date
                                    showingWorkoutDay = true
                                }
                            )
                        }
                    }
                    .id(refreshTrigger)
                    .padding(.horizontal)
                    
                    WeeklyProgressView(
                        viewModel: viewModel,
                        onConfigure: { showingWeeklyProgressSetup = true }
                    )
                    .padding(.horizontal)
                    .padding(.bottom, 24)
                }
            }
            .navigationTitle("Calendar")
            .foregroundColor(AppColors.textPrimary)
            .background(AppColors.background)
            .onAppear {
                viewModel.setModelContext(modelContext)
                viewModel.refreshWeeklyProgress()
            }
            .sheet(isPresented: $showingWorkoutDay) {
                if let date = selectedDate {
                    WorkoutDayView(date: date, modelContext: modelContext)
                }
            }
            .sheet(isPresented: $showingWeeklyProgressSetup) {
                WeeklyProgressSetupView(calendarVM: viewModel)
            }
            .sheet(isPresented: $showingThemePicker) {
                ThemePickerView()
            }
            .onChange(of: showingWorkoutDay) { _, isPresented in
                if isPresented { return }
                refreshTrigger = UUID()
                viewModel.refreshWeeklyProgress()
            }
            .onReceive(NotificationCenter.default.publisher(for: .workoutDayUpdated)) { _ in
                refreshTrigger = UUID()
                viewModel.refreshWeeklyProgress()
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showingThemePicker = true
                    } label: {
                        Image(systemName: "paintpalette.fill")
                    }
                    .accessibilityLabel("Change color theme")
                }
            }
        }
        .background(AppColors.background.ignoresSafeArea())
        .tint(AppColors.accent)
        .toolbarBackground(AppColors.background, for: .navigationBar)
        .toolbarColorScheme(AppColors.isDarkMode ? .dark : .light, for: .navigationBar)
    }
}

