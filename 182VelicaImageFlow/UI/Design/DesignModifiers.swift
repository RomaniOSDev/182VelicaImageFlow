import SwiftUI

// MARK: - Shared gradients (static, no per-frame allocation)

enum AppGradients {
    static let screen = LinearGradient(
        colors: [
            Color("AppPrimary").opacity(0.42),
            Color("AppBackground"),
            Color("AppAccent").opacity(0.28),
            Color("AppSurface").opacity(0.5),
            Color("AppBackground")
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static let cardSurface = LinearGradient(
        colors: [
            Color("AppSurface").opacity(0.26),
            Color("AppSurface").opacity(0.14),
            Color("AppPrimary").opacity(0.1)
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static let cardHighlight = LinearGradient(
        colors: [
            Color("AppPrimary").opacity(0.45),
            Color("AppAccent").opacity(0.35),
            Color("AppTextSecondary").opacity(0.12)
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static let primaryButton = LinearGradient(
        colors: [Color("AppPrimary"), Color("AppAccent")],
        startPoint: .leading,
        endPoint: .trailing
    )

    static let glowOrb = RadialGradient(
        colors: [Color("AppPrimary").opacity(0.55), Color.clear],
        center: .center,
        startRadius: 0,
        endRadius: 140
    )

    static let accentOrb = RadialGradient(
        colors: [Color("AppAccent").opacity(0.45), Color.clear],
        center: .center,
        startRadius: 0,
        endRadius: 130
    )

    static let surfaceWash = RadialGradient(
        colors: [Color("AppAccent").opacity(0.2), Color.clear],
        center: .center,
        startRadius: 20,
        endRadius: 300
    )
}

// MARK: - Depth levels (single shadow per view — GPU-friendly)

enum DepthLevel {
    case standard
    case raised
    case floating

    var shadowRadius: CGFloat {
        switch self {
        case .standard: return 5
        case .raised: return 9
        case .floating: return 14
        }
    }

    var shadowY: CGFloat {
        switch self {
        case .standard: return 3
        case .raised: return 5
        case .floating: return 8
        }
    }

    var shadowOpacity: Double {
        switch self {
        case .standard: return 0.2
        case .raised: return 0.28
        case .floating: return 0.34
        }
    }
}

struct DepthCardBackground: View {
    let cornerRadius: CGFloat
    let level: DepthLevel
    var highlighted: Bool = false

    var body: some View {
        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
            .fill(AppGradients.cardSurface)
            .overlay(alignment: .top) {
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color("AppTextPrimary").opacity(0.07),
                                Color.clear
                            ],
                            startPoint: .top,
                            endPoint: .center
                        )
                    )
                    .frame(height: cornerRadius * 2)
                    .allowsHitTesting(false)
            }
            .overlay {
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .strokeBorder(AppGradients.cardHighlight, lineWidth: highlighted ? 1.5 : 1)
                    .opacity(highlighted ? 1 : 0.65)
            }
            .shadow(
                color: Color("AppBackground").opacity(level.shadowOpacity + 0.12),
                radius: level.shadowRadius,
                y: level.shadowY
            )
    }
}

struct AccentCardModifier: ViewModifier {
    var cornerRadius: CGFloat = 16
    var highlighted: Bool = false
    var level: DepthLevel = .standard

    func body(content: Content) -> some View {
        content
            .background {
                DepthCardBackground(
                    cornerRadius: cornerRadius,
                    level: highlighted ? .raised : level,
                    highlighted: highlighted
                )
            }
    }
}

extension View {
    func accentCard(
        cornerRadius: CGFloat = 16,
        highlighted: Bool = false,
        level: DepthLevel = .standard
    ) -> some View {
        modifier(AccentCardModifier(cornerRadius: cornerRadius, highlighted: highlighted, level: level))
    }

    func depthRaised(cornerRadius: CGFloat = 16) -> some View {
        accentCard(cornerRadius: cornerRadius, level: .raised)
    }

    func depthFloating(cornerRadius: CGFloat = 20) -> some View {
        accentCard(cornerRadius: cornerRadius, highlighted: true, level: .floating)
    }
}

// MARK: - Chrome

struct ScreenHeader: View {
    let title: String
    var subtitle: String?
    var trailingItems: AnyView?

    init(title: String, subtitle: String? = nil, @ViewBuilder trailing: () -> some View = { EmptyView() }) {
        self.title = title
        self.subtitle = subtitle
        self.trailingItems = AnyView(trailing())
    }

    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.title2.bold())
                    .foregroundStyle(Color("AppTextPrimary"))
                if let subtitle {
                    Text(subtitle)
                        .font(.caption)
                        .foregroundStyle(Color("AppTextSecondary"))
                }
            }
            Spacer(minLength: 0)
            trailingItems
        }
        .padding(.horizontal, 20)
        .padding(.top, 12)
        .padding(.bottom, 8)
    }
}

struct HeaderIconButton: View {
    let systemImage: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: systemImage)
                .font(.body.weight(.semibold))
                .foregroundStyle(Color("AppPrimary"))
                .frame(width: 40, height: 40)
                .background {
                    DepthCardBackground(cornerRadius: 12, level: .standard)
                }
        }
        .buttonStyle(.plain)
    }
}

struct IconBadge: View {
    let content: String
    var isSymbol: Bool = false
    var size: CGFloat = 52

    var body: some View {
        ZStack {
            Circle()
                .fill(
                    LinearGradient(
                        colors: [
                            Color("AppPrimary").opacity(0.3),
                            Color("AppSurface"),
                            Color("AppBackground").opacity(0.6)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: size, height: size)
                .shadow(color: Color("AppPrimary").opacity(0.25), radius: 4, y: 2)
            if isSymbol {
                Image(systemName: content)
                    .font(.system(size: size * 0.38, weight: .semibold))
                    .foregroundStyle(Color("AppAccent"))
            } else {
                Text(content)
                    .font(.system(size: size * 0.46))
            }
        }
    }
}

struct EmptyStateView: View {
    let symbol: String
    let title: String
    let message: String
    var actionTitle: String?
    var action: (() -> Void)?

    var body: some View {
        VStack(spacing: 20) {
            ZStack {
                Circle()
                    .fill(AppGradients.cardSurface)
                    .frame(width: 100, height: 100)
                    .overlay {
                        Circle()
                            .strokeBorder(AppGradients.cardHighlight, lineWidth: 1)
                    }
                    .shadow(color: Color("AppPrimary").opacity(0.2), radius: 10, y: 5)
                Image(systemName: symbol)
                    .font(.system(size: 40))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Color("AppAccent"), Color("AppPrimary")],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            }
            Text(title)
                .font(.title3.bold())
                .foregroundStyle(Color("AppTextPrimary"))
            Text(message)
                .font(.subheadline)
                .foregroundStyle(Color("AppTextSecondary"))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
            if let actionTitle, let action {
                Button(actionTitle, action: action)
                    .buttonStyle(PrimaryButtonStyle())
                    .padding(.horizontal, 40)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 32)
    }
}

struct SectionTitle: View {
    let text: String

    var body: some View {
        HStack(spacing: 8) {
            RoundedRectangle(cornerRadius: 2, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [Color("AppPrimary"), Color("AppAccent")],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .frame(width: 3, height: 14)
            Text(text)
                .font(.subheadline.weight(.bold))
                .foregroundStyle(Color("AppTextSecondary"))
                .textCase(.uppercase)
                .tracking(0.6)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
