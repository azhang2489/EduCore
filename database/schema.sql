-- EduCore · Esquema y datos de demostración (MySQL 8.0+ / MariaDB 10.4+)
-- Importar este archivo desde phpMyAdmin o: mysql -u root -p < database/schema.sql
CREATE DATABASE IF NOT EXISTS educore CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
USE educore;
SET NAMES utf8mb4;
SET FOREIGN_KEY_CHECKS = 0;
DROP TABLE IF EXISTS audit_logs, user_requests, login_attempts, grades, schedules, enrollments, courses, students, users, roles, careers;
SET FOREIGN_KEY_CHECKS = 1;

CREATE TABLE careers (
  id SMALLINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  name VARCHAR(120) NOT NULL UNIQUE,
  code VARCHAR(20) NOT NULL UNIQUE,
  status ENUM('active','inactive') NOT NULL DEFAULT 'active',
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB;

CREATE TABLE roles (
  id TINYINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  name VARCHAR(40) NOT NULL UNIQUE,
  label VARCHAR(80) NOT NULL,
  description VARCHAR(255) NOT NULL,
  access_profile VARCHAR(40) NOT NULL DEFAULT 'admin'
) ENGINE=InnoDB;

CREATE TABLE users (
  id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  role_id TINYINT UNSIGNED NOT NULL,
  career_id SMALLINT UNSIGNED NULL,
  full_name VARCHAR(120) NOT NULL,
  email VARCHAR(190) NOT NULL UNIQUE,
  password_hash VARCHAR(255) NOT NULL,
  status ENUM('active','inactive') NOT NULL DEFAULT 'active',
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  CONSTRAINT fk_users_role FOREIGN KEY (role_id) REFERENCES roles(id),
  CONSTRAINT fk_users_career FOREIGN KEY (career_id) REFERENCES careers(id) ON DELETE SET NULL,
  INDEX idx_users_name (full_name),
  INDEX idx_users_role_career (role_id, career_id),
  INDEX idx_users_status (status)
) ENGINE=InnoDB;

CREATE TABLE students (
  id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  user_id INT UNSIGNED NULL UNIQUE,
  career_id SMALLINT UNSIGNED NOT NULL,
  full_name VARCHAR(120) NOT NULL,
  email VARCHAR(190) NULL,
  student_code VARCHAR(30) NOT NULL UNIQUE,
  enrollment_year YEAR NOT NULL,
  status ENUM('active','inactive','graduated') NOT NULL DEFAULT 'active',
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT fk_students_user FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
  CONSTRAINT fk_students_career FOREIGN KEY (career_id) REFERENCES careers(id),
  INDEX idx_students_career (career_id),
  INDEX idx_students_name (full_name),
  INDEX idx_students_email (email),
  INDEX idx_students_status (status)
) ENGINE=InnoDB;

CREATE TABLE courses (
  id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  career_id SMALLINT UNSIGNED NOT NULL,
  teacher_id INT UNSIGNED NOT NULL,
  code VARCHAR(24) NOT NULL UNIQUE,
  name VARCHAR(140) NOT NULL,
  credits TINYINT UNSIGNED NOT NULL DEFAULT 3,
  capacity SMALLINT UNSIGNED NOT NULL DEFAULT 30,
  status ENUM('active','inactive') NOT NULL DEFAULT 'active',
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  CONSTRAINT fk_courses_career FOREIGN KEY (career_id) REFERENCES careers(id),
  CONSTRAINT fk_courses_teacher FOREIGN KEY (teacher_id) REFERENCES users(id),
  INDEX idx_courses_career (career_id),
  INDEX idx_courses_teacher (teacher_id),
  INDEX idx_courses_name (name),
  INDEX idx_courses_status (status)
) ENGINE=InnoDB;

CREATE TABLE enrollments (
  id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  student_id INT UNSIGNED NOT NULL,
  course_id INT UNSIGNED NOT NULL,
  status ENUM('enrolled','withdrawn','completed') NOT NULL DEFAULT 'enrolled',
  enrolled_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT fk_enrollments_student FOREIGN KEY (student_id) REFERENCES students(id) ON DELETE CASCADE,
  CONSTRAINT fk_enrollments_course FOREIGN KEY (course_id) REFERENCES courses(id) ON DELETE CASCADE,
  UNIQUE KEY uq_enrollment_student_course (student_id, course_id),
  INDEX idx_enrollments_course_status (course_id, status),
  INDEX idx_enrollments_student_status (student_id, status)
) ENGINE=InnoDB;

CREATE TABLE schedules (
  id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  course_id INT UNSIGNED NOT NULL,
  weekday TINYINT UNSIGNED NOT NULL COMMENT '1=Lunes ... 7=Domingo',
  starts_at TIME NOT NULL,
  ends_at TIME NOT NULL,
  classroom VARCHAR(80) NOT NULL,
  CONSTRAINT fk_schedules_course FOREIGN KEY (course_id) REFERENCES courses(id) ON DELETE CASCADE,
  UNIQUE KEY uq_course_schedule (course_id, weekday, starts_at),
  INDEX idx_schedule_day_time (weekday, starts_at)
) ENGINE=InnoDB;

CREATE TABLE grades (
  id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  enrollment_id INT UNSIGNED NOT NULL,
  assessment_name VARCHAR(80) NOT NULL,
  score DECIMAL(5,2) NULL,
  updated_by INT UNSIGNED NULL,
  updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  CONSTRAINT fk_grades_enrollment FOREIGN KEY (enrollment_id) REFERENCES enrollments(id) ON DELETE CASCADE,
  CONSTRAINT fk_grades_updater FOREIGN KEY (updated_by) REFERENCES users(id) ON DELETE SET NULL,
  CONSTRAINT chk_grade_range CHECK (score >= 0 AND score <= 100),
  UNIQUE KEY uq_grade_assessment (enrollment_id, assessment_name),
  INDEX idx_grades_updated (updated_at)
) ENGINE=InnoDB;

CREATE TABLE login_attempts (
  id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  email VARCHAR(190) NOT NULL,
  ip_address VARCHAR(45) NOT NULL,
  attempted_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  INDEX idx_login_attempts_email_time (email, attempted_at),
  INDEX idx_login_attempts_ip_time (ip_address, attempted_at)
) ENGINE=InnoDB;

CREATE TABLE user_requests (
  id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  coordinator_id INT UNSIGNED NOT NULL,
  career_id SMALLINT UNSIGNED NOT NULL,
  full_name VARCHAR(120) NOT NULL,
  email VARCHAR(190) NOT NULL,
  requested_role ENUM('teacher','student') NOT NULL,
  message VARCHAR(500) NULL,
  status ENUM('pending','approved','rejected','fulfilled') NOT NULL DEFAULT 'pending',
  reviewed_by INT UNSIGNED NULL,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  reviewed_at TIMESTAMP NULL DEFAULT NULL,
  CONSTRAINT fk_user_requests_coordinator FOREIGN KEY (coordinator_id) REFERENCES users(id) ON DELETE CASCADE,
  CONSTRAINT fk_user_requests_career FOREIGN KEY (career_id) REFERENCES careers(id),
  CONSTRAINT fk_user_requests_reviewer FOREIGN KEY (reviewed_by) REFERENCES users(id) ON DELETE SET NULL,
  INDEX idx_user_requests_status_time (status, created_at),
  INDEX idx_user_requests_coordinator (coordinator_id, created_at)
) ENGINE=InnoDB;

CREATE TABLE audit_logs (
  id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  user_id INT UNSIGNED NULL,
  action VARCHAR(80) NOT NULL,
  entity VARCHAR(80) NOT NULL,
  entity_id BIGINT UNSIGNED NULL,
  details VARCHAR(255) NULL,
  ip_address VARCHAR(45) NULL,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT fk_audit_user FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE SET NULL,
  INDEX idx_audit_user_time (user_id, created_at),
  INDEX idx_audit_entity (entity, entity_id)
) ENGINE=InnoDB;

INSERT INTO roles (name, label, description, access_profile) VALUES
('system_admin', 'Administrador de Sistema', 'Acceso total a usuarios, carreras, cursos, matrículas y notas.', 'system_admin'),
('admin', 'Administrador', 'Acceso de solo lectura a toda la información.', 'admin'),
('career_coordinator', 'Coordinador de Carrera', 'Gestiona estudiantes y cursos de su carrera asignada.', 'career_coordinator'),
('teacher', 'Docente', 'Consulta sus cursos y modifica notas de sus propios estudiantes.', 'teacher'),
('student', 'Estudiante', 'Consulta sus cursos, horarios y calificaciones.', 'student');

INSERT INTO careers (name, code) VALUES
('Ingeniería de Software', 'ISW'),
('Ingeniería de Sistemas', 'ISC'),
('Diseño Gráfico', 'DGR'),
('Ciencias Computacionales', 'CCC');

-- Contraseña común de demo para todas las cuentas: EduCore2026!
-- Este valor es un hash bcrypt generado con password_hash(), nunca texto plano.
INSERT INTO users (role_id, career_id, full_name, email, password_hash) VALUES
((SELECT id FROM roles WHERE name='system_admin'), NULL, 'María Cedeño', 'maria.cedeno@educore.edu', '$2y$10$QNcuTjiKasqSfEibJvX/ru06BGg8wUSpO2aYORsppTDuKgYWBbC2.'),
((SELECT id FROM roles WHERE name='admin'), NULL, 'Víctor Gómez', 'victor.gomez@educore.edu', '$2y$10$QNcuTjiKasqSfEibJvX/ru06BGg8wUSpO2aYORsppTDuKgYWBbC2.'),
((SELECT id FROM roles WHERE name='career_coordinator'), (SELECT id FROM careers WHERE code='ISW'), 'Elena Castillo', 'elena.castillo@educore.edu', '$2y$10$QNcuTjiKasqSfEibJvX/ru06BGg8wUSpO2aYORsppTDuKgYWBbC2.'),
((SELECT id FROM roles WHERE name='career_coordinator'), (SELECT id FROM careers WHERE code='ISC'), 'Roberto Méndez', 'roberto.mendez@educore.edu', '$2y$10$QNcuTjiKasqSfEibJvX/ru06BGg8wUSpO2aYORsppTDuKgYWBbC2.'),
((SELECT id FROM roles WHERE name='career_coordinator'), (SELECT id FROM careers WHERE code='DGR'), 'Lucía Pérez', 'lucia.perez@educore.edu', '$2y$10$QNcuTjiKasqSfEibJvX/ru06BGg8wUSpO2aYORsppTDuKgYWBbC2.'),
((SELECT id FROM roles WHERE name='career_coordinator'), (SELECT id FROM careers WHERE code='CCC'), 'Gabriel Núñez', 'gabriel.nunez@educore.edu', '$2y$10$QNcuTjiKasqSfEibJvX/ru06BGg8wUSpO2aYORsppTDuKgYWBbC2.'),
((SELECT id FROM roles WHERE name='teacher'), (SELECT id FROM careers WHERE code='ISW'), 'Andrea López', 'andrea.lopez@educore.edu', '$2y$10$QNcuTjiKasqSfEibJvX/ru06BGg8wUSpO2aYORsppTDuKgYWBbC2.'),
((SELECT id FROM roles WHERE name='teacher'), (SELECT id FROM careers WHERE code='ISW'), 'Carlos Méndez', 'carlos.mendez@educore.edu', '$2y$10$QNcuTjiKasqSfEibJvX/ru06BGg8wUSpO2aYORsppTDuKgYWBbC2.'),
((SELECT id FROM roles WHERE name='teacher'), (SELECT id FROM careers WHERE code='ISC'), 'Julio Rivera', 'julio.rivera@educore.edu', '$2y$10$QNcuTjiKasqSfEibJvX/ru06BGg8wUSpO2aYORsppTDuKgYWBbC2.'),
((SELECT id FROM roles WHERE name='teacher'), (SELECT id FROM careers WHERE code='ISC'), 'Ana Castillo', 'ana.castillo@educore.edu', '$2y$10$QNcuTjiKasqSfEibJvX/ru06BGg8wUSpO2aYORsppTDuKgYWBbC2.'),
((SELECT id FROM roles WHERE name='teacher'), (SELECT id FROM careers WHERE code='DGR'), 'Laura Pérez', 'laura.perez@educore.edu', '$2y$10$QNcuTjiKasqSfEibJvX/ru06BGg8wUSpO2aYORsppTDuKgYWBbC2.'),
((SELECT id FROM roles WHERE name='teacher'), (SELECT id FROM careers WHERE code='DGR'), 'Miguel Torres', 'miguel.torres@educore.edu', '$2y$10$QNcuTjiKasqSfEibJvX/ru06BGg8wUSpO2aYORsppTDuKgYWBbC2.'),
((SELECT id FROM roles WHERE name='teacher'), (SELECT id FROM careers WHERE code='CCC'), 'Sofía Díaz', 'sofia.diaz@educore.edu', '$2y$10$QNcuTjiKasqSfEibJvX/ru06BGg8wUSpO2aYORsppTDuKgYWBbC2.'),
((SELECT id FROM roles WHERE name='teacher'), (SELECT id FROM careers WHERE code='CCC'), 'Ricardo Gómez', 'ricardo.gomez@educore.edu', '$2y$10$QNcuTjiKasqSfEibJvX/ru06BGg8wUSpO2aYORsppTDuKgYWBbC2.');

INSERT INTO users (role_id, career_id, full_name, email, password_hash) VALUES
((SELECT id FROM roles WHERE name='student'), (SELECT id FROM careers WHERE code='ISW'), 'Javier Rodríguez', 'javier.rodriguez@educore.edu', '$2y$10$QNcuTjiKasqSfEibJvX/ru06BGg8wUSpO2aYORsppTDuKgYWBbC2.'),
((SELECT id FROM roles WHERE name='student'), (SELECT id FROM careers WHERE code='ISW'), 'Sofía Vargas', 'sofia.vargas@educore.edu', '$2y$10$QNcuTjiKasqSfEibJvX/ru06BGg8wUSpO2aYORsppTDuKgYWBbC2.'),
((SELECT id FROM roles WHERE name='student'), (SELECT id FROM careers WHERE code='ISC'), 'Daniela Pérez', 'daniela.perez@educore.edu', '$2y$10$QNcuTjiKasqSfEibJvX/ru06BGg8wUSpO2aYORsppTDuKgYWBbC2.'),
((SELECT id FROM roles WHERE name='student'), (SELECT id FROM careers WHERE code='CCC'), 'Carlos Mendoza', 'carlos.mendoza@educore.edu', '$2y$10$QNcuTjiKasqSfEibJvX/ru06BGg8wUSpO2aYORsppTDuKgYWBbC2.'),
((SELECT id FROM roles WHERE name='student'), (SELECT id FROM careers WHERE code='DGR'), 'Ana Lucía Morales', 'ana.morales@educore.edu', '$2y$10$QNcuTjiKasqSfEibJvX/ru06BGg8wUSpO2aYORsppTDuKgYWBbC2.');

INSERT INTO students (user_id, career_id, full_name, email, student_code, enrollment_year) VALUES
((SELECT id FROM users WHERE email='javier.rodriguez@educore.edu'), (SELECT id FROM careers WHERE code='ISW'), 'Javier Rodríguez', 'javier.rodriguez@educore.edu', '2026-ISW-001', 2026),
((SELECT id FROM users WHERE email='sofia.vargas@educore.edu'), (SELECT id FROM careers WHERE code='ISW'), 'Sofía Vargas', 'sofia.vargas@educore.edu', '2026-ISW-002', 2026),
((SELECT id FROM users WHERE email='daniela.perez@educore.edu'), (SELECT id FROM careers WHERE code='ISC'), 'Daniela Pérez', 'daniela.perez@educore.edu', '2026-ISC-001', 2026),
((SELECT id FROM users WHERE email='carlos.mendoza@educore.edu'), (SELECT id FROM careers WHERE code='CCC'), 'Carlos Mendoza', 'carlos.mendoza@educore.edu', '2026-CCC-001', 2026),
((SELECT id FROM users WHERE email='ana.morales@educore.edu'), (SELECT id FROM careers WHERE code='DGR'), 'Ana Lucía Morales', 'ana.morales@educore.edu', '2026-DGR-001', 2026);

INSERT INTO courses (career_id, teacher_id, code, name, credits, capacity) VALUES
((SELECT id FROM careers WHERE code='ISW'), (SELECT id FROM users WHERE email='andrea.lopez@educore.edu'), 'ISW-101', 'Programación Web', 4, 30),
((SELECT id FROM careers WHERE code='ISW'), (SELECT id FROM users WHERE email='andrea.lopez@educore.edu'), 'ISW-102', 'Diseño de Interfaces', 3, 30),
((SELECT id FROM careers WHERE code='ISW'), (SELECT id FROM users WHERE email='andrea.lopez@educore.edu'), 'ISW-103', 'Estructuras de Datos', 4, 28),
((SELECT id FROM careers WHERE code='ISW'), (SELECT id FROM users WHERE email='carlos.mendez@educore.edu'), 'ISW-104', 'Bases de Datos', 4, 30),
((SELECT id FROM careers WHERE code='ISW'), (SELECT id FROM users WHERE email='carlos.mendez@educore.edu'), 'ISW-105', 'Arquitectura de Software', 3, 25),
((SELECT id FROM careers WHERE code='ISC'), (SELECT id FROM users WHERE email='julio.rivera@educore.edu'), 'ISC-101', 'Matemática Aplicada', 4, 35),
((SELECT id FROM careers WHERE code='ISC'), (SELECT id FROM users WHERE email='julio.rivera@educore.edu'), 'ISC-102', 'Fundamentos de Redes', 3, 30),
((SELECT id FROM careers WHERE code='ISC'), (SELECT id FROM users WHERE email='julio.rivera@educore.edu'), 'ISC-103', 'Sistemas Operativos', 4, 28),
((SELECT id FROM careers WHERE code='ISC'), (SELECT id FROM users WHERE email='ana.castillo@educore.edu'), 'ISC-104', 'Administración de Servidores', 3, 25),
((SELECT id FROM careers WHERE code='ISC'), (SELECT id FROM users WHERE email='ana.castillo@educore.edu'), 'ISC-105', 'Seguridad Informática', 4, 30),
((SELECT id FROM careers WHERE code='DGR'), (SELECT id FROM users WHERE email='laura.perez@educore.edu'), 'DGR-101', 'Comunicación Visual', 3, 30),
((SELECT id FROM careers WHERE code='DGR'), (SELECT id FROM users WHERE email='laura.perez@educore.edu'), 'DGR-102', 'Ilustración Digital', 4, 25),
((SELECT id FROM careers WHERE code='DGR'), (SELECT id FROM users WHERE email='laura.perez@educore.edu'), 'DGR-103', 'Tipografía', 3, 28),
((SELECT id FROM careers WHERE code='DGR'), (SELECT id FROM users WHERE email='miguel.torres@educore.edu'), 'DGR-104', 'Fotografía', 3, 24),
((SELECT id FROM careers WHERE code='DGR'), (SELECT id FROM users WHERE email='miguel.torres@educore.edu'), 'DGR-105', 'Diseño Editorial', 4, 26),
((SELECT id FROM careers WHERE code='CCC'), (SELECT id FROM users WHERE email='sofia.diaz@educore.edu'), 'CCC-101', 'Fundamentos de Computación', 4, 30),
((SELECT id FROM careers WHERE code='CCC'), (SELECT id FROM users WHERE email='sofia.diaz@educore.edu'), 'CCC-102', 'Matemática Discreta', 4, 30),
((SELECT id FROM careers WHERE code='CCC'), (SELECT id FROM users WHERE email='sofia.diaz@educore.edu'), 'CCC-103', 'Inteligencia Artificial', 4, 28),
((SELECT id FROM careers WHERE code='CCC'), (SELECT id FROM users WHERE email='ricardo.gomez@educore.edu'), 'CCC-104', 'Análisis de Algoritmos', 3, 25),
((SELECT id FROM careers WHERE code='CCC'), (SELECT id FROM users WHERE email='ricardo.gomez@educore.edu'), 'CCC-105', 'Computación Científica', 3, 26);

INSERT INTO schedules (course_id, weekday, starts_at, ends_at, classroom)
SELECT id, MOD(id - 1, 5) + 1, MAKETIME(8 + MOD(id, 7), 0, 0), MAKETIME(9 + MOD(id, 7), 0, 0), CONCAT('Aula ', 100 + id) FROM courses;

-- Cada estudiante queda matriculado en 4 cursos y uno de ellos en 5; todos pertenecen a su carrera.
INSERT INTO enrollments (student_id, course_id)
SELECT s.id, c.id FROM students s JOIN courses c ON c.career_id=s.career_id WHERE s.student_code IN ('2026-ISW-001','2026-ISW-002') AND c.code IN ('ISW-101','ISW-102','ISW-103','ISW-104');
INSERT INTO enrollments (student_id, course_id)
SELECT s.id, c.id FROM students s JOIN courses c ON c.career_id=s.career_id WHERE s.student_code IN ('2026-ISC-001','2026-ISC-002') AND c.code IN ('ISC-101','ISC-102','ISC-103','ISC-104');
INSERT INTO enrollments (student_id, course_id)
SELECT s.id, c.id FROM students s JOIN courses c ON c.career_id=s.career_id WHERE s.student_code='2026-CCC-001' AND c.code IN ('CCC-101','CCC-102','CCC-103','CCC-104');
INSERT INTO enrollments (student_id, course_id)
SELECT s.id, c.id FROM students s JOIN courses c ON c.career_id=s.career_id WHERE s.student_code='2026-DGR-001' AND c.code IN ('DGR-101','DGR-102','DGR-103','DGR-104','DGR-105');

INSERT INTO grades (enrollment_id, assessment_name, score, updated_by)
SELECT e.id, 'Parcial 1', 72 + MOD(e.id * 7, 27), c.teacher_id FROM enrollments e JOIN courses c ON c.id=e.course_id;
INSERT INTO grades (enrollment_id, assessment_name, score, updated_by)
SELECT e.id, 'Proyecto', 75 + MOD(e.id * 5, 25), c.teacher_id FROM enrollments e JOIN courses c ON c.id=e.course_id;

INSERT INTO audit_logs (user_id, action, entity, details) VALUES
((SELECT id FROM users WHERE email='maria.cedeno@educore.edu'), 'seed', 'database', 'Esquema y cuentas de demostración cargados.');
