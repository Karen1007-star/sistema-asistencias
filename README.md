# Sistema de Asistencias

Sistema web para administrar cursos, grupos, inscripciones, asistencia y movimientos de estudiantes.

## Tecnologias

- PostgreSQL
- Node.js + Express (JavaScript)
- React + Vite (JavaScript)
- Tailwind CSS

## Primera etapa: base de datos

La migracion inicial se encuentra en:

`database/migrations/001_initial_schema.sql`

Esta primera estructura permite:

- Registrar una sola persona por DNI.
- Dar varios roles a la misma persona.
- Permitir que un docente tambien sea estudiante.
- Asignar docentes y registradores por grupo.
- Inscribir a una persona en diferentes cursos sin duplicarla.
- Registrar asistencias como P, F o T.
- Conservar el historial cuando un estudiante cambia de grupo.
- Reportar y resolver retiros o suspensiones.
- Generar notificaciones y mantener una auditoria de cambios.
- Preparar analisis por curso, grupo, filial y ciudad.

Consulta `database/README.md` para ejecutar la migracion.
