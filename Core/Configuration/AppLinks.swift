//
//  AppLinks.swift
//  Checkpoint
//
//  Centralized URL and link management for the Checkpoint app
//

import Foundation

/// Centralized configuration for all URLs, API endpoints, and external links
struct AppLinks {

    // MARK: - Website URLs

    struct Website {
        static let base = "https://checkpoint.so"
        static let faq = "https://jumpshare.com/share/ibVBz16LlxDlusG8Mveg"
        static let termsOfService = "https://jumpshare.com/share/iOYj4PH7dGXYqk3V08Hh"
        static let privacyPolicy = "https://jumpshare.com/share/Dm8znhpfVCdyqsa9iScQ"
    }

    // MARK: - API Configuration

    struct API {
        /// Club Ralley API endpoint (Railway)
        static let baseURL: String = {
            #if DEBUG
            return "https://web-production-86cc2.up.railway.app"
            #else
            return "https://web-production-86cc2.up.railway.app"
            #endif
        }()

        /// Checkpoint verification endpoint
        static var verifyCheckpoint: String {
            "\(baseURL)/api/checkpoint/verify"
        }
    }

    // MARK: - DNS Configuration

    struct DNS {
        /// Checkpoint DNS filtering server
        struct Filtering {
            static let url = "https://checkpoint.rest/dns-query"
            static let ip = "66.241.124.229"
        }

        /// Cloudflare DNS passthrough server (fallback)
        struct Passthrough {
            static let url = "https://cloudflare-dns.com/dns-query"
            static let ip = "1.1.1.1"
        }
    }

    // MARK: - External Services

    struct External {
        /// Apple App Store redeem code URL
        static let appStoreRedeem = "https://apps.apple.com/redeem"

        /// Support helplines
        struct Helplines {
            static let ncpg = "tel://18005224700" // 1-800-522-4700
        }
    }

    // MARK: - Deep Links & URL Schemes

    struct DeepLinks {
        // NOTE: Apple only allows UIApplication.openSettingsURLString
        // Using "prefs:root=" will result in App Store rejection
        // These deep links are not allowed and have been removed
    }
}
