import SwiftUI
import UIKit

// MARK: - Tab bar height (passed from MainTabView)

enum TabBarHeightPreferenceKey: PreferenceKey {
    static var defaultValue: CGFloat = TabBarMetrics.fallbackHeight

    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = max(value, nextValue())
    }
}

enum TabBarMetrics {
    /// Approximate height until CustomTabBar measures itself.
    static let fallbackHeight: CGFloat = 88
}

private struct TabBarBottomInsetKey: EnvironmentKey {
    static let defaultValue: CGFloat = 0
}

extension EnvironmentValues {
    var tabBarBottomInset: CGFloat {
        get { self[TabBarBottomInsetKey.self] }
        set { self[TabBarBottomInsetKey.self] = newValue }
    }
}

/// UIKit + SwiftUI chrome so system layers do not paint black over `LayeredBackground`.
enum AppChromeConfiguration {
    static let tabBarScrollBottomMargin: CGFloat = 12

    static func applyIfNeeded() {
        guard !didApply else { return }
        didApply = true

        let nav = UINavigationBarAppearance()
        nav.configureWithTransparentBackground()
        nav.backgroundColor = .clear
        nav.shadowColor = .clear

        let bar = UINavigationBar.appearance()
        bar.standardAppearance = nav
        bar.scrollEdgeAppearance = nav
        bar.compactAppearance = nav
        bar.isTranslucent = true

        UITableView.appearance().backgroundColor = .clear
        UICollectionView.appearance().backgroundColor = .clear
        UIScrollView.appearance().backgroundColor = .clear

        applyWindowBackground()
    }

    static func applyWindowBackground() {
        let uiColor = UIColor(named: "AppBackground")
            ?? UIColor(red: 0.22, green: 0.26, blue: 0.45, alpha: 1)
        DispatchQueue.main.async {
            for scene in UIApplication.shared.connectedScenes {
                guard let windowScene = scene as? UIWindowScene else { continue }
                for window in windowScene.windows {
                    window.backgroundColor = uiColor
                }
            }
        }
    }

    private static var didApply = false
}

extension View {
    /// Transparent navigation bar (use with `ZStack { LayeredBackground(); … }` on each screen).
    func transparentNavigationBar() -> some View {
        toolbarBackground(.hidden, for: .navigationBar)
    }

    /// Scroll on tab screens: clear system background + bottom margin for tab bar.
    func tabScrollContent() -> some View {
        modifier(TabScrollContentModifier())
    }

    /// Pins a bottom action bar above CustomTabBar (use for FloatingAddButton).
    func tabBarFloatingInset<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        modifier(TabBarFloatingInsetModifier(floatingContent: AnyView(content())))
    }
}

private struct TabScrollContentModifier: ViewModifier {
    @Environment(\.tabBarBottomInset) private var tabBarBottomInset

    func body(content: Content) -> some View {
        content
            .scrollContentBackground(.hidden)
            .contentMargins(
                .bottom,
                tabBarBottomInset + AppChromeConfiguration.tabBarScrollBottomMargin,
                for: .scrollContent
            )
    }
}

private struct TabBarFloatingInsetModifier: ViewModifier {
    @Environment(\.tabBarBottomInset) private var tabBarBottomInset
    let floatingContent: AnyView

    func body(content: Content) -> some View {
        content
            .safeAreaInset(edge: .bottom, spacing: 8) {
                floatingContent
                    .padding(.bottom, tabBarBottomInset)
            }
    }
}
