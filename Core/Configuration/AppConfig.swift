//
//  AppConfig.swift
//  Checkpoint
//
//  Centralized configuration for app settings
//  These are PUBLIC keys safe for client-side use
//

import Foundation

enum AppConfig {

    // MARK: - Supabase Configuration

    // TODO: Replace Supabase with AWS backend
    enum Supabase {
        /// Your Supabase project URL (public, safe to include)
        /// Get this from: Supabase Dashboard → Settings → API → Project URL
        static let projectURL: String = {
            #if DEBUG
            // Development environment
            return "https://yzjasxkathlqmysdtoji.supabase.co"
            #else
            // Production environment
            return "https://yzjasxkathlqmysdtoji.supabase.co"
            #endif
        }()

        /// Your Supabase anon/public key (safe for client-side)
        /// Get this from: Supabase Dashboard → Settings → API → anon/public key
        /// This is NOT the service_role key - never use that in client apps!
        static let anonKey: String = {
            #if DEBUG
            // Development anon key
            return "sb_publishable_nWGsQ3b1rRHrGF91VXZcpA_96pO6-W1"
            #else
            // Production anon key
            return "sb_publishable_nWGsQ3b1rRHrGF91VXZcpA_96pO6-W1"
            #endif
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
            // Production key - replace with production key when ready
            return "appl_hnYiEvNaJsxBfuyPvhzLZXzpSBw"
            #endif
        }()

        /// Entitlement identifier for premium access
        /// Must match what's configured in RevenueCat dashboard
        static let premiumEntitlement = "Get Over Him Pro"
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