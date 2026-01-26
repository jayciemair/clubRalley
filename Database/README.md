# Club Ralley Database Setup

This directory contains SQL scripts to set up the Club Ralley backend in Supabase.

## 🚀 Quick Setup Instructions

### Step 1: Run the Main Schema
1. Go to your **Supabase Dashboard**: https://supabase.com/dashboard
2. Select your project: `yzjasxkathlqmysdtoji`
3. Navigate to **SQL Editor** (left sidebar)
4. Click **"New query"**
5. Copy and paste the entire contents of `supabase_schema.sql`
6. Click **"Run"** to execute

### Step 2: Add Sample Data (Optional)
1. In the SQL Editor, create another new query
2. Copy and paste the contents of `seed_data.sql` 
3. Click **"Run"** to execute

## 📊 What Gets Created

### Core Tables:
- **club_users** - User profiles with athlete verification
- **sports** - Reference table of all sports
- **schools** - Reference table of colleges/universities
- **athlete_info** - Detailed athlete credentials
- **user_sports** - Sports preferences and skill levels
- **friendships** - Follow/friend connections
- **ralleys** - Events and activities
- **ralley_participants** - Event RSVPs
- **posts** - Social feed posts
- **user_photos** - Profile photo galleries
- **user_teams** - Team memberships

### Features Included:
✅ **Row Level Security (RLS)** - Proper permissions and privacy
✅ **Automatic Counters** - Friends, followers, likes update automatically
✅ **Indexes** - Optimized for fast queries
✅ **Sample Data** - Realistic test data including "Gracie King" profile

## 🔧 After Running the Scripts:

Your Supabase will have:
1. **Complete Club Ralley database** ready for the app
2. **Proper security policies** protecting user data  
3. **Sample sports and schools** for testing
4. **Mock user profile** (Gracie King from your Figma)

## 🏃‍♂️ Next Steps:

Once the backend is set up:
1. **Profile section** will connect to real data
2. **User registration** will create actual accounts
3. **Social features** will work with real friendships
4. **Event system** will store actual ralleys

## 🛠️ Troubleshooting:

If you get permission errors:
- Make sure you're using the **SQL Editor** (not the Table Editor)
- Run as **postgres** user (should be default)
- Scripts include all necessary permissions and RLS policies

## 📱 Testing the Backend:

After setup, you can:
1. **View tables** in Supabase Table Editor
2. **See the sample data** (sports, schools, Gracie King profile)
3. **Test queries** in SQL Editor
4. **Connect the app** to real data instead of mocks

Run these scripts and your Club Ralley backend will be fully functional! 🎯