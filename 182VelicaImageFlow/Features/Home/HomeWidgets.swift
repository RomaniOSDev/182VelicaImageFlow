import SwiftUI

// MARK: - Feed model

enum HomeFeedItem: Identifiable {
    case gallery(CuratedEntry)
    case journal(PhotoJournalItem)

    var id: UUID {
        switch self {
        case .gallery(let entry): return entry.id
        case .journal(let item): return item.id
        }
    }

    var createdAt: Date {
        switch self {
        case .gallery(let entry): return entry.createdAt
        case .journal(let item): return item.createdAt
        }
    }

    var hasDevicePhoto: Bool {
        switch self {
        case .gallery: return false
        case .journal(let item): return item.hasDevicePhoto
        }
    }

    var kindLabel: String {
        switch self {
        case .gallery: return "Gallery"
        case .journal: return "Journal"
        }
    }

    var displayTitle: String {
        switch self {
        case .gallery(let entry): return entry.title
        case .journal(let item): return item.title
        }
    }
}

// MARK: - Section labels

struct HomeSectionHeader: View {
    let title: String
    var subtitle: String? = nil
    var actionTitle: String? = nil
    var action: (() -> Void)? = nil

    var body: some View {
        HStack(alignment: .firstTextBaseline) {
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(Color("AppTextPrimary"))
                if let subtitle {
                    Text(subtitle)
                        .font(.caption)
                        .foregroundStyle(Color("AppTextSecondary"))
                }
            }
            Spacer(minLength: 0)
            if let actionTitle, let action {
                Button(action: {
                    FeedbackManager.tapLight()
                    action()
                }) {
                    Text(actionTitle)
                        .font(.caption.weight(.bold))
                        .foregroundStyle(Color("AppPrimary"))
                }
            }
        }
    }
}

struct HomeKindPill: View {
    let text: String

    var body: some View {
        Text(text.uppercased())
            .font(.caption2.weight(.bold))
            .foregroundStyle(Color("AppPrimary"))
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(Color("AppSurface").opacity(0.85))
            .clipShape(Capsule())
    }
}

// MARK: - Greeting strip

struct HomeGreetingStrip: View {
    let streak: Int
    let itemsCount: Int
    let favourites: Int

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            VStack(alignment: .leading, spacing: 2) {
                Text(greetingLine)
                    .font(.caption.weight(.bold))
                    .foregroundStyle(Color("AppAccent"))
                Text("Your visual space")
                    .font(.title3.bold())
                    .foregroundStyle(Color("AppTextPrimary"))
                Text("Gallery moments and photo journal")
                    .font(.caption)
                    .foregroundStyle(Color("AppTextSecondary"))
            }
            HStack(spacing: 10) {
                statBadge(icon: "flame.fill", value: streak, label: "Streak")
                statBadge(icon: "square.stack.3d.up.fill", value: itemsCount, label: "Items")
                statBadge(icon: "heart.fill", value: favourites, label: "Saved")
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .accentCard(cornerRadius: 18)
    }

    private var greetingLine: String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 5..<12: return "GOOD MORNING"
        case 12..<17: return "GOOD AFTERNOON"
        case 17..<22: return "GOOD EVENING"
        default: return "GOOD NIGHT"
        }
    }

    private func statBadge(icon: String, value: Int, label: String) -> some View {
        VStack(spacing: 4) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.caption2.weight(.bold))
                    .foregroundStyle(Color("AppPrimary"))
                Text("\(value)")
                    .font(.subheadline.bold())
                    .foregroundStyle(Color("AppTextPrimary"))
            }
            Text(label)
                .font(.caption2)
                .foregroundStyle(Color("AppTextSecondary"))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .background(Color("AppSurface").opacity(0.25), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
    }
}

// MARK: - Icon-only quick actions

struct HomeQuickAction: Identifiable {
    let id: String
    let title: String
    let icon: String
}

struct HomeIconActionRow: View {
    let actions: [HomeQuickAction]
    let onTap: (HomeQuickAction) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HomeSectionHeader(
                title: "Quick actions",
                subtitle: "Add, open journal, or view insights"
            )
            HStack(spacing: 10) {
                ForEach(actions) { action in
                    Button {
                        onTap(action)
                    } label: {
                        VStack(spacing: 8) {
                            Image(systemName: action.icon)
                                .font(.title3.weight(.semibold))
                                .foregroundStyle(Color("AppPrimary"))
                            Text(action.title)
                                .font(.caption.weight(.bold))
                                .foregroundStyle(Color("AppTextPrimary"))
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .accentCard(cornerRadius: 14)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }
}

// MARK: - Featured hero

struct HomeFeaturedMoment: View {
    let item: HomeFeedItem

    var body: some View {
        ZStack(alignment: .bottomLeading) {
            visualContent
                .frame(maxWidth: .infinity)
                .frame(height: 220)
                .clipped()
            LinearGradient(
                colors: [Color.clear, Color("AppBackground").opacity(0.85)],
                startPoint: .center,
                endPoint: .bottom
            )
            VStack(alignment: .leading, spacing: 6) {
                HomeKindPill(text: item.kindLabel)
                HStack(spacing: 8) {
                    badgeIcon
                    Text(item.displayTitle)
                        .font(.subheadline.bold())
                        .foregroundStyle(Color("AppTextPrimary"))
                        .lineLimit(1)
                }
            }
            .padding(14)
        }
        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .strokeBorder(Color("AppPrimary").opacity(0.3), lineWidth: 1)
        }
    }

    @ViewBuilder
    private var visualContent: some View {
        switch item {
        case .gallery(let entry):
            ZStack {
                AppGradients.cardSurface
                Text(entry.icon)
                    .font(.system(size: 88))
            }
        case .journal(let photo):
            JournalPhotoView(item: photo, cornerRadius: 0, showsSymbolFallback: true)
        }
    }

    @ViewBuilder
    private var badgeIcon: some View {
        switch item {
        case .gallery(let entry):
            if entry.isPinned {
                Image(systemName: "pin.fill")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(Color("AppPrimary"))
            }
        case .journal(let photo):
            if photo.isFavorite {
                Image(systemName: "heart.fill")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(Color("AppPrimary"))
            }
        }
    }

}

// MARK: - Mosaic grid

struct HomeMosaicGrid: View {
    let items: [HomeFeedItem]
    let onTap: (HomeFeedItem) -> Void

    private let columns = [
        GridItem(.flexible(), spacing: 8),
        GridItem(.flexible(), spacing: 8),
        GridItem(.flexible(), spacing: 8)
    ]

    var body: some View {
        LazyVGrid(columns: columns, spacing: 8) {
            ForEach(items) { item in
                Button {
                    FeedbackManager.tapLight()
                    onTap(item)
                } label: {
                    HomeMosaicTile(item: item)
                }
                .buttonStyle(.plain)
            }
        }
    }
}

struct HomeMosaicTile: View {
    let item: HomeFeedItem

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ZStack(alignment: .topTrailing) {
                tileVisual
                statusBadge
                    .padding(6)
            }
            .aspectRatio(1, contentMode: .fit)
            .frame(maxWidth: .infinity)
            VStack(alignment: .leading, spacing: 2) {
                Text(item.kindLabel)
                    .font(.caption2.weight(.bold))
                    .foregroundStyle(Color("AppPrimary"))
                Text(item.displayTitle)
                    .font(.caption2)
                    .foregroundStyle(Color("AppTextPrimary"))
                    .lineLimit(1)
            }
            .padding(.horizontal, 6)
            .padding(.vertical, 6)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color("AppSurface").opacity(0.2))
        }
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .strokeBorder(Color("AppPrimary").opacity(0.22), lineWidth: 1)
        }
    }

    @ViewBuilder
    private var tileVisual: some View {
        switch item {
        case .gallery(let entry):
            ZStack {
                AppGradients.cardHighlight
                Text(entry.icon)
                    .font(.system(size: 36))
            }
        case .journal(let photo):
            JournalPhotoView(item: photo, cornerRadius: 0)
        }
    }

    @ViewBuilder
    private var statusBadge: some View {
        switch item {
        case .gallery(let entry):
            if entry.isPinned {
                Image(systemName: "pin.fill")
                    .font(.caption2.weight(.bold))
                    .foregroundStyle(Color("AppPrimary"))
                    .padding(5)
                    .background(Color("AppSurface").opacity(0.9))
                    .clipShape(Circle())
            }
        case .journal(let photo):
            if photo.isFavorite {
                Image(systemName: "heart.fill")
                    .font(.caption2.weight(.bold))
                    .foregroundStyle(Color("AppPrimary"))
                    .padding(5)
                    .background(Color("AppSurface").opacity(0.9))
                    .clipShape(Circle())
            }
        }
    }
}

// MARK: - Empty state

struct HomeEmptyVisual: View {
    let onAdd: () -> Void

    var body: some View {
        Button(action: onAdd) {
            ZStack {
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .fill(AppGradients.cardSurface)
                    .frame(height: 200)
                VStack(spacing: 12) {
                    Image(systemName: "photo.on.rectangle.angled")
                        .font(.system(size: 44))
                        .foregroundStyle(Color("AppAccent"))
                    Text("No moments yet")
                        .font(.headline)
                        .foregroundStyle(Color("AppTextPrimary"))
                    Text("Add a gallery entry or journal photo")
                        .font(.caption)
                        .foregroundStyle(Color("AppTextSecondary"))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 24)
                    Label("Tap to add", systemImage: "plus.circle.fill")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(Color("AppPrimary"))
                }
            }
            .overlay {
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .strokeBorder(Color("AppPrimary").opacity(0.25), lineWidth: 1)
            }
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Add your first moment")
    }
}
