# EduCore · Entregable 2

Prototipo PHP/MySQL de gestión académica con inicio y cierre de sesión, autorización por rol, gestión de estudiantes/cursos y calificaciones.

## Requisitos

- PHP 8.1 o superior con las extensiones `pdo` y `pdo_mysql` habilitadas.
- MySQL 8 o MariaDB 10.4 o superior.
- Apache (incluido en XAMPP/LAMPP).

## Instalación en XAMPP/LAMPP

1. Inicia Apache y MySQL.
2. Importa `database/schema.sql` desde phpMyAdmin o desde la terminal MySQL. **El script recrea las tablas EduCore y borra los datos previos de esas tablas.**
3. Si el usuario/contraseña MySQL no son `root`/vacío, configura las variables `EDUCORE_DB_HOST`, `EDUCORE_DB_NAME`, `EDUCORE_DB_USER` y `EDUCORE_DB_PASSWORD`, o modifica los valores predeterminados en `config/database.php`.
4. Abre `http://localhost/EduCore/`.

## Cuentas de demostración

Todas las cuentas de prueba usan la contraseña `EduCore2026!`.

| Perfil | Correo |
|---|---|
| Administrador de Sistema | `maria.cedeno@educore.edu` |
| Administrador (solo lectura) | `victor.gomez@educore.edu` |
| Coordinador · Ingeniería de Software | `elena.castillo@educore.edu` |
| Coordinador · Ingeniería de Sistemas | `roberto.mendez@educore.edu` |
| Coordinadora · Diseño Gráfico | `lucia.perez@educore.edu` |
| Coordinador · Ciencias Computacionales | `gabriel.nunez@educore.edu` |
| Docente | `andrea.lopez@educore.edu` |
| Docente | `carlos.mendez@educore.edu` |
| Docente | `julio.rivera@educore.edu` |
| Docente | `ana.castillo@educore.edu` |
| Docente | `laura.perez@educore.edu` |
| Docente | `miguel.torres@educore.edu` |
| Docente | `sofia.diaz@educore.edu` |
| Docente | `ricardo.gomez@educore.edu` |
| Estudiante | `javier.rodriguez@educore.edu` |

Hay un coordinador y dos docentes por cada carrera registrada (incluidas las carreras que ya aparecían en el prototipo), además de cinco estudiantes de muestra. Cada estudiante tiene entre cuatro y cinco cursos con día, hora y aula definidos en `schedules`.

## Horarios y calificaciones

- Docentes y estudiantes tienen el módulo **Mi horario**, que ordena las clases por día y hora; para estudiantes se limita a sus matrículas y muestra docente, aula y enlace a notas.
- Docentes y estudiantes consultan las calificaciones agrupadas primero por materia.
- Coordinadores, administradores y Administradores de Sistema las consultan agrupadas primero por estudiante y luego por materia. Solo el Administrador de Sistema puede modificar notas en esa vista.

## Permisos

- **Administrador de Sistema:** acceso total; puede crear usuarios, cursos, estudiantes y cambiar notas.
- **Administrador:** lectura de todos los módulos, sin acciones de escritura.
- **Coordinador de Carrera:** CRUD de estudiantes, matrículas y cursos limitados a su carrera; no crea cuentas de acceso.
- **Docente:** consulta únicamente los cursos que imparte y modifica notas solo de sus cursos; no puede crear estudiantes ni editar cursos.
- **Estudiante:** consulta sus cursos y calificaciones.

El registro de cuentas está cerrado al público. Solo el Administrador de Sistema crea usuarios; los coordinadores administran las fichas académicas de estudiantes sin crear credenciales.

## Notas de seguridad implementadas

PDO con consultas preparadas, `password_hash()`/`password_verify()`, regeneración de sesión, bloqueo temporal tras cinco intentos de acceso, tokens CSRF en las operaciones POST, escape HTML, validación de propiedad/alcance por carrera y cabeceras CSP/X-Frame-Options/X-Content-Type-Options. Para uso fuera de una máquina local, activa HTTPS y establece credenciales de base de datos seguras mediante variables de entorno.
