import SwiftUI

struct InsightsView: View {
    @EnvironmentObject private var store: MoodSyncDataStore
    @State private var highlightedTag: String?

    private let columns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12)
    ]

    var body: some View {
        NavigationStack {
            ZStack {
                LayeredBackground()
                ScrollView {
                    VStack(spacing: 20) {
                        progressSection
                        InsightsChartsSection()
                        PopularTagsCloud(
                            tags: store.popularTags(),
                            selectedTag: $highlightedTag
                        )
                        timelineSection
                        achievementsSection
                    }
                    .padding(16)
                    .padding(.bottom, 24)
                }
                .tabScrollContent()
            }
            .navigationTitle("Insights")
            .navigationBarTitleDisplayMode(.large)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .transparentNavigationBar()
        }
    }

    private var progressSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            SectionTitle(text: "Your progress")
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                MetricCell(value: "\(store.itemsAdded)", label: "Items Added", icon: "square.grid.2x2.fill")
                MetricCell(value: "\(store.entriesWritten)", label: "Journal Entries", icon: "book.fill")
                MetricCell(value: "\(store.favouritesCount)", label: "Discover Favourites", icon: "heart.fill")
                MetricCell(value: "\(store.streakDays)", label: "Day Streak", icon: "flame.fill")
                MetricCell(value: "\(store.userAlbums.count)", label: "My Albums", icon: "rectangle.stack.fill")
                MetricCell(value: "\(store.curatedEntries.filter(\.isPinned).count)", label: "Pinned", icon: "pin.fill")
            }
        }
    }

    private var timelineSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            SectionTitle(text: "Timeline")
            TimelineView()
        }
        .depthRaised(cornerRadius: 18)
    }

    private var achievementsSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            SectionTitle(text: "Achievements")
            LazyVGrid(columns: columns, spacing: 12) {
                ForEach(AchievementCatalog.all) { achievement in
                    AchievementCell(
                        achievement: achievement,
                        unlocked: store.achievementsUnlocked[achievement.id] != nil
                    )
                }
            }
        }
    }
}
