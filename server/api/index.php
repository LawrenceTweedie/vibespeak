<?php

require_once __DIR__ . '/../vendor/autoload.php';

use VibeSpeak\Response;
use VibeSpeak\Users;
use VibeSpeak\Rooms;

// Enable CORS
Response::cors();

// Parse request
$method = $_SERVER['REQUEST_METHOD'];
$path = parse_url($_SERVER['REQUEST_URI'], PHP_URL_PATH);
$path = trim($path, '/');
$segments = explode('/', $path);

// Get JSON input
$input = json_decode(file_get_contents('php://input'), true) ?? [];

// Merge with GET/POST data
$data = array_merge($_GET, $_POST, $input);

try {
    // Route handlers
    switch ($segments[0] ?? '') {
        case 'users':
            $users = new Users();

            switch ($segments[1] ?? '') {
                case 'register':
                    if ($method !== 'POST') Response::error('Method not allowed', 405);
                    $users->register($data);
                    break;

                case 'login':
                    if ($method !== 'POST') Response::error('Method not allowed', 405);
                    $users->login($data);
                    break;

                case 'list':
                    if ($method !== 'GET') Response::error('Method not allowed', 405);
                    $result = $users->getAll();
                    Response::success($result);
                    break;

                default:
                    if (isset($segments[1]) && is_numeric($segments[1])) {
                        $user = $users->getById($segments[1]);
                        if ($user) {
                            Response::success($user);
                        } else {
                            Response::error('User not found', 404);
                        }
                    } else {
                        Response::error('Invalid endpoint', 404);
                    }
            }
            break;

        case 'rooms':
            $rooms = new Rooms();

            switch ($segments[1] ?? '') {
                case 'create':
                    if ($method !== 'POST') Response::error('Method not allowed', 405);
                    $rooms->create($data);
                    break;

                case 'list':
                    if ($method !== 'GET') Response::error('Method not allowed', 405);
                    $result = $rooms->getAll($data['user_id'] ?? null);
                    Response::success($result);
                    break;

                case 'join':
                    if ($method !== 'POST') Response::error('Method not allowed', 405);
                    if (empty($data['room_id']) || empty($data['user_id'])) {
                        Response::error('room_id and user_id are required', 400);
                    }
                    $rooms->join($data['room_id'], $data['user_id'], $data['password'] ?? null);
                    break;

                case 'leave':
                    if ($method !== 'POST') Response::error('Method not allowed', 405);
                    if (empty($data['room_id']) || empty($data['user_id'])) {
                        Response::error('room_id and user_id are required', 400);
                    }
                    $rooms->leave($data['room_id'], $data['user_id']);
                    break;

                case 'media':
                    if ($method !== 'POST') Response::error('Method not allowed', 405);
                    if (empty($data['room_id']) || empty($data['user_id'])) {
                        Response::error('room_id and user_id are required', 400);
                    }
                    $rooms->updateMediaState($data['room_id'], $data['user_id'], $data);
                    break;

                case 'code':
                    if ($method !== 'GET') Response::error('Method not allowed', 405);
                    if (empty($segments[2])) {
                        Response::error('Room code is required', 400);
                    }
                    $room = $rooms->getByCode($segments[2]);
                    if ($room) {
                        Response::success($room);
                    } else {
                        Response::error('Room not found', 404);
                    }
                    break;

                default:
                    if (isset($segments[1]) && is_numeric($segments[1])) {
                        $room = $rooms->getById($segments[1]);
                        if ($room) {
                            Response::success($room);
                        } else {
                            Response::error('Room not found', 404);
                        }
                    } else {
                        Response::error('Invalid endpoint', 404);
                    }
            }
            break;

        case 'health':
            Response::success(['status' => 'ok', 'timestamp' => time()]);
            break;

        default:
            Response::error('Endpoint not found', 404);
    }
} catch (Exception $e) {
    error_log("API Error: " . $e->getMessage());
    Response::error('Internal server error: ' . $e->getMessage(), 500);
}
