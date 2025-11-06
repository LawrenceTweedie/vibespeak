-- Migration: Add last_activity field to rooms table
-- This allows tracking when rooms become inactive for automatic cleanup

ALTER TABLE rooms
ADD COLUMN last_activity TIMESTAMP DEFAULT CURRENT_TIMESTAMP AFTER password_hash,
ADD INDEX idx_last_activity (last_activity);

-- Update existing rooms to have current timestamp
UPDATE rooms SET last_activity = CURRENT_TIMESTAMP WHERE last_activity IS NULL;
