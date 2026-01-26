# Club Ralley - Supabase Setup Instructions

Your Club Ralley backend is set up and running! 🎉 Now let's connect your iOS app to the live database.

## ✅ What's Done

- ✅ **Database created** with all Club Ralley tables
- ✅ **Sample data loaded** including Gracie King profile
- ✅ **iOS integration code** written and ready
- ✅ **Profile section** connected to backend

## 🚀 Final Setup Steps

### 1. Get Your Supabase Key

1. Go to **Supabase Dashboard**: https://supabase.com/dashboard
2. Select your project: `yzjasxkathlqmysdtoji`
3. Click **Settings** → **API**
4. Copy the **"anon public"** key (it's safe to use in your app)

### 2. Configure iOS App

1. **Open**: `/Users/jayciemair/Desktop/club_ralley/Core/Configuration/SupabaseConfig.swift`
2. **Replace** `"YOUR_SUPABASE_ANON_KEY_HERE"` with your actual anon key
3. **Save the file**

### 3. Add Supabase SDK

**In Xcode:**
1. **File** → **Add Package Dependencies**
2. **URL**: `https://github.com/supabase/supabase-swift`
3. **Add to Target**: Your app target (probably "Get Over Him")
4. **Click "Add Package"**

## 🎯 What Happens Next

Once configured:

- **Profile tab** will load **real data** from your Supabase database
- **Gracie King's profile** will display with live stats (130 followers, teams, photos)
- **Follow/unfollow** will update the actual `friendships` table
- **All data** will persist between app launches

## 🧪 Testing

1. **Run the app** in Xcode
2. **Go to Profile tab**
3. **If not working**: Click "Load Sample Profile (Gracie)" button
4. **You should see**: Real profile data from your Supabase database

## 📱 Development Mode

The app has **smart fallbacks**:
- ✅ **Supabase configured**: Uses live database
- ⚠️ **Not configured**: Uses mock data (still functional)
- 🔄 **API errors**: Falls back to mocks automatically

## 🐛 Troubleshooting

**If you see "⚠️ Supabase not configured":**
- Check that you replaced the anon key in `SupabaseConfig.swift`
- Make sure the Supabase package was added to your target

**If you get compile errors:**
- Build the project once after adding the Supabase package
- Clean build folder: **Product** → **Clean Build Folder**

**If data doesn't load:**
- Check your internet connection
- Verify the anon key is correct
- Use the "Load Sample Profile" button as fallback

## 🎉 Success!

When everything works, you'll see:
- **Real profile data** from Supabase
- **Follow buttons** that update the database
- **Live stats** and team information
- **Photos section** with actual like counts

Your Club Ralley app is now connected to a real backend! 🚀