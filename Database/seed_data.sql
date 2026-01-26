-- Club Ralley Seed Data
-- Run this after creating the main schema

-- =============================================
-- SPORTS REFERENCE DATA
-- =============================================

insert into sports (name, category, icon_name, is_popular) values
-- Team Sports (Popular)
('Basketball', 'team', 'basketball.fill', true),
('Football', 'team', 'football.fill', true),
('Soccer', 'team', 'soccerball', true),
('Volleyball', 'team', 'volleyball.fill', true),
('Baseball', 'team', 'baseball.fill', true),
('Softball', 'team', 'baseball.fill', true),
('Field Hockey', 'team', 'hockey.puck.fill', true),
('Lacrosse', 'team', 'sportscourt.fill', true),

-- Individual Sports (Popular)
('Tennis', 'individual', 'tennisball.fill', true),
('Track & Field', 'individual', 'figure.run', true),
('Swimming', 'water_sports', 'figure.pool.swim', true),
('Golf', 'individual', 'figure.golf', true),
('Cross Country', 'individual', 'figure.run', true),

-- Combat Sports
('Wrestling', 'combat_sports', 'figure.wrestling', false),
('Boxing', 'combat_sports', 'figure.boxing', false),
('Martial Arts', 'combat_sports', 'figure.martial.arts', false),

-- Winter Sports
('Skiing', 'winter_sports', 'figure.skiing.downhill', false),
('Snowboarding', 'winter_sports', 'snowboard', false),
('Ice Hockey', 'winter_sports', 'hockey.puck.fill', false),

-- Water Sports
('Water Polo', 'water_sports', 'waterpolo', false),
('Diving', 'water_sports', 'figure.pool.swim', false),
('Rowing', 'water_sports', 'oar.2.crossed', false),

-- Fitness & Recreational
('Cycling', 'individual', 'bicycle', false),
('Rock Climbing', 'individual', 'figure.climbing', false),
('Yoga', 'fitness', 'figure.yoga', false),
('CrossFit', 'fitness', 'dumbbell.fill', false),
('Powerlifting', 'fitness', 'dumbbell.fill', false),
('Gymnastics', 'individual', 'figure.gymnastics', false);

-- =============================================
-- SCHOOLS REFERENCE DATA (Sample)
-- =============================================

insert into schools (name, state, division, conference) values
-- Major D1 Schools
('University of California, Los Angeles', 'CA', 'D1', 'Pac-12'),
('Stanford University', 'CA', 'D1', 'Pac-12'),
('University of Southern California', 'CA', 'D1', 'Pac-12'),
('Duke University', 'NC', 'D1', 'ACC'),
('University of North Carolina', 'NC', 'D1', 'ACC'),
('Harvard University', 'MA', 'D1', 'Ivy League'),
('Yale University', 'CT', 'D1', 'Ivy League'),
('Princeton University', 'NJ', 'D1', 'Ivy League'),
('University of Michigan', 'MI', 'D1', 'Big Ten'),
('Ohio State University', 'OH', 'D1', 'Big Ten'),
('University of Texas', 'TX', 'D1', 'Big 12'),
('University of Florida', 'FL', 'D1', 'SEC'),
('University of Georgia', 'GA', 'D1', 'SEC'),
('University of Alabama', 'AL', 'D1', 'SEC'),

-- Northeast Schools (Patriot League, etc.)
('Bucknell University', 'PA', 'D1', 'Patriot League'),
('Colgate University', 'NY', 'D1', 'Patriot League'),
('Lafayette College', 'PA', 'D1', 'Patriot League'),
('Lehigh University', 'PA', 'D1', 'Patriot League'),
('Army West Point', 'NY', 'D1', 'Patriot League'),
('Navy', 'MD', 'D1', 'Patriot League'),

-- Liberal Arts Colleges (NESCAC)
('Williams College', 'MA', 'D3', 'NESCAC'),
('Amherst College', 'MA', 'D3', 'NESCAC'),
('Middlebury College', 'VT', 'D3', 'NESCAC'),
('Bowdoin College', 'ME', 'D3', 'NESCAC'),
('Colby College', 'ME', 'D3', 'NESCAC'),

-- More D2/D3 Schools
('Colorado School of Mines', 'CO', 'D2', 'RMAC'),
('UC San Diego', 'CA', 'D2', 'CCAA'),
('Bentley University', 'MA', 'D2', 'Northeast-10'),

-- Regional Schools
('Penn State University', 'PA', 'D1', 'Big Ten'),
('Temple University', 'PA', 'D1', 'American Athletic'),
('Villanova University', 'PA', 'D1', 'Big East'),
('Drexel University', 'PA', 'D1', 'CAA'),

-- West Coast
('USC', 'CA', 'D1', 'Pac-12'),
('UCLA', 'CA', 'D1', 'Pac-12'),
('University of Oregon', 'OR', 'D1', 'Pac-12'),
('University of Washington', 'WA', 'D1', 'Pac-12');

-- =============================================  
-- SAMPLE USER DATA (Optional - for testing)
-- =============================================

-- Note: In production, users will be created through the app
-- This is just sample data for development/testing

-- Sample user (matches your Figma design - Gracie King)
insert into club_users (
  id, email, first_name, last_name, username,
  date_of_birth_month, date_of_birth_year, gender,
  location_city, location_state, bio, instagram_handle,
  is_verified_athlete, verification_status
) values (
  '550e8400-e29b-41d4-a716-446655440001',
  'gracie.king@example.com', 'Gracie', 'King', 'gking',
  3, 2002, 'female',
  'Chicago', 'IL', 'Former D1 tennis player passionate about fitness and meeting new people!', 'Gking',
  true, 'verified'
);

-- Gracie's athlete info
insert into athlete_info (user_id, sport_id, school_id, class_year)
select 
  '550e8400-e29b-41d4-a716-446655440001',
  s.id,
  sc.id,
  '2025'
from sports s, schools sc
where s.name = 'Tennis' and sc.name = 'Bucknell University';

-- Gracie's teams
insert into user_teams (user_id, name, sport, level, school, years, is_current_team) values
('550e8400-e29b-41d4-a716-446655440001', 'AVS Club', 'Volleyball', 'Club', 'Bucknell University', '2023-2025', true),
('550e8400-e29b-41d4-a716-446655440001', 'Basketball Club', 'Basketball', 'Intramural', 'Bucknell University', '2021-2023', false);

-- =============================================
-- HELPFUL VIEWS (Optional)
-- =============================================

-- User profile view with computed stats
create or replace view user_profiles as
select 
  u.*,
  coalesce(follower_counts.followers, 0) as followers_count,
  coalesce(following_counts.following, 0) as following_count,
  coalesce(post_counts.posts, 0) as posts_count,
  coalesce(ralley_counts.hosted, 0) as ralleys_hosted,
  coalesce(participant_counts.attended, 0) as ralleys_attended
from club_users u
left join (
  select addressee_id as user_id, count(*) as followers
  from friendships where status = 'accepted'
  group by addressee_id
) follower_counts on u.id = follower_counts.user_id
left join (
  select requester_id as user_id, count(*) as following  
  from friendships where status = 'accepted'
  group by requester_id
) following_counts on u.id = following_counts.user_id
left join (
  select user_id, count(*) as posts
  from posts group by user_id
) post_counts on u.id = post_counts.user_id
left join (
  select host_user_id as user_id, count(*) as hosted
  from ralleys group by host_user_id  
) ralley_counts on u.id = ralley_counts.user_id
left join (
  select user_id, count(*) as attended
  from ralley_participants where status = 'attending'
  group by user_id
) participant_counts on u.id = participant_counts.user_id;