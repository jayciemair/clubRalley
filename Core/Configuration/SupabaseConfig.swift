import Foundation

/// Configuration for Supabase connection
struct SupabaseConfig {
    
    // MARK: - Project Configuration
    
    /// Your Supabase project URL
    /// Note: This should match AppConfig.Supabase.projectURL
    static let projectURL = AppConfig.Supabase.projectURL
    
    /// Your Supabase anon key (public key - safe to expose)
    /// Note: This should match AppConfig.Supabase.anonKey
    static let anonKey = AppConfig.Supabase.anonKey
    
    // MARK: - Setup Instructions
    
    /*
     ✅ Supabase Setup Complete!
     
     Your app is now configured to connect to:
     - Project: yzjasxkathlqmysdtoji.supabase.co
     - Database: All Club Ralley tables with sample data
     - Authentication: Ready for user sign-up and login
     
     🎯 Next Steps:
     1. Build and run your app (⌘+R)
     2. Go to Profile tab and try "Load Sample Profile"
     3. You should see Gracie King's profile with real data!
     
     ⚡ Your app is now connected to your live Supabase database!
     */
    
    // MARK: - Validation

    /// Check if Supabase is properly configured
    static var isConfigured: Bool {
        // Supabase anon keys are JWTs that start with "eyJ"
        let hasValidURL = projectURL.contains("supabase.co")
        let hasValidKey = anonKey.hasPrefix("eyJ") && anonKey.count > 100
        return hasValidURL && hasValidKey
    }
    
    /// Configuration status for debugging
    static var configurationStatus: String {
        if isConfigured {
            return "✅ Supabase configured and ready"
        } else {
            return "⚠️ Supabase not configured - using mock data"
        }
    }
}