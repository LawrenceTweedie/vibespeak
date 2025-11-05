<?php

namespace VibeSpeak;

class Users
{
    private $db;

    public function __construct()
    {
        $this->db = Database::getInstance();
    }

    public function register($data)
    {
        $required = ['username', 'email', 'password'];
        foreach ($required as $field) {
            if (empty($data[$field])) {
                Response::error("Field '{$field}' is required", 400);
            }
        }

        // Check if user exists
        $existing = $this->db->fetchOne(
            "SELECT id FROM users WHERE username = ? OR email = ?",
            [$data['username'], $data['email']]
        );

        if ($existing) {
            Response::error("User already exists", 409);
        }

        // Create user
        $passwordHash = password_hash($data['password'], PASSWORD_DEFAULT);
        $displayName = $data['display_name'] ?? $data['username'];

        $this->db->execute(
            "INSERT INTO users (username, email, password_hash, display_name, status)
             VALUES (?, ?, ?, ?, 'online')",
            [$data['username'], $data['email'], $passwordHash, $displayName]
        );

        $userId = $this->db->lastInsertId();
        $user = $this->getById($userId);

        Response::success($user, 'User registered successfully');
    }

    public function login($data)
    {
        if (empty($data['username']) || empty($data['password'])) {
            Response::error("Username and password are required", 400);
        }

        $user = $this->db->fetchOne(
            "SELECT * FROM users WHERE username = ? OR email = ?",
            [$data['username'], $data['username']]
        );

        if (!$user || !password_verify($data['password'], $user['password_hash'])) {
            Response::error("Invalid credentials", 401);
        }

        // Update status to online
        $this->updateStatus($user['id'], 'online');

        unset($user['password_hash']);
        Response::success($user, 'Login successful');
    }

    public function getById($id)
    {
        $user = $this->db->fetchOne("SELECT * FROM users WHERE id = ?", [$id]);
        if ($user) {
            unset($user['password_hash']);
        }
        return $user;
    }

    public function updateStatus($userId, $status)
    {
        $this->db->execute(
            "UPDATE users SET status = ? WHERE id = ?",
            [$status, $userId]
        );
    }

    public function getAll()
    {
        $users = $this->db->fetchAll("SELECT id, username, display_name, avatar_url, status FROM users");
        return $users;
    }
}
