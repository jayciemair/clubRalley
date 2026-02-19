-- venues_table_migration_osm.sql
-- Adds OSM deduplication and source tracking columns to the venues table.
-- Run in the Supabase SQL editor BEFORE testing the Overpass integration.

-- Source tracking: 'manual' (hand-seeded) or 'osm' (Overpass-discovered)
ALTER TABLE venues ADD COLUMN IF NOT EXISTS source TEXT NOT NULL DEFAULT 'manual';

-- OSM element ID for deduplication (e.g. "node/12345", "way/67890")
ALTER TABLE venues ADD COLUMN IF NOT EXISTS osm_id TEXT;

-- When OSM data was last fetched (used for 24h cache staleness check)
ALTER TABLE venues ADD COLUMN IF NOT EXISTS last_fetched_at TIMESTAMPTZ;

-- Unique index on osm_id prevents duplicate imports; NULL osm_id (manual venues) are excluded
CREATE UNIQUE INDEX IF NOT EXISTS idx_venues_osm_id ON venues (osm_id) WHERE osm_id IS NOT NULL;

-- Spatial lookup index for proximity queries
CREATE INDEX IF NOT EXISTS idx_venues_lat_lng ON venues (latitude, longitude);

-- Allow authenticated users to update venues (needed for upsert)
CREATE POLICY "venues_update_authenticated" ON venues
    FOR UPDATE TO authenticated
    USING (true)
    WITH CHECK (true);
