-- Ejecutar una sola vez en una instalación existente para habilitar roles y solicitudes.
USE educore;

ALTER TABLE roles
  ADD COLUMN access_profile VARCHAR(40) NOT NULL DEFAULT 'admin' AFTER description;

UPDATE roles SET access_profile = name
WHERE name IN ('system_admin', 'admin', 'career_coordinator', 'teacher', 'student');

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