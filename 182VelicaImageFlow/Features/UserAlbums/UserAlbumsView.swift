import SwiftUI

struct UserAlbumsView: View {
    @EnvironmentObject private var store: MoodSyncDataStore
    @Environment(\.dismiss) private var dismiss
    @State private var showCreateAlbum = false
    @State private var newAlbumTitle = ""
    @State private var selectedAlbum: UserAlbum?
    @State private var editMode: EditMode = .inactive

    var body: some View {
        NavigationStack {
            ZStack {
                LayeredBackground()
                if store.userAlbums.isEmpty {
                    ScrollView {
                        EmptyStateView(
                            symbol: "rectangle.stack.fill.badge.plus",
                            title: "No albums yet",
                            message: "Create albums from gallery and journal items.",
                            actionTitle: "New Album",
                            action: { showCreateAlbum = true }
                        )
                    }
                    .tabScrollContent()
                } else {
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            ForEach(store.userAlbums) { album in
                                Button {
                                    FeedbackManager.tapLight()
                                    selectedAlbum = album
                                } label: {
                                    AlbumListCell(album: album)
                                }
                                .buttonStyle(.plain)
                                .contextMenu {
                                    Button(role: .destructive) {
                                        store.deleteAlbum(id: album.id)
                                    } label: {
                                        Label("Delete Album", systemImage: "trash")
                                    }
                                }
                            }
                        }
                        .padding(16)
                    }
                    .tabScrollContent()
                }
            }
            .navigationTitle("My Albums")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Close") {
                        FeedbackManager.tapLight()
                        dismiss()
                    }
                    .foregroundStyle(Color("AppPrimary"))
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showCreateAlbum = true
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .foregroundStyle(Color("AppPrimary"))
                    }
                }
            }
            .sheet(isPresented: $showCreateAlbum) { createAlbumSheet }
            .navigationDestination(item: $selectedAlbum) { album in
                AlbumDetailView(albumID: album.id)
            }
        }
    }

    private var createAlbumSheet: some View {
        NavigationStack {
            ZStack {
                LayeredBackground()
                VStack(alignment: .leading, spacing: 16) {
                    SectionTitle(text: "Album name")
                    TextField("Summer moments", text: $newAlbumTitle)
                        .foregroundStyle(Color("AppTextPrimary"))
                        .padding(14)
                        .accentCard(cornerRadius: 12)
                    Spacer()
                }
                .padding(20)
            }
            .navigationTitle("New Album")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        showCreateAlbum = false
                        newAlbumTitle = ""
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Create") {
                        store.addAlbum(title: newAlbumTitle)
                        FeedbackManager.success()
                        showCreateAlbum = false
                        newAlbumTitle = ""
                    }
                    .fontWeight(.bold)
                    .foregroundStyle(Color("AppPrimary"))
                }
            }
        }
        .presentationDetents([.medium])
    }
}

struct AlbumDetailView: View {
    @EnvironmentObject private var store: MoodSyncDataStore
    let albumID: UUID
    @State private var showAddItems = false
    @State private var editMode: EditMode = .inactive

    private var album: UserAlbum? {
        store.userAlbums.first(where: { $0.id == albumID })
    }

    var body: some View {
        ZStack {
            LayeredBackground()
            VStack(spacing: 0) {
                if let album {
                    if album.itemRefs.isEmpty {
                        ScrollView {
                            EmptyStateView(
                                symbol: "plus.rectangle.on.rectangle",
                                title: "Empty album",
                                message: "Add curated entries or journal photos.",
                                actionTitle: "Add Items",
                                action: { showAddItems = true }
                            )
                        }
                    } else {
                        List {
                            ForEach(album.itemRefs) { ref in
                                if let resolved = store.resolveAlbumRef(ref) {
                                    AlbumItemCell(
                                        title: resolved.title,
                                        glyph: resolved.glyph,
                                        isSymbol: resolved.isSymbol
                                    )
                                    .listRowInsets(EdgeInsets(top: 6, leading: 16, bottom: 6, trailing: 16))
                                    .listRowBackground(Color.clear)
                                    .listRowSeparator(.hidden)
                                }
                            }
                            .onMove { source, destination in
                                store.moveAlbumItems(albumID: albumID, from: source, to: destination)
                            }
                            .onDelete { offsets in
                                guard let current = store.userAlbums.first(where: { $0.id == albumID }) else { return }
                                for index in offsets {
                                    store.removeFromAlbum(albumID: albumID, ref: current.itemRefs[index])
                                }
                            }
                        }
                        .listStyle(.plain)
                        .scrollContentBackground(.hidden)
                        .environment(\.editMode, $editMode)
                    }
                }
            }
            .safeAreaInset(edge: .bottom, spacing: 8) {
                if album != nil {
                    FloatingAddButton(title: "Add Items") {
                        showAddItems = true
                    }
                }
            }
        }
        .navigationTitle(album?.title ?? "Album")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                if album?.itemRefs.isEmpty == false {
                    EditButton()
                        .foregroundStyle(Color("AppPrimary"))
                }
            }
        }
        .sheet(isPresented: $showAddItems) {
            AddToAlbumSheet(albumID: albumID)
        }
    }
}

struct AddToAlbumSheet: View {
    @EnvironmentObject private var store: MoodSyncDataStore
    @Environment(\.dismiss) private var dismiss
    let albumID: UUID

    var body: some View {
        NavigationStack {
            ZStack {
                LayeredBackground()
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        SectionTitle(text: "Gallery")
                        LazyVStack(spacing: 10) {
                            ForEach(store.curatedEntries) { entry in
                                addRow(title: entry.title, glyph: entry.icon, isSymbol: false) {
                                    store.addToAlbum(albumID: albumID, ref: .curated(entry.id))
                                    FeedbackManager.success()
                                }
                            }
                        }
                        SectionTitle(text: "Journal")
                        LazyVStack(spacing: 10) {
                            ForEach(store.photoJournalItems) { item in
                                addRow(title: item.title, glyph: item.symbolName, isSymbol: true) {
                                    store.addToAlbum(albumID: albumID, ref: .journal(item.id))
                                    FeedbackManager.success()
                                }
                            }
                        }
                    }
                    .padding(16)
                }
                .tabScrollContent()
            }
            .navigationTitle("Add Items")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                        .fontWeight(.bold)
                        .foregroundStyle(Color("AppPrimary"))
                }
            }
        }
    }

    private func addRow(title: String, glyph: String, isSymbol: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 14) {
                IconBadge(content: glyph, isSymbol: isSymbol, size: 40)
                Text(title)
                    .font(.headline)
                    .foregroundStyle(Color("AppTextPrimary"))
                Spacer(minLength: 0)
                Image(systemName: "plus.circle.fill")
                    .foregroundStyle(Color("AppPrimary"))
            }
            .padding(12)
            .accentCard(cornerRadius: 12)
        }
        .buttonStyle(.plain)
    }
}
