import SwiftUI

struct Feature1View: View {
    @EnvironmentObject private var store: MoodSyncDataStore
    @StateObject private var viewModel = Feature1ViewModel()
    @State private var editMode: EditMode = .inactive
    @State private var searchText = ""
    @State private var pinnedOnly = false
    @State private var selectedTag: String?
    @State private var showAlbums = false
    @State private var entryPendingDelete: CuratedEntry?

    private var filteredEntries: [CuratedEntry] {
        store.filteredCuratedEntries(search: searchText, pinnedOnly: pinnedOnly, tag: selectedTag)
    }

    private var hasActiveFilters: Bool {
        !searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            || pinnedOnly
            || selectedTag != nil
    }

    var body: some View {
        NavigationStack {
            ZStack {
                LayeredBackground()
                ZStack {
                VStack(spacing: 0) {
                    ScreenHeader(
                        title: "Curated Gallery",
                        subtitle: "\(store.curatedEntries.count) moments curated"
                    ) {
                        HStack(spacing: 8) {
                            HeaderIconButton(systemImage: "rectangle.stack.fill") {
                                FeedbackManager.tapLight()
                                showAlbums = true
                            }
                            if !store.curatedEntries.isEmpty, !hasActiveFilters {
                                Button(editMode == .active ? "Done" : "Reorder") {
                                    FeedbackManager.tapLight()
                                    withAnimation(.easeInOut(duration: 0.3)) {
                                        editMode = editMode == .active ? .inactive : .active
                                    }
                                }
                                .font(.caption.weight(.bold))
                                .foregroundStyle(Color("AppPrimary"))
                                .padding(.horizontal, 12)
                                .padding(.vertical, 10)
                                .background(Color("AppSurface"))
                                .clipShape(Capsule())
                            }
                        }
                    }
                    SearchFilterBar(
                        searchText: $searchText,
                        placeholder: "Search gallery...",
                        favouritesOnly: $pinnedOnly,
                        favouritesLabel: "Pinned only",
                        showFavouritesToggle: true,
                        selectedTag: $selectedTag,
                        availableTags: store.allCuratedTags(),
                        showTagFilter: true
                    )
                    .padding(.bottom, 8)
                    galleryContent
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
                }
                SuccessCheckmarkOverlay(isVisible: $viewModel.showSuccessCheck)
                }
            }
            .navigationBarHidden(true)
            .environment(\.editMode, $editMode)
            .sheet(isPresented: $viewModel.showAddSheet) {
                EntryEditorSheet(
                    entry: nil,
                    titleError: $viewModel.titleError,
                    shakeTrigger: viewModel.shakeTrigger,
                    onSave: { title, icon, description, tags in
                        viewModel.saveEntry(title: title, icon: icon, description: description, tags: tags, existingID: nil)
                    }
                )
            }
            .sheet(isPresented: $viewModel.showEditSheet) {
                EntryEditorSheet(
                    entry: viewModel.editingEntry,
                    titleError: $viewModel.titleError,
                    shakeTrigger: viewModel.shakeTrigger,
                    onSave: { title, icon, description, tags in
                        viewModel.saveEntry(
                            title: title,
                            icon: icon,
                            description: description,
                            tags: tags,
                            existingID: viewModel.editingEntry?.id
                        )
                    }
                )
            }
            .fullScreenCover(isPresented: $showAlbums) {
                UserAlbumsView()
            }
            .navigationDestination(item: $viewModel.detailEntry) { entry in
                EntryDetailView(entry: entry, viewModel: viewModel, onRequestDelete: { entryPendingDelete = $0 })
            }
            .alert("Delete entry?", isPresented: Binding(
                get: { entryPendingDelete != nil },
                set: { if !$0 { entryPendingDelete = nil } }
            )) {
                Button("Cancel", role: .cancel) {
                    entryPendingDelete = nil
                }
                Button("Delete", role: .destructive) {
                    if let entry = entryPendingDelete {
                        viewModel.delete(entry)
                    }
                    entryPendingDelete = nil
                }
            } message: {
                Text("This moment will be removed from your gallery.")
            }
        }
        .onAppear { viewModel.bind(store: store) }
        .onReceive(NotificationCenter.default.publisher(for: .dataReset)) { _ in
            viewModel.bind(store: store)
            searchText = ""
            pinnedOnly = false
            selectedTag = nil
        }
    }

    @ViewBuilder
    private var galleryContent: some View {
        if store.curatedEntries.isEmpty {
            content
        } else {
            content
                .tabBarFloatingInset {
                    FloatingAddButton(title: "Add Entry") {
                        viewModel.openAdd()
                    }
                }
        }
    }

    @ViewBuilder
    private var content: some View {
        if store.curatedEntries.isEmpty {
            ScrollView {
                EmptyStateView(
                    symbol: "sparkles",
                    title: "Add your first moment!",
                    message: "No curated moments yet! Start by adding one today.",
                    actionTitle: "Add Entry",
                    action: { viewModel.openAdd() }
                )
            }
            .tabScrollContent()
        } else if filteredEntries.isEmpty {
            ScrollView {
                EmptyStateView(
                    symbol: "magnifyingglass",
                    title: "No matches",
                    message: "Try adjusting search or filters to find entries."
                )
            }
            .tabScrollContent()
        } else if editMode == .active && !hasActiveFilters {
            List {
                ForEach(filteredEntries) { entry in
                    CuratedEntryCell(
                        entry: entry,
                        highlighted: viewModel.highlightEntryID == entry.id,
                        onEdit: { viewModel.openEdit(entry) },
                        onDelete: { entryPendingDelete = entry }
                    )
                    .listRowInsets(EdgeInsets(top: 6, leading: 16, bottom: 6, trailing: 16))
                    .listRowBackground(Color.clear)
                    .listRowSeparator(.hidden)
                }
                .onMove(perform: moveRows)
                .onDelete(perform: deleteRows)
            }
            .listStyle(.plain)
            .tabScrollContent()
        } else {
            ScrollView {
                LazyVStack(spacing: 12) {
                    ForEach(filteredEntries) { entry in
                        Button {
                            FeedbackManager.tapLight()
                            viewModel.detailEntry = entry
                        } label: {
                            CuratedEntryCell(
                                entry: entry,
                                highlighted: viewModel.highlightEntryID == entry.id,
                                onEdit: { viewModel.openEdit(entry) },
                                onDelete: { entryPendingDelete = entry }
                            )
                        }
                        .buttonStyle(.plain)
                        .swipeActions(edge: .leading, allowsFullSwipe: false) {
                            Button {
                                viewModel.openEdit(entry)
                            } label: {
                                Label("Edit", systemImage: "pencil")
                            }
                            .tint(Color("AppPrimary"))
                        }
                        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                            Button(role: .destructive) {
                                entryPendingDelete = entry
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                        }
                        .contextMenu {
                            Button {
                                viewModel.togglePin(entry)
                            } label: {
                                Label(entry.isPinned ? "Unpin" : "Pin", systemImage: entry.isPinned ? "pin.slash" : "pin")
                            }
                            Button {
                                viewModel.openEdit(entry)
                            } label: {
                                Label("Edit", systemImage: "pencil")
                            }
                            Button(role: .destructive) {
                                entryPendingDelete = entry
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 16)
            }
            .tabScrollContent()
        }
    }

    private func moveRows(from source: IndexSet, to destination: Int) {
        guard !hasActiveFilters else { return }
        store.moveCuratedEntries(from: source, to: destination)
    }

    private func deleteRows(at offsets: IndexSet) {
        for index in offsets {
            viewModel.delete(filteredEntries[index])
        }
    }
}

private struct EntryEditorSheet: View {
    let entry: CuratedEntry?
    @Binding var titleError: String?
    let shakeTrigger: Int
    let onSave: (String, String, String, [String]) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var title = ""
    @State private var description = ""
    @State private var tagsText = ""
    @State private var selectedIcon = CuratedEmojiPicker.options[0]
    @State private var selectedTemplateID: String?

    var body: some View {
        NavigationStack {
            ZStack {
                LayeredBackground()
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        if entry == nil {
                            SectionTitle(text: "Templates")
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 12) {
                                    ForEach(EntryTemplates.all) { template in
                                        TemplatePickerCell(
                                            template: template,
                                            isSelected: selectedTemplateID == template.id
                                        ) {
                                            FeedbackManager.tapLight()
                                            selectedTemplateID = template.id
                                            applyTemplate(template)
                                        }
                                    }
                                }
                            }
                        }
                        VStack(alignment: .leading, spacing: 12) {
                            SectionTitle(text: "Details")
                            VStack(spacing: 12) {
                                editorField("Title", text: $title)
                                if let titleError {
                                    Text(titleError).font(.caption).foregroundStyle(.red)
                                }
                                editorField("Description", text: $description, axis: true)
                                editorField("Tags (comma separated)", text: $tagsText)
                            }
                        }
                        VStack(alignment: .leading, spacing: 12) {
                            SectionTitle(text: "Icon")
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 10) {
                                    ForEach(CuratedEmojiPicker.options, id: \.self) { emoji in
                                        Button {
                                            FeedbackManager.tapLight()
                                            selectedIcon = emoji
                                        } label: {
                                            Text(emoji)
                                                .font(.title)
                                                .frame(width: 52, height: 52)
                                                .accentCard(cornerRadius: 14, highlighted: selectedIcon == emoji)
                                        }
                                        .buttonStyle(.plain)
                                    }
                                }
                            }
                        }
                    }
                    .padding(20)
                }
                .tabScrollContent()
            }
            .navigationTitle(entry == nil ? "New Entry" : "Edit Entry")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        FeedbackManager.tapLight()
                        dismiss()
                    }
                    .foregroundStyle(Color("AppTextSecondary"))
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        onSave(title, selectedIcon, description, TagNormalizer.parseInput(tagsText))
                    }
                    .fontWeight(.bold)
                    .foregroundStyle(Color("AppPrimary"))
                }
            }
            .onAppear {
                if let entry {
                    title = entry.title
                    description = entry.description
                    selectedIcon = entry.icon
                    tagsText = entry.tags.joined(separator: ", ")
                }
            }
        }
        .presentationDetents([.large])
    }

    private func editorField(_ label: String, text: Binding<String>, axis: Bool = false) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label)
                .font(.caption.weight(.semibold))
                .foregroundStyle(Color("AppTextSecondary"))
            if axis {
                TextField(label, text: text, axis: .vertical)
                    .lineLimit(3...6)
                    .foregroundStyle(Color("AppTextPrimary"))
                    .padding(14)
                    .accentCard(cornerRadius: 12)
                    .shake(trigger: shakeTrigger)
            } else {
                TextField(label, text: text)
                    .foregroundStyle(Color("AppTextPrimary"))
                    .padding(14)
                    .accentCard(cornerRadius: 12)
                    .shake(trigger: shakeTrigger)
            }
        }
    }

    private func applyTemplate(_ template: EntryTemplate) {
        title = template.title
        description = template.descriptionHint
        selectedIcon = template.icon
        tagsText = template.suggestedTags.joined(separator: ", ")
    }
}

private struct EntryDetailView: View {
    let entry: CuratedEntry
    @ObservedObject var viewModel: Feature1ViewModel
    var onRequestDelete: (CuratedEntry) -> Void

    var body: some View {
        ZStack {
            LayeredBackground()
            ScrollView {
                EntryHeroCard(entry: entry)
                    .padding(20)
            }
            .tabScrollContent()
        }
        .navigationTitle("Entry")
        .navigationBarTitleDisplayMode(.inline)
        .transparentNavigationBar()
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    Button {
                        viewModel.openEdit(entry)
                    } label: {
                        Label("Edit", systemImage: "pencil")
                    }
                    Button(role: .destructive) {
                        onRequestDelete(entry)
                    } label: {
                        Label("Delete", systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                        .foregroundStyle(Color("AppPrimary"))
                }
            }
        }
    }
}
