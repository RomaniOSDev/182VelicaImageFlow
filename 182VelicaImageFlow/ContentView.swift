//
//  ContentView.swift
//  182VelicaImageFlow
//
//  Created by Roman on 5/20/26.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var store = MoodSyncDataStore.shared

    var body: some View {
        Group {
            if store.hasSeenOnboarding {
                MainTabView()
            } else {
                OnboardingView()
            }
        }
        .environmentObject(store)
        .preferredColorScheme(.dark)
        .onAppear {
            AppChromeConfiguration.applyIfNeeded()
        }
    }
}

#Preview {
    ContentView()
}
