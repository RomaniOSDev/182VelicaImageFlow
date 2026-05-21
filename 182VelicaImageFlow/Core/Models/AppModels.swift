import Foundation

struct CuratedEntry: Identifiable, Codable, Equatable, Hashable {
    let id: UUID
    var title: String
    var icon: String
    var description: String
    var tags: [String]
    var isPinned: Bool
    var createdAt: Date

    private enum CodingKeys: String, CodingKey {
        case id, title, icon, description, tags, isPinned, createdAt
    }

    init(
        id: UUID = UUID(),
        title: String,
        icon: String,
        description: String,
        tags: [String] = [],
        isPinned: Bool = false,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.title = title
        self.icon = icon
        self.description = description
        self.tags = tags
        self.isPinned = isPinned
        self.createdAt = createdAt
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        title = try container.decode(String.self, forKey: .title)
        icon = try container.decode(String.self, forKey: .icon)
        description = try container.decode(String.self, forKey: .description)
        tags = try container.decodeIfPresent([String].self, forKey: .tags) ?? []
        isPinned = try container.decodeIfPresent(Bool.self, forKey: .isPinned) ?? false
        createdAt = try container.decodeIfPresent(Date.self, forKey: .createdAt) ?? Date()
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(title, forKey: .title)
        try container.encode(icon, forKey: .icon)
        try container.encode(description, forKey: .description)
        try container.encode(tags, forKey: .tags)
        try container.encode(isPinned, forKey: .isPinned)
        try container.encode(createdAt, forKey: .createdAt)
    }
}

struct PhotoCaption: Identifiable, Codable, Equatable {
    let id: UUID
    let photoID: UUID
    var text: String
    var date: Date

    init(id: UUID = UUID(), photoID: UUID, text: String, date: Date = Date()) {
        self.id = id
        self.photoID = photoID
        self.text = text
        self.date = date
    }
}

struct JournalEntry: Identifiable, Codable, Equatable {
    let id: UUID
    let photoID: UUID
    var content: String
    var date: Date
    var tags: [String]

    private enum CodingKeys: String, CodingKey {
        case id, photoID, content, date, tags
    }

    init(id: UUID = UUID(), photoID: UUID, content: String, date: Date = Date(), tags: [String] = []) {
        self.id = id
        self.photoID = photoID
        self.content = content
        self.date = date
        self.tags = tags
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        photoID = try container.decode(UUID.self, forKey: .photoID)
        content = try container.decode(String.self, forKey: .content)
        date = try container.decodeIfPresent(Date.self, forKey: .date) ?? Date()
        tags = try container.decodeIfPresent([String].self, forKey: .tags) ?? []
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(photoID, forKey: .photoID)
        try container.encode(content, forKey: .content)
        try container.encode(date, forKey: .date)
        try container.encode(tags, forKey: .tags)
    }
}

struct PhotoJournalItem: Identifiable, Codable, Equatable {
    let id: UUID
    var title: String
    var symbolName: String
    var accentHue: Double
    var imageFileName: String?
    var tags: [String]
    var isFavorite: Bool
    var createdAt: Date

    var hasDevicePhoto: Bool {
        imageFileName != nil
    }

    private enum CodingKeys: String, CodingKey {
        case id, title, symbolName, accentHue, imageFileName, tags, isFavorite, createdAt
    }

    init(
        id: UUID = UUID(),
        title: String,
        symbolName: String = "photo.fill",
        accentHue: Double,
        imageFileName: String? = nil,
        tags: [String] = [],
        isFavorite: Bool = false,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.title = title
        self.symbolName = symbolName
        self.accentHue = accentHue
        self.imageFileName = imageFileName
        self.tags = tags
        self.isFavorite = isFavorite
        self.createdAt = createdAt
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        title = try container.decode(String.self, forKey: .title)
        symbolName = try container.decodeIfPresent(String.self, forKey: .symbolName) ?? "photo.fill"
        accentHue = try container.decode(Double.self, forKey: .accentHue)
        imageFileName = try container.decodeIfPresent(String.self, forKey: .imageFileName)
        tags = try container.decodeIfPresent([String].self, forKey: .tags) ?? []
        isFavorite = try container.decodeIfPresent(Bool.self, forKey: .isFavorite) ?? false
        createdAt = try container.decodeIfPresent(Date.self, forKey: .createdAt) ?? Date()
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(title, forKey: .title)
        try container.encode(symbolName, forKey: .symbolName)
        try container.encode(accentHue, forKey: .accentHue)
        try container.encodeIfPresent(imageFileName, forKey: .imageFileName)
        try container.encode(tags, forKey: .tags)
        try container.encode(isFavorite, forKey: .isFavorite)
        try container.encode(createdAt, forKey: .createdAt)
    }
}

struct DiscoverCollection: Identifiable, Codable, Equatable, Hashable {
    let id: String
    var title: String
    var themeLabel: String
    var symbolName: String
    var items: [CollectionItem]
}

struct CollectionItem: Identifiable, Codable, Equatable, Hashable {
    let id: String
    var title: String
    var symbolName: String
}

struct AlbumItemRef: Identifiable, Codable, Equatable, Hashable {
    enum Kind: String, Codable {
        case curated
        case journal
    }

    let kind: Kind
    let referenceID: UUID

    var id: String { "\(kind.rawValue)-\(referenceID.uuidString)" }

    static func curated(_ id: UUID) -> AlbumItemRef {
        AlbumItemRef(kind: .curated, referenceID: id)
    }

    static func journal(_ id: UUID) -> AlbumItemRef {
        AlbumItemRef(kind: .journal, referenceID: id)
    }
}

struct UserAlbum: Identifiable, Codable, Equatable, Hashable {
    let id: UUID
    var title: String
    var itemRefs: [AlbumItemRef]
    var createdAt: Date

    init(id: UUID = UUID(), title: String, itemRefs: [AlbumItemRef] = [], createdAt: Date = Date()) {
        self.id = id
        self.title = title
        self.itemRefs = itemRefs
        self.createdAt = createdAt
    }
}

struct EntryTemplate: Identifiable {
    let id: String
    let title: String
    let icon: String
    let descriptionHint: String
    let suggestedTags: [String]
}

enum EntryTemplates {
    static let all: [EntryTemplate] = [
        EntryTemplate(
            id: "trip",
            title: "Trip",
            icon: "✈️",
            descriptionHint: "Where did you go and what stood out?",
            suggestedTags: ["travel", "trip"]
        ),
        EntryTemplate(
            id: "event",
            title: "Event",
            icon: "🎉",
            descriptionHint: "Describe the occasion and how it felt.",
            suggestedTags: ["event", "celebration"]
        ),
        EntryTemplate(
            id: "daily",
            title: "Daily",
            icon: "☀️",
            descriptionHint: "A small moment worth keeping from today.",
            suggestedTags: ["daily", "life"]
        )
    ]
}

struct TimelineItem: Identifiable {
    let id: String
    let date: Date
    let title: String
    let subtitle: String
    let glyph: String
    let isSymbol: Bool
    let kind: String
}

struct ActivityDayCount: Identifiable {
    let date: Date
    let count: Int
    var id: Date { date }
}

struct AchievementDefinition: Identifiable {
    let id: String
    let title: String
    let description: String
    let systemImage: String
    let isUnlocked: (MoodSyncDataStore) -> Bool
}

enum AchievementCatalog {
    static let all: [AchievementDefinition] = [
        AchievementDefinition(
            id: "first_step",
            title: "First Step",
            description: "Added your first item.",
            systemImage: "star.fill",
            isUnlocked: { $0.itemsAdded >= 1 }
        ),
        AchievementDefinition(
            id: "avid_collector",
            title: "Avid Collector",
            description: "Added ten items.",
            systemImage: "square.stack.3d.up.fill",
            isUnlocked: { $0.itemsAdded >= 10 }
        ),
        AchievementDefinition(
            id: "storyteller",
            title: "Storyteller",
            description: "Wrote ten entries in the journal.",
            systemImage: "book.fill",
            isUnlocked: { $0.entriesWritten >= 10 }
        ),
        AchievementDefinition(
            id: "fifty_favourites",
            title: "+50 Milestone",
            description: "'Favourited' fifty times.",
            systemImage: "heart.fill",
            isUnlocked: { $0.favouritesCount >= 50 }
        ),
        AchievementDefinition(
            id: "hundred_favourites",
            title: "+100 Enthusiast",
            description: "'Favourited' one hundred times.",
            systemImage: "heart.circle.fill",
            isUnlocked: { $0.favouritesCount >= 100 }
        ),
        AchievementDefinition(
            id: "dedicated_contributor",
            title: "Dedicated Contributor",
            description: "Wrote fifty journal entries.",
            systemImage: "pencil.and.list.clipboard",
            isUnlocked: { $0.entriesWritten >= 50 }
        ),
        AchievementDefinition(
            id: "gallery_curator",
            title: "Gallery Curator",
            description: "Added one hundred items.",
            systemImage: "photo.stack.fill",
            isUnlocked: { $0.itemsAdded >= 100 }
        ),
        AchievementDefinition(
            id: "reflective_writer",
            title: "Reflective Writer",
            description: "Wrote twenty-five journal entries.",
            systemImage: "text.book.closed.fill",
            isUnlocked: { $0.entriesWritten >= 25 }
        )
    ]
}

enum CuratedEmojiPicker {
    static let options = ["✨", "📷", "🌿", "🏙️", "🎨", "☀️", "🌊", "🎭", "📖", "🎵", "🍂", "🌸"]
}
