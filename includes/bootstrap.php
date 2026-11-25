<?php
declare(strict_types=1);

require_once __DIR__ . '/../config/database.php';

ini_set('session.use_strict_mode', '1');
ini_set('session.use_only_cookies', '1');
ini_set('session.cookie_httponly', '1');
session_set_cookie_params([
    'lifetime' => 0,
    'path' => '/',
    'secure' => !empty($_SERVER['HTTPS']) && $_SERVER['HTTPS'] !== 'off',
    'httponly' => true,
    'samesite' => 'Lax',
]);
session_start();

$sessionIdleLimit = 1800;
if (isset($_SESSION['last_activity']) && time() - (int) $_SESSION['last_activity'] > $sessionIdleLimit) {
    $_SESSION = [];
    session_regenerate_id(true);
}
$_SESSION['last_activity'] = time();

header("Content-Security-Policy: default-src 'self'; style-src 'self'; script-src 'self'; img-src 'self' data:; font-src 'self'; form-action 'self'; base-uri 'self'; frame-ancestors 'none'");
header('X-Frame-Options: DENY');
header('X-Content-Type-Options: nosniff');
header('Referrer-Policy: strict-origin-when-cross-origin');
header('Permissions-Policy: camera=(), microphone=(), geolocation=()');
header('Cache-Control: no-store, private');
if (!empty($_SERVER['HTTPS']) && $_SERVER['HTTPS'] !== 'off') {
    header('Strict-Transport-Security: max-age=31536000; includeSubDomains');
}

function e(mixed $value): string
{
    return htmlspecialchars((string) $value, ENT_QUOTES | ENT_SUBSTITUTE, 'UTF-8');
}

function csrf_token(): string
{
    if (!isset($_SESSION['csrf_token'])) {
        $_SESSION['csrf_token'] = bin2hex(random_bytes(32));
    }
    return $_SESSION['csrf_token'];
}

function verify_csrf(): void
{
    $submitted = (string) ($_POST['csrf_token'] ?? '');
    if ($submitted === '' || !hash_equals(csrf_token(), $submitted)) {
        http_response_code(403);
        throw new RuntimeException('El formulario expiró o el token de seguridad no es válido. Recarga e inténtalo nuevamente.');
    }
}

function current_user(): ?array
{
    static $loaded = false;
    static $user = null;
    if ($loaded) {
        return $user;
    }
    $loaded = true;
    if (empty($_SESSION['user_id'])) {
        return null;
    }

    $statement = db()->prepare(
        'SELECT u.id, u.full_name, u.email, u.role_id, u.career_id, u.status,
            r.name AS role_name, r.access_profile AS role, r.label AS role_label, c.name AS career_name
         FROM users u JOIN roles r ON r.id = u.role_id
         LEFT JOIN careers c ON c.id = u.career_id
         WHERE u.id = :id LIMIT 1'
    );
    $statement->execute(['id' => (int) $_SESSION['user_id']]);
    $user = $statement->fetch() ?: null;
    if (!$user || $user['status'] !== 'active') {
        unset($_SESSION['user_id']);
        $user = null;
    }
    return $user;
}

function require_login(): array
{
    $user = current_user();
    if (!$user) {
        header('Location: index.php');
        exit;
    }
    return $user;
}

function require_roles(array $allowed): array
{
    $user = require_login();
    if (!in_array($user['role'], $allowed, true)) {
        http_response_code(403);
        throw new RuntimeException('No tienes permiso para realizar esta acción.');
    }
    return $user;
}

function password_is_strong(string $password): bool
{
    return strlen($password) >= 10
        && preg_match('/[a-z]/', $password) === 1
        && preg_match('/[A-Z]/', $password) === 1
        && preg_match('/[0-9]/', $password) === 1
        && preg_match('/[^A-Za-z0-9]/', $password) === 1;
}

function audit_log(PDO $pdo, ?int $userId, string $action, string $entity, ?int $entityId = null, ?string $details = null): void
{
    $statement = $pdo->prepare(
        'INSERT INTO audit_logs (user_id, action, entity, entity_id, details, ip_address)
         VALUES (:user_id, :action, :entity, :entity_id, :details, :ip)'
    );
    $statement->execute([
        'user_id' => $userId,
        'action' => $action,
        'entity' => $entity,
        'entity_id' => $entityId,
        'details' => $details,
        'ip' => substr((string) ($_SERVER['REMOTE_ADDR'] ?? ''), 0, 45),
    ]);
}

function flash(string $type, string $message): void
{
    $_SESSION['flash'] = ['type' => $type, 'message' => $message];
}

function redirect_to(string $page = 'dashboard'): never
{
    header('Location: index.php?page=' . rawurlencode($page));
    exit;
}
