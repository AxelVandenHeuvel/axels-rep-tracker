import SwiftUI

struct RootTabView: View {
    @SceneStorage("selectedTab") private var selectedTab = 0
    @SceneStorage("selectedDate") private var selectedDateStorage: String = ""
    
    var body: some View {
        TabView(selection: $selectedTab) {
            CalendarView()
                .tabItem {
                    Label("Calendar", systemImage: "calendar")
                }
                .tag(0)
            
            TemplatesView()
                .tabItem {
                    Label("Templates", systemImage: "list.bullet.rectangle")
                }
                .tag(1)
            
            ChartsRootView()
                .tabItem {
                    Label("Charts", systemImage: "chart.line.uptrend.xyaxis")
                }
                .tag(2)
        }
        .tint(AppColors.accent)
        .background(AppColors.background.ignoresSafeArea())
        .toolbarBackground(AppColors.background, for: .tabBar)
        .toolbarColorScheme(AppColors.isDarkMode ? .dark : .light, for: .tabBar)
    }
}

