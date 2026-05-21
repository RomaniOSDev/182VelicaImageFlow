import Combine
import Foundation

final class Feature1ViewModel: ObservableObject {
    @Published var showAddSheet = false
    @Published var showEditSheet = false
    @Published var editingEntry: CuratedEntry?
    @Published var detailEntry: CuratedEntry?
    @Published var highlightEntryID: UUID?
    @Published var showSuccessCheck = false
    @Published var shakeTrigger = 0
    @Published var titleError: String?

    private var store: MoodSyncDataStore?

    func bind(store: MoodSyncDataStore) {
        self.store = store
    }

    func openAdd() {
        editingEntry = nil
        showAddSheet = true
    }

    func openEdit(_ entry: CuratedEntry) {
        editingEntry = entry
        showEditSheet = true
    }

    func saveEntry(title: String, icon: String, description: String, tags: [String], existingID: UUID?) {
        let trimmedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedTitle.isEmpty else {
            titleError = "Title is required."
            shakeTrigger += 1
            FeedbackManager.warning()
            return
        }
        titleError = nil

        if let id = existingID, let store,
           let existing = store.curatedEntries.first(where: { $0.id == id }) {
            let updated = CuratedEntry(
                id: id,
                title: trimmedTitle,
                icon: icon,
                description: description,
                tags: tags,
                isPinned: existing.isPinned,
                createdAt: existing.createdAt
            )
            store.updateCuratedEntry(updated)
            FeedbackManager.success()
        } else if let store {
            let entry = CuratedEntry(title: trimmedTitle, icon: icon, description: description, tags: tags)
            store.addCuratedEntry(entry)
            FeedbackManager.entryAdded()
            highlightEntryID = entry.id
            showSuccessCheck = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                self.showSuccessCheck = false
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                self.highlightEntryID = nil
            }
        }

        showAddSheet = false
        showEditSheet = false
        editingEntry = nil
    }

    func delete(_ entry: CuratedEntry) {
        store?.deleteCuratedEntry(id: entry.id)
        if detailEntry?.id == entry.id {
            detailEntry = nil
        }
        if editingEntry?.id == entry.id {
            editingEntry = nil
            showEditSheet = false
        }
        FeedbackManager.tapLight()
    }

    func togglePin(_ entry: CuratedEntry) {
        store?.toggleCuratedPin(id: entry.id)
        FeedbackManager.tapLight()
    }
}
