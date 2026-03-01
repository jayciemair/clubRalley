//
//  ImageUploadService.swift
//  Club Ralley
//
//  Service for uploading images to Supabase Storage
//

import Foundation
import SwiftUI
import UIKit
import Storage

/**
 * ImageUploadService: Handles image uploads to Supabase Storage
 *
 * Purpose: Upload profile photos and post images to cloud storage
 * Strategy: Compress images before upload, return public URLs
 * Usage: Used by onboarding, edit profile, and post creation flows
 */
@MainActor
class ImageUploadService: ObservableObject {

    // MARK: - Singleton

    static let shared = ImageUploadService()

    // MARK: - Published Properties

    @Published var isUploading = false
    @Published var uploadProgress: Double = 0
    @Published var lastError: ImageUploadError?

    // MARK: - Dependencies

    private let supabase = SupabaseManager.shared

    // MARK: - Configuration

    /// Maximum image dimension (width or height) for uploads
    private let maxImageDimension: CGFloat = 1200

    /// JPEG compression quality (0.0 to 1.0)
    private let compressionQuality: CGFloat = 0.8

    /// Maximum file size in bytes (5MB)
    private let maxFileSizeBytes: Int = 5 * 1024 * 1024

    // MARK: - Profile Photo Upload

    /**
     * Upload profile photo for user
     * @param imageData: Raw image data
     * @param userId: User ID for folder organization
     * @returns: Public URL of uploaded image
     */
    func uploadProfilePhoto(imageData: Data, userId: UUID) async throws -> String {
        isUploading = true
        uploadProgress = 0
        lastError = nil

        defer {
            isUploading = false
            uploadProgress = 0
        }

        // Process and compress image
        guard let processedData = processImage(data: imageData) else {
            let error = ImageUploadError.compressionFailed
            lastError = error
            throw error
        }

        uploadProgress = 0.3

        // Check file size
        guard processedData.count <= maxFileSizeBytes else {
            let error = ImageUploadError.fileTooLarge
            lastError = error
            throw error
        }

        uploadProgress = 0.5

        // Generate unique filename
        let filename = "profile_\(userId.uuidString)_\(Int(Date().timeIntervalSince1970)).jpg"
        let path = "profiles/\(userId.uuidString)/\(filename)"

        // Upload to storage
        do {
            let url = try await uploadToStorage(data: processedData, path: path, bucket: "profile-photos")
            uploadProgress = 1.0
            print("ImageUploadService: Profile photo uploaded: \(url)")
            return url
        } catch {
            let uploadError = ImageUploadError.uploadFailed(error.localizedDescription)
            lastError = uploadError
            throw uploadError
        }
    }

    // MARK: - Post Image Upload

    /**
     * Upload image for a post
     * @param imageData: Raw image data
     * @param postId: Post ID for folder organization
     * @returns: Public URL of uploaded image
     */
    func uploadPostImage(imageData: Data, postId: UUID) async throws -> String {
        isUploading = true
        uploadProgress = 0
        lastError = nil

        defer {
            isUploading = false
            uploadProgress = 0
        }

        // Process and compress image
        guard let processedData = processImage(data: imageData) else {
            let error = ImageUploadError.compressionFailed
            lastError = error
            throw error
        }

        uploadProgress = 0.3

        // Check file size
        guard processedData.count <= maxFileSizeBytes else {
            let error = ImageUploadError.fileTooLarge
            lastError = error
            throw error
        }

        uploadProgress = 0.5

        // Generate unique filename
        let filename = "post_\(postId.uuidString)_\(Int(Date().timeIntervalSince1970)).jpg"
        let path = "posts/\(postId.uuidString)/\(filename)"

        // Upload to storage
        do {
            let url = try await uploadToStorage(data: processedData, path: path, bucket: "post-images")
            uploadProgress = 1.0
            print("ImageUploadService: Post image uploaded: \(url)")
            return url
        } catch {
            let uploadError = ImageUploadError.uploadFailed(error.localizedDescription)
            lastError = uploadError
            throw uploadError
        }
    }

    // MARK: - Multiple Images Upload

    /**
     * Upload multiple images for a post
     * @param imageDatas: Array of raw image data
     * @param postId: Post ID for folder organization
     * @returns: Array of public URLs
     */
    func uploadPostImages(imageDatas: [Data], postId: UUID) async throws -> [String] {
        var urls: [String] = []

        for (index, imageData) in imageDatas.enumerated() {
            let url = try await uploadPostImage(imageData: imageData, postId: postId)
            urls.append(url)
            uploadProgress = Double(index + 1) / Double(imageDatas.count)
        }

        return urls
    }

    // MARK: - Image Processing

    /**
     * Process and compress image data
     * @param data: Raw image data
     * @returns: Compressed JPEG data or nil if processing fails
     */
    private func processImage(data: Data) -> Data? {
        guard let image = UIImage(data: data) else {
            print("ImageUploadService: Failed to create UIImage from data")
            return nil
        }

        // Resize if needed
        let resizedImage = resizeImage(image, maxDimension: maxImageDimension)

        // Compress to JPEG
        guard let compressedData = resizedImage.jpegData(compressionQuality: compressionQuality) else {
            print("ImageUploadService: Failed to compress image to JPEG")
            return nil
        }

        print("ImageUploadService: Image processed - Original: \(data.count) bytes, Compressed: \(compressedData.count) bytes")

        return compressedData
    }

    /**
     * Resize image to fit within max dimension while maintaining aspect ratio
     */
    private func resizeImage(_ image: UIImage, maxDimension: CGFloat) -> UIImage {
        let size = image.size

        // Check if resize is needed
        guard size.width > maxDimension || size.height > maxDimension else {
            return image
        }

        // Calculate new size maintaining aspect ratio
        let ratio = min(maxDimension / size.width, maxDimension / size.height)
        let newSize = CGSize(width: size.width * ratio, height: size.height * ratio)

        // Resize using UIGraphicsImageRenderer
        let renderer = UIGraphicsImageRenderer(size: newSize)
        let resizedImage = renderer.image { _ in
            image.draw(in: CGRect(origin: .zero, size: newSize))
        }

        print("ImageUploadService: Image resized from \(size) to \(newSize)")

        return resizedImage
    }

    // MARK: - Storage Upload

    /**
     * Upload data to Supabase Storage
     * @param data: File data to upload
     * @param path: Storage path including filename
     * @param bucket: Storage bucket name
     * @returns: Public URL of uploaded file
     */
    /// Set of bucket names we've already verified exist this session
    private var verifiedBuckets: Set<String> = []

    /// Ensure a storage bucket exists, creating it if needed
    private func ensureBucketExists(_ bucket: String) async {
        guard !verifiedBuckets.contains(bucket) else { return }

        let storage = SupabaseClientManager.shared.storage
        do {
            // Try to get bucket info — if this succeeds, bucket exists
            _ = try await storage.getBucket(bucket)
            verifiedBuckets.insert(bucket)
            print("✅ ImageUploadService: Bucket '\(bucket)' exists")
        } catch {
            // Bucket doesn't exist — create it as public
            print("⚠️ ImageUploadService: Bucket '\(bucket)' not found, creating...")
            do {
                try await storage.createBucket(bucket, options: BucketOptions(public: true))
                verifiedBuckets.insert(bucket)
                print("✅ ImageUploadService: Created bucket '\(bucket)'")
            } catch {
                print("❌ ImageUploadService: Failed to create bucket '\(bucket)': \(error)")
            }
        }
    }

    private func uploadToStorage(data: Data, path: String, bucket: String) async throws -> String {
        let storage = SupabaseClientManager.shared.storage

        // Auto-create bucket if it doesn't exist
        await ensureBucketExists(bucket)

        do {
            // Upload file to Supabase Storage
            let _ = try await storage.from(bucket).upload(
                path,
                data: data,
                options: FileOptions(
                    cacheControl: "3600",
                    contentType: "image/jpeg",
                    upsert: true
                )
            )

            // Get the public URL
            let publicURL = try storage.from(bucket).getPublicURL(path: path)

            print("✅ ImageUploadService: Uploaded to \(bucket)/\(path)")
            print("✅ ImageUploadService: Public URL: \(publicURL.absoluteString)")

            return publicURL.absoluteString

        } catch {
            print("❌ ImageUploadService: Upload failed: \(error)")
            throw error
        }
    }

    // MARK: - Delete Image

    /**
     * Delete image from storage
     * @param url: Public URL of image to delete
     */
    func deleteImage(url: String) async throws {
        let storage = SupabaseClientManager.shared.storage

        // Extract bucket and path from URL
        // URL format: https://xxx.supabase.co/storage/v1/object/public/{bucket}/{path}
        guard let urlComponents = URLComponents(string: url),
              let pathComponents = urlComponents.path.split(separator: "/").dropFirst(4).map(String.init) as? [String],
              pathComponents.count >= 2 else {
            print("❌ ImageUploadService: Invalid URL format for deletion: \(url)")
            return
        }

        let bucket = pathComponents[0]
        let path = pathComponents.dropFirst().joined(separator: "/")

        do {
            try await storage.from(bucket).remove(paths: [path])
            print("✅ ImageUploadService: Deleted \(bucket)/\(path)")
        } catch {
            print("❌ ImageUploadService: Delete failed: \(error)")
            throw error
        }
    }
}

// MARK: - Image Upload Errors

enum ImageUploadError: LocalizedError {
    case invalidImage
    case compressionFailed
    case fileTooLarge
    case uploadFailed(String)
    case networkError(String)

    var errorDescription: String? {
        switch self {
        case .invalidImage:
            return "The selected image could not be processed"
        case .compressionFailed:
            return "Failed to compress image for upload"
        case .fileTooLarge:
            return "Image is too large. Please select a smaller image."
        case .uploadFailed(let message):
            return "Upload failed: \(message)"
        case .networkError(let message):
            return "Network error: \(message)"
        }
    }
}
