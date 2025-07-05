-- Initialize the database for local development
-- This script will be run automatically when the postgres container starts

-- Create the metadata table if it doesn't exist
CREATE TABLE IF NOT EXISTS metadata (
    id SERIAL PRIMARY KEY,
    key VARCHAR(255) UNIQUE NOT NULL,
    value TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Insert the app name for local development
INSERT INTO metadata (key, value) 
VALUES ('app_name', 'sliostudio') 
ON CONFLICT (key) DO UPDATE SET 
    value = EXCLUDED.value,
    updated_at = CURRENT_TIMESTAMP;

-- Create an index on the key column for better performance
CREATE INDEX IF NOT EXISTS idx_metadata_key ON metadata(key);

-- You can add other initialization data here as needed
INSERT INTO metadata (key, value) 
VALUES ('environment', 'local') 
ON CONFLICT (key) DO UPDATE SET 
    value = EXCLUDED.value,
    updated_at = CURRENT_TIMESTAMP;
