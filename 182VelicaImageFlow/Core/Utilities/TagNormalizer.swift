import Foundation

enum TagNormalizer {
    static func normalize(_ raw: String) -> String {
        var tag = raw.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        if tag.hasPrefix("#") {
            tag.removeFirst()
        }
        return tag
    }

    static func parseInput(_ text: String) -> [String] {
        let parts = text.split { $0 == "," || $0 == " " || $0 == "\n" }
        var seen = Set<String>()
        var result: [String] = []
        for part in parts {
            let tag = normalize(String(part))
            guard !tag.isEmpty, !seen.contains(tag) else { continue }
            seen.insert(tag)
            result.append(tag)
        }
        return result
    }

    static func display(_ tag: String) -> String {
        tag.hasPrefix("#") ? tag : "#\(tag)"
    }
}
