<?php
/**
 * Application Configuration
 */

return [
    'websocket' => [
        'host' => getenv('WS_HOST') ?: '0.0.0.0',
        'port' => getenv('WS_PORT') ?: 8080,
    ],
    'api' => [
        'host' => getenv('API_HOST') ?: '0.0.0.0',
        'port' => getenv('API_PORT') ?: 8000,
    ],
    'cors' => [
        'allowed_origins' => ['*'],
        'allowed_methods' => ['GET', 'POST', 'PUT', 'DELETE', 'OPTIONS'],
        'allowed_headers' => ['Content-Type', 'Authorization'],
    ],
];
