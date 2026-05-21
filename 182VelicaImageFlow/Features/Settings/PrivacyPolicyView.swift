import SwiftUI

struct PrivacyPolicyView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var markdown = ""

    var body: some View {
        NavigationStack {
            ZStack {
                LayeredBackground()
                ScrollView {
                    Group {
                        if markdown.isEmpty {
                            ProgressView()
                                .tint(Color("AppPrimary"))
                                .frame(maxWidth: .infinity)
                                .padding(.top, 60)
                        } else if let attributed = try? AttributedString(markdown: markdown) {
                            Text(attributed)
                                .foregroundStyle(Color("AppTextPrimary"))
                                .tint(Color("AppPrimary"))
                        } else {
                            Text(markdown)
                                .foregroundStyle(Color("AppTextPrimary"))
                        }
                    }
                    .padding(20)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .accentCard(cornerRadius: 18)
                    .padding(16)
                }
                .tabScrollContent()
            }
            .navigationTitle("Privacy Policy")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Close") {
                        FeedbackManager.tapLight()
                        dismiss()
                    }
                    .fontWeight(.semibold)
                    .foregroundStyle(Color("AppPrimary"))
                }
            }
            .onAppear(perform: loadPolicy)
        }
    }

    private func loadPolicy() {
        guard let url = Bundle.main.url(forResource: "privacy_policy", withExtension: "md"),
              let text = try? String(contentsOf: url, encoding: .utf8) else {
            markdown = "# Privacy Policy\nContent unavailable."
            return
        }
        markdown = text
    }
}
