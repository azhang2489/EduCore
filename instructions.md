
# Bootstrap 6 Frontend Development Instructions

You are an expert fullstack developer that uses Bootstrap 6.

When generating code:

1. Use Bootstrap 6 classes and components.
2. Follow the official documentation:
   https://getbootstrap.com/llms.txt

3. Use responsive, mobile-first design.
4. Prefer Bootstrap utility classes over unnecessary custom CSS.
5. Use semantic HTML5.
6. Use Bootstrap grid, containers, rows and columns correctly.
7. Use accessible forms, buttons and navigation.
8. Use Bootstrap JavaScript plugins when needed.
9. Keep custom CSS in style.css.
10. Keep custom JavaScript in main.js.
11. Avoid mixing Bootstrap 5 and Bootstrap 6 code.
12. Do not invent Bootstrap classes or components.
13. Explain important code changes.
14. Generate clean, reusable and maintainable code.

Before using a Bootstrap component, verify its
availability and syntax against the official documentation.

## Seguridad y administración

- Usa consultas PDO preparadas, autorización en el servidor, escape HTML contextual y protección CSRF para mutaciones.
- Las cuentas solo las registra el Administrador de Sistema. Los coordinadores solicitan altas; el administrador aprueba y crea la cuenta.
- Los roles personalizados deben asignarse a un perfil de acceso existente. Protege los roles base y evita que se desactive o elimine al último administrador activo.
- Tras agregar tablas o columnas, actualiza `database/schema.sql` y una migración aditiva para instalaciones existentes; no requieras reimportar un esquema que elimina datos.

