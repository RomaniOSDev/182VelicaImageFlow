import SwiftUI
import UIKit

struct SettingsView: View {
    @EnvironmentObject private var store: MoodSyncDataStore
    @State private var showResetAlert = false

    private var appVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
    }

    var body: some View {
        NavigationStack {
            ZStack {
                LayeredBackground()
                ScrollView {
                    VStack(spacing: 20) {
                        statsSection
                        legalSection
                        dangerSection
                        versionFooter
                    }
                    .padding(16)
                    .padding(.bottom, 24)
                }
                .tabScrollContent()
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.large)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .transparentNavigationBar()
            .alert("Reset All Data?", isPresented: $showResetAlert) {
                Button("Cancel", role: .cancel) { FeedbackManager.tapLight() }
                Button("Reset", role: .destructive) {
                    FeedbackManager.warning()
                    store.resetAllData()
                }
            } message: {
                Text("This will erase all entries, journals, favourites, and achievements. This cannot be undone.")
            }
        }
    }

    private var statsSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            SectionTitle(text: "Stats")
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                MetricCell(value: "\(store.itemsAdded)", label: "Entries", icon: "tray.full.fill")
                MetricCell(value: "\(store.totalMinutesUsed)", label: "Minutes", icon: "clock.fill")
                MetricCell(value: "\(store.streakDays)", label: "Streak", icon: "flame.fill")
            }
        }
    }

    private var legalSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            SectionTitle(text: "Feedback & Legal")
            VStack(spacing: 0) {
                settingsRow(title: "Rate Us", icon: "star.fill") {
                    FeedbackManager.tapLight()
                    AppSettingsAction.rateApp()
                }
                rowDivider
                settingsRow(
                    title: AppExternalLink.privacyPolicy.settingsTitle,
                    icon: AppExternalLink.privacyPolicy.settingsIcon
                ) {
                    FeedbackManager.tapLight()
                    if let url = AppExternalLink.privacyPolicy.url {
                        UIApplication.shared.open(url)
                    }
                }
                rowDivider
                settingsRow(
                    title: AppExternalLink.termsOfUse.settingsTitle,
                    icon: AppExternalLink.termsOfUse.settingsIcon
                ) {
                    FeedbackManager.tapLight()
                    if let url = AppExternalLink.termsOfUse.url {
                        UIApplication.shared.open(url)
                    }
                }
            }
            .depthRaised(cornerRadius: 18)
        }
    }

    private var dangerSection: some View {
        VStack(spacing: 0) {
            Button {
                FeedbackManager.tapLight()
                showResetAlert = true
            } label: {
                SettingsActionCell(title: "Reset All Data", icon: "trash.fill", destructive: true)
            }
            .buttonStyle(.plain)
        }
        .depthRaised(cornerRadius: 18)
    }

    private var rowDivider: some View {
        Divider().overlay(Color("AppTextSecondary").opacity(0.2))
    }

    private func settingsRow(title: String, icon: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            SettingsActionCell(title: title, icon: icon)
        }
        .buttonStyle(.plain)
    }

    private var versionFooter: some View {
        Text("Version \(appVersion)")
            .font(.caption.weight(.medium))
            .foregroundStyle(Color("AppTextSecondary"))
            .frame(maxWidth: .infinity)
            .padding(.top, 8)
    }
}
