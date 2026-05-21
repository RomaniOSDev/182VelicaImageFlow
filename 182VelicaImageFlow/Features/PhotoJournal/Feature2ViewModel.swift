import Combine
import Foundation
import UIKit

final class Feature2ViewModel: ObservableObject {
    @Published var selectedIndex = 0
    @Published var captionText = ""
    @Published var journalText = ""
    @Published var tagsText = ""
    @Published var showAddPhotoSheet = false
    @Published var showEditPhotoSheet = false
    @Published var editPhotoTitle = ""
    @Published var showSuccessCheck = false
    @Published var newPhotoTitle = ""
    @Published var pickedImagePreview: UIImage?
    @Published var pickedImageData: Data?
    @Published var titleError: String?
    @Published var photoError: String?
    @Published var shakeTrigger = 0
    @Published var showFavoritesOnly = false
    @Published var searchText = ""

    private var store: MoodSyncDataStore?

    func bind(store: MoodSyncDataStore) {
        self.store = store
        reloadCurrentTexts()
    }

    var filteredItems: [PhotoJournalItem] {
        store?.filteredJournalItems(search: searchText, favoritesOnly: showFavoritesOnly) ?? []
    }

    var currentItem: PhotoJournalItem? {
        guard !filteredItems.isEmpty else { return nil }
        let index = min(max(selectedIndex, 0), filteredItems.count - 1)
        return filteredItems[index]
    }

    func reloadCurrentTexts() {
        guard let item = currentItem, let store else {
            captionText = ""
            journalText = ""
            tagsText = ""
            return
        }
        captionText = store.caption(for: item.id)
        journalText = store.journal(for: item.id)
        let tags = store.journalTags(for: item.id)
        tagsText = tags.joined(separator: ", ")
    }

    func select(index: Int) {
        selectedIndex = index
        reloadCurrentTexts()
    }

    func swipeNext() {
        guard !filteredItems.isEmpty else { return }
        selectedIndex = (selectedIndex + 1) % filteredItems.count
        reloadCurrentTexts()
        FeedbackManager.tapLight()
    }

    func swipePrevious() {
        guard !filteredItems.isEmpty else { return }
        selectedIndex = selectedIndex == 0 ? filteredItems.count - 1 : selectedIndex - 1
        reloadCurrentTexts()
        FeedbackManager.tapLight()
    }

    func applyPickedPhoto(_ image: UIImage) {
        guard let jpeg = PhotoImageStore.preparedJPEG(from: image),
              let preview = UIImage(data: jpeg) else {
            photoError = "Could not load this image. Try another photo."
            pickedImagePreview = nil
            pickedImageData = nil
            return
        }
        photoError = nil
        pickedImagePreview = preview
        pickedImageData = jpeg
    }

    func addPhoto() {
        let trimmed = newPhotoTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            titleError = "Title is required."
            shakeTrigger += 1
            FeedbackManager.warning()
            return
        }
        guard let imageData = pickedImageData else {
            photoError = "Choose a photo from your library."
            shakeTrigger += 1
            FeedbackManager.warning()
            return
        }
        titleError = nil
        photoError = nil
        let hue = Double.random(in: 0...1)
        let item = PhotoJournalItem(title: trimmed, accentHue: hue)
        store?.addPhotoJournalItem(item, imageData: imageData)
        if let store {
            selectedIndex = max(store.filteredJournalItems(search: searchText, favoritesOnly: showFavoritesOnly).count - 1, 0)
        }
        reloadCurrentTexts()
        resetAddPhotoForm()
        showAddPhotoSheet = false
        FeedbackManager.entryAdded()
        FeedbackManager.tapLight()
    }

    func resetAddPhotoForm() {
        newPhotoTitle = ""
        pickedImagePreview = nil
        pickedImageData = nil
        titleError = nil
        photoError = nil
    }

    func saveCurrent() {
        guard let item = currentItem, let store else { return }
        let tags = TagNormalizer.parseInput(tagsText)
        store.saveCaption(photoID: item.id, text: captionText)
        store.saveJournal(photoID: item.id, content: journalText, tags: tags)
        FeedbackManager.captionSaved()
        FeedbackManager.success()
        showSuccessCheck = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            self.showSuccessCheck = false
        }
    }

    func toggleFavoriteCurrent() {
        guard let item = currentItem, let store else { return }
        store.toggleJournalFavorite(id: item.id)
        FeedbackManager.tapLight()
    }

    func beginEdit(item: PhotoJournalItem) {
        if let index = filteredItems.firstIndex(where: { $0.id == item.id }) {
            selectedIndex = index
            reloadCurrentTexts()
        }
        editPhotoTitle = item.title
        pickedImagePreview = item.imageFileName.flatMap { PhotoImageStore.load(fileName: $0) }
        pickedImageData = nil
        titleError = nil
        photoError = nil
        showEditPhotoSheet = true
    }

    func beginEditCurrent() {
        guard let item = currentItem else { return }
        beginEdit(item: item)
    }

    func saveEditedPhoto() {
        guard let item = currentItem, let store else { return }
        let trimmed = editPhotoTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            titleError = "Title is required."
            shakeTrigger += 1
            FeedbackManager.warning()
            return
        }
        titleError = nil
        photoError = nil
        var updated = item
        updated.title = trimmed
        store.updatePhotoJournalItem(updated)
        if let imageData = pickedImageData {
            store.replacePhotoJournalImage(id: item.id, imageData: imageData)
        }
        resetEditPhotoForm()
        showEditPhotoSheet = false
        reloadCurrentTexts()
        FeedbackManager.success()
    }

    func resetEditPhotoForm() {
        editPhotoTitle = ""
        pickedImagePreview = nil
        pickedImageData = nil
        titleError = nil
        photoError = nil
    }

    func delete(item: PhotoJournalItem) {
        guard let store else { return }
        let index = filteredItems.firstIndex(where: { $0.id == item.id }) ?? selectedIndex
        store.deletePhotoJournalItem(id: item.id)
        let remaining = store.filteredJournalItems(search: searchText, favoritesOnly: showFavoritesOnly)
        if remaining.isEmpty {
            selectedIndex = 0
        } else {
            selectedIndex = min(index, remaining.count - 1)
        }
        reloadCurrentTexts()
        FeedbackManager.tapLight()
    }

    func deleteCurrent() {
        guard let item = currentItem else { return }
        delete(item: item)
    }
}
