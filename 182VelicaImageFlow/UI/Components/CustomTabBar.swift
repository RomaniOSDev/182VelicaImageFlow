import SwiftUI

enum MainTab: Int, CaseIterable, Identifiable {
    case home
    case gallery
    case media
    case insights
    case settings

    var id: Int { rawValue }

    var title: String {
        switch self {
        case .home: return "Home"
        case .gallery: return "Gallery"
        case .media: return "Journal"
        case .insights: return "Insights"
        case .settings: return "Settings"
        }
    }

    var icon: String {
        switch self {
        case .home: return "house.fill"
        case .gallery: return "square.grid.2x2.fill"
        case .media: return "book.fill"
        case .insights: return "chart.bar.fill"
        case .settings: return "gearshape.fill"
        }
    }
}

struct CustomTabBar: View {
    @Binding var selection: MainTab

    var body: some View {
        HStack(spacing: 6) {
            ForEach(MainTab.allCases) { tab in
                tabButton(tab)
            }
        }
        .padding(8)
        .background {
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [
                            Color("AppSurface").opacity(0.72),
                            Color("AppSurface").opacity(0.48)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay {
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .strokeBorder(
                            LinearGradient(
                                colors: [
                                    Color("AppPrimary").opacity(0.45),
                                    Color("AppTextSecondary").opacity(0.1)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1
                        )
                }
                .shadow(color: Color("AppPrimary").opacity(0.22), radius: 14, y: -5)
        }
        .padding(.horizontal, 14)
        .padding(.top, 6)
        .padding(.bottom, 4)
    }

    private func tabButton(_ tab: MainTab) -> some View {
        let isSelected = selection == tab
        return Button {
            FeedbackManager.tapLight()
            var transaction = Transaction()
            transaction.disablesAnimations = true
            withTransaction(transaction) {
                selection = tab
            }
        } label: {
            VStack(spacing: 5) {
                ZStack {
                    if isSelected {
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .fill(AppGradients.primaryButton)
                            .frame(width: 48, height: 36)
                            .shadow(color: Color("AppPrimary").opacity(0.45), radius: 8, y: 3)
                    }
                    Image(systemName: tab.icon)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(isSelected ? Color("AppBackground") : Color("AppTextSecondary"))
                }
                .frame(height: 36)
                Text(tab.title)
                    .font(.system(size: 9, weight: .bold))
                    .foregroundStyle(isSelected ? Color("AppPrimary") : Color("AppTextSecondary"))
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
            }
            .frame(maxWidth: .infinity)
            .frame(minHeight: 52)
        }
        .buttonStyle(TabPressStyle())
    }
}

private struct TabPressStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.94 : 1)
            .animation(.spring(response: 0.35, dampingFraction: 0.7), value: configuration.isPressed)
    }
}
