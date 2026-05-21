import SwiftUI
import UIKit

struct Feature3View: View {
    @EnvironmentObject private var store: MoodSyncDataStore
    @StateObject private var viewModel = Feature3ViewModel()
    @State private var searchText = ""
    @State private var favouritesOnly = false

    private var filteredCollections: [DiscoverCollection] {
        store.filteredDiscoverCollections(search: searchText, favoritesOnly: favouritesOnly)
    }

    var body: some View {
        ZStack {
            VStack(spacing: 0) {
                SearchFilterBar(
                    searchText: $searchText,
                    placeholder: "Search collections...",
                    favouritesOnly: $favouritesOnly,
                    favouritesLabel: "Favourites only",
                    showFavouritesToggle: true
                )
                .padding(.vertical, 8)
                ScrollView {
                    LazyVStack(spacing: 14) {
                        if filteredCollections.isEmpty {
                            EmptyStateView(
                                symbol: "heart.slash",
                                title: favouritesOnly ? "No favourites yet" : "No matches",
                                message: favouritesOnly
                                    ? "Tap the heart on a collection to save it here."
                                    : "Try a different search term."
                            )
                            .padding(.top, 24)
                        } else {
                            ForEach(filteredCollections) { collection in
                                Button {
                                    viewModel.openCollection(collection)
                                } label: {
                                    DiscoverCollectionCell(
                                        collection: collection,
                                        isFavorite: viewModel.isFavorite(collection.id),
                                        onFavorite: { viewModel.toggleFavorite(collection) }
                                    )
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 20)
                }
                .tabScrollContent()
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        }
        .navigationTitle("Discover Collections")
        .navigationBarTitleDisplayMode(.inline)
        .navigationDestination(item: $viewModel.selectedCollection) { collection in
            CollectionDetailView(collection: collection, viewModel: viewModel)
        }
        .onAppear { viewModel.bind(store: store) }
        .onReceive(NotificationCenter.default.publisher(for: .dataReset)) { _ in
            viewModel.bind(store: store)
            searchText = ""
            favouritesOnly = false
        }
    }
}

struct CollectionDetailView: View {
    let collection: DiscoverCollection
    @ObservedObject var viewModel: Feature3ViewModel

    var body: some View {
        ZStack {
            LayeredBackground()
            ScrollView {
            VStack(spacing: 16) {
                HStack(spacing: 14) {
                    IconBadge(content: collection.symbolName, isSymbol: true, size: 64)
                        VStack(alignment: .leading, spacing: 6) {
                            Text(collection.title)
                                .font(.title2.bold())
                                .foregroundStyle(Color("AppTextPrimary"))
                            Text(collection.themeLabel)
                                .font(.subheadline)
                                .foregroundStyle(Color("AppTextSecondary"))
                        }
                        Spacer(minLength: 0)
                    }
                    .padding(16)
                    .accentCard(highlighted: true)

                    SectionTitle(text: "In this collection")
                    ForEach(collection.items) { item in
                        DiscoverItemCell(item: item)
                    }
                }
                .padding(16)
            }
            .tabScrollContent()
        }
        .navigationTitle(collection.title)
        .navigationBarTitleDisplayMode(.inline)
        .transparentNavigationBar()
    }
}
