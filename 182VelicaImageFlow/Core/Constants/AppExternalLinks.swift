import StoreKit
import UIKit

enum AppExternalLink: String, CaseIterable {
    case privacyPolicy = "https://velicaimageflow182.site/privacy/199"
    case termsOfUse = "https://velicaimageflow182.site/terms/199"

    var url: URL? {
        URL(string: rawValue)
    }

    var settingsTitle: String {
        switch self {
        case .privacyPolicy: return "Privacy Policy"
        case .termsOfUse: return "Terms of Use"
        }
    }

    var settingsIcon: String {
        switch self {
        case .privacyPolicy: return "hand.raised.fill"
        case .termsOfUse: return "doc.text.fill"
        }
    }

    static func open(_ link: AppExternalLink) {
        guard let url = link.url else { return }
        UIApplication.shared.open(url)
    }
}

enum AppSettingsAction {
    static func rateApp() {
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
            SKStoreReviewController.requestReview(in: windowScene)
        }
    }
}
