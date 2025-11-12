import Foundation

extension Date {
    /// Returns the start of the day for the given date
    static func startOfDay(_ date: Date) -> Date {
        Calendar.current.startOfDay(for: date)
    }
    
    /// Checks if two dates are on the same day
    static func isSameDay(_ d1: Date, _ d2: Date) -> Bool {
        Calendar.current.isDate(d1, inSameDayAs: d2)
    }
    
    /// Returns all days in the month grid, including leading/trailing days from adjacent months
    /// to fill a 6x7 grid (42 days total)
    static func daysInMonthGrid(for month: Date) -> [Date] {
        let calendar = Calendar.current
        let startOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: month))!
        
        // First day of the month
        let firstDay = calendar.component(.weekday, from: startOfMonth)
        let firstWeekday = calendar.firstWeekday
        
        // Calculate leading days (days from previous month to show)
        let leadingDays = (firstDay - firstWeekday + 7) % 7
        
        // Get start date (first day minus leading days)
        guard let gridStart = calendar.date(byAdding: .day, value: -leadingDays, to: startOfMonth) else {
            return []
        }
        
        // Generate 42 days (6 weeks * 7 days)
        var days: [Date] = []
        for i in 0..<42 {
            if let date = calendar.date(byAdding: .day, value: i, to: gridStart) {
                days.append(date)
            }
        }
        
        return days
    }
    
    /// Adds or subtracts months from a date
    static func addMonths(_ date: Date, _ delta: Int) -> Date {
        Calendar.current.date(byAdding: .month, value: delta, to: date) ?? date
    }
}

