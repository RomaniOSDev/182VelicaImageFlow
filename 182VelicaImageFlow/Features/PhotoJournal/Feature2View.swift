import SwiftUI

struct Feature2View: View {
    @EnvironmentObject private var store: MoodSyncDataStore
    @StateObject private var viewModel = Feature2ViewModel()
    @State private var showDevicePhotoPicker = false
    @State private var journalPendingDelete: PhotoJournalItem?

    var body: some View {
        ZStack {
            if store.photoJournalItems.isEmpty {
                ScrollView {
                    EmptyStateView(
                        symbol: "photo.on.rectangle",
                        title: "Add your first photo journal",
                        message: "Start your visual journey by selecting a photo to caption.",
                        actionTitle: "Add Photo",
                        action: { viewModel.showAddPhotoSheet = true }
                    )
                }
                .tabScrollContent()
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            } else {
                journalContent
            }
            SuccessCheckmarkOverlay(isVisible: $viewModel.showSuccessCheck)
        }
        .onAppear { viewModel.bind(store: store) }
        .onChange(of: viewModel.selectedIndex) { _ in viewModel.reloadCurrentTexts() }
        .onChange(of: viewModel.searchText) { _ in
            viewModel.selectedIndex = 0
            viewModel.reloadCurrentTexts()
        }
        .onChange(of: viewModel.showFavoritesOnly) { _ in
            viewModel.selectedIndex = 0
            viewModel.reloadCurrentTexts()
        }
        .onReceive(NotificationCenter.default.publisher(for: .dataReset)) { _ in
            viewModel.selectedIndex = 0
            viewModel.searchText = ""
            viewModel.showFavoritesOnly = false
            viewModel.bind(store: store)
        }
        .sheet(isPresented: $viewModel.showAddPhotoSheet, onDismiss: {
            viewModel.resetAddPhotoForm()
        }) {
            addPhotoSheet
        }
        .sheet(isPresented: $viewModel.showEditPhotoSheet, onDismiss: {
            viewModel.resetEditPhotoForm()
        }) {
            editPhotoSheet
        }
        .alert("Delete photo entry?", isPresented: Binding(
            get: { journalPendingDelete != nil },
            set: { if !$0 { journalPendingDelete = nil } }
        )) {
            Button("Cancel", role: .cancel) {
                journalPendingDelete = nil
            }
            Button("Delete", role: .destructive) {
                if let item = journalPendingDelete {
                    viewModel.delete(item: item)
                }
                journalPendingDelete = nil
            }
        } message: {
            Text("This photo and its caption will be removed from your journal.")
        }
    }

    private var journalContent: some View {
        VStack(spacing: 0) {
            ScreenHeader(
                title: "Photo Journal",
                subtitle: "\(viewModel.filteredItems.count) of \(store.photoJournalItems.count) shown"
            ) {
                HeaderIconButton(systemImage: "plus.circle.fill") {
                    viewModel.showAddPhotoSheet = true
                }
            }
            SearchFilterBar(
                searchText: $viewModel.searchText,
                placeholder: "Search journal...",
                favouritesOnly: $viewModel.showFavoritesOnly,
                favouritesLabel: "Favorites only",
                showFavouritesToggle: true
            )
            .padding(.bottom, 4)

            if viewModel.filteredItems.isEmpty {
                ScrollView {
                    EmptyStateView(
                        symbol: "star.slash",
                        title: "No matches",
                        message: "Adjust search or turn off favorites filter."
                    )
                }
                .tabScrollContent()
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            } else {
                JournalThumbnailStrip(
                    items: viewModel.filteredItems,
                    selectedIndex: $viewModel.selectedIndex,
                    onEdit: { viewModel.beginEdit(item: $0) },
                    onDelete: { journalPendingDelete = $0 }
                )
                .padding(.vertical, 8)
                ScrollView {
                    VStack(spacing: 16) {
                        if let item = viewModel.currentItem {
                            photoHero(item)
                        }
                        JournalEditorCard(
                            title: "CAPTION",
                            text: $viewModel.captionText,
                            placeholder: "Add a caption...",
                            lineLimit: 2...4
                        )
                        JournalEditorCard(
                            title: "JOURNAL",
                            text: $viewModel.journalText,
                            placeholder: "Write your thoughts...",
                            lineLimit: 4...10
                        )
                        JournalEditorCard(
                            title: "TAGS",
                            text: $viewModel.tagsText,
                            placeholder: "travel, family",
                            lineLimit: 1...2
                        )
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 16)
                }
                .tabScrollContent()
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
                .tabBarFloatingInset {
                    FloatingAddButton(title: "Save Entry") {
                        viewModel.saveCurrent()
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
    }

    private func photoHero(_ item: PhotoJournalItem) -> some View {
        ZStack(alignment: .topTrailing) {
            PhotoPlaceholderCard(item: item)
                .frame(height: 260)
                .accentCard(cornerRadius: 20, highlighted: item.isFavorite)
            HStack(spacing: 8) {
                Button {
                    FeedbackManager.tapLight()
                    viewModel.beginEditCurrent()
                } label: {
                    Image(systemName: "pencil")
                        .font(.body.weight(.semibold))
                        .foregroundStyle(Color("AppTextPrimary"))
                        .frame(width: 44, height: 44)
                        .background(Color("AppSurface").opacity(0.9))
                        .clipShape(Circle())
                        .overlay(Circle().stroke(Color("AppPrimary").opacity(0.5), lineWidth: 1))
                }
                Button {
                    journalPendingDelete = item
                } label: {
                    Image(systemName: "trash")
                        .font(.body.weight(.semibold))
                        .foregroundStyle(Color("AppTextPrimary"))
                        .frame(width: 44, height: 44)
                        .background(Color("AppSurface").opacity(0.9))
                        .clipShape(Circle())
                        .overlay(Circle().stroke(Color("AppPrimary").opacity(0.5), lineWidth: 1))
                }
                Button {
                    viewModel.toggleFavoriteCurrent()
                } label: {
                    Image(systemName: item.isFavorite ? "star.fill" : "star")
                        .font(.title2)
                        .foregroundStyle(item.isFavorite ? Color("AppPrimary") : Color("AppTextPrimary"))
                        .frame(width: 48, height: 48)
                        .background(Color("AppSurface").opacity(0.9))
                        .clipShape(Circle())
                        .overlay(Circle().stroke(Color("AppPrimary").opacity(0.5), lineWidth: 1))
                }
            }
            .padding(14)
        }
        .gesture(
            DragGesture(minimumDistance: 40)
                .onEnded { value in
                    if value.translation.width < -40 {
                        viewModel.swipeNext()
                    } else if value.translation.width > 40 {
                        viewModel.swipePrevious()
                    }
                }
        )
    }

    private var editPhotoSheet: some View {
        NavigationStack {
            ZStack {
                LayeredBackground()
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        SectionTitle(text: "Photo")
                        editPhotoPickerSection
                        if let photoError = viewModel.photoError {
                            Text(photoError).font(.caption).foregroundStyle(.red)
                        }
                        SectionTitle(text: "Title")
                        editorField("Photo title", text: $viewModel.editPhotoTitle)
                        if let titleError = viewModel.titleError {
                            Text(titleError).font(.caption).foregroundStyle(.red)
                        }
                    }
                    .padding(20)
                }
                .tabScrollContent()
            }
            .navigationTitle("Edit Photo")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        FeedbackManager.tapLight()
                        viewModel.showEditPhotoSheet = false
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        viewModel.saveEditedPhoto()
                    }
                    .fontWeight(.bold)
                    .foregroundStyle(Color("AppPrimary"))
                }
            }
        }
        .presentationDetents([.medium, .large])
        .sheet(isPresented: $showDevicePhotoPicker) {
            DevicePhotoPicker(
                onImagePicked: { image in
                    viewModel.applyPickedPhoto(image)
                    showDevicePhotoPicker = false
                },
                onCancel: {
                    showDevicePhotoPicker = false
                }
            )
            .ignoresSafeArea()
        }
    }

    @ViewBuilder
    private var editPhotoPickerSection: some View {
        if let preview = viewModel.pickedImagePreview {
            ZStack(alignment: .topTrailing) {
                Image(uiImage: preview)
                    .resizable()
                    .scaledToFill()
                    .frame(maxWidth: .infinity)
                    .frame(height: 220)
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                Button("Change") {
                    FeedbackManager.tapLight()
                    showDevicePhotoPicker = true
                }
                .font(.caption.weight(.bold))
                .foregroundStyle(Color("AppBackground"))
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(Color("AppPrimary"))
                .clipShape(Capsule())
                .padding(12)
            }
        } else {
            Button {
                FeedbackManager.tapLight()
                showDevicePhotoPicker = true
            } label: {
                VStack(spacing: 12) {
                    Image(systemName: "photo.on.rectangle.angled")
                        .font(.system(size: 40))
                        .foregroundStyle(Color("AppPrimary"))
                    Text("Replace Photo")
                        .font(.headline)
                        .foregroundStyle(Color("AppTextPrimary"))
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 28)
                .accentCard(cornerRadius: 16)
            }
            .buttonStyle(.plain)
        }
    }

    private var addPhotoSheet: some View {
        NavigationStack {
            ZStack {
                LayeredBackground()
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        SectionTitle(text: "Photo from library")
                        photoPickerSection
                        if let photoError = viewModel.photoError {
                            Text(photoError).font(.caption).foregroundStyle(.red)
                        }
                        SectionTitle(text: "Title")
                        editorField("Photo title", text: $viewModel.newPhotoTitle)
                        if let titleError = viewModel.titleError {
                            Text(titleError).font(.caption).foregroundStyle(.red)
                        }
                    }
                    .padding(20)
                }
                .tabScrollContent()
            }
            .navigationTitle("New Photo")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        FeedbackManager.tapLight()
                        viewModel.showAddPhotoSheet = false
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        viewModel.addPhoto()
                    }
                    .fontWeight(.bold)
                    .foregroundStyle(Color("AppPrimary"))
                    .disabled(viewModel.pickedImageData == nil)
                }
            }
        }
        .presentationDetents([.medium, .large])
        .sheet(isPresented: $showDevicePhotoPicker) {
            DevicePhotoPicker(
                onImagePicked: { image in
                    viewModel.applyPickedPhoto(image)
                    showDevicePhotoPicker = false
                },
                onCancel: {
                    showDevicePhotoPicker = false
                }
            )
            .ignoresSafeArea()
        }
    }

    @ViewBuilder
    private var photoPickerSection: some View {
        if let preview = viewModel.pickedImagePreview {
            ZStack(alignment: .topTrailing) {
                Image(uiImage: preview)
                    .resizable()
                    .scaledToFill()
                    .frame(maxWidth: .infinity)
                    .frame(height: 220)
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                Button("Change") {
                    FeedbackManager.tapLight()
                    showDevicePhotoPicker = true
                }
                .font(.caption.weight(.bold))
                .foregroundStyle(Color("AppBackground"))
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(Color("AppPrimary"))
                .clipShape(Capsule())
                .padding(12)
            }
        } else {
            Button {
                FeedbackManager.tapLight()
                showDevicePhotoPicker = true
            } label: {
                VStack(spacing: 12) {
                    Image(systemName: "photo.on.rectangle.angled")
                        .font(.system(size: 40))
                        .foregroundStyle(Color("AppPrimary"))
                    Text("Choose from Library")
                        .font(.headline)
                        .foregroundStyle(Color("AppTextPrimary"))
                    Text("Select a photo saved on this device")
                        .font(.caption)
                        .foregroundStyle(Color("AppTextSecondary"))
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 36)
                .accentCard(cornerRadius: 16)
            }
            .buttonStyle(.plain)
        }
    }

    private func editorField(_ label: String, text: Binding<String>) -> some View {
        TextField(label, text: text)
            .foregroundStyle(Color("AppTextPrimary"))
            .padding(14)
            .accentCard(cornerRadius: 12)
            .shake(trigger: viewModel.shakeTrigger)
    }
}

struct PhotoPlaceholderCard: View {
    let item: PhotoJournalItem

    var body: some View {
        ZStack {
            JournalPhotoView(item: item, cornerRadius: 20)
            VStack {
                Spacer()
                Text(item.title)
                    .font(.title3.bold())
                    .foregroundStyle(Color("AppTextPrimary"))
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(Color("AppSurface").opacity(0.75))
                    .clipShape(Capsule())
                    .padding(.bottom, 20)
            }
        }
    }
}
