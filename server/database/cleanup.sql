-- VibeSpeak Database Cleanup Script
-- This script will delete all data from the database
-- WARNING: This action cannot be undone!

USE vibespeak;

-- Disable foreign key checks temporarily
SET FOREIGN_KEY_CHECKS = 0;

-- Clear all tables
TRUNCATE TABLE messages;
TRUNCATE TABLE webrtc_sessions;
TRUNCATE TABLE room_participants;
TRUNCATE TABLE rooms;

-- Optional: Clear users (uncomment if you want to delete all users too)
-- TRUNCATE TABLE users;
-- If you uncomment above, you'll need to recreate the demo user:
-- INSERT INTO users (username, email, password_hash, display_name, status) VALUES
-- ('demo', 'demo@vibespeak.com', '$2y$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', 'Demo User', 'online');

-- Re-enable foreign key checks
SET FOREIGN_KEY_CHECKS = 1;

-- Show counts
SELECT 'Cleanup completed!' as Status;
SELECT
    (SELECT COUNT(*) FROM messages) as messages_count,
    (SELECT COUNT(*) FROM rooms) as rooms_count,
    (SELECT COUNT(*) FROM room_participants) as participants_count,
    (SELECT COUNT(*) FROM users) as users_count;
