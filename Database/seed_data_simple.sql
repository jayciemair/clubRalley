-- Club Ralley Sample Data - Simple Version
-- Run this AFTER the main schema runs successfully

-- =============================================
-- SPORTS REFERENCE DATA
-- =============================================

insert into sports (name, category, icon_name, is_popular) values
-- Popular Sports
('Basketball', 'team', 'basketball.fill', true),
('Tennis', 'individual', 'tennisball.fill', true),
('Soccer', 'team', 'soccerball', true),
('Volleyball', 'team', 'volleyball.fill', true),
('Swimming', 'water_sports', 'figure.pool.swim', true),
('Track & Field', 'individual', 'figure.run', true),
('Football', 'team', 'football.fill', true),
('Golf', 'individual', 'figure.golf', true),

-- Additional Sports  
('Baseball', 'team', 'baseball.fill', false),
('Lacrosse', 'team', 'sportscourt.fill', false),
('CrossFit', 'fitness', 'dumbbell.fill', false),
('Yoga', 'fitness', 'figure.yoga', false),
('Rock Climbing', 'individual', 'figure.climbing', false);

-- =============================================
-- SCHOOLS REFERENCE DATA
-- =============================================

insert into schools (name, state, division, conference) values
-- Major Universities
('Bucknell University', 'PA', 'D1', 'Patriot League'),
('Stanford University', 'CA', 'D1', 'Pac-12'),
('Duke University', 'NC', 'D1', 'ACC'),
('University of Michigan', 'MI', 'D1', 'Big Ten'),
('UCLA', 'CA', 'D1', 'Pac-12'),
('Harvard University', 'MA', 'D1', 'Ivy League'),
('Yale University', 'CT', 'D1', 'Ivy League'),
('University of Pennsylvania', 'PA', 'D1', 'Ivy League'),

-- More Schools
('Williams College', 'MA', 'D3', 'NESCAC'),
('Middlebury College', 'VT', 'D3', 'NESCAC'),
('Colgate University', 'NY', 'D1', 'Patriot League'),
('Lafayette College', 'PA', 'D1', 'Patriot League');

-- =============================================
-- SAMPLE USER (Gracie King from Figma)
-- =============================================

insert into club_users (
  id, email, first_name, last_name, username,
  date_of_birth_month, date_of_birth_year, gender,
  location_city, location_state, bio, instagram_handle,
  is_verified_athlete, verification_status, friends_count
) values (
  '550e8400-e29b-41d4-a716-446655440001',
  'gracie.king@example.com', 'Gracie', 'King', 'gking',
  3, 2002, 'female',
  'Chicago', 'IL', 
  'Former D1 tennis player passionate about fitness and meeting new people!', 
  'Gking',
  true, 'verified', 130
);

-- Gracie's athlete verification
insert into athlete_info (user_id, sport_id, school_id, class_year)
select 
  '550e8400-e29b-41d4-a716-446655440001',
  s.id,
  sc.id,
  '2025'
from sports s, schools sc
where s.name = 'Tennis' and sc.name = 'Bucknell University'
limit 1;

-- Gracie's teams (matching Figma design)
insert into user_teams (user_id, name, sport, level, school, years, is_current_team) values
('550e8400-e29b-41d4-a716-446655440001', 'AVS Club', 'Volleyball', 'Club', 'Bucknell University', '2023-2025', true),
('550e8400-e29b-41d4-a716-446655440001', 'Basketball Club', 'Basketball', 'Intramural', 'Bucknell University', '2021-2023', false),
('550e8400-e29b-41d4-a716-446655440001', 'Tennis Team', 'Tennis', 'Varsity D1', 'Bucknell University', '2021-2024', false);

-- Gracie's sports preferences  
insert into user_sports (user_id, sport_id, skill_level, is_preferred)
select 
  '550e8400-e29b-41d4-a716-446655440001',
  s.id,
  'expert',
  true
from sports s
where s.name = 'Tennis'
limit 1;

insert into user_sports (user_id, sport_id, skill_level, is_preferred)
select 
  '550e8400-e29b-41d4-a716-446655440001',
  s.id,
  'advanced',
  false
from sports s
where s.name in ('Volleyball', 'Basketball')
limit 2;

-- Sample photos for Gracie's profile
insert into user_photos (user_id, image_url, caption, likes_count) values
('550e8400-e29b-41d4-a716-446655440001', 'https://example.com/photo1.jpg', 'Tennis practice! 🎾', 24),
('550e8400-e29b-41d4-a716-446655440001', 'https://example.com/photo2.jpg', 'AVS Club championship! 🏐', 18),
('550e8400-e29b-41d4-a716-446655440001', 'https://example.com/photo3.jpg', 'Chicago skyline run', 15),
('550e8400-e29b-41d4-a716-446655440001', 'https://example.com/photo4.jpg', 'Post-workout selfie 💪', 32);

-- =============================================
-- VERIFICATION COMPLETE MESSAGE
-- =============================================

-- If you see this message, the database setup is complete!
select 'Club Ralley database setup completed successfully! 🎯' as status;