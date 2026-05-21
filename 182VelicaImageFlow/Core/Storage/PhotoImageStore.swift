import UIKit

enum PhotoImageStore {
    private static let folderName = "PhotoJournal"

    private static var directoryURL: URL {
        let base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        let folder = base.appendingPathComponent(folderName, isDirectory: true)
        if !FileManager.default.fileExists(atPath: folder.path) {
            try? FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        }
        return folder
    }

    static func fileName(for itemID: UUID) -> String {
        "\(itemID.uuidString).jpg"
    }

    @discardableResult
    static func saveJPEG(_ data: Data, itemID: UUID) -> String? {
        let name = fileName(for: itemID)
        let url = directoryURL.appendingPathComponent(name)
        do {
            try data.write(to: url, options: .atomic)
            return name
        } catch {
            return nil
        }
    }

    static func load(fileName: String) -> UIImage? {
        let url = directoryURL.appendingPathComponent(fileName)
        guard let data = try? Data(contentsOf: url) else { return nil }
        return UIImage(data: data)
    }

    static func delete(fileName: String) {
        let url = directoryURL.appendingPathComponent(fileName)
        try? FileManager.default.removeItem(at: url)
    }

    static func deleteAll() {
        guard let files = try? FileManager.default.contentsOfDirectory(at: directoryURL, includingPropertiesForKeys: nil) else {
            return
        }
        for url in files {
            try? FileManager.default.removeItem(at: url)
        }
    }

    static func preparedJPEG(from data: Data, maxDimension: CGFloat = 1600) -> Data? {
        guard let image = UIImage(data: data) else { return nil }
        return preparedJPEG(from: image, maxDimension: maxDimension)
    }

    static func preparedJPEG(from image: UIImage, maxDimension: CGFloat = 1600) -> Data? {
        let resized = image.resized(maxDimension: maxDimension)
        return resized.jpegData(compressionQuality: 0.82)
    }
}

private extension UIImage {
    func resized(maxDimension: CGFloat) -> UIImage {
        let maxSide = max(size.width, size.height)
        guard maxSide > maxDimension, maxSide > 0 else { return self }
        let scale = maxDimension / maxSide
        let newSize = CGSize(width: size.width * scale, height: size.height * scale)
        let renderer = UIGraphicsImageRenderer(size: newSize)
        return renderer.image { _ in
            draw(in: CGRect(origin: .zero, size: newSize))
        }
    }
}
