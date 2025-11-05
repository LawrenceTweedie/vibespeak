<?php

require_once __DIR__ . '/../vendor/autoload.php';

use Ratchet\Server\IoServer;
use Ratchet\Http\HttpServer;
use Ratchet\WebSocket\WsServer;
use VibeSpeak\WebSocket\SignalingServer;

$config = include __DIR__ . '/../config/app.php';

$server = IoServer::factory(
    new HttpServer(
        new WsServer(
            new SignalingServer()
        )
    ),
    $config['websocket']['port'],
    $config['websocket']['host']
);

echo "WebSocket server started on {$config['websocket']['host']}:{$config['websocket']['port']}\n";

$server->run();
