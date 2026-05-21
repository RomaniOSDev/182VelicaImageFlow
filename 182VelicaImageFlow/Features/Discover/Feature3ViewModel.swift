import Combine
import Foundation

final class Feature3ViewModel: ObservableObject {
    @Published var selectedCollection: DiscoverCollection?
    @Published var heartScale: [String: CGFloat] = [:]

    private var store: MoodSyncDataStore?

    func bind(store: MoodSyncDataStore) {
        self.store = store
    }

    var collections: [DiscoverCollection] {
        store?.discoverCollections ?? []
    }

    func toggleFavorite(_ collection: DiscoverCollection) {
        guard let store else { return }
        let wasFavorite = store.isFavorite(collectionID: collection.id)
        store.toggleFavorite(collectionID: collection.id)
        if !wasFavorite {
            FeedbackManager.favorited()
            heartScale[collection.id] = 1.25
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                self.heartScale[collection.id] = 1
            }
        } else {
            FeedbackManager.tapLight()
        }
    }

    func openCollection(_ collection: DiscoverCollection) {
        store?.lastViewedCollection = collection.id
        store?.recordMeaningfulActivity()
        selectedCollection = collection
        FeedbackManager.tapLight()
    }

    func isFavorite(_ id: String) -> Bool {
        store?.isFavorite(collectionID: id) ?? false
    }
}
