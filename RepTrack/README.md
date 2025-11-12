# RepTrack

A native iOS app built with SwiftUI and SwiftData for tracking weight-lifting workouts. RepTrack helps you log your sets, track progress over time, and visualize your strength gains with beautiful charts.

## Features

### 📅 Calendar Home Screen
- Month view calendar showing all your workout days
- Visual indicators (dots) for days with logged sets
- Template-applied days tinted with their assigned colors
- Today highlighted for easy reference
- Tap any date to view or log a workout

### 💪 Workout Logging
- Add multiple movements to any workout day
- Quick set entry with weight, reps, and optional RPE
- **Duplicate-last feature**: After adding a set, the next set automatically prefills with the last values for rapid logging
- Swipe to delete sets
- See total sets count for each workout day

### 🏋️ Movement Library
- Search movements by name (case-insensitive)
- Filter by tags (Chest, Back, Barbell, Dumbbell, etc.)
- Create new movements with custom tags
- Prevents duplicate movements (case-insensitive matching)
- Preset tags: Chest, Back, Shoulders, Quads, Hamstrings, Glutes, Biceps, Triceps, Core, Calves, Barbell, Dumbbell, Machine, Cable, Bodyweight

### 📋 Workout Templates
- Create reusable workout templates
- Quickly apply templates to any workout day
- Edit templates by adding/removing/reordering movements
- Pre-seeded templates: Push, Pull, Legs
- Assign a color to each template for calendar visualization

### 📊 Progress Charts
- **Reps @ Weight**: See how many reps you can do at a specific weight over time
- **Weight @ Reps**: Track the maximum weight you've lifted for a target rep count
- Beautiful line charts with point markers
- Best performance per day aggregation

## Technical Details

### Requirements
- iOS 17.0+
- Xcode 15.0+
- Swift 5.9+

### Architecture
- **UI Framework**: SwiftUI
- **Persistence**: SwiftData (no Core Data)
- **Charts**: Apple's Charts framework
- **Architecture**: Lightweight MVVM per feature
- **State Management**: @State, @StateObject, @Environment(ModelContext)

### Project Structure

```
RepTrack/
├── RepTrackApp.swift          # App entry point
├── Models/                     # SwiftData models
│   ├── Movement.swift
│   ├── WorkoutDay.swift
│   ├── WorkoutMovement.swift
│   ├── SetEntry.swift
│   └── WorkoutTemplate.swift
├── ViewModels/                 # View models
│   ├── CalendarVM.swift
│   ├── WorkoutDayVM.swift
│   ├── MovementLibraryVM.swift
│   ├── TemplatesVM.swift
│   └── ChartsVM.swift
├── Views/                      # SwiftUI views
│   ├── RootTabView.swift
│   ├── Calendar/
│   ├── WorkoutDay/
│   ├── Movements/
│   ├── Templates/
│   └── Charts/
├── Components/                 # Reusable components
│   ├── MovementTagPills.swift
│   └── PrimaryButton.swift
├── Services/                   # Business logic
│   └── SeedDataService.swift
└── Utils/
    └── Date+Extensions.swift
```

## Getting Started

### Building in Xcode

1. Open the project in Xcode 15.0 or later
2. Select a simulator or device running iOS 17.0+
3. Build and run (Cmd+R)

### First Launch

On first launch in DEBUG mode, the app will automatically seed:
- Example movements (Barbell Bench Press, Back Squat, Conventional Deadlift, etc.)
- Pre-configured templates (Push, Pull, Legs)
- Sample workout data from the past few days

### Usage

1. **Log a Workout**:
   - Tap any date on the calendar
   - Tap "Add Movement"
   - Select an existing movement or create a new one
   - Enter weight and reps, then tap "Add Set"
   - The next set will auto-fill with your last values for quick entry

2. **Create a Template**:
   - Go to the Templates tab
   - Tap the "+" button
   - Enter a template name
   - Add movements to the template
   - Save

3. **Apply a Template**:
   - Open a workout day
   - Tap "Apply Template" in the toolbar
   - Select a template
   - Movements are added instantly (no sets)

4. **View Progress**:
   - Go to the Charts tab
   - Select a movement
   - Choose a chart mode (Reps @ Weight or Weight @ Reps)
   - For weight/reps modes, enter your target value
   - View your progress over time

## Data Model

### Movement
- Unique ID
- Name
- Tags (array of strings)
- Created date

### WorkoutDay
- Unique ID
- Date (normalized to midnight)
- Array of WorkoutMovements

### WorkoutMovement
- Unique ID
- Reference to Movement
- Optional notes
- Array of SetEntries

### SetEntry
- Unique ID
- Weight (Double)
- Reps (Int)
- Optional RPE (Double)
- Timestamp

### WorkoutTemplate
- Unique ID
- Name
- Array of Movement IDs
- Optional notes per movement

## Settings

- **RPE Field**: Hidden by default. Enable via `@AppStorage("showRPE")` in SetEditorRow
- **Last Selected Tab**: Persisted with @SceneStorage
- **Selected Date**: Persisted with @SceneStorage

## Accessibility

- Minimum 44pt tap targets
- VoiceOver labels for important buttons
- Semantic labels for navigation

## Notes

- All data persists automatically with SwiftData
- Movement names are case-insensitive for duplicate detection
- Charts aggregate best performance per day
- Reps @ Weight mode uses ±0.5% tolerance for weight matching
- Calendar highlights any template applied to a day using the template's color

## Future Enhancements (Non-MVP)

- Accounts and sync
- watchOS companion app
- Timers and rest periods
- Notifications
- Data export/import
- Supersets and AMRAP tracking
- Social features

## License

This project is created for demonstration purposes.

