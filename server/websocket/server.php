<?php

require_once __DIR__ . '/../vendor/autoload.php';

use Ratchet\Server\IoServer;
use Ratchet\Http\HttpServer;
use Ratchet\WebSocket\WsServer;
use VibeSpeak\WebSocket\SignalingServer;
use React\EventLoop\Factory;

$config = include __DIR__ . '/../config/app.php';

// Create event loop
$loop = Factory::create();

$server = IoServer::factory(
    new HttpServer(
        new WsServer(
            new SignalingServer($loop)
        )
    ),
    $config['websocket']['port'],
    $config['websocket']['host'],
    $loop
);

echo "WebSocket server started on {$config['websocket']['host']}:{$config['websocket']['port']}\n";
echo "Empty rooms will be automatically deleted after 3 minutes of inactivity\n";

$server->run();
