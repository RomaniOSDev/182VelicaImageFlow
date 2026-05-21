import SwiftUI

struct HomeView: View {
    @EnvironmentObject private var store: MoodSyncDataStore
    @Binding var selectedTab: MainTab
    @State private var showAddEntry = false

    private var feedItems: [HomeFeedItem] {
        let gallery = store.curatedEntries.map { HomeFeedItem.gallery($0) }
        let journal = store.photoJournalItems.map { HomeFeedItem.journal($0) }
        return (gallery + journal)
            .sorted { lhs, rhs in
                if lhs.hasDevicePhoto != rhs.hasDevicePhoto {
                    return lhs.hasDevicePhoto && !rhs.hasDevicePhoto
                }
                return lhs.createdAt > rhs.createdAt
            }
            .prefix(12)
            .map { $0 }
    }

    private var featuredItem: HomeFeedItem? {
        feedItems.first
    }

    private var mosaicItems: [HomeFeedItem] {
        Array(feedItems.dropFirst())
    }

    private var quickActions: [HomeQuickAction] {
        [
            HomeQuickAction(id: "gallery", title: "Add", icon: "plus.circle.fill"),
            HomeQuickAction(id: "journal", title: "Journal", icon: "book.fill"),
            HomeQuickAction(id: "insights", title: "Insights", icon: "chart.bar.fill")
        ]
    }

    var body: some View {
        NavigationStack {
            ZStack {
                LayeredBackground()
                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 16) {
                        HomeGreetingStrip(
                            streak: store.streakDays,
                            itemsCount: store.itemsAdded,
                            favourites: store.favouritesCount
                        )

                        if let featured = featuredItem {
                            HomeSectionHeader(
                                title: "Latest",
                                subtitle: "Opens in \(featured.kindLabel)"
                            )
                            Button {
                                FeedbackManager.tapLight()
                                open(item: featured)
                            } label: {
                                HomeFeaturedMoment(item: featured)
                            }
                            .buttonStyle(.plain)

                            if !mosaicItems.isEmpty {
                                HomeSectionHeader(
                                    title: "More moments",
                                    subtitle: "Gallery entries and journal photos",
                                    actionTitle: "See all",
                                    action: { selectedTab = .gallery }
                                )
                                HomeMosaicGrid(items: mosaicItems, onTap: open)
                            }
                        } else {
                            HomeEmptyVisual {
                                FeedbackManager.tapLight()
                                showAddEntry = true
                            }
                        }

                        HomeIconActionRow(actions: quickActions, onTap: handleQuickAction)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .padding(.bottom, 8)
                }
                .tabScrollContent()
            }
            .navigationBarHidden(true)
        }
        .sheet(isPresented: $showAddEntry) {
            HomeAddEntrySheet()
        }
    }

    private func open(item: HomeFeedItem) {
        switch item {
        case .gallery:
            selectedTab = .gallery
        case .journal:
            selectedTab = .media
        }
    }

    private func handleQuickAction(_ action: HomeQuickAction) {
        FeedbackManager.tapLight()
        switch action.id {
        case "gallery":
            showAddEntry = true
        case "journal":
            selectedTab = .media
        case "insights":
            selectedTab = .insights
        default:
            break
        }
    }
}

// MARK: - Quick add sheet from Home

private struct HomeAddEntrySheet: View {
    @EnvironmentObject private var store: MoodSyncDataStore
    @Environment(\.dismiss) private var dismiss
    @State private var title = ""
    @State private var description = ""
    @State private var tagsText = ""
    @State private var selectedIcon = CuratedEmojiPicker.options[0]
    @State private var titleError: String?
    @State private var shakeTrigger = 0

    var body: some View {
        NavigationStack {
            ZStack {
                LayeredBackground()
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .fill(
                                    LinearGradient(
                                        colors: [Color("AppPrimary").opacity(0.3), Color("AppSurface").opacity(0.5)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .frame(height: 100)
                            Text(selectedIcon)
                                .font(.system(size: 56))
                        }
                        TextField("Title", text: $title)
                            .padding(14)
                            .accentCard(cornerRadius: 12)
                            .shake(trigger: shakeTrigger)
                        if let titleError {
                            Text(titleError).font(.caption).foregroundStyle(.red)
                        }
                        TextField("Description", text: $description, axis: .vertical)
                            .lineLimit(3...5)
                            .padding(14)
                            .accentCard(cornerRadius: 12)
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Tags")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(Color("AppTextSecondary"))
                            TextField("travel, family", text: $tagsText)
                                .padding(14)
                                .accentCard(cornerRadius: 12)
                        }
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                ForEach(CuratedEmojiPicker.options, id: \.self) { emoji in
                                    Button {
                                        FeedbackManager.tapLight()
                                        selectedIcon = emoji
                                    } label: {
                                        Text(emoji)
                                            .font(.title2)
                                            .frame(width: 48, height: 48)
                                            .accentCard(cornerRadius: 12, highlighted: selectedIcon == emoji)
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                        }
                    }
                    .padding(20)
                }
                .tabScrollContent()
            }
            .navigationTitle("Quick Add")
            .navigationBarTitleDisplayMode(.inline)
            .transparentNavigationBar()
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .foregroundStyle(Color("AppTextSecondary"))
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }
                        .fontWeight(.bold)
                        .foregroundStyle(Color("AppPrimary"))
                }
            }
        }
        .presentationDetents([.large])
    }

    private func save() {
        let trimmed = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            titleError = "Title is required."
            shakeTrigger += 1
            FeedbackManager.warning()
            return
        }
        let entry = CuratedEntry(
            title: trimmed,
            icon: selectedIcon,
            description: description,
            tags: TagNormalizer.parseInput(tagsText)
        )
        store.addCuratedEntry(entry)
        FeedbackManager.entryAdded()
        FeedbackManager.success()
        dismiss()
    }
}
