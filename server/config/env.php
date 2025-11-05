<?php
/**
 * Simple .env file loader
 */

function loadEnv($path) {
    if (!file_exists($path)) {
        return;
    }

    $lines = file($path, FILE_IGNORE_NEW_LINES | FILE_SKIP_EMPTY_LINES);
    foreach ($lines as $line) {
        // Skip comments
        if (strpos(trim($line), '#') === 0) {
            continue;
        }

        // Parse KEY=VALUE
        if (strpos($line, '=') !== false) {
            list($key, $value) = explode('=', $line, 2);
            $key = trim($key);
            $value = trim($value);

            // Remove quotes if present
            $value = trim($value, '"\'');

            // Set in $_ENV and putenv
            $_ENV[$key] = $value;
            putenv("$key=$value");
        }
    }
}

// Load .env file from server directory
$envPath = __DIR__ . '/../.env';
loadEnv($envPath);
