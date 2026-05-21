import SwiftUI

struct OnboardingView: View {
    @EnvironmentObject private var store: MoodSyncDataStore
    @State private var page = 0

    private let pages: [OnboardingPage] = [
        OnboardingPage(
            step: 1,
            headline: "Welcome Guide",
            description: "Organize and personalize your media collection effortlessly.",
            symbols: ["square.grid.2x2.fill", "photo.stack.fill", "sparkles"],
            hues: [0.12, 0.52, 0.08],
            chips: ["Organize", "Curate", "Personal"]
        ),
        OnboardingPage(
            step: 2,
            headline: "Capture Moments",
            description: "Add descriptions and tags to your photos for easy recall.",
            symbols: ["camera.fill", "text.bubble.fill", "tag.fill"],
            hues: [0.55, 0.14, 0.72],
            chips: ["Caption", "Tags", "Recall"]
        ),
        OnboardingPage(
            step: 3,
            headline: "Start Your Journey",
            description: "Create your first photo note today.",
            symbols: ["book.fill", "heart.fill", "arrow.right.circle.fill"],
            hues: [0.02, 0.95, 0.42],
            chips: ["Journal", "Favourites", "Go"]
        )
    ]

    var body: some View {
        ZStack {
            LayeredBackground()
            VStack(spacing: 0) {
                topBar
                TabView(selection: $page) {
                    ForEach(Array(pages.enumerated()), id: \.offset) { index, item in
                        onboardingPage(item, isActive: page == index)
                            .tag(index)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .background(Color.clear)

                bottomPanel
            }
        }
    }

    private var topBar: some View {
        HStack {
            HStack(spacing: 6) {
                RoundedRectangle(cornerRadius: 2, style: .continuous)
                    .fill(AppGradients.primaryButton)
                    .frame(width: 3, height: 16)
                Text("STEP \(page + 1) OF \(pages.count)")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(Color("AppTextSecondary"))
                    .tracking(0.8)
            }
            Spacer(minLength: 0)
            Text("\(Int((Double(page + 1) / Double(pages.count)) * 100))%")
                .font(.caption.weight(.bold))
                .foregroundStyle(Color("AppPrimary"))
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background {
                    Capsule()
                        .fill(Color("AppSurface").opacity(0.8))
                        .overlay {
                            Capsule()
                                .strokeBorder(Color("AppPrimary").opacity(0.35), lineWidth: 1)
                        }
                }
        }
        .padding(.horizontal, 24)
        .padding(.top, 16)
        .padding(.bottom, 8)
    }

    private func onboardingPage(_ item: OnboardingPage, isActive: Bool) -> some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 22) {
                OnboardingVisualPanel(
                    symbols: item.symbols,
                    hues: item.hues,
                    animate: isActive
                )
                .frame(height: 260)
                .depthFloating(cornerRadius: 24)

                HStack(spacing: 8) {
                    ForEach(item.chips, id: \.self) { chip in
                        Text(chip)
                            .font(.caption2.weight(.bold))
                            .foregroundStyle(Color("AppBackground"))
                            .padding(.horizontal, 12)
                            .padding(.vertical, 7)
                            .background {
                                Capsule()
                                    .fill(AppGradients.primaryButton)
                                    .shadow(color: Color("AppPrimary").opacity(0.25), radius: 3, y: 2)
                            }
                    }
                }

                VStack(spacing: 14) {
                    Text(item.headline)
                        .font(.largeTitle.bold())
                        .foregroundStyle(Color("AppTextPrimary"))
                        .multilineTextAlignment(.center)
                    Text(item.description)
                        .font(.body)
                        .foregroundStyle(Color("AppTextSecondary"))
                        .multilineTextAlignment(.center)
                        .lineSpacing(4)
                }
                .padding(22)
                .frame(maxWidth: .infinity)
                .depthRaised(cornerRadius: 18)
            }
            .padding(.horizontal, 20)
            .padding(.top, 8)
            .padding(.bottom, 16)
        }
        .scrollContentBackground(.hidden)
    }

    private var bottomPanel: some View {
        VStack(spacing: 20) {
            HStack(spacing: 10) {
                ForEach(0..<pages.count, id: \.self) { index in
                    Capsule()
                        .fill(
                            index == page
                                ? AnyShapeStyle(AppGradients.primaryButton)
                                : AnyShapeStyle(Color("AppTextSecondary").opacity(0.3))
                        )
                        .frame(width: index == page ? 28 : 8, height: 8)
                        .shadow(
                            color: index == page ? Color("AppPrimary").opacity(0.4) : Color.clear,
                            radius: 4,
                            y: 2
                        )
                        .animation(.spring(response: 0.4, dampingFraction: 0.7), value: page)
                }
            }

            Button(action: advance) {
                HStack(spacing: 10) {
                    Text(page < pages.count - 1 ? "Next" : "Get Started")
                    Image(systemName: page < pages.count - 1 ? "arrow.right" : "checkmark.circle.fill")
                        .font(.body.weight(.semibold))
                }
                .frame(maxWidth: .infinity)
            }
            .buttonStyle(PrimaryButtonStyle())
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 20)
        .background {
            LinearGradient(
                colors: [
                    Color("AppSurface").opacity(0),
                    Color("AppSurface").opacity(0.75)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea(edges: .bottom)
        }
        .padding(.bottom, 24)
    }

    private func advance() {
        FeedbackManager.tapLight()
        if page < pages.count - 1 {
            withAnimation(.easeInOut(duration: 0.3)) {
                page += 1
            }
        } else {
            FeedbackManager.success()
            store.completeOnboarding()
        }
    }
}

// MARK: - Models

private struct OnboardingPage {
    let step: Int
    let headline: String
    let description: String
    let symbols: [String]
    let hues: [Double]
    let chips: [String]
}

// MARK: - Visual panel (collage — matches Home hero)

private struct OnboardingVisualPanel: View {
    let symbols: [String]
    let hues: [Double]
    let animate: Bool

    @State private var appeared = false

    var body: some View {
        GeometryReader { geo in
            HStack(spacing: 0) {
                panel(symbol: symbols[safe: 0] ?? "photo.fill", hue: hues[safe: 0] ?? 0.1)
                panel(symbol: symbols[safe: 1] ?? "sparkles", hue: hues[safe: 1] ?? 0.5)
                panel(symbol: symbols[safe: 2] ?? "heart.fill", hue: hues[safe: 2] ?? 0.8)
            }
            .overlay {
                LinearGradient(
                    colors: [
                        Color("AppPrimary").opacity(0.08),
                        Color.clear,
                        Color("AppBackground").opacity(0.15)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            }
            .overlay(alignment: .center) {
                ZStack {
                    Circle()
                        .fill(Color("AppPrimary").opacity(0.12))
                        .frame(width: geo.size.height * 0.55, height: geo.size.height * 0.55)
                    Image(systemName: symbols[safe: 1] ?? "sparkles")
                        .font(.system(size: geo.size.height * 0.22, weight: .semibold))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [Color("AppAccent"), Color("AppPrimary")],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .shadow(color: Color("AppAccent").opacity(0.45), radius: 10)
                }
                .scaleEffect(appeared ? 1 : 0.7)
                .opacity(appeared ? 1 : 0)
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .onAppear {
            guard animate else { return }
            triggerAppear()
        }
        .onChange(of: animate) { active in
            if active {
                appeared = false
                triggerAppear()
            }
        }
    }

    private func panel(symbol: String, hue: Double) -> some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(hue: hue, saturation: 0.55, brightness: 0.36),
                    Color("AppSurface"),
                    Color("AppBackground").opacity(0.5)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            VStack(spacing: 16) {
                Image(systemName: symbol)
                    .font(.system(size: 36, weight: .semibold))
                    .foregroundStyle(Color("AppAccent").opacity(0.9))
                Image(systemName: "photo")
                    .font(.caption)
                    .foregroundStyle(Color("AppTextSecondary").opacity(0.5))
            }
        }
        .frame(maxWidth: .infinity)
        .frame(maxHeight: .infinity)
    }

    private func triggerAppear() {
        withAnimation(.spring(response: 0.45, dampingFraction: 0.72)) {
            appeared = true
        }
    }
}

private extension Array {
    subscript(safe index: Int) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}
