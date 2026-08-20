# Base de datos

## Crear la base local

Desde PostgreSQL:

```sql
CREATE DATABASE sistema_asistencias;
```

## Ejecutar la primera migracion

Desde la carpeta principal del proyecto:

```bash
psql -U postgres -d sistema_asistencias -f database/migrations/001_initial_schema.sql
```

La migracion crea las tablas, relaciones, indices, roles iniciales y vistas de analisis.

## Reglas principales

- `personas.dni` es unico: una persona no se duplica aunque estudie varios cursos.
- Los permisos de docente o registrador se asignan a grupos concretos.
- Una inscripcion solo tiene un grupo actual.
- Al cambiar de grupo, las asistencias anteriores permanecen ligadas a las sesiones del grupo anterior.
- Los retiros y suspensiones pueden quedar pendientes hasta que la administradora los resuelva.
- La contrasena nunca se guarda directamente: `usuarios.password_hash` recibira un hash generado por el backend.

## Vistas iniciales para reportes

- `vw_inscripciones_actuales`
- `vw_resumen_asistencia_alumno`
- `vw_historial_movimientos`
