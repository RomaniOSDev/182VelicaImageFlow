import SwiftUI

// MARK: - Gallery

struct CuratedEntryCell: View {
    let entry: CuratedEntry
    var highlighted: Bool = false
    var onEdit: (() -> Void)? = nil
    var onDelete: (() -> Void)? = nil

    var body: some View {
        HStack(spacing: 14) {
            IconBadge(content: entry.icon, size: 56)
            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 8) {
                    Text(entry.title)
                        .font(.headline)
                        .foregroundStyle(Color("AppTextPrimary"))
                        .lineLimit(1)
                    if entry.isPinned {
                        StatusPill(text: "Pinned", icon: "pin.fill", tint: Color("AppPrimary"))
                    }
                }
                if !entry.description.isEmpty {
                    Text(entry.description)
                        .font(.subheadline)
                        .foregroundStyle(Color("AppTextSecondary"))
                        .lineLimit(2)
                }
                if !entry.tags.isEmpty {
                    TagsRowView(tags: entry.tags)
                }
                Text(entry.createdAt, style: .date)
                    .font(.caption2)
                    .foregroundStyle(Color("AppTextSecondary").opacity(0.8))
            }
            Spacer(minLength: 0)
            if onEdit != nil || onDelete != nil {
                Menu {
                    if let onEdit {
                        Button {
                            onEdit()
                        } label: {
                            Label("Edit", systemImage: "pencil")
                        }
                    }
                    if let onDelete {
                        Button(role: .destructive) {
                            onDelete()
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                    }
                } label: {
                    Image(systemName: "ellipsis.circle.fill")
                        .font(.title3)
                        .foregroundStyle(Color("AppPrimary"))
                        .frame(width: 36, height: 36)
                }
            }
            Image(systemName: "chevron.right")
                .font(.caption.weight(.bold))
                .foregroundStyle(Color("AppPrimary"))
                .padding(10)
                .background(Color("AppBackground").opacity(0.5))
                .clipShape(Circle())
        }
        .padding(14)
        .accentCard(highlighted: highlighted)
    }
}

// MARK: - Discover

struct DiscoverCollectionCell: View {
    let collection: DiscoverCollection
    let isFavorite: Bool
    var onFavorite: () -> Void

    var body: some View {
        HStack(spacing: 0) {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [Color("AppAccent").opacity(0.35), Color("AppSurface")],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .frame(width: 6)
            HStack(spacing: 14) {
                ZStack {
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(Color("AppBackground").opacity(0.6))
                        .frame(width: 64, height: 64)
                    Image(systemName: collection.symbolName)
                        .font(.title2)
                        .foregroundStyle(Color("AppAccent"))
                }
                VStack(alignment: .leading, spacing: 6) {
                    Text(collection.title)
                        .font(.headline)
                        .foregroundStyle(Color("AppTextPrimary"))
                    Text(collection.themeLabel)
                        .font(.caption.weight(.medium))
                        .foregroundStyle(Color("AppTextSecondary"))
                    Text("\(collection.items.count) items")
                        .font(.caption2)
                        .foregroundStyle(Color("AppPrimary"))
                }
                Spacer(minLength: 0)
                Button(action: onFavorite) {
                    Image(systemName: isFavorite ? "heart.fill" : "heart")
                        .font(.title3)
                        .foregroundStyle(isFavorite ? Color("AppPrimary") : Color("AppTextSecondary"))
                        .frame(width: 44, height: 44)
                        .background(Color("AppBackground").opacity(0.45))
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)
            }
            .padding(14)
        }
        .accentCard()
    }
}

struct DiscoverItemCell: View {
    let item: CollectionItem

    var body: some View {
        HStack(spacing: 14) {
            IconBadge(content: item.symbolName, isSymbol: true, size: 44)
            Text(item.title)
                .font(.headline)
                .foregroundStyle(Color("AppTextPrimary"))
            Spacer(minLength: 0)
        }
        .padding(12)
        .accentCard(cornerRadius: 12)
    }
}

// MARK: - Journal

struct JournalEditorCard: View {
    let title: String
    @Binding var text: String
    let placeholder: String
    var lineLimit: ClosedRange<Int> = 2...6

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.caption.weight(.bold))
                .foregroundStyle(Color("AppTextSecondary"))
                .tracking(0.5)
            TextField(placeholder, text: $text, axis: .vertical)
                .lineLimit(lineLimit)
                .foregroundStyle(Color("AppTextPrimary"))
        }
        .padding(16)
        .accentCard(cornerRadius: 14)
    }
}

struct JournalThumbnailStrip: View {
    let items: [PhotoJournalItem]
    @Binding var selectedIndex: Int
    var onEdit: ((PhotoJournalItem) -> Void)? = nil
    var onDelete: ((PhotoJournalItem) -> Void)? = nil

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                ForEach(Array(items.enumerated()), id: \.element.id) { index, item in
                    Button {
                        FeedbackManager.tapLight()
                        selectedIndex = index
                    } label: {
                        VStack(spacing: 6) {
                            ZStack {
                                JournalPhotoView(item: item, cornerRadius: 12)
                                    .frame(width: 56, height: 56)
                                if item.isFavorite {
                                    Image(systemName: "star.fill")
                                        .font(.caption2)
                                        .foregroundStyle(Color("AppPrimary"))
                                        .offset(x: 18, y: -18)
                                }
                            }
                            Text(item.title)
                                .font(.caption2)
                                .foregroundStyle(selectedIndex == index ? Color("AppPrimary") : Color("AppTextSecondary"))
                                .lineLimit(1)
                        }
                        .padding(8)
                        .background(selectedIndex == index ? Color("AppPrimary").opacity(0.15) : Color.clear)
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .stroke(selectedIndex == index ? Color("AppPrimary") : Color.clear, lineWidth: 2)
                        )
                    }
                    .buttonStyle(.plain)
                    .contextMenu {
                        if let onEdit {
                            Button {
                                onEdit(item)
                            } label: {
                                Label("Edit", systemImage: "pencil")
                            }
                        }
                        if let onDelete {
                            Button(role: .destructive) {
                                onDelete(item)
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                        }
                    }
                }
            }
            .padding(.horizontal, 16)
        }
    }
}

// MARK: - Insights & Settings

struct MetricCell: View {
    let value: String
    let label: String
    let icon: String

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Image(systemName: icon)
                .font(.body.weight(.semibold))
                .foregroundStyle(Color("AppPrimary"))
            Text(value)
                .font(.title2.bold())
                .foregroundStyle(Color("AppAccent"))
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            Text(label)
                .font(.caption)
                .foregroundStyle(Color("AppTextSecondary"))
                .lineLimit(2)
                .minimumScaleFactor(0.7)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .accentCard(cornerRadius: 14)
    }
}

struct AchievementCell: View {
    let achievement: AchievementDefinition
    let unlocked: Bool

    var body: some View {
        VStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(unlocked ? Color("AppPrimary").opacity(0.2) : Color("AppBackground").opacity(0.5))
                    .frame(width: 48, height: 48)
                Image(systemName: achievement.systemImage)
                    .font(.title3)
                    .foregroundStyle(unlocked ? Color("AppPrimary") : Color("AppTextSecondary").opacity(0.45))
            }
            Text(achievement.title)
                .font(.subheadline.weight(.bold))
                .foregroundStyle(Color("AppTextPrimary"))
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .minimumScaleFactor(0.7)
            Text(achievement.description)
                .font(.caption2)
                .foregroundStyle(Color("AppTextSecondary"))
                .multilineTextAlignment(.center)
                .lineLimit(3)
                .minimumScaleFactor(0.7)
            if unlocked {
                StatusPill(text: "Unlocked", icon: "checkmark", tint: Color("AppAccent"))
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, minHeight: 150)
        .accentCard(cornerRadius: 14, highlighted: unlocked)
        .opacity(unlocked ? 1 : 0.72)
    }
}

struct SettingsActionCell: View {
    let title: String
    let icon: String
    var destructive: Bool = false

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill((destructive ? Color.red : Color("AppPrimary")).opacity(0.18))
                    .frame(width: 36, height: 36)
                Image(systemName: icon)
                    .font(.body.weight(.semibold))
                    .foregroundStyle(destructive ? .red : Color("AppPrimary"))
            }
            Text(title)
                .font(.body.weight(.semibold))
                .foregroundStyle(destructive ? .red : Color("AppTextPrimary"))
            Spacer(minLength: 0)
            if !destructive {
                Image(systemName: "chevron.right")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(Color("AppTextSecondary"))
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .frame(minHeight: 56)
    }
}

struct AlbumListCell: View {
    let album: UserAlbum

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [Color("AppPrimary").opacity(0.3), Color("AppSurface")],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 56, height: 56)
                Image(systemName: "rectangle.stack.fill")
                    .font(.title2)
                    .foregroundStyle(Color("AppPrimary"))
            }
            VStack(alignment: .leading, spacing: 4) {
                Text(album.title)
                    .font(.headline)
                    .foregroundStyle(Color("AppTextPrimary"))
                Text("\(album.itemRefs.count) items")
                    .font(.caption)
                    .foregroundStyle(Color("AppTextSecondary"))
            }
            Spacer(minLength: 0)
            Image(systemName: "chevron.right")
                .foregroundStyle(Color("AppPrimary"))
        }
        .padding(14)
        .accentCard()
    }
}

struct AlbumItemCell: View {
    let title: String
    let glyph: String
    let isSymbol: Bool

    var body: some View {
        HStack(spacing: 14) {
            IconBadge(content: glyph, isSymbol: isSymbol, size: 44)
            Text(title)
                .font(.headline)
                .foregroundStyle(Color("AppTextPrimary"))
            Spacer(minLength: 0)
        }
        .padding(12)
        .accentCard(cornerRadius: 12)
    }
}

struct TimelineActivityCell: View {
    let item: TimelineItem

    var body: some View {
        HStack(spacing: 14) {
            IconBadge(content: item.glyph, isSymbol: item.isSymbol, size: 44)
            VStack(alignment: .leading, spacing: 4) {
                Text(item.title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Color("AppTextPrimary"))
                Text(item.subtitle)
                    .font(.caption)
                    .foregroundStyle(Color("AppTextSecondary"))
                    .lineLimit(2)
            }
            Spacer(minLength: 0)
            StatusPill(text: item.kind, icon: nil, tint: Color("AppAccent"))
        }
        .padding(12)
        .accentCard(cornerRadius: 12)
    }
}

struct TemplatePickerCell: View {
    let template: EntryTemplate
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 10) {
                Text(template.icon)
                    .font(.system(size: 32))
                Text(template.title)
                    .font(.caption.weight(.bold))
                    .foregroundStyle(Color("AppTextPrimary"))
            }
            .frame(width: 96, height: 96)
            .accentCard(cornerRadius: 14, highlighted: isSelected)
        }
        .buttonStyle(.plain)
    }
}

struct StatusPill: View {
    let text: String
    var icon: String? = nil
    let tint: Color

    var body: some View {
        HStack(spacing: 4) {
            if let icon, !icon.isEmpty {
                Image(systemName: icon)
                    .font(.caption2.weight(.bold))
            }
            Text(text)
                .font(.caption2.weight(.bold))
        }
        .foregroundStyle(tint)
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(tint.opacity(0.15))
        .clipShape(Capsule())
    }
}

struct EntryHeroCard: View {
    let entry: CuratedEntry

    var body: some View {
        VStack(spacing: 20) {
            Text(entry.icon)
                .font(.system(size: 80))
            VStack(spacing: 8) {
                Text(entry.title)
                    .font(.largeTitle.bold())
                    .foregroundStyle(Color("AppTextPrimary"))
                    .multilineTextAlignment(.center)
                if entry.isPinned {
                    StatusPill(text: "Pinned", icon: "pin.fill", tint: Color("AppPrimary"))
                }
            }
            if !entry.description.isEmpty {
                Text(entry.description)
                    .font(.body)
                    .foregroundStyle(Color("AppTextSecondary"))
                    .multilineTextAlignment(.center)
            }
            TagsRowView(tags: entry.tags)
            Text(entry.createdAt.formatted(date: .abbreviated, time: .omitted))
                .font(.caption)
                .foregroundStyle(Color("AppTextSecondary"))
        }
        .padding(28)
        .frame(maxWidth: .infinity)
        .depthFloating(cornerRadius: 20)
    }
}

struct FloatingAddButton: View {
    let title: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 10) {
                Image(systemName: "plus.circle.fill")
                    .font(.title3)
                Text(title)
                    .font(.headline)
            }
            .foregroundStyle(Color("AppBackground"))
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(AppGradients.primaryButton)
                    .shadow(color: Color("AppPrimary").opacity(0.35), radius: 10, y: 5)
            }
        }
        .buttonStyle(.plain)
        .padding(.horizontal, 20)
        .padding(.vertical, 14)
    }
}
