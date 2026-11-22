<?php
declare(strict_types=1);

function db(): PDO
{
    static $connection = null;
    if ($connection instanceof PDO) {
        return $connection;
    }

    $host = getenv('EDUCORE_DB_HOST') ?: '127.0.0.1';
    $name = getenv('EDUCORE_DB_NAME') ?: 'educore';
    $user = getenv('EDUCORE_DB_USER') ?: 'root';
    $password = getenv('EDUCORE_DB_PASSWORD') ?: '';
    $dsn = sprintf('mysql:host=%s;dbname=%s;charset=utf8mb4', $host, $name);

    $connection = new PDO($dsn, $user, $password, [
        PDO::ATTR_ERRMODE => PDO::ERRMODE_EXCEPTION,
        PDO::ATTR_DEFAULT_FETCH_MODE => PDO::FETCH_ASSOC,
        PDO::ATTR_EMULATE_PREPARES => false,
    ]);

    return $connection;
}
