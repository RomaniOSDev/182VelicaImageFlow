import SwiftUI

/// Shows a saved journal photo or a gradient + SF Symbol fallback.
struct JournalPhotoView: View {
    let item: PhotoJournalItem
    var cornerRadius: CGFloat = 12
    var showsSymbolFallback: Bool = true

    var body: some View {
        Group {
            if let fileName = item.imageFileName,
               let uiImage = PhotoImageStore.load(fileName: fileName) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFill()
            } else if showsSymbolFallback {
                ZStack {
                    LinearGradient(
                        colors: [
                            Color(hue: item.accentHue, saturation: 0.5, brightness: 0.38),
                            Color("AppSurface")
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                    Image(systemName: item.symbolName)
                        .font(.title2)
                        .foregroundStyle(Color("AppAccent"))
                }
            } else {
                Color("AppSurface")
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
    }
}
