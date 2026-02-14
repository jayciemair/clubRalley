//
//  AppConfig.swift
//  Club Ralley
//
//  Centralized configuration for app settings
//  These are PUBLIC keys safe for client-side use
//

import Foundation

enum AppConfig {
    
    // MARK: - App Information
    
    enum App {
        static let name = "Club Ralley"
        static let tagline = "GFTO - Get the F*** Outside"
        static let version = "1.0.0"
        static let buildNumber = "1"
        
        // App Store Information
        static let appStoreID = "1234567890" // Replace with actual App Store ID
        static let bundleIdentifier = "com.clubralley.app"
        
        // Support & Social
        static let supportEmail = "support@clubralley.com"
        static let websiteURL = "https://clubralley.com"
        static let instagramHandle = "@clubralley"
        static let twitterHandle = "@clubralley"
    }

    // MARK: - Supabase Configuration

    enum Supabase {
        /// Your Supabase project URL (public, safe to include)
        /// Get this from: Supabase Dashboard → Settings → API → Project URL
        static let projectURL: String = {
            return "https://kcxrboserpzvchbbvpbu.supabase.co"
        }()

        /// Your Supabase anon/public key (safe for client-side)
        /// Get this from: Supabase Dashboard → Settings → API → anon/public key
        /// This is NOT the service_role key - never use that in client apps!
        static let anonKey: String = {
            return "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImtjeHJib3NlcnB6dmNoYmJ2cGJ1Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjkzNTk4NzEsImV4cCI6MjA4NDkzNTg3MX0.Q5H15ftCj5FZgxtJ6L5AGaA18OcSulGc9F23ch0GgSo"
        }()
    }

    // MARK: - RevenueCat Configuration

    enum RevenueCat {
        /// RevenueCat public SDK key
        /// Get this from: RevenueCat Dashboard → Project Settings → API Keys
        static let apiKey: String = {
            #if DEBUG
            // Test/sandbox key
            return "appl_hnYiEvNaJsxBfuyPvhzLZXzpSBw"
            #else
            // Production key - replace with Club Ralley production key when ready
            return "appl_hnYiEvNaJsxBfuyPvhzLZXzpSBw"
            #endif
        }()

        /// Entitlement identifier for premium access
        /// Must match what's configured in RevenueCat dashboard
        static let premiumEntitlement = "Club Ralley Pro"
        
        // Premium features
        static let premiumFeatures = [
            "Advanced search filters",
            "Priority ralley visibility",
            "Unlimited saved locations",
            "Enhanced profile features",
            "Premium athlete badges"
        ]
    }

    // MARK: - Google Sign In Configuration

    enum Google {
        /// Your Google OAuth Client ID for iOS
        /// Get this from: Google Cloud Console → APIs & Services → Credentials
        /// Create an OAuth 2.0 Client ID of type "iOS"
        static let clientID: String = {
            // This is safe to include - it's restricted to your bundle ID
            return "87946294443-icka49fug40v86vqo59fg13ue0tj94na.apps.googleusercontent.com"
        }()
    }
    
    // MARK: - Maps & Location Configuration
    
    enum Maps {
        // Default search radius in miles
        static let defaultSearchRadius: Double = 25
        static let maxSearchRadius: Double = 100
        static let minSearchRadius: Double = 5
        
        // Map zoom levels
        static let defaultZoomLevel: Double = 0.1
        static let cityZoomLevel: Double = 0.05
        static let neighborhoodZoomLevel: Double = 0.01
    }
    
    // MARK: - Social Features Configuration
    
    enum Social {
        // Maximum friends per user
        static let maxFriends = 5000
        
        // Post character limits
        static let maxPostLength = 280
        static let maxCommentLength = 140
        
        // Feed pagination
        static let feedPageSize = 20
        static let maxFeedItems = 1000
    }
    
    // MARK: - Ralley Configuration
    
    enum Ralleys {
        // Default limits
        static let maxParticipants = 50
        static let defaultDuration: TimeInterval = 2 * 60 * 60 // 2 hours
        
        // Time constraints
        static let minAdvanceBooking: TimeInterval = 60 * 60 // 1 hour
        static let maxAdvanceBooking: TimeInterval = 30 * 24 * 60 * 60 // 30 days
        
        // Categories (placeholder for now)
        static let categories: [String] = [
            "sports", "fitness", "social", "outdoor", "competitive", "casual", "training"
        ]
    }

    // MARK: - Security Notes

    /*
     IMPORTANT SECURITY INFORMATION:

     ✅ SAFE to include in iOS app (what's in this file):
     - Supabase project URL (it's public like a website URL)
     - Supabase anon/public key (designed for client-side use with RLS)
     - Google OAuth Client ID (restricted to your bundle ID)

     ❌ NEVER include in iOS app:
     - Supabase service_role key (master access - backend only!)
     - JWT secrets
     - Database passwords
     - Any "secret" keys

     The anon key only works with Row Level Security (RLS) policies.
     Without proper RLS, it cannot access data. Think of it like
     a visitor badge - it identifies you but doesn't give you access
     to restricted areas without additional authentication.
     */
}

// MARK: - Helper Extension

extension AppConfig {
    /// Check if configuration is properly set up
    static func validateConfiguration() -> Bool {
        let supabaseConfigured = !Supabase.projectURL.contains("your-") &&
                                !Supabase.anonKey.contains("your-")

        let googleConfigured = !Google.clientID.contains("123456789")

        return supabaseConfigured
    }
}