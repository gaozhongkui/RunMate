//
//  RemoteConfigManager.swift
//  RunMate
//

import FirebaseRemoteConfig
import Foundation

// The following keys must be configured in the Firebase Console (see default values in defaultValues)
final class RemoteConfigManager {
    static let shared = RemoteConfigManager()

    private let remoteConfig = RemoteConfig.remoteConfig()

    // MARK: - Keys
    enum Key: String {
        case pollinationsBaseURL   = "pollinations_base_url"
        case pollinationsApiKey    = "pollinations_api_key"
        case huggingFaceBaseURL    = "huggingface_base_url"
        case huggingFaceToken      = "huggingface_token"
        case openRouterBaseURL     = "openrouter_base_url"
        case openRouterApiKey      = "openrouter_api_key"
        case openRouterImageModel  = "openrouter_image_model"
        case civitaiBaseURL        = "civitai_base_url"
        case civitaiApiKey         = "civitai_api_key"
        case privacyURL            = "privacy_url"
        case termsURL              = "terms_url"
        case feedbackEmail         = "feedback_email"
    }

    // MARK: - Defaults (fallback values, always in effect before Firebase delivers values)
    private let defaultValues: [String: NSObject] = [
        Key.pollinationsBaseURL.rawValue : "https://gen.pollinations.ai/image" as NSObject,
        Key.pollinationsApiKey.rawValue  : "sk_UhsZmc01AcRpoVcqd9I83kLCJLGy8OS8" as NSObject,
        Key.huggingFaceBaseURL.rawValue  : "https://api-inference.huggingface.co/models" as NSObject,
        Key.huggingFaceToken.rawValue    : "" as NSObject,
        Key.openRouterBaseURL.rawValue    : "https://openrouter.ai/api/v1/chat/completions" as NSObject,
        Key.openRouterApiKey.rawValue     : "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" as NSObject,
        Key.openRouterImageModel.rawValue : "black-forest-labs/flux-1-schnell" as NSObject,
        Key.civitaiBaseURL.rawValue      : "https://civitai.com/api/v1/images" as NSObject,
        Key.civitaiApiKey.rawValue       : "" as NSObject,
        Key.privacyURL.rawValue          : "https://velvety-manatee-9d0a84.netlify.app/privacy.html" as NSObject,
        Key.termsURL.rawValue            : "https://velvety-manatee-9d0a84.netlify.app/terms.html" as NSObject,
        Key.feedbackEmail.rawValue       : "gzkhhy@gmail.com" as NSObject,
    ]

    private init() {
        let settings = RemoteConfigSettings()
        settings.fetchTimeout = 10
        #if DEBUG
        settings.minimumFetchInterval = 0  // Always fetch latest during development
        #else
        settings.minimumFetchInterval = 3600  // Fetch at most once per hour in production
        #endif
        remoteConfig.configSettings = settings
        remoteConfig.setDefaults(defaultValues)
    }

    // MARK: - Fetch config on launch and activate on success
    func fetchAndActivate(completion: ((RemoteConfigFetchAndActivateStatus, Error?) -> Void)? = nil) {
        remoteConfig.fetchAndActivate { status, error in
            if let error {
                print("[RemoteConfig] ❌ fetch error: \(error.localizedDescription)")
                completion?(status, error)
                return
            }
            print("[RemoteConfig] ✅ status: \(status == .successFetchedFromRemote ? "fetched from remote" : "used cache")")
            print("[RemoteConfig] pollinations_base_url  = \(self.pollinationsBaseURL)")
            print("[RemoteConfig] pollinations_api_key   = \(self.pollinationsApiKey)")
            print("[RemoteConfig] huggingface_base_url   = \(self.huggingFaceBaseURL)")
            print("[RemoteConfig] huggingface_token      = \(self.huggingFaceToken.isEmpty ? "(empty)" : self.huggingFaceToken)")
            print("[RemoteConfig] openrouter_base_url    = \(self.openRouterBaseURL)")
            print("[RemoteConfig] openrouter_api_key     = \(self.openRouterApiKey.isEmpty ? "(empty)" : "(configured)")")
            print("[RemoteConfig] openrouter_image_model = \(self.openRouterImageModel)")
            print("[RemoteConfig] civitai_base_url       = \(self.civitaiBaseURL)")
            print("[RemoteConfig] privacy_url            = \(self.string(.privacyURL))")
            print("[RemoteConfig] terms_url              = \(self.string(.termsURL))")
            print("[RemoteConfig] feedback_email         = \(self.feedbackEmail)")
            completion?(status, nil)
        }
    }

    // MARK: - Typed accessors
    func string(_ key: Key) -> String {
        remoteConfig[key.rawValue].stringValue
    }

    func url(_ key: Key) -> URL? {
        URL(string: string(key))
    }

    // Convenience properties
    var pollinationsBaseURL: String  { string(.pollinationsBaseURL) }
    var pollinationsApiKey: String   { string(.pollinationsApiKey) }
    var huggingFaceBaseURL: String   { string(.huggingFaceBaseURL) }
    var huggingFaceToken: String     { string(.huggingFaceToken) }
    var openRouterBaseURL: String    { string(.openRouterBaseURL) }
    var openRouterApiKey: String     { string(.openRouterApiKey) }
    var openRouterImageModel: String { string(.openRouterImageModel) }
    var civitaiBaseURL: String       { string(.civitaiBaseURL) }
    var civitaiApiKey: String        { string(.civitaiApiKey) }
    var privacyURL: URL?             { url(.privacyURL) }
    var termsURL: URL?               { url(.termsURL) }
    var feedbackEmail: String        { string(.feedbackEmail) }
}
