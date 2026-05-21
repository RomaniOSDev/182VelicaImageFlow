import SwiftUI

struct TagsInputSection: View {
    @Binding var tagsText: String

    var body: some View {
        Section("Tags") {
            TextField("travel, family, daily", text: $tagsText)
                .foregroundStyle(Color("AppTextPrimary"))
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
            Text("Separate with commas. Tags appear as #name.")
                .font(.caption)
                .foregroundStyle(Color("AppTextSecondary"))
        }
    }
}

struct TagsRowView: View {
    let tags: [String]

    var body: some View {
        if !tags.isEmpty {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 6) {
                    ForEach(tags, id: \.self) { tag in
                        Text(TagNormalizer.display(tag))
                            .font(.caption2.weight(.bold))
                            .foregroundStyle(Color("AppBackground"))
                            .padding(.horizontal, 10)
                            .padding(.vertical, 5)
                            .background(
                                LinearGradient(
                                    colors: [Color("AppPrimary").opacity(0.9), Color("AppAccent").opacity(0.8)],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .clipShape(Capsule())
                    }
                }
            }
        }
    }
}
