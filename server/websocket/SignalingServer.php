<?php

namespace VibeSpeak\WebSocket;

use Ratchet\MessageComponentInterface;
use Ratchet\ConnectionInterface;

class SignalingServer implements MessageComponentInterface
{
    protected $clients;
    protected $rooms;

    public function __construct()
    {
        $this->clients = new \SplObjectStorage;
        $this->rooms = [];
        echo "WebSocket server initialized\n";
    }

    public function onOpen(ConnectionInterface $conn)
    {
        $this->clients->attach($conn);
        $conn->roomId = null;
        $conn->userId = null;
        $conn->peerId = null;

        echo "New connection: {$conn->resourceId}\n";
    }

    public function onMessage(ConnectionInterface $from, $msg)
    {
        $data = json_decode($msg, true);

        if (!$data || !isset($data['type'])) {
            $this->sendError($from, 'Invalid message format');
            return;
        }

        echo "Message type: {$data['type']} from {$from->resourceId}\n";

        switch ($data['type']) {
            case 'join':
                $this->handleJoin($from, $data);
                break;

            case 'leave':
                $this->handleLeave($from);
                break;

            case 'offer':
            case 'answer':
            case 'ice-candidate':
                $this->handleSignaling($from, $data);
                break;

            case 'media-state':
                $this->handleMediaState($from, $data);
                break;

            case 'chat':
                $this->handleChat($from, $data);
                break;

            default:
                $this->sendError($from, 'Unknown message type');
        }
    }

    public function onClose(ConnectionInterface $conn)
    {
        $this->handleLeave($conn);
        $this->clients->detach($conn);
        echo "Connection closed: {$conn->resourceId}\n";
    }

    public function onError(ConnectionInterface $conn, \Exception $e)
    {
        echo "Error: {$e->getMessage()}\n";
        $conn->close();
    }

    private function handleJoin(ConnectionInterface $conn, $data)
    {
        if (empty($data['roomId']) || empty($data['userId'])) {
            $this->sendError($conn, 'roomId and userId are required');
            return;
        }

        $roomId = $data['roomId'];
        $userId = $data['userId'];
        $peerId = $data['peerId'] ?? uniqid('peer_');

        // Leave previous room if any
        if ($conn->roomId) {
            $this->handleLeave($conn);
        }

        // Join new room
        $conn->roomId = $roomId;
        $conn->userId = $userId;
        $conn->peerId = $peerId;

        if (!isset($this->rooms[$roomId])) {
            $this->rooms[$roomId] = [];
        }

        $this->rooms[$roomId][$conn->resourceId] = [
            'conn' => $conn,
            'userId' => $userId,
            'peerId' => $peerId,
            'audio' => $data['audio'] ?? true,
            'video' => $data['video'] ?? false,
            'screen' => $data['screen'] ?? false,
        ];

        // Send current participants to new user
        $participants = [];
        foreach ($this->rooms[$roomId] as $clientId => $client) {
            if ($clientId !== $conn->resourceId) {
                $participants[] = [
                    'peerId' => $client['peerId'],
                    'userId' => $client['userId'],
                    'audio' => $client['audio'],
                    'video' => $client['video'],
                    'screen' => $client['screen'],
                ];
            }
        }

        $this->send($conn, [
            'type' => 'joined',
            'peerId' => $peerId,
            'participants' => $participants
        ]);

        // Notify others about new participant
        $this->broadcastToRoom($roomId, [
            'type' => 'peer-joined',
            'peerId' => $peerId,
            'userId' => $userId,
            'audio' => $data['audio'] ?? true,
            'video' => $data['video'] ?? false,
            'screen' => $data['screen'] ?? false,
        ], $conn->resourceId);

        echo "User {$userId} joined room {$roomId} as {$peerId}\n";
    }

    private function handleLeave(ConnectionInterface $conn)
    {
        if (!$conn->roomId) {
            return;
        }

        $roomId = $conn->roomId;
        $peerId = $conn->peerId;

        if (isset($this->rooms[$roomId][$conn->resourceId])) {
            unset($this->rooms[$roomId][$conn->resourceId]);

            // Notify others
            $this->broadcastToRoom($roomId, [
                'type' => 'peer-left',
                'peerId' => $peerId
            ]);

            // Clean up empty rooms
            if (empty($this->rooms[$roomId])) {
                unset($this->rooms[$roomId]);
            }

            echo "Peer {$peerId} left room {$roomId}\n";
        }

        $conn->roomId = null;
        $conn->userId = null;
        $conn->peerId = null;
    }

    private function handleSignaling(ConnectionInterface $from, $data)
    {
        if (empty($data['targetPeerId'])) {
            $this->sendError($from, 'targetPeerId is required');
            return;
        }

        $roomId = $from->roomId;
        if (!$roomId || !isset($this->rooms[$roomId])) {
            $this->sendError($from, 'Not in a room');
            return;
        }

        // Find target peer
        $targetConn = null;
        foreach ($this->rooms[$roomId] as $client) {
            if ($client['peerId'] === $data['targetPeerId']) {
                $targetConn = $client['conn'];
                break;
            }
        }

        if ($targetConn) {
            $message = [
                'type' => $data['type'],
                'fromPeerId' => $from->peerId,
            ];

            if (isset($data['sdp'])) {
                $message['sdp'] = $data['sdp'];
            }
            if (isset($data['candidate'])) {
                $message['candidate'] = $data['candidate'];
            }

            $this->send($targetConn, $message);
        } else {
            $this->sendError($from, 'Target peer not found');
        }
    }

    private function handleMediaState(ConnectionInterface $from, $data)
    {
        $roomId = $from->roomId;
        if (!$roomId || !isset($this->rooms[$roomId][$from->resourceId])) {
            return;
        }

        // Update media state
        if (isset($data['audio'])) {
            $this->rooms[$roomId][$from->resourceId]['audio'] = $data['audio'];
        }
        if (isset($data['video'])) {
            $this->rooms[$roomId][$from->resourceId]['video'] = $data['video'];
        }
        if (isset($data['screen'])) {
            $this->rooms[$roomId][$from->resourceId]['screen'] = $data['screen'];
        }

        // Broadcast to others
        $this->broadcastToRoom($roomId, [
            'type' => 'peer-media-state',
            'peerId' => $from->peerId,
            'audio' => $this->rooms[$roomId][$from->resourceId]['audio'],
            'video' => $this->rooms[$roomId][$from->resourceId]['video'],
            'screen' => $this->rooms[$roomId][$from->resourceId]['screen'],
        ], $from->resourceId);
    }

    private function handleChat(ConnectionInterface $from, $data)
    {
        $roomId = $from->roomId;
        if (!$roomId) {
            return;
        }

        $message = [
            'type' => 'chat',
            'userId' => $from->userId,
            'peerId' => $from->peerId,
            'message' => $data['message'] ?? '',
            'timestamp' => time() * 1000 // JavaScript uses milliseconds
        ];

        // Include image if present
        if (!empty($data['image'])) {
            $message['image'] = $data['image'];
        }

        $this->broadcastToRoom($roomId, $message, $from->resourceId);
    }

    private function broadcastToRoom($roomId, $message, $excludeResourceId = null)
    {
        if (!isset($this->rooms[$roomId])) {
            return;
        }

        foreach ($this->rooms[$roomId] as $clientId => $client) {
            if ($clientId !== $excludeResourceId) {
                $this->send($client['conn'], $message);
            }
        }
    }

    private function send(ConnectionInterface $conn, $data)
    {
        $conn->send(json_encode($data));
    }

    private function sendError(ConnectionInterface $conn, $message)
    {
        $this->send($conn, [
            'type' => 'error',
            'message' => $message
        ]);
    }
}
