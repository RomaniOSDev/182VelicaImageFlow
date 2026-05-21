import Combine
import Foundation

final class MoodSyncDataStore: ObservableObject {
    static let shared = MoodSyncDataStore()

    private let defaults = UserDefaults.standard
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    private enum Keys {
        static let hasSeenOnboarding = "hasSeenOnboarding"
        static let totalSessionsCompleted = "totalSessionsCompleted"
        static let totalMinutesUsed = "totalMinutesUsed"
        static let streakDays = "streakDays"
        static let lastActivityDate = "lastActivityDate"
        static let achievementsUnlocked = "achievementsUnlocked"
        static let curatedEntries = "curatedEntries"
        static let lastEntryDate = "lastEntryDate"
        static let entryCount = "entryCount"
        static let photoCaptions = "photoCaptions"
        static let journalEntries = "journalEntries"
        static let photoJournalItems = "photoJournalItems"
        static let favoriteCollections = "favoriteCollections"
        static let lastViewedCollection = "lastViewedCollection"
        static let itemsAdded = "itemsAdded"
        static let entriesWritten = "entriesWritten"
        static let favouritesCount = "favouritesCount"
        static let userAlbums = "userAlbums"
    }

    @Published var hasSeenOnboarding: Bool {
        didSet { defaults.set(hasSeenOnboarding, forKey: Keys.hasSeenOnboarding) }
    }

    @Published var totalSessionsCompleted: Int {
        didSet { defaults.set(totalSessionsCompleted, forKey: Keys.totalSessionsCompleted) }
    }

    @Published var totalMinutesUsed: Int {
        didSet { defaults.set(totalMinutesUsed, forKey: Keys.totalMinutesUsed) }
    }

    @Published var streakDays: Int {
        didSet { defaults.set(streakDays, forKey: Keys.streakDays) }
    }

    @Published var lastActivityDate: Date? {
        didSet {
            if let date = lastActivityDate {
                defaults.set(date, forKey: Keys.lastActivityDate)
            } else {
                defaults.removeObject(forKey: Keys.lastActivityDate)
            }
        }
    }

    @Published var achievementsUnlocked: [String: Date] {
        didSet { saveDictionary(achievementsUnlocked, key: Keys.achievementsUnlocked) }
    }

    @Published var curatedEntries: [CuratedEntry] {
        didSet {
            saveArray(curatedEntries, key: Keys.curatedEntries)
            entryCount = curatedEntries.count
        }
    }

    @Published var lastEntryDate: Date? {
        didSet {
            if let date = lastEntryDate {
                defaults.set(date, forKey: Keys.lastEntryDate)
            } else {
                defaults.removeObject(forKey: Keys.lastEntryDate)
            }
        }
    }

    @Published var entryCount: Int {
        didSet { defaults.set(entryCount, forKey: Keys.entryCount) }
    }

    @Published var photoCaptions: [PhotoCaption] {
        didSet { saveArray(photoCaptions, key: Keys.photoCaptions) }
    }

    @Published var journalEntries: [JournalEntry] {
        didSet { saveArray(journalEntries, key: Keys.journalEntries) }
    }

    @Published var photoJournalItems: [PhotoJournalItem] {
        didSet { saveArray(photoJournalItems, key: Keys.photoJournalItems) }
    }

    @Published var favoriteCollections: [String] {
        didSet { defaults.set(favoriteCollections, forKey: Keys.favoriteCollections) }
    }

    @Published var lastViewedCollection: String? {
        didSet {
            if let value = lastViewedCollection {
                defaults.set(value, forKey: Keys.lastViewedCollection)
            } else {
                defaults.removeObject(forKey: Keys.lastViewedCollection)
            }
        }
    }

    @Published var itemsAdded: Int {
        didSet { defaults.set(itemsAdded, forKey: Keys.itemsAdded) }
    }

    @Published var entriesWritten: Int {
        didSet { defaults.set(entriesWritten, forKey: Keys.entriesWritten) }
    }

    @Published var favouritesCount: Int {
        didSet { defaults.set(favouritesCount, forKey: Keys.favouritesCount) }
    }

    @Published var userAlbums: [UserAlbum] {
        didSet { saveArray(userAlbums, key: Keys.userAlbums) }
    }

    @Published var newlyUnlockedAchievement: AchievementDefinition?

    private var pendingAchievementQueue: [AchievementDefinition] = []
    private var isShowingAchievementBanner = false

    private init() {
        hasSeenOnboarding = defaults.bool(forKey: Keys.hasSeenOnboarding)
        totalSessionsCompleted = defaults.integer(forKey: Keys.totalSessionsCompleted)
        totalMinutesUsed = defaults.integer(forKey: Keys.totalMinutesUsed)
        streakDays = defaults.integer(forKey: Keys.streakDays)
        lastActivityDate = defaults.object(forKey: Keys.lastActivityDate) as? Date
        achievementsUnlocked = Self.loadDateDictionary(key: Keys.achievementsUnlocked, defaults: defaults)
        curatedEntries = Self.loadArray(key: Keys.curatedEntries, defaults: defaults) ?? []
        lastEntryDate = defaults.object(forKey: Keys.lastEntryDate) as? Date
        entryCount = defaults.integer(forKey: Keys.entryCount)
        photoCaptions = Self.loadArray(key: Keys.photoCaptions, defaults: defaults) ?? []
        journalEntries = Self.loadArray(key: Keys.journalEntries, defaults: defaults) ?? []
        photoJournalItems = Self.loadArray(key: Keys.photoJournalItems, defaults: defaults) ?? []
        favoriteCollections = defaults.stringArray(forKey: Keys.favoriteCollections) ?? []
        lastViewedCollection = defaults.string(forKey: Keys.lastViewedCollection)
        itemsAdded = defaults.integer(forKey: Keys.itemsAdded)
        entriesWritten = defaults.integer(forKey: Keys.entriesWritten)
        favouritesCount = defaults.integer(forKey: Keys.favouritesCount)
        userAlbums = Self.loadArray(key: Keys.userAlbums, defaults: defaults) ?? []

        if entryCount == 0 {
            entryCount = curatedEntries.count
        }
    }

    var discoverCollections: [DiscoverCollection] {
        DiscoverSampleData.collections
    }

    // MARK: - Search & filter

    func filteredCuratedEntries(
        search: String,
        pinnedOnly: Bool,
        tag: String?
    ) -> [CuratedEntry] {
        curatedEntries.filter { entry in
            if pinnedOnly, !entry.isPinned { return false }
            if let tag, !entry.tags.contains(tag) { return false }
            let query = search.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
            guard !query.isEmpty else { return true }
            return entry.title.lowercased().contains(query)
                || entry.icon.contains(query)
                || entry.description.lowercased().contains(query)
                || entry.tags.contains(where: { $0.contains(query) })
        }
    }

    func filteredJournalItems(search: String, favoritesOnly: Bool) -> [PhotoJournalItem] {
        photoJournalItems.filter { item in
            if favoritesOnly, !item.isFavorite { return false }
            let query = search.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
            guard !query.isEmpty else { return true }
            let caption = caption(for: item.id).lowercased()
            let journal = self.journal(for: item.id).lowercased()
            return item.title.lowercased().contains(query)
                || caption.contains(query)
                || journal.contains(query)
                || item.tags.contains(where: { $0.contains(query) })
        }
    }

    func filteredDiscoverCollections(search: String, favoritesOnly: Bool) -> [DiscoverCollection] {
        discoverCollections.filter { collection in
            if favoritesOnly, !isFavorite(collectionID: collection.id) { return false }
            let query = search.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
            guard !query.isEmpty else { return true }
            return collection.title.lowercased().contains(query)
                || collection.themeLabel.lowercased().contains(query)
        }
    }

    func allCuratedTags() -> [String] {
        Array(Set(curatedEntries.flatMap(\.tags))).sorted()
    }

    func popularTags(limit: Int = 12) -> [(tag: String, count: Int)] {
        var counts: [String: Int] = [:]
        for tag in curatedEntries.flatMap(\.tags) {
            counts[tag, default: 0] += 1
        }
        for entry in journalEntries {
            for tag in entry.tags {
                counts[tag, default: 0] += 1
            }
        }
        for item in photoJournalItems {
            for tag in item.tags {
                counts[tag, default: 0] += 1
            }
        }
        return counts
            .sorted { $0.value > $1.value }
            .prefix(limit)
            .map { ($0.key, $0.value) }
    }

    // MARK: - Stats

    func activityCounts(lastDays: Int = 7) -> [ActivityDayCount] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        var dayCounts: [Date: Int] = [:]

        for dayOffset in 0..<lastDays {
            guard let day = calendar.date(byAdding: .day, value: -dayOffset, to: today) else { continue }
            dayCounts[day] = 0
        }

        func bump(_ date: Date) {
            let day = calendar.startOfDay(for: date)
            guard dayCounts[day] != nil else { return }
            dayCounts[day, default: 0] += 1
        }

        for entry in curatedEntries { bump(entry.createdAt) }
        for item in photoJournalItems { bump(item.createdAt) }
        for caption in photoCaptions { bump(caption.date) }
        for journal in journalEntries { bump(journal.date) }

        return dayCounts
            .map { ActivityDayCount(date: $0.key, count: $0.value) }
            .sorted { $0.date < $1.date }
    }

    func mostUsedEmoji() -> (emoji: String, count: Int)? {
        var counts: [String: Int] = [:]
        for entry in curatedEntries {
            counts[entry.icon, default: 0] += 1
        }
        return counts.max(by: { $0.value < $1.value }).map { ($0.key, $0.value) }
    }

    func topDiscoverCollectionTitle() -> String? {
        guard !favoriteCollections.isEmpty else { return nil }
        var counts: [String: Int] = [:]
        for id in favoriteCollections {
            counts[id, default: 0] += 1
        }
        guard let topID = counts.max(by: { $0.value < $1.value })?.key else { return nil }
        return discoverCollections.first(where: { $0.id == topID })?.title
    }

    func activeCalendarDates(for month: Date) -> Set<Date> {
        let calendar = Calendar.current
        guard let interval = calendar.dateInterval(of: .month, for: month) else { return [] }
        var dates = Set<Date>()
        func add(_ date: Date) {
            let day = calendar.startOfDay(for: date)
            if interval.contains(day) { dates.insert(day) }
        }
        for entry in curatedEntries { add(entry.createdAt) }
        for item in photoJournalItems { add(item.createdAt) }
        for caption in photoCaptions { add(caption.date) }
        for journal in journalEntries { add(journal.date) }
        if let lastEntryDate { add(lastEntryDate) }
        return dates
    }

    func timelineItems(on day: Date) -> [TimelineItem] {
        let calendar = Calendar.current
        let target = calendar.startOfDay(for: day)
        var items: [TimelineItem] = []

        for entry in curatedEntries where calendar.isDate(entry.createdAt, inSameDayAs: target) {
            items.append(TimelineItem(
                id: "c-\(entry.id.uuidString)",
                date: entry.createdAt,
                title: entry.title,
                subtitle: entry.description.isEmpty ? "Curated entry" : entry.description,
                glyph: entry.icon,
                isSymbol: false,
                kind: "Gallery"
            ))
        }

        for item in photoJournalItems where calendar.isDate(item.createdAt, inSameDayAs: target) {
            let caption = self.caption(for: item.id)
            let journal = self.journal(for: item.id)
            items.append(TimelineItem(
                id: "j-\(item.id.uuidString)",
                date: item.createdAt,
                title: item.title,
                subtitle: journal.isEmpty ? caption : journal,
                glyph: item.symbolName,
                isSymbol: true,
                kind: "Journal"
            ))
        }

        for caption in photoCaptions where calendar.isDate(caption.date, inSameDayAs: target) {
            guard !items.contains(where: { $0.id == "cap-\(caption.photoID.uuidString)" }) else { continue }
            if let item = photoJournalItems.first(where: { $0.id == caption.photoID }) {
                items.append(TimelineItem(
                    id: "cap-\(caption.photoID.uuidString)",
                    date: caption.date,
                    title: item.title,
                    subtitle: caption.text,
                    glyph: item.symbolName,
                    isSymbol: true,
                    kind: "Caption"
                ))
            }
        }

        return items.sorted { $0.date > $1.date }
    }

    // MARK: - Curated

    func completeOnboarding() {
        hasSeenOnboarding = true
        recordSessionCompleted(minutes: 1)
    }

    func recordSessionCompleted(minutes: Int = 1) {
        totalSessionsCompleted += 1
        totalMinutesUsed += minutes
        updateStreak()
        checkAchievements()
    }

    func recordMeaningfulActivity() {
        updateStreak()
        checkAchievements()
    }

    func addCuratedEntry(_ entry: CuratedEntry) {
        curatedEntries.append(entry)
        itemsAdded += 1
        lastEntryDate = Date()
        recordMeaningfulActivity()
        checkAchievements()
    }

    func updateCuratedEntry(_ entry: CuratedEntry) {
        guard let index = curatedEntries.firstIndex(where: { $0.id == entry.id }) else { return }
        curatedEntries[index] = entry
        recordMeaningfulActivity()
    }

    func deleteCuratedEntry(id: UUID) {
        curatedEntries.removeAll { $0.id == id }
        removeReferenceToCurated(id: id)
        recordMeaningfulActivity()
    }

    func toggleCuratedPin(id: UUID) {
        guard let index = curatedEntries.firstIndex(where: { $0.id == id }) else { return }
        curatedEntries[index].isPinned.toggle()
        recordMeaningfulActivity()
    }

    func moveCuratedEntries(from source: IndexSet, to destination: Int) {
        var list = curatedEntries
        guard !source.isEmpty, destination >= 0, destination <= list.count else { return }

        let moving = source.sorted().map { list[$0] }
        for index in source.sorted().reversed() {
            list.remove(at: index)
        }

        var target = destination
        for index in source where index < destination {
            target -= 1
        }

        for (offset, item) in moving.enumerated() {
            list.insert(item, at: target + offset)
        }
        curatedEntries = list
    }

    // MARK: - Journal

    func addPhotoJournalItem(_ item: PhotoJournalItem, imageData: Data) {
        var entry = item
        if let jpeg = PhotoImageStore.preparedJPEG(from: imageData),
           let fileName = PhotoImageStore.saveJPEG(jpeg, itemID: item.id) {
            entry.imageFileName = fileName
        }
        photoJournalItems.append(entry)
        itemsAdded += 1
        recordMeaningfulActivity()
        checkAchievements()
    }

    func updatePhotoJournalItem(_ item: PhotoJournalItem) {
        guard let index = photoJournalItems.firstIndex(where: { $0.id == item.id }) else { return }
        photoJournalItems[index] = item
        recordMeaningfulActivity()
    }

    func replacePhotoJournalImage(id: UUID, imageData: Data) {
        guard let index = photoJournalItems.firstIndex(where: { $0.id == id }) else { return }
        guard let jpeg = PhotoImageStore.preparedJPEG(from: imageData),
              let fileName = PhotoImageStore.saveJPEG(jpeg, itemID: id) else { return }
        var item = photoJournalItems[index]
        if let old = item.imageFileName, old != fileName {
            PhotoImageStore.delete(fileName: old)
        }
        item.imageFileName = fileName
        photoJournalItems[index] = item
        recordMeaningfulActivity()
    }

    func deletePhotoJournalItem(id: UUID) {
        if let item = photoJournalItems.first(where: { $0.id == id }),
           let fileName = item.imageFileName {
            PhotoImageStore.delete(fileName: fileName)
        }
        photoJournalItems.removeAll { $0.id == id }
        photoCaptions.removeAll { $0.photoID == id }
        journalEntries.removeAll { $0.photoID == id }
        removeReferenceToJournal(id: id)
        recordMeaningfulActivity()
    }

    func toggleJournalFavorite(id: UUID) {
        guard let index = photoJournalItems.firstIndex(where: { $0.id == id }) else { return }
        photoJournalItems[index].isFavorite.toggle()
        recordMeaningfulActivity()
    }

    func saveCaption(photoID: UUID, text: String) {
        if let index = photoCaptions.firstIndex(where: { $0.photoID == photoID }) {
            photoCaptions[index].text = text
            photoCaptions[index].date = Date()
        } else {
            photoCaptions.append(PhotoCaption(photoID: photoID, text: text))
        }
        recordMeaningfulActivity()
    }

    func saveJournal(photoID: UUID, content: String, tags: [String]) {
        let trimmed = content.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        if let index = journalEntries.firstIndex(where: { $0.photoID == photoID }) {
            let wasEmpty = journalEntries[index].content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            journalEntries[index].content = trimmed
            journalEntries[index].date = Date()
            journalEntries[index].tags = tags
            if wasEmpty {
                entriesWritten += 1
            }
        } else {
            journalEntries.append(JournalEntry(photoID: photoID, content: trimmed, tags: tags))
            entriesWritten += 1
        }

        if let itemIndex = photoJournalItems.firstIndex(where: { $0.id == photoID }) {
            var merged = Set(photoJournalItems[itemIndex].tags)
            tags.forEach { merged.insert($0) }
            photoJournalItems[itemIndex].tags = Array(merged).sorted()
        }

        recordMeaningfulActivity()
        checkAchievements()
    }

    func caption(for photoID: UUID) -> String {
        photoCaptions.first(where: { $0.photoID == photoID })?.text ?? ""
    }

    func journal(for photoID: UUID) -> String {
        journalEntries.first(where: { $0.photoID == photoID })?.content ?? ""
    }

    func journalTags(for photoID: UUID) -> [String] {
        if let entry = journalEntries.first(where: { $0.photoID == photoID }) {
            return entry.tags
        }
        return photoJournalItems.first(where: { $0.id == photoID })?.tags ?? []
    }

    // MARK: - Discover

    func toggleFavorite(collectionID: String) {
        if favoriteCollections.contains(collectionID) {
            favoriteCollections.removeAll { $0 == collectionID }
        } else {
            favoriteCollections.append(collectionID)
            favouritesCount += 1
            recordMeaningfulActivity()
            checkAchievements()
        }
    }

    func isFavorite(collectionID: String) -> Bool {
        favoriteCollections.contains(collectionID)
    }

    // MARK: - User albums

    func addAlbum(title: String) {
        let trimmed = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        userAlbums.append(UserAlbum(title: trimmed))
        recordMeaningfulActivity()
    }

    func deleteAlbum(id: UUID) {
        userAlbums.removeAll { $0.id == id }
    }

    func renameAlbum(id: UUID, title: String) {
        guard let index = userAlbums.firstIndex(where: { $0.id == id }) else { return }
        let trimmed = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        userAlbums[index].title = trimmed
    }

    func addToAlbum(albumID: UUID, ref: AlbumItemRef) {
        guard let index = userAlbums.firstIndex(where: { $0.id == albumID }) else { return }
        guard !userAlbums[index].itemRefs.contains(ref) else { return }
        userAlbums[index].itemRefs.append(ref)
        recordMeaningfulActivity()
    }

    func removeFromAlbum(albumID: UUID, ref: AlbumItemRef) {
        guard let index = userAlbums.firstIndex(where: { $0.id == albumID }) else { return }
        userAlbums[index].itemRefs.removeAll { $0 == ref }
    }

    func moveAlbumItems(albumID: UUID, from source: IndexSet, to destination: Int) {
        guard let index = userAlbums.firstIndex(where: { $0.id == albumID }) else { return }
        var refs = userAlbums[index].itemRefs
        guard !source.isEmpty, destination >= 0, destination <= refs.count else { return }

        let moving = source.sorted().map { refs[$0] }
        for offset in source.sorted().reversed() {
            refs.remove(at: offset)
        }
        var target = destination
        for offset in source where offset < destination {
            target -= 1
        }
        for (i, ref) in moving.enumerated() {
            refs.insert(ref, at: target + i)
        }
        userAlbums[index].itemRefs = refs
    }

    func resolveAlbumRef(_ ref: AlbumItemRef) -> (title: String, glyph: String, isSymbol: Bool)? {
        switch ref.kind {
        case .curated:
            guard let entry = curatedEntries.first(where: { $0.id == ref.referenceID }) else { return nil }
            return (entry.title, entry.icon, false)
        case .journal:
            guard let item = photoJournalItems.first(where: { $0.id == ref.referenceID }) else { return nil }
            return (item.title, item.symbolName, true)
        }
    }

    private func removeReferenceToCurated(id: UUID) {
        for index in userAlbums.indices {
            userAlbums[index].itemRefs.removeAll {
                $0.kind == .curated && $0.referenceID == id
            }
        }
    }

    private func removeReferenceToJournal(id: UUID) {
        for index in userAlbums.indices {
            userAlbums[index].itemRefs.removeAll {
                $0.kind == .journal && $0.referenceID == id
            }
        }
    }

    // MARK: - Reset

    func resetAllData() {
        let domain = Bundle.main.bundleIdentifier ?? ""
        defaults.removePersistentDomain(forName: domain)
        defaults.synchronize()

        hasSeenOnboarding = false
        totalSessionsCompleted = 0
        totalMinutesUsed = 0
        streakDays = 0
        lastActivityDate = nil
        achievementsUnlocked = [:]
        curatedEntries = []
        lastEntryDate = nil
        entryCount = 0
        photoCaptions = []
        journalEntries = []
        photoJournalItems = []
        PhotoImageStore.deleteAll()
        favoriteCollections = []
        lastViewedCollection = nil
        itemsAdded = 0
        entriesWritten = 0
        favouritesCount = 0
        userAlbums = []
        newlyUnlockedAchievement = nil
        pendingAchievementQueue = []
        isShowingAchievementBanner = false

        NotificationCenter.default.post(name: .dataReset, object: nil)
    }

    func checkAchievements() {
        for achievement in AchievementCatalog.all {
            guard achievementsUnlocked[achievement.id] == nil else { continue }
            guard achievement.isUnlocked(self) else { continue }
            unlockAchievement(achievement)
        }
    }

    private func unlockAchievement(_ achievement: AchievementDefinition) {
        achievementsUnlocked[achievement.id] = Date()
        FeedbackManager.achievementUnlocked()
        if isShowingAchievementBanner {
            pendingAchievementQueue.append(achievement)
        } else {
            showAchievementBanner(achievement)
        }
    }

    func dismissAchievementBanner() {
        isShowingAchievementBanner = false
        newlyUnlockedAchievement = nil
        if let next = pendingAchievementQueue.first {
            pendingAchievementQueue.removeFirst()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) { [weak self] in
                self?.showAchievementBanner(next)
            }
        }
    }

    private func showAchievementBanner(_ achievement: AchievementDefinition) {
        isShowingAchievementBanner = true
        newlyUnlockedAchievement = achievement
    }

    private func updateStreak() {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())

        if let last = lastActivityDate {
            let lastDay = calendar.startOfDay(for: last)
            if lastDay == today {
                return
            }
            if let yesterday = calendar.date(byAdding: .day, value: -1, to: today),
               lastDay == yesterday {
                streakDays += 1
            } else {
                streakDays = 1
            }
        } else {
            streakDays = 1
        }
        lastActivityDate = Date()
    }

    private func saveArray<T: Encodable>(_ value: T, key: String) {
        guard let data = try? encoder.encode(value) else { return }
        defaults.set(data, forKey: key)
    }

    private func saveDictionary(_ value: [String: Date], key: String) {
        let strings = value.mapValues { $0.timeIntervalSince1970 }
        guard let data = try? encoder.encode(strings) else { return }
        defaults.set(data, forKey: key)
    }

    private static func loadArray<T: Decodable>(key: String, defaults: UserDefaults) -> T? {
        guard let data = defaults.data(forKey: key) else { return nil }
        return try? JSONDecoder().decode(T.self, from: data)
    }

    private static func loadDateDictionary(key: String, defaults: UserDefaults) -> [String: Date] {
        guard let data = defaults.data(forKey: key),
              let raw = try? JSONDecoder().decode([String: TimeInterval].self, from: data) else {
            return [:]
        }
        return raw.mapValues { Date(timeIntervalSince1970: $0) }
    }
}

enum DiscoverSampleData {
    static let collections: [DiscoverCollection] = [
        DiscoverCollection(
            id: "nature",
            title: "Nature",
            themeLabel: "Nature",
            symbolName: "leaf.fill",
            items: [
                CollectionItem(id: "n1", title: "Forest Light", symbolName: "tree.fill"),
                CollectionItem(id: "n2", title: "Mountain Dawn", symbolName: "mountain.2.fill"),
                CollectionItem(id: "n3", title: "River Calm", symbolName: "water.waves")
            ]
        ),
        DiscoverCollection(
            id: "urban",
            title: "Urban",
            themeLabel: "Urban",
            symbolName: "building.2.fill",
            items: [
                CollectionItem(id: "u1", title: "City Nights", symbolName: "moon.stars.fill"),
                CollectionItem(id: "u2", title: "Street Lines", symbolName: "road.lanes"),
                CollectionItem(id: "u3", title: "Metro Glow", symbolName: "tram.fill")
            ]
        ),
        DiscoverCollection(
            id: "vintage",
            title: "Vintage",
            themeLabel: "Vintage",
            symbolName: "camera.fill",
            items: [
                CollectionItem(id: "v1", title: "Sepia Days", symbolName: "photo.artframe"),
                CollectionItem(id: "v2", title: "Classic Frames", symbolName: "rectangle.on.rectangle"),
                CollectionItem(id: "v3", title: "Retro Glow", symbolName: "sparkles")
            ]
        )
    ]
}
