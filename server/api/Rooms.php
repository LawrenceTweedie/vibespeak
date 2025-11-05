<?php

namespace VibeSpeak;

class Rooms
{
    private $db;

    public function __construct()
    {
        $this->db = Database::getInstance();
    }

    public function create($data)
    {
        $required = ['name', 'owner_id'];
        foreach ($required as $field) {
            if (empty($data[$field])) {
                Response::error("Field '{$field}' is required", 400);
            }
        }

        // Generate unique room code
        $roomCode = $this->generateRoomCode();

        $passwordHash = null;
        if (!empty($data['password'])) {
            $passwordHash = password_hash($data['password'], PASSWORD_DEFAULT);
        }

        $this->db->execute(
            "INSERT INTO rooms (room_code, name, description, owner_id, max_participants, is_public, password_hash)
             VALUES (?, ?, ?, ?, ?, ?, ?)",
            [
                $roomCode,
                $data['name'],
                $data['description'] ?? '',
                $data['owner_id'],
                $data['max_participants'] ?? 10,
                $data['is_public'] ?? false,
                $passwordHash
            ]
        );

        $roomId = $this->db->lastInsertId();

        // Add owner as participant and admin
        $this->addParticipant($roomId, $data['owner_id'], true);

        $room = $this->getById($roomId);
        Response::success($room, 'Room created successfully');
    }

    public function getById($id)
    {
        $room = $this->db->fetchOne(
            "SELECT r.*, u.username as owner_name
             FROM rooms r
             JOIN users u ON r.owner_id = u.id
             WHERE r.id = ?",
            [$id]
        );

        if ($room) {
            unset($room['password_hash']);
            $room['participants'] = $this->getParticipants($id);
        }

        return $room;
    }

    public function getByCode($code)
    {
        $room = $this->db->fetchOne(
            "SELECT r.*, u.username as owner_name
             FROM rooms r
             JOIN users u ON r.owner_id = u.id
             WHERE r.room_code = ?",
            [$code]
        );

        if ($room) {
            unset($room['password_hash']);
            $room['participants'] = $this->getParticipants($room['id']);
        }

        return $room;
    }

    public function getAll($userId = null)
    {
        if ($userId) {
            $rooms = $this->db->fetchAll(
                "SELECT DISTINCT r.*, u.username as owner_name
                 FROM rooms r
                 JOIN users u ON r.owner_id = u.id
                 LEFT JOIN room_participants rp ON r.id = rp.room_id
                 WHERE r.is_public = 1 OR r.owner_id = ? OR rp.user_id = ?
                 ORDER BY r.created_at DESC",
                [$userId, $userId]
            );
        } else {
            $rooms = $this->db->fetchAll(
                "SELECT r.*, u.username as owner_name
                 FROM rooms r
                 JOIN users u ON r.owner_id = u.id
                 WHERE r.is_public = 1
                 ORDER BY r.created_at DESC"
            );
        }

        foreach ($rooms as &$room) {
            unset($room['password_hash']);
            $room['participant_count'] = $this->getParticipantCount($room['id']);
        }

        return $rooms;
    }

    public function join($roomId, $userId, $password = null)
    {
        $room = $this->db->fetchOne("SELECT * FROM rooms WHERE id = ?", [$roomId]);

        if (!$room) {
            Response::error("Room not found", 404);
        }

        // Check password if required
        if ($room['password_hash'] && !password_verify($password, $room['password_hash'])) {
            Response::error("Invalid room password", 401);
        }

        // Check max participants
        $count = $this->getParticipantCount($roomId);
        if ($count >= $room['max_participants']) {
            Response::error("Room is full", 403);
        }

        // Add participant
        $this->addParticipant($roomId, $userId);

        $updatedRoom = $this->getById($roomId);
        Response::success($updatedRoom, 'Joined room successfully');
    }

    public function leave($roomId, $userId)
    {
        $this->db->execute(
            "DELETE FROM room_participants WHERE room_id = ? AND user_id = ?",
            [$roomId, $userId]
        );

        Response::success([], 'Left room successfully');
    }

    public function updateMediaState($roomId, $userId, $data)
    {
        $fields = [];
        $params = [];

        if (isset($data['audio_enabled'])) {
            $fields[] = "audio_enabled = ?";
            $params[] = $data['audio_enabled'] ? 1 : 0;
        }
        if (isset($data['video_enabled'])) {
            $fields[] = "video_enabled = ?";
            $params[] = $data['video_enabled'] ? 1 : 0;
        }
        if (isset($data['screen_sharing'])) {
            $fields[] = "screen_sharing = ?";
            $params[] = $data['screen_sharing'] ? 1 : 0;
        }

        if (empty($fields)) {
            Response::error("No media state to update", 400);
        }

        $params[] = $roomId;
        $params[] = $userId;

        $this->db->execute(
            "UPDATE room_participants SET " . implode(', ', $fields) . " WHERE room_id = ? AND user_id = ?",
            $params
        );

        Response::success([], 'Media state updated');
    }

    private function addParticipant($roomId, $userId, $isAdmin = false)
    {
        $this->db->execute(
            "INSERT INTO room_participants (room_id, user_id, is_admin)
             VALUES (?, ?, ?)
             ON DUPLICATE KEY UPDATE joined_at = CURRENT_TIMESTAMP",
            [$roomId, $userId, $isAdmin ? 1 : 0]
        );
    }

    private function getParticipants($roomId)
    {
        return $this->db->fetchAll(
            "SELECT u.id, u.username, u.display_name, u.avatar_url, u.status,
                    rp.is_admin, rp.audio_enabled, rp.video_enabled, rp.screen_sharing, rp.joined_at
             FROM room_participants rp
             JOIN users u ON rp.user_id = u.id
             WHERE rp.room_id = ?",
            [$roomId]
        );
    }

    private function getParticipantCount($roomId)
    {
        $result = $this->db->fetchOne(
            "SELECT COUNT(*) as count FROM room_participants WHERE room_id = ?",
            [$roomId]
        );
        return $result['count'] ?? 0;
    }

    private function generateRoomCode()
    {
        $characters = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
        do {
            $code = '';
            for ($i = 0; $i < 8; $i++) {
                $code .= $characters[random_int(0, strlen($characters) - 1)];
            }
            $existing = $this->db->fetchOne("SELECT id FROM rooms WHERE room_code = ?", [$code]);
        } while ($existing);

        return $code;
    }
}
