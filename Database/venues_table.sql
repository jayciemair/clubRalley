-- venues_table.sql
-- Curated venue data for map pins and default location suggestions.
-- Run in the Supabase SQL editor.

CREATE TABLE IF NOT EXISTS venues (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name TEXT NOT NULL,
    address TEXT NOT NULL,
    city TEXT NOT NULL,
    state TEXT NOT NULL,
    type TEXT NOT NULL DEFAULT 'other',  -- park / court / field / gym / other
    latitude DECIMAL(10, 8) NOT NULL,
    longitude DECIMAL(11, 8) NOT NULL,
    sports JSONB NOT NULL DEFAULT '[]'::jsonb,
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Indexes
CREATE INDEX IF NOT EXISTS idx_venues_city_state ON venues (city, state);
CREATE INDEX IF NOT EXISTS idx_venues_sports ON venues USING GIN (sports);
CREATE INDEX IF NOT EXISTS idx_venues_is_active ON venues (is_active);

-- RLS
ALTER TABLE venues ENABLE ROW LEVEL SECURITY;

-- Anyone can read active venues
CREATE POLICY "venues_read_all" ON venues
    FOR SELECT USING (true);

-- Authenticated users can insert venues
CREATE POLICY "venues_insert_authenticated" ON venues
    FOR INSERT TO authenticated
    WITH CHECK (true);

-- Seed: Lewisburg, PA venues (beta)
INSERT INTO venues (name, address, city, state, type, latitude, longitude, sports) VALUES
    ('Sojka Pavilion', '1 Dent Dr', 'Lewisburg', 'PA', 'gym', 40.95450000, -76.88450000, '["Basketball", "Volleyball"]'),
    ('Gerhard Fieldhouse', '1 Dent Dr', 'Lewisburg', 'PA', 'gym', 40.95720000, -76.88700000, '["Basketball", "Tennis", "Volleyball", "Running"]'),
    ('Davis Gym', '701 Moore Ave', 'Lewisburg', 'PA', 'gym', 40.95250000, -76.88150000, '["Volleyball", "Wrestling"]'),
    ('Bucknell Turf Fields', 'Smoketown Rd', 'Lewisburg', 'PA', 'field', 40.95950000, -76.89200000, '["Soccer", "Lacrosse", "Football"]'),
    ('Christy Mathewson Stadium', 'Moore Ave', 'Lewisburg', 'PA', 'field', 40.95080000, -76.87900000, '["Football", "Lacrosse", "Soccer"]'),
    ('Hufnagle Park', 'S Front St', 'Lewisburg', 'PA', 'park', 40.96500000, -76.88650000, '["Basketball", "Tennis", "Running"]'),
    ('Buffalo Valley Rail Trail', 'St Mary St Trailhead', 'Lewisburg', 'PA', 'park', 40.97000000, -76.87800000, '["Running", "Cycling", "Hiking"]'),
    ('Kinney Natatorium', '1 Dent Dr', 'Lewisburg', 'PA', 'gym', 40.95580000, -76.88250000, '["Swimming"]');
