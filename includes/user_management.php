<?php
declare(strict_types=1);

function handle_user_management_action(PDO $pdo, int $actorId, int $careerId, string $action): never
{
    $profiles = ['admin', 'career_coordinator', 'teacher', 'student'];

    if ($action === 'user_request_create') {
        require_roles(['career_coordinator']);
        $name = trim((string) ($_POST['full_name'] ?? ''));
        $email = strtolower(trim((string) ($_POST['email'] ?? '')));
        $requestedRole = (string) ($_POST['requested_role'] ?? '');
        $message = trim((string) ($_POST['message'] ?? ''));
        if ($name === '' || mb_strlen($name) > 120 || strlen($email) > 190 || !filter_var($email, FILTER_VALIDATE_EMAIL)
            || !in_array($requestedRole, ['teacher', 'student'], true) || mb_strlen($message) > 500) {
            throw new RuntimeException('Verifica los datos de la solicitud.');
        }
        $careerQuery = $pdo->prepare("SELECT id FROM careers WHERE id = :id AND status = 'active'");
        $careerQuery->execute(['id' => $careerId]);
        if (!$careerQuery->fetch()) {
            throw new RuntimeException('Tu cuenta no tiene una carrera activa asignada.');
        }
        $query = $pdo->prepare('SELECT id FROM users WHERE email = :email');
        $query->execute(['email' => $email]);
        if ($query->fetch()) {
            throw new RuntimeException('Ya existe una cuenta con ese correo.');
        }
        $query = $pdo->prepare("SELECT id FROM user_requests WHERE email = :email AND status IN ('pending','approved')");
        $query->execute(['email' => $email]);
        if ($query->fetch()) {
            throw new RuntimeException('Ya hay una solicitud abierta para ese correo.');
        }
        $insert = $pdo->prepare('INSERT INTO user_requests (coordinator_id,career_id,full_name,email,requested_role,message) VALUES (:coordinator,:career,:name,:email,:role,:message)');
        $insert->execute(['coordinator' => $actorId, 'career' => $careerId, 'name' => $name, 'email' => $email, 'role' => $requestedRole, 'message' => $message ?: null]);
        $id = (int) $pdo->lastInsertId();
        audit_log($pdo, $actorId, 'request', 'user', $id, $requestedRole);
        flash('success', 'Solicitud enviada al Administrador de Sistema.');
        redirect_to('users');
    }

    if ($action === 'user_request_review') {
        require_roles(['system_admin']);
        $id = (int) ($_POST['request_id'] ?? 0);
        $decision = (string) ($_POST['decision'] ?? '');
        if (!in_array($decision, ['approved', 'rejected'], true)) {
            throw new RuntimeException('Decisión de solicitud no válida.');
        }
        $update = $pdo->prepare("UPDATE user_requests SET status = :status, reviewed_by = :actor, reviewed_at = NOW() WHERE id = :id AND status = 'pending'");
        $update->execute(['status' => $decision, 'actor' => $actorId, 'id' => $id]);
        if (!$update->rowCount()) {
            throw new RuntimeException('La solicitud ya fue atendida o no existe.');
        }
        audit_log($pdo, $actorId, $decision, 'user_request', $id);
        flash('success', $decision === 'approved' ? 'Solicitud aprobada; completa el registro desde la bandeja.' : 'Solicitud rechazada.');
        redirect_to('users');
    }

    if ($action === 'user_create' || $action === 'user_update') {
        require_roles(['system_admin']);
        $id = (int) ($_POST['user_id'] ?? 0);
        $requestId = (int) ($_POST['request_id'] ?? 0);
        $name = trim((string) ($_POST['full_name'] ?? ''));
        $email = strtolower(trim((string) ($_POST['email'] ?? '')));
        $password = (string) ($_POST['password'] ?? '');
        $newRole = (string) ($_POST['role'] ?? '');
        $career = (int) ($_POST['career_id'] ?? 0);
        $code = strtoupper(trim((string) ($_POST['student_code'] ?? '')));
        $query = $pdo->prepare('SELECT id, access_profile FROM roles WHERE name = :name');
        $query->execute(['name' => $newRole]);
        $role = $query->fetch();
        $profile = (string) ($role['access_profile'] ?? '');
        $needsCareer = in_array($profile, ['career_coordinator', 'teacher', 'student'], true);

        if ($name === '' || mb_strlen($name) > 120 || strlen($email) > 190 || !filter_var($email, FILTER_VALIDATE_EMAIL)
            || !$role || ($action === 'user_create' && !password_is_strong($password))
            || ($action === 'user_update' && $password !== '' && !password_is_strong($password))
            || ($needsCareer && $career < 1) || ($profile === 'student' && $code === '')) {
            throw new RuntimeException('Verifica los datos, rol, carrera y política de contraseña.');
        }
        if ($needsCareer) {
            $query = $pdo->prepare("SELECT id FROM careers WHERE id = :id AND status = 'active'");
            $query->execute(['id' => $career]);
            if (!$query->fetch()) {
                throw new RuntimeException('Selecciona una carrera activa.');
            }
        }

        $pdo->beginTransaction();
        if ($action === 'user_create') {
            if ($requestId) {
                $query = $pdo->prepare("SELECT email, requested_role, career_id FROM user_requests WHERE id = :id AND status = 'approved'");
                $query->execute(['id' => $requestId]);
                $request = $query->fetch();
                if (!$request || $request['email'] !== $email || $request['requested_role'] !== $profile || (int) $request['career_id'] !== $career) {
                    throw new RuntimeException('La cuenta no coincide con la solicitud aprobada.');
                }
            }
            $insert = $pdo->prepare('INSERT INTO users (role_id,career_id,full_name,email,password_hash) VALUES (:role,:career,:name,:email,:hash)');
            $insert->execute(['role' => $role['id'], 'career' => $needsCareer ? $career : null, 'name' => $name, 'email' => $email, 'hash' => password_hash($password, PASSWORD_DEFAULT)]);
            $id = (int) $pdo->lastInsertId();
            if ($profile === 'student') {
                $insert = $pdo->prepare('INSERT INTO students (user_id,career_id,full_name,email,student_code,enrollment_year) VALUES (:user,:career,:name,:email,:code,:year)');
                $insert->execute(['user' => $id, 'career' => $career, 'name' => $name, 'email' => $email, 'code' => $code, 'year' => (int) date('Y')]);
            }
            if ($requestId) {
                $pdo->prepare("UPDATE user_requests SET status = 'fulfilled', reviewed_by = :actor, reviewed_at = NOW() WHERE id = :id AND status = 'approved'")->execute(['actor' => $actorId, 'id' => $requestId]);
            }
        } else {
            $query = $pdo->prepare('SELECT u.id, u.status, r.access_profile FROM users u JOIN roles r ON r.id = u.role_id WHERE u.id = :id');
            $query->execute(['id' => $id]);
            $oldUser = $query->fetch();
            if (!$oldUser || ($id === $actorId && $profile !== 'system_admin')) {
                throw new RuntimeException('No puedes quitarte los permisos de Administrador de Sistema.');
            }
            if ($oldUser['status'] === 'active' && $oldUser['access_profile'] === 'system_admin' && $profile !== 'system_admin') {
                $activeAdmins = (int) $pdo->query("SELECT COUNT(*) FROM users u JOIN roles r ON r.id = u.role_id WHERE u.status = 'active' AND r.access_profile = 'system_admin'")->fetchColumn();
                if ($activeAdmins <= 1) {
                    throw new RuntimeException('Debe permanecer al menos un Administrador de Sistema activo.');
                }
            }
            $params = ['role' => $role['id'], 'career' => $needsCareer ? $career : null, 'name' => $name, 'email' => $email, 'id' => $id];
            $sql = 'UPDATE users SET role_id = :role, career_id = :career, full_name = :name, email = :email';
            if ($password !== '') {
                $sql .= ', password_hash = :hash';
                $params['hash'] = password_hash($password, PASSWORD_DEFAULT);
            }
            $pdo->prepare($sql . ' WHERE id = :id')->execute($params);
            $query = $pdo->prepare('SELECT id FROM students WHERE user_id = :id');
            $query->execute(['id' => $id]);
            $studentId = $query->fetchColumn();
            if ($profile === 'student') {
                if ($studentId) {
                    $pdo->prepare("UPDATE students SET career_id = :career, full_name = :name, email = :email, student_code = :code, status = 'active' WHERE id = :id")->execute(['career' => $career, 'name' => $name, 'email' => $email, 'code' => $code, 'id' => $studentId]);
                } else {
                    $pdo->prepare('INSERT INTO students (user_id,career_id,full_name,email,student_code,enrollment_year) VALUES (:user,:career,:name,:email,:code,:year)')->execute(['user' => $id, 'career' => $career, 'name' => $name, 'email' => $email, 'code' => $code, 'year' => (int) date('Y')]);
                }
            } elseif ($studentId) {
                $pdo->prepare('UPDATE students SET user_id = NULL WHERE id = :id')->execute(['id' => $studentId]);
            }
        }
        $pdo->commit();
        audit_log($pdo, $actorId, $action === 'user_create' ? 'create' : 'update', 'user', $id, $newRole);
        flash('success', $action === 'user_create' ? 'Usuario registrado.' : 'Usuario actualizado.');
        redirect_to('users');
    }

    if ($action === 'user_status' || $action === 'user_delete') {
        require_roles(['system_admin']);
        $id = (int) ($_POST['user_id'] ?? 0);
        if ($id === $actorId) {
            throw new RuntimeException('No puedes desactivar ni eliminar tu propia cuenta.');
        }
        $query = $pdo->prepare('SELECT u.status, r.access_profile FROM users u JOIN roles r ON r.id = u.role_id WHERE u.id = :id');
        $query->execute(['id' => $id]);
        $target = $query->fetch();
        if (!$target) {
            throw new RuntimeException('Usuario no encontrado.');
        }
        if ($target['status'] === 'active' && $target['access_profile'] === 'system_admin') {
            $count = (int) $pdo->query("SELECT COUNT(*) FROM users u JOIN roles r ON r.id = u.role_id WHERE u.status = 'active' AND r.access_profile = 'system_admin'")->fetchColumn();
            if ($count <= 1) {
                throw new RuntimeException('Debe permanecer al menos un Administrador de Sistema activo.');
            }
        }
        if ($action === 'user_status') {
            $pdo->prepare("UPDATE users SET status = IF(status = 'active', 'inactive', 'active') WHERE id = :id")->execute(['id' => $id]);
            audit_log($pdo, $actorId, 'toggle_status', 'user', $id);
            flash('success', 'Estado actualizado.');
        } else {
            $query = $pdo->prepare('SELECT COUNT(*) FROM courses WHERE teacher_id = :id');
            $query->execute(['id' => $id]);
            if ((int) $query->fetchColumn() > 0) {
                throw new RuntimeException('Reasigna los cursos del docente antes de eliminar su cuenta.');
            }
            $pdo->beginTransaction();
            $pdo->prepare('UPDATE students SET user_id = NULL WHERE user_id = :id')->execute(['id' => $id]);
            $pdo->prepare('DELETE FROM users WHERE id = :id')->execute(['id' => $id]);
            $pdo->commit();
            audit_log($pdo, $actorId, 'delete', 'user', $id);
            flash('success', 'Usuario eliminado; los datos académicos del estudiante se conservaron.');
        }
        redirect_to('users');
    }

    if (str_starts_with($action, 'role_')) {
        require_roles(['system_admin']);
        $name = strtolower(trim((string) ($_POST['role_name'] ?? '')));
        $label = trim((string) ($_POST['role_label'] ?? ''));
        $description = trim((string) ($_POST['role_description'] ?? ''));
        $profile = (string) ($_POST['access_profile'] ?? '');
        $id = (int) ($_POST['role_id'] ?? 0);
        if ($action === 'role_create') {
            if (!preg_match('/^[a-z][a-z0-9_]{2,39}$/', $name) || $label === '' || mb_strlen($label) > 80 || mb_strlen($description) > 255 || !in_array($profile, $profiles, true)) {
                throw new RuntimeException('Verifica el nombre, descripción y perfil de acceso del rol.');
            }
            $pdo->prepare('INSERT INTO roles (name,label,description,access_profile) VALUES (:name,:label,:description,:profile)')->execute(['name' => $name, 'label' => $label, 'description' => $description, 'profile' => $profile]);
            $id = (int) $pdo->lastInsertId();
            audit_log($pdo, $actorId, 'create', 'role', $id, $name);
            flash('success', 'Rol creado con el perfil seleccionado.');
        } elseif ($action === 'role_update') {
            $query = $pdo->prepare('SELECT name FROM roles WHERE id = :id');
            $query->execute(['id' => $id]);
            $roleName = $query->fetchColumn();
            if (!$roleName || $label === '' || mb_strlen($label) > 80 || mb_strlen($description) > 255
                || (!in_array($roleName, ['system_admin','admin','career_coordinator','teacher','student'], true) && !in_array($profile, $profiles, true))
                || ($roleName === 'system_admin' && $profile !== 'system_admin')) {
                throw new RuntimeException('Verifica los datos; el perfil del administrador principal está protegido.');
            }
            if (in_array($roleName, ['system_admin','admin','career_coordinator','teacher','student'], true)) {
                $pdo->prepare('UPDATE roles SET label = :label, description = :description WHERE id = :id')->execute(['label' => $label, 'description' => $description, 'id' => $id]);
            } else {
                $pdo->prepare('UPDATE roles SET label = :label, description = :description, access_profile = :profile WHERE id = :id')->execute(['label' => $label, 'description' => $description, 'profile' => $profile, 'id' => $id]);
            }
            audit_log($pdo, $actorId, 'update', 'role', $id, (string) $roleName);
            flash('success', 'Rol actualizado.');
        } elseif ($action === 'role_delete') {
            $query = $pdo->prepare('SELECT name FROM roles WHERE id = :id');
            $query->execute(['id' => $id]);
            $roleName = $query->fetchColumn();
            if (!$roleName || in_array($roleName, ['system_admin','admin','career_coordinator','teacher','student'], true)) {
                throw new RuntimeException('Los roles base del sistema no se pueden eliminar.');
            }
            $query = $pdo->prepare('SELECT COUNT(*) FROM users WHERE role_id = :id');
            $query->execute(['id' => $id]);
            if ((int) $query->fetchColumn() > 0) {
                throw new RuntimeException('Reasigna los usuarios de este rol antes de eliminarlo.');
            }
            $pdo->prepare('DELETE FROM roles WHERE id = :id')->execute(['id' => $id]);
            audit_log($pdo, $actorId, 'delete', 'role', $id, (string) $roleName);
            flash('success', 'Rol eliminado.');
        }
        redirect_to('users');
    }

    throw new RuntimeException('Acción de usuarios no reconocida.');
}
