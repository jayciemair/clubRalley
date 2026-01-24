//
//  CommitmentSignatureCache.swift
//  Checkpoint
//
//  Cache for commitment signature image data to avoid re-downloading
//

import Foundation
import SwiftUI
import OSLog

@MainActor
class CommitmentSignatureCache {
    static let shared = CommitmentSignatureCache()

    private let imageDataCacheKey = "cached_commitment_signature_image_data"
    private let signedDateCacheKey = "cached_commitment_signed_date"
    private let logger = Logger(subsystem: "com.checkpoint.cache", category: "CommitmentSignature")

    private init() {}

    // MARK: - Public Methods

    /// Get cached signature image (returns nil if not cached)
    func getCachedSignatureImage() -> UIImage? {
        guard let imageData = UserDefaults.standard.data(forKey: imageDataCacheKey) else {
            logger.debug("❌ No cached signature image data found")
            return nil
        }

        guard let image = UIImage(data: imageData) else {
            logger.debug("❌ Failed to decode cached signature image data")
            return nil
        }

        logger.debug("✅ Loaded signature image from cache")
        return image
    }

    /// Get cached signed date (returns nil if not cached)
    func getCachedSignedDate() -> Date? {
        guard let timestamp = UserDefaults.standard.object(forKey: signedDateCacheKey) as? TimeInterval else {
            logger.debug("❌ No cached signed date found")
            return nil
        }
        let date = Date(timeIntervalSince1970: timestamp)
        logger.debug("✅ Loaded signed date from cache: \(date)")
        return date
    }

    /// Load signature from Supabase and cache the image data
    func loadAndCacheSignature() async {
        logger.debug("🔄 Starting signature load from Supabase...")

        guard let session = AuthenticationService.shared.currentSession,
              let userId = UUID(uuidString: session.userId) else {
            logger.debug("❌ No authenticated session")
            return
        }

        do {
            // Fetch signature URL and created_at date from database
            struct UserProfile: Decodable {
                let commitment_signature_url: String?
                let created_at: String
            }

            let supabase = SupabaseClientManager.shared
            let profile: UserProfile = try await supabase.database
                .from("user_profiles")
                .select("commitment_signature_url, created_at")
                .eq("user_id", value: userId.uuidString)
                .single()
                .execute()
                .value

            // Cache the signed date (created_at is when onboarding completed)
            logger.debug("📅 Raw created_at from DB: \(profile.created_at)")
            let formatter = ISO8601DateFormatter()
            formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
            if let signedDate = formatter.date(from: profile.created_at) {
                UserDefaults.standard.set(signedDate.timeIntervalSince1970, forKey: signedDateCacheKey)
                logger.debug("✅ Signed date cached: \(signedDate) (timestamp: \(signedDate.timeIntervalSince1970))")
            } else {
                logger.debug("❌ Failed to parse created_at date: \(profile.created_at)")
            }

            guard let signatureUrlString = profile.commitment_signature_url,
                  let signatureUrl = URL(string: signatureUrlString) else {
                logger.debug("❌ No signature URL found in profile")
                return
            }

            logger.debug("📥 Downloading signature from: \(signatureUrlString)")

            // Download image data
            let (data, _) = try await URLSession.shared.data(from: signatureUrl)

            // Verify it's a valid image
            guard UIImage(data: data) != nil else {
                logger.debug("❌ Downloaded data is not a valid image")
                return
            }

            // Cache the image data
            UserDefaults.standard.set(data, forKey: imageDataCacheKey)
            logger.debug("✅ Signature image cached successfully (\(data.count) bytes)")

        } catch {
            logger.error("❌ Failed to load signature: \(error.localizedDescription)")
        }
    }

    /// Force refresh the cached signature
    func refreshCache() async {
        logger.debug("🔄 Force refreshing signature cache...")
        await loadAndCacheSignature()
    }

    /// Clear cached signature and date
    func clearCache() {
        UserDefaults.standard.removeObject(forKey: imageDataCacheKey)
        UserDefaults.standard.removeObject(forKey: signedDateCacheKey)
        logger.debug("🗑️ Signature cache cleared")
    }
}
