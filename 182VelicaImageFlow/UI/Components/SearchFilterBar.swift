import SwiftUI

struct SearchFilterBar: View {
    @Binding var searchText: String
    var placeholder: String = "Search"
    @Binding var favouritesOnly: Bool
    var favouritesLabel: String = "Favourites only"
    var showFavouritesToggle: Bool = true
    var selectedTag: Binding<String?>?
    var availableTags: [String] = []
    var showTagFilter: Bool = false

    var body: some View {
        VStack(spacing: 12) {
            HStack(spacing: 12) {
                Image(systemName: "magnifyingglass")
                    .font(.body.weight(.semibold))
                    .foregroundStyle(Color("AppPrimary"))
                TextField(placeholder, text: $searchText)
                    .foregroundStyle(Color("AppTextPrimary"))
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                if !searchText.isEmpty {
                    Button {
                        FeedbackManager.tapLight()
                        searchText = ""
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(Color("AppTextSecondary"))
                    }
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .depthRaised(cornerRadius: 14)

            if showFavouritesToggle {
                HStack {
                    Image(systemName: favouritesOnly ? "line.3.horizontal.decrease.circle.fill" : "line.3.horizontal.decrease.circle")
                        .foregroundStyle(Color("AppPrimary"))
                    Toggle(isOn: $favouritesOnly) {
                        Text(favouritesLabel)
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(Color("AppTextPrimary"))
                    }
                    .tint(Color("AppPrimary"))
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .accentCard(cornerRadius: 12)
                .onChange(of: favouritesOnly) { _ in
                    FeedbackManager.tapLight()
                }
            }

            if showTagFilter, let selectedTag, !availableTags.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        filterChip(label: "All", tag: nil, binding: selectedTag)
                        ForEach(availableTags, id: \.self) { tag in
                            filterChip(label: TagNormalizer.display(tag), tag: tag, binding: selectedTag)
                        }
                    }
                    .padding(.horizontal, 2)
                }
            }
        }
        .padding(.horizontal, 16)
    }

    private func filterChip(label: String, tag: String?, binding: Binding<String?>) -> some View {
        let selected = binding.wrappedValue == tag
        return Button {
            FeedbackManager.tapLight()
            binding.wrappedValue = tag
        } label: {
            Text(label)
                .font(.caption.weight(.bold))
                .foregroundStyle(selected ? Color("AppBackground") : Color("AppTextSecondary"))
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background {
                    if selected {
                        RoundedRectangle(cornerRadius: 20, style: .continuous)
                            .fill(AppGradients.primaryButton)
                            .shadow(color: Color("AppPrimary").opacity(0.3), radius: 4, y: 2)
                    } else {
                        DepthCardBackground(cornerRadius: 20, level: .standard)
                    }
                }
        }
        .buttonStyle(.plain)
    }
}
