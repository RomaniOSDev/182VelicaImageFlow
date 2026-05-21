import SwiftUI

struct MainTabView: View {
    @EnvironmentObject private var store: MoodSyncDataStore
    @State private var selectedTab: MainTab = .home
    @State private var tabBarHeight = TabBarMetrics.fallbackHeight

    var body: some View {
        Group {
            switch selectedTab {
            case .home:
                HomeView(selectedTab: $selectedTab)
            case .gallery:
                Feature1View()
            case .media:
                MediaHubView()
            case .insights:
                InsightsView()
            case .settings:
                SettingsView()
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .environment(\.tabBarBottomInset, tabBarHeight)
        .safeAreaInset(edge: .bottom, spacing: 0) {
            CustomTabBar(selection: $selectedTab)
                .background {
                    GeometryReader { proxy in
                        Color.clear
                            .preference(key: TabBarHeightPreferenceKey.self, value: proxy.size.height)
                    }
                }
        }
        .onPreferenceChange(TabBarHeightPreferenceKey.self) { height in
            if height > 0 {
                tabBarHeight = height
            }
        }
        .onAppear {
            AppChromeConfiguration.applyIfNeeded()
            store.checkAchievements()
        }
        .overlay(alignment: .top) {
            if let achievement = store.newlyUnlockedAchievement {
                AchievementBannerView(achievement: achievement) {
                    store.dismissAchievementBanner()
                }
                .padding(.top, 8)
                .padding(.horizontal, 16)
                .zIndex(10)
            }
        }
    }
}
