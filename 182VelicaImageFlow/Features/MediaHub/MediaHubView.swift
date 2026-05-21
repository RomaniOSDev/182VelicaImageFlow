import SwiftUI

enum MediaHubSection: String, CaseIterable, Identifiable {
    case journal = "Photo Journal"
    case discover = "Discover"

    var id: String { rawValue }
}

struct MediaHubView: View {
    @State private var section: MediaHubSection = .journal

    var body: some View {
        NavigationStack {
            ZStack {
                LayeredBackground()
                VStack(spacing: 0) {
                Picker("Section", selection: $section) {
                    ForEach(MediaHubSection.allCases) { item in
                        Text(item.rawValue).tag(item)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(Color("AppSurface").opacity(0.2))
                .onChange(of: section) { _ in FeedbackManager.tapLight() }

                Group {
                    switch section {
                    case .journal:
                        Feature2View()
                    case .discover:
                        Feature3View()
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            }
        }
    }
}
