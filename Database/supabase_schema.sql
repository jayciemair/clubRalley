-- Club Ralley Database Schema
-- Run these commands in your Supabase SQL Editor

-- Enable necessary extensions
create extension if not exists "uuid-ossp";

-- =============================================
-- REFERENCE TABLES (Sports, Schools)
-- =============================================

-- Sports reference table
create table sports (
  id uuid default uuid_generate_v4() primary key,
  name varchar(100) not null,
  category varchar(50) not null check (category in ('team', 'individual', 'water_sports', 'winter_sports', 'combat_sports', 'fitness', 'recreational')),
  icon_name varchar(100) not null,
  is_popular boolean default false,
  created_at timestamp with time zone default timezone('utc'::text, now()) not null
);

-- Schools reference table  
create table schools (
  id uuid default uuid_generate_v4() primary key,
  name varchar(200) not null,
  state varchar(2) not null,
  division varchar(20) not null check (division in ('D1', 'D2', 'D3', 'NAIA', 'JUCO', 'Club', 'Intramural')),
  conference varchar(100),
  logo_url text,
  created_at timestamp with time zone default timezone('utc'::text, now()) not null
);

-- =============================================
-- USER SYSTEM 
-- =============================================

-- Enhanced users table for Club Ralley
create table club_users (
  id uuid default uuid_generate_v4() primary key,
  email varchar(255) unique not null,
  first_name varchar(100) not null,
  last_name varchar(100) not null,
  username varchar(50) unique not null,
  date_of_birth_month integer not null check (date_of_birth_month between 1 and 12),
  date_of_birth_year integer not null check (date_of_birth_year between 1960 and 2010),
  gender varchar(20) not null check (gender in ('male', 'female', 'non_binary', 'prefer_not_to_say')),
  location_city varchar(100) not null,
  location_state varchar(2) not null,
  bio text,
  instagram_handle varchar(100),
  linkedin_handle varchar(100),
  twitter_handle varchar(100),
  profile_photo_url text,
  is_verified_athlete boolean default false,
  verification_status varchar(20) default 'not_submitted' check (verification_status in ('pending', 'verified', 'rejected', 'not_submitted')),
  verification_image_url text,
  verification_submitted_at timestamp with time zone,
  verification_verified_at timestamp with time zone,
  friends_count integer default 0,
  ralleys_count integer default 0,
  created_at timestamp with time zone default timezone('utc'::text, now()) not null,
  updated_at timestamp with time zone default timezone('utc'::text, now()) not null
);

-- Athlete information (separate table for verified athletes)
create table athlete_info (
  id uuid default uuid_generate_v4() primary key,
  user_id uuid references club_users(id) on delete cascade,
  sport_id uuid references sports(id),
  school_id uuid references schools(id),
  verification_notes text,
  class_year varchar(10),
  achievements text[],
  created_at timestamp with time zone default timezone('utc'::text, now()) not null,
  unique(user_id)
);

-- User sports/interests
create table user_sports (
  id uuid default uuid_generate_v4() primary key,
  user_id uuid references club_users(id) on delete cascade,
  sport_id uuid references sports(id),
  skill_level varchar(20) not null check (skill_level in ('beginner', 'intermediate', 'advanced', 'expert')),
  is_preferred boolean default false,
  created_at timestamp with time zone default timezone('utc'::text, now()) not null
);

-- User hobbies and interests
create table user_interests (
  id uuid default uuid_generate_v4() primary key,
  user_id uuid references club_users(id) on delete cascade,
  hobbies text[],
  workout_brands text[],
  class_types text[],
  hometown varchar(100),
  favorite_teams text[],
  updated_at timestamp with time zone default timezone('utc'::text, now()) not null
);

-- User availability
create table user_availability (
  id uuid default uuid_generate_v4() primary key,
  user_id uuid references club_users(id) on delete cascade,
  day_of_week integer not null check (day_of_week between 1 and 7),
  start_time time not null,
  end_time time not null,
  created_at timestamp with time zone default timezone('utc'::text, now()) not null
);

-- User preferences and settings
create table user_preferences (
  id uuid default uuid_generate_v4() primary key,
  user_id uuid references club_users(id) on delete cascade unique,
  max_distance integer default 25,
  social_preferences text[],
  notification_ralley_invites boolean default true,
  notification_friend_requests boolean default true,
  notification_ralley_reminders boolean default true,
  notification_social_updates boolean default true,
  notification_new_matches boolean default true,
  privacy_profile_visibility varchar(20) default 'everyone' check (privacy_profile_visibility in ('everyone', 'friends_only', 'private')),
  privacy_show_location boolean default true,
  privacy_show_age boolean default true,
  privacy_allow_friend_requests boolean default true,
  updated_at timestamp with time zone default timezone('utc'::text, now()) not null
);

-- =============================================
-- SOCIAL SYSTEM
-- =============================================

-- Friendships/Follows
create table friendships (
  id uuid default uuid_generate_v4() primary key,
  requester_id uuid references club_users(id) on delete cascade,
  addressee_id uuid references club_users(id) on delete cascade,
  status varchar(20) not null default 'pending' check (status in ('pending', 'accepted', 'blocked')),
  created_at timestamp with time zone default timezone('utc'::text, now()) not null,
  accepted_at timestamp with time zone,
  unique(requester_id, addressee_id)
);

-- Social feed posts
create table posts (
  id uuid default uuid_generate_v4() primary key,
  user_id uuid references club_users(id) on delete cascade,
  content text not null,
  post_type varchar(20) not null default 'text' check (post_type in ('text', 'ralley_update', 'achievement')),
  likes_count integer default 0,
  comments_count integer default 0,
  created_at timestamp with time zone default timezone('utc'::text, now()) not null,
  updated_at timestamp with time zone default timezone('utc'::text, now()) not null
);

-- Post likes
create table post_likes (
  id uuid default uuid_generate_v4() primary key,
  post_id uuid references posts(id) on delete cascade,
  user_id uuid references club_users(id) on delete cascade,
  created_at timestamp with time zone default timezone('utc'::text, now()) not null,
  unique(post_id, user_id)
);

-- Post comments
create table post_comments (
  id uuid default uuid_generate_v4() primary key,
  post_id uuid references posts(id) on delete cascade,
  user_id uuid references club_users(id) on delete cascade,
  content text not null,
  created_at timestamp with time zone default timezone('utc'::text, now()) not null
);

-- =============================================
-- RALLEYS (EVENTS) SYSTEM
-- =============================================

-- Main ralleys table
create table ralleys (
  id uuid default uuid_generate_v4() primary key,
  host_user_id uuid references club_users(id) on delete cascade,
  title varchar(200) not null,
  description text,
  location_name varchar(200) not null,
  location_address text,
  location_city varchar(100) not null,
  location_state varchar(2) not null,
  latitude decimal(10,8) not null,
  longitude decimal(11,8) not null,
  date_time timestamp with time zone not null,
  sport_id uuid references sports(id),
  category varchar(50) not null check (category in ('sports', 'fitness', 'social', 'outdoor', 'competitive', 'casual', 'training')),
  max_participants integer,
  current_participants integer default 0,
  is_public boolean default true,
  created_at timestamp with time zone default timezone('utc'::text, now()) not null,
  updated_at timestamp with time zone default timezone('utc'::text, now()) not null
);

-- Ralley participants/RSVPs
create table ralley_participants (
  id uuid default uuid_generate_v4() primary key,
  ralley_id uuid references ralleys(id) on delete cascade,
  user_id uuid references club_users(id) on delete cascade,
  status varchar(20) not null check (status in ('attending', 'maybe', 'not_attending', 'requested')),
  joined_at timestamp with time zone default timezone('utc'::text, now()) not null,
  unique(ralley_id, user_id)
);

-- Saved locations for users
create table saved_locations (
  id uuid default uuid_generate_v4() primary key,
  user_id uuid references club_users(id) on delete cascade,
  name varchar(200) not null,
  address text,
  city varchar(100) not null,
  state varchar(2) not null,
  latitude decimal(10,8) not null,
  longitude decimal(11,8) not null,
  usage_count integer default 1,
  created_at timestamp with time zone default timezone('utc'::text, now()) not null
);

-- =============================================
-- TEAMS & PHOTOS SYSTEM
-- =============================================

-- User teams (for profile display)
create table user_teams (
  id uuid default uuid_generate_v4() primary key,
  user_id uuid references club_users(id) on delete cascade,
  name varchar(200) not null,
  sport varchar(100) not null,
  level varchar(50) not null,
  school varchar(200),
  years varchar(20),
  image_url text,
  is_current_team boolean default false,
  achievements text[],
  created_at timestamp with time zone default timezone('utc'::text, now()) not null
);

-- User photos
create table user_photos (
  id uuid default uuid_generate_v4() primary key,
  user_id uuid references club_users(id) on delete cascade,
  image_url text not null,
  caption text,
  tags text[],
  likes_count integer default 0,
  comments_count integer default 0,
  created_at timestamp with time zone default timezone('utc'::text, now()) not null
);

-- Photo likes
create table photo_likes (
  id uuid default uuid_generate_v4() primary key,
  photo_id uuid references user_photos(id) on delete cascade,
  user_id uuid references club_users(id) on delete cascade,
  created_at timestamp with time zone default timezone('utc'::text, now()) not null,
  unique(photo_id, user_id)
);

-- =============================================
-- ACTIVITY FEED
-- =============================================

-- Activity feed items
create table activity_feed (
  id uuid default uuid_generate_v4() primary key,
  user_id uuid references club_users(id) on delete cascade,
  activity_type varchar(50) not null check (activity_type in ('joined_ralley', 'created_ralley', 'new_friend', 'posted_update')),
  ralley_id uuid references ralleys(id) on delete cascade,
  ralley_title varchar(200),
  friend_id uuid references club_users(id) on delete cascade,
  friend_name varchar(200),
  post_id uuid references posts(id) on delete cascade,
  post_content text,
  created_at timestamp with time zone default timezone('utc'::text, now') not null
);

-- =============================================
-- INDEXES FOR PERFORMANCE
-- =============================================

-- User lookup indexes
create index idx_club_users_username on club_users(username);
create index idx_club_users_email on club_users(email);
create index idx_club_users_location on club_users(location_city, location_state);

-- Social indexes
create index idx_friendships_requester on friendships(requester_id);
create index idx_friendships_addressee on friendships(addressee_id);
create index idx_friendships_status on friendships(status);

-- Ralley indexes  
create index idx_ralleys_host on ralleys(host_user_id);
create index idx_ralleys_datetime on ralleys(date_time);
create index idx_ralleys_location on ralleys(location_city, location_state);
create index idx_ralleys_sport on ralleys(sport_id);

-- Feed indexes
create index idx_posts_user_created on posts(user_id, created_at desc);
create index idx_activity_feed_user_created on activity_feed(user_id, created_at desc);

-- =============================================
-- ROW LEVEL SECURITY (RLS) POLICIES
-- =============================================

-- Enable RLS on all tables
alter table club_users enable row level security;
alter table athlete_info enable row level security;
alter table user_sports enable row level security;
alter table user_interests enable row level security;
alter table user_availability enable row level security;
alter table user_preferences enable row level security;
alter table friendships enable row level security;
alter table posts enable row level security;
alter table post_likes enable row level security;
alter table post_comments enable row level security;
alter table ralleys enable row level security;
alter table ralley_participants enable row level security;
alter table saved_locations enable row level security;
alter table user_teams enable row level security;
alter table user_photos enable row level security;
alter table photo_likes enable row level security;
alter table activity_feed enable row level security;

-- Sports and schools are public reference data
alter table sports enable row level security;
alter table schools enable row level security;

-- =============================================
-- RLS POLICIES
-- =============================================

-- Sports (public read access)
create policy "Sports are publicly readable" on sports for select using (true);

-- Schools (public read access)  
create policy "Schools are publicly readable" on schools for select using (true);

-- Users can read their own profile and update it
create policy "Users can view own profile" on club_users for select using (auth.uid()::text = id::text);
create policy "Users can update own profile" on club_users for update using (auth.uid()::text = id::text);

-- Users can view public profiles of others (privacy rules applied in app)
create policy "Public profiles viewable" on club_users for select using (true);

-- Athlete info access
create policy "Users can manage own athlete info" on athlete_info for all using (auth.uid()::text = user_id::text);
create policy "Athlete info is publicly readable" on athlete_info for select using (true);

-- User sports preferences
create policy "Users manage own sports" on user_sports for all using (auth.uid()::text = user_id::text);
create policy "User sports are publicly readable" on user_sports for select using (true);

-- User interests
create policy "Users manage own interests" on user_interests for all using (auth.uid()::text = user_id::text);
create policy "User interests are publicly readable" on user_interests for select using (true);

-- User availability
create policy "Users manage own availability" on user_availability for all using (auth.uid()::text = user_id::text);

-- User preferences (private)
create policy "Users manage own preferences" on user_preferences for all using (auth.uid()::text = user_id::text);

-- Friendships
create policy "Users can view friendships" on friendships 
  for select using (auth.uid()::text = requester_id::text or auth.uid()::text = addressee_id::text);
create policy "Users can create friendships" on friendships 
  for insert with check (auth.uid()::text = requester_id::text);
create policy "Users can update friendships" on friendships 
  for update using (auth.uid()::text = requester_id::text or auth.uid()::text = addressee_id::text);

-- Posts
create policy "Users can manage own posts" on posts for all using (auth.uid()::text = user_id::text);
create policy "Posts are publicly readable" on posts for select using (true);

-- Post likes
create policy "Users can manage own likes" on post_likes for all using (auth.uid()::text = user_id::text);
create policy "Post likes are publicly readable" on post_likes for select using (true);

-- Post comments
create policy "Users can manage own comments" on post_comments for all using (auth.uid()::text = user_id::text);
create policy "Post comments are publicly readable" on post_comments for select using (true);

-- Ralleys
create policy "Users can manage own ralleys" on ralleys for all using (auth.uid()::text = host_user_id::text);
create policy "Public ralleys are readable" on ralleys for select using (is_public = true);

-- Ralley participants
create policy "Users can manage own participation" on ralley_participants 
  for all using (auth.uid()::text = user_id::text);
create policy "Ralley participants are publicly readable" on ralley_participants for select using (true);

-- Saved locations (private to user)
create policy "Users manage own saved locations" on saved_locations for all using (auth.uid()::text = user_id::text);

-- User teams
create policy "Users manage own teams" on user_teams for all using (auth.uid()::text = user_id::text);
create policy "User teams are publicly readable" on user_teams for select using (true);

-- User photos
create policy "Users manage own photos" on user_photos for all using (auth.uid()::text = user_id::text);
create policy "User photos are publicly readable" on user_photos for select using (true);

-- Photo likes
create policy "Users can manage photo likes" on photo_likes for all using (auth.uid()::text = user_id::text);
create policy "Photo likes are publicly readable" on photo_likes for select using (true);

-- Activity feed (users see their own feed + friends)
create policy "Users can view own activity feed" on activity_feed for select using (auth.uid()::text = user_id::text);

-- =============================================
-- FUNCTIONS FOR COUNTER UPDATES
-- =============================================

-- Function to update user friends count
create or replace function update_friends_count()
returns trigger as $$
begin
  if TG_OP = 'INSERT' and NEW.status = 'accepted' then
    update club_users set friends_count = friends_count + 1 where id = NEW.requester_id;
    update club_users set friends_count = friends_count + 1 where id = NEW.addressee_id;
  elsif TG_OP = 'UPDATE' and OLD.status != 'accepted' and NEW.status = 'accepted' then
    update club_users set friends_count = friends_count + 1 where id = NEW.requester_id;
    update club_users set friends_count = friends_count + 1 where id = NEW.addressee_id;
  elsif TG_OP = 'UPDATE' and OLD.status = 'accepted' and NEW.status != 'accepted' then
    update club_users set friends_count = friends_count - 1 where id = NEW.requester_id;
    update club_users set friends_count = friends_count - 1 where id = NEW.addressee_id;
  elsif TG_OP = 'DELETE' and OLD.status = 'accepted' then
    update club_users set friends_count = friends_count - 1 where id = OLD.requester_id;
    update club_users set friends_count = friends_count - 1 where id = OLD.addressee_id;
  end if;
  return coalesce(NEW, OLD);
end;
$$ language plpgsql;

-- Trigger for friends count
create trigger friendship_count_trigger
  after insert or update or delete on friendships
  for each row execute function update_friends_count();

-- Function to update ralley participants count  
create or replace function update_ralley_participants_count()
returns trigger as $$
begin
  if TG_OP = 'INSERT' and NEW.status = 'attending' then
    update ralleys set current_participants = current_participants + 1 where id = NEW.ralley_id;
  elsif TG_OP = 'UPDATE' and OLD.status != 'attending' and NEW.status = 'attending' then
    update ralleys set current_participants = current_participants + 1 where id = NEW.ralley_id;
  elsif TG_OP = 'UPDATE' and OLD.status = 'attending' and NEW.status != 'attending' then
    update ralleys set current_participants = current_participants - 1 where id = NEW.ralley_id;
  elsif TG_OP = 'DELETE' and OLD.status = 'attending' then
    update ralleys set current_participants = current_participants - 1 where id = OLD.ralley_id;
  end if;
  return coalesce(NEW, OLD);
end;
$$ language plpgsql;

-- Trigger for ralley participants count
create trigger ralley_participants_count_trigger
  after insert or update or delete on ralley_participants  
  for each row execute function update_ralley_participants_count();

-- Function to update post engagement counts
create or replace function update_post_likes_count()
returns trigger as $$
begin
  if TG_OP = 'INSERT' then
    update posts set likes_count = likes_count + 1 where id = NEW.post_id;
  elsif TG_OP = 'DELETE' then
    update posts set likes_count = likes_count - 1 where id = OLD.post_id;
  end if;
  return coalesce(NEW, OLD);
end;
$$ language plpgsql;

create trigger post_likes_count_trigger
  after insert or delete on post_likes
  for each row execute function update_post_likes_count();

-- Function to update post comments count
create or replace function update_post_comments_count()
returns trigger as $$
begin
  if TG_OP = 'INSERT' then
    update posts set comments_count = comments_count + 1 where id = NEW.post_id;
  elsif TG_OP = 'DELETE' then
    update posts set comments_count = comments_count - 1 where id = OLD.post_id;
  end if;
  return coalesce(NEW, OLD);
end;
$$ language plpgsql;

create trigger post_comments_count_trigger
  after insert or delete on post_comments
  for each row execute function update_post_comments_count();