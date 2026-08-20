BEGIN;

CREATE TYPE estado_usuario AS ENUM (
  'ACTIVO',
  'BLOQUEADO',
  'INACTIVO'
);

CREATE TYPE tipo_asignacion_grupo AS ENUM (
  'DOCENTE',
  'REGISTRADOR_ASISTENCIA'
);

CREATE TYPE estado_inscripcion AS ENUM (
  'PENDIENTE',
  'ACTIVO',
  'SUSPENDIDO',
  'RETIRADO',
  'FINALIZADO',
  'RECHAZADO'
);

CREATE TYPE estado_sesion AS ENUM (
  'ABIERTA',
  'CERRADA',
  'CANCELADA'
);

CREATE TYPE estado_asistencia AS ENUM (
  'P',
  'F',
  'T'
);

CREATE TYPE tipo_movimiento_inscripcion AS ENUM (
  'INSCRIPCION',
  'CAMBIO_GRUPO',
  'SOLICITUD_RETIRO',
  'RETIRO',
  'SUSPENSION',
  'REACTIVACION',
  'FINALIZACION',
  'OTRO'
);

CREATE TYPE estado_movimiento AS ENUM (
  'INFORMATIVO',
  'PENDIENTE',
  'APROBADO',
  'RECHAZADO'
);

CREATE TYPE tipo_notificacion AS ENUM (
  'NOVEDAD',
  'CAMBIO_GRUPO',
  'RETIRO',
  'SUSPENSION',
  'SISTEMA'
);

CREATE TABLE filiales (
  id_filial BIGSERIAL PRIMARY KEY,
  nombre VARCHAR(120) NOT NULL,
  ciudad VARCHAR(120) NOT NULL,
  departamento VARCHAR(120),
  activo BOOLEAN NOT NULL DEFAULT TRUE,
  creado_en TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  actualizado_en TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  CONSTRAINT uq_filial_nombre_ciudad UNIQUE (nombre, ciudad)
);

CREATE TABLE personas (
  id_persona BIGSERIAL PRIMARY KEY,
  dni VARCHAR(20) NOT NULL UNIQUE,
  nombres VARCHAR(120) NOT NULL,
  apellidos VARCHAR(160) NOT NULL,
  correo VARCHAR(180),
  telefono VARCHAR(30),
  ciudad_residencia VARCHAR(120),
  id_filial BIGINT REFERENCES filiales(id_filial) ON DELETE SET NULL,
  activo BOOLEAN NOT NULL DEFAULT TRUE,
  creado_en TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  actualizado_en TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  CONSTRAINT ck_persona_dni_no_vacio CHECK (BTRIM(dni) <> ''),
  CONSTRAINT ck_persona_nombres_no_vacios CHECK (BTRIM(nombres) <> ''),
  CONSTRAINT ck_persona_apellidos_no_vacios CHECK (BTRIM(apellidos) <> '')
);

CREATE UNIQUE INDEX uq_personas_correo_normalizado
  ON personas (LOWER(correo))
  WHERE correo IS NOT NULL;

CREATE TABLE usuarios (
  id_usuario BIGSERIAL PRIMARY KEY,
  id_persona BIGINT NOT NULL UNIQUE
    REFERENCES personas(id_persona) ON DELETE RESTRICT,
  password_hash TEXT NOT NULL,
  estado estado_usuario NOT NULL DEFAULT 'ACTIVO',
  ultimo_acceso_en TIMESTAMPTZ,
  creado_en TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  actualizado_en TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  CONSTRAINT ck_usuario_password_hash_no_vacio CHECK (BTRIM(password_hash) <> '')
);

CREATE TABLE roles (
  id_rol SMALLSERIAL PRIMARY KEY,
  codigo VARCHAR(40) NOT NULL UNIQUE,
  nombre VARCHAR(80) NOT NULL,
  descripcion VARCHAR(240),
  activo BOOLEAN NOT NULL DEFAULT TRUE
);

CREATE TABLE usuario_roles (
  id_usuario BIGINT NOT NULL
    REFERENCES usuarios(id_usuario) ON DELETE CASCADE,
  id_rol SMALLINT NOT NULL
    REFERENCES roles(id_rol) ON DELETE RESTRICT,
  asignado_en TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  PRIMARY KEY (id_usuario, id_rol)
);

CREATE TABLE periodos_academicos (
  id_periodo BIGSERIAL PRIMARY KEY,
  nombre VARCHAR(120) NOT NULL UNIQUE,
  fecha_inicio DATE NOT NULL,
  fecha_fin DATE NOT NULL,
  activo BOOLEAN NOT NULL DEFAULT TRUE,
  creado_en TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  actualizado_en TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  CONSTRAINT ck_periodo_fechas CHECK (fecha_fin >= fecha_inicio)
);

CREATE TABLE materias (
  id_materia BIGSERIAL PRIMARY KEY,
  codigo VARCHAR(40) UNIQUE,
  nombre VARCHAR(160) NOT NULL UNIQUE,
  descripcion TEXT,
  activo BOOLEAN NOT NULL DEFAULT TRUE,
  creado_en TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  actualizado_en TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE cursos (
  id_curso BIGSERIAL PRIMARY KEY,
  id_materia BIGINT NOT NULL
    REFERENCES materias(id_materia) ON DELETE RESTRICT,
  id_periodo BIGINT NOT NULL
    REFERENCES periodos_academicos(id_periodo) ON DELETE RESTRICT,
  codigo VARCHAR(50) NOT NULL UNIQUE,
  nombre_publico VARCHAR(180),
  slug_inscripcion VARCHAR(140) NOT NULL UNIQUE,
  inscripcion_abierta BOOLEAN NOT NULL DEFAULT FALSE,
  activo BOOLEAN NOT NULL DEFAULT TRUE,
  creado_en TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  actualizado_en TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  CONSTRAINT ck_curso_codigo_no_vacio CHECK (BTRIM(codigo) <> ''),
  CONSTRAINT ck_curso_slug_no_vacio CHECK (BTRIM(slug_inscripcion) <> ''),
  CONSTRAINT uq_curso_materia_periodo UNIQUE (id_materia, id_periodo)
);

CREATE TABLE grupos (
  id_grupo BIGSERIAL PRIMARY KEY,
  id_curso BIGINT NOT NULL
    REFERENCES cursos(id_curso) ON DELETE RESTRICT,
  codigo VARCHAR(50) NOT NULL,
  nombre VARCHAR(120) NOT NULL,
  horario_descripcion VARCHAR(240),
  capacidad INTEGER,
  activo BOOLEAN NOT NULL DEFAULT TRUE,
  creado_en TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  actualizado_en TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  CONSTRAINT uq_grupo_curso_codigo UNIQUE (id_curso, codigo),
  CONSTRAINT uq_grupo_id_curso UNIQUE (id_grupo, id_curso),
  CONSTRAINT ck_grupo_capacidad CHECK (capacidad IS NULL OR capacidad > 0)
);

CREATE TABLE asignaciones_grupo (
  id_asignacion BIGSERIAL PRIMARY KEY,
  id_persona BIGINT NOT NULL
    REFERENCES personas(id_persona) ON DELETE RESTRICT,
  id_grupo BIGINT NOT NULL
    REFERENCES grupos(id_grupo) ON DELETE RESTRICT,
  tipo tipo_asignacion_grupo NOT NULL,
  fecha_inicio DATE NOT NULL DEFAULT CURRENT_DATE,
  fecha_fin DATE,
  activo BOOLEAN NOT NULL DEFAULT TRUE,
  asignado_por BIGINT
    REFERENCES usuarios(id_usuario) ON DELETE SET NULL,
  creado_en TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  actualizado_en TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  CONSTRAINT uq_asignacion_persona_grupo_tipo_inicio
    UNIQUE (id_persona, id_grupo, tipo, fecha_inicio),
  CONSTRAINT ck_asignacion_fechas
    CHECK (fecha_fin IS NULL OR fecha_fin >= fecha_inicio)
);

CREATE TABLE inscripciones (
  id_inscripcion BIGSERIAL PRIMARY KEY,
  id_persona BIGINT NOT NULL
    REFERENCES personas(id_persona) ON DELETE RESTRICT,
  id_curso BIGINT NOT NULL
    REFERENCES cursos(id_curso) ON DELETE RESTRICT,
  id_grupo_actual BIGINT,
  estado estado_inscripcion NOT NULL DEFAULT 'PENDIENTE',
  fecha_inscripcion DATE NOT NULL DEFAULT CURRENT_DATE,
  fecha_aprobacion DATE,
  aprobado_por BIGINT
    REFERENCES usuarios(id_usuario) ON DELETE SET NULL,
  creado_en TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  actualizado_en TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  CONSTRAINT uq_inscripcion_persona_curso UNIQUE (id_persona, id_curso),
  CONSTRAINT fk_inscripcion_grupo_del_curso
    FOREIGN KEY (id_grupo_actual, id_curso)
    REFERENCES grupos(id_grupo, id_curso) ON DELETE RESTRICT,
  CONSTRAINT ck_inscripcion_aprobacion
    CHECK (fecha_aprobacion IS NULL OR fecha_aprobacion >= fecha_inscripcion)
);

CREATE TABLE sesiones_clase (
  id_sesion BIGSERIAL PRIMARY KEY,
  id_grupo BIGINT NOT NULL
    REFERENCES grupos(id_grupo) ON DELETE RESTRICT,
  fecha DATE NOT NULL,
  numero_sesion SMALLINT NOT NULL DEFAULT 1,
  hora_inicio TIME,
  tema VARCHAR(240),
  estado estado_sesion NOT NULL DEFAULT 'ABIERTA',
  creada_por BIGINT NOT NULL
    REFERENCES usuarios(id_usuario) ON DELETE RESTRICT,
  cerrada_por BIGINT
    REFERENCES usuarios(id_usuario) ON DELETE SET NULL,
  cerrada_en TIMESTAMPTZ,
  creado_en TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  actualizado_en TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  CONSTRAINT uq_sesion_grupo_fecha_numero
    UNIQUE (id_grupo, fecha, numero_sesion),
  CONSTRAINT ck_sesion_numero_positivo CHECK (numero_sesion > 0)
);

CREATE TABLE asistencias (
  id_asistencia BIGSERIAL PRIMARY KEY,
  id_sesion BIGINT NOT NULL
    REFERENCES sesiones_clase(id_sesion) ON DELETE CASCADE,
  id_inscripcion BIGINT NOT NULL
    REFERENCES inscripciones(id_inscripcion) ON DELETE RESTRICT,
  estado estado_asistencia NOT NULL,
  observacion VARCHAR(400),
  marcado_por BIGINT NOT NULL
    REFERENCES usuarios(id_usuario) ON DELETE RESTRICT,
  creado_en TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  actualizado_en TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  CONSTRAINT uq_asistencia_sesion_inscripcion
    UNIQUE (id_sesion, id_inscripcion)
);

CREATE TABLE movimientos_inscripcion (
  id_movimiento BIGSERIAL PRIMARY KEY,
  id_inscripcion BIGINT NOT NULL
    REFERENCES inscripciones(id_inscripcion) ON DELETE RESTRICT,
  tipo tipo_movimiento_inscripcion NOT NULL,
  estado estado_movimiento NOT NULL DEFAULT 'PENDIENTE',
  id_grupo_origen BIGINT
    REFERENCES grupos(id_grupo) ON DELETE RESTRICT,
  id_grupo_destino BIGINT
    REFERENCES grupos(id_grupo) ON DELETE RESTRICT,
  fecha_efectiva DATE,
  motivo TEXT,
  reportado_por BIGINT NOT NULL
    REFERENCES usuarios(id_usuario) ON DELETE RESTRICT,
  resuelto_por BIGINT
    REFERENCES usuarios(id_usuario) ON DELETE SET NULL,
  resuelto_en TIMESTAMPTZ,
  comentario_resolucion TEXT,
  creado_en TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  actualizado_en TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  CONSTRAINT ck_movimiento_cambio_grupo CHECK (
    tipo <> 'CAMBIO_GRUPO'
    OR (
      id_grupo_origen IS NOT NULL
      AND id_grupo_destino IS NOT NULL
      AND id_grupo_origen <> id_grupo_destino
      AND fecha_efectiva IS NOT NULL
    )
  ),
  CONSTRAINT ck_movimiento_resolucion CHECK (
    (estado IN ('INFORMATIVO', 'PENDIENTE') AND resuelto_por IS NULL AND resuelto_en IS NULL)
    OR
    (estado IN ('APROBADO', 'RECHAZADO') AND resuelto_por IS NOT NULL AND resuelto_en IS NOT NULL)
  )
);

CREATE TABLE notificaciones (
  id_notificacion BIGSERIAL PRIMARY KEY,
  id_usuario_destino BIGINT NOT NULL
    REFERENCES usuarios(id_usuario) ON DELETE CASCADE,
  id_movimiento BIGINT
    REFERENCES movimientos_inscripcion(id_movimiento) ON DELETE CASCADE,
  tipo tipo_notificacion NOT NULL DEFAULT 'NOVEDAD',
  titulo VARCHAR(180) NOT NULL,
  mensaje TEXT NOT NULL,
  leida_en TIMESTAMPTZ,
  creado_en TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE auditoria (
  id_auditoria BIGSERIAL PRIMARY KEY,
  id_usuario BIGINT
    REFERENCES usuarios(id_usuario) ON DELETE SET NULL,
  entidad VARCHAR(80) NOT NULL,
  id_registro BIGINT,
  accion VARCHAR(50) NOT NULL,
  datos_anteriores JSONB,
  datos_nuevos JSONB,
  direccion_ip INET,
  creado_en TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_personas_filial ON personas(id_filial);
CREATE INDEX idx_asignaciones_grupo_persona ON asignaciones_grupo(id_persona);
CREATE INDEX idx_asignaciones_grupo_grupo_activo ON asignaciones_grupo(id_grupo, activo);
CREATE INDEX idx_inscripciones_curso_estado ON inscripciones(id_curso, estado);
CREATE INDEX idx_inscripciones_grupo_estado ON inscripciones(id_grupo_actual, estado);
CREATE INDEX idx_sesiones_grupo_fecha ON sesiones_clase(id_grupo, fecha DESC);
CREATE INDEX idx_asistencias_inscripcion ON asistencias(id_inscripcion);
CREATE INDEX idx_movimientos_inscripcion_fecha
  ON movimientos_inscripcion(id_inscripcion, creado_en DESC);
CREATE INDEX idx_movimientos_pendientes
  ON movimientos_inscripcion(estado, creado_en DESC)
  WHERE estado = 'PENDIENTE';
CREATE INDEX idx_notificaciones_usuario_no_leidas
  ON notificaciones(id_usuario_destino, creado_en DESC)
  WHERE leida_en IS NULL;
CREATE INDEX idx_auditoria_entidad_registro
  ON auditoria(entidad, id_registro, creado_en DESC);

INSERT INTO roles (codigo, nombre, descripcion) VALUES
  ('ADMINISTRADOR', 'Administrador', 'Acceso total al sistema'),
  ('DOCENTE', 'Docente', 'Gestiona los grupos que tiene asignados'),
  ('REGISTRADOR_ASISTENCIA', 'Registrador de asistencia', 'Pasa asistencia en grupos autorizados'),
  ('ESTUDIANTE', 'Estudiante', 'Se inscribe y consulta su propia informacion');

CREATE OR REPLACE FUNCTION actualizar_fecha_modificacion()
RETURNS TRIGGER AS $$
BEGIN
  NEW.actualizado_en = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_filiales_actualizado
BEFORE UPDATE ON filiales
FOR EACH ROW EXECUTE FUNCTION actualizar_fecha_modificacion();

CREATE TRIGGER trg_personas_actualizado
BEFORE UPDATE ON personas
FOR EACH ROW EXECUTE FUNCTION actualizar_fecha_modificacion();

CREATE TRIGGER trg_usuarios_actualizado
BEFORE UPDATE ON usuarios
FOR EACH ROW EXECUTE FUNCTION actualizar_fecha_modificacion();

CREATE TRIGGER trg_periodos_actualizado
BEFORE UPDATE ON periodos_academicos
FOR EACH ROW EXECUTE FUNCTION actualizar_fecha_modificacion();

CREATE TRIGGER trg_materias_actualizado
BEFORE UPDATE ON materias
FOR EACH ROW EXECUTE FUNCTION actualizar_fecha_modificacion();

CREATE TRIGGER trg_cursos_actualizado
BEFORE UPDATE ON cursos
FOR EACH ROW EXECUTE FUNCTION actualizar_fecha_modificacion();

CREATE TRIGGER trg_grupos_actualizado
BEFORE UPDATE ON grupos
FOR EACH ROW EXECUTE FUNCTION actualizar_fecha_modificacion();

CREATE TRIGGER trg_asignaciones_actualizado
BEFORE UPDATE ON asignaciones_grupo
FOR EACH ROW EXECUTE FUNCTION actualizar_fecha_modificacion();

CREATE TRIGGER trg_inscripciones_actualizado
BEFORE UPDATE ON inscripciones
FOR EACH ROW EXECUTE FUNCTION actualizar_fecha_modificacion();

CREATE TRIGGER trg_sesiones_actualizado
BEFORE UPDATE ON sesiones_clase
FOR EACH ROW EXECUTE FUNCTION actualizar_fecha_modificacion();

CREATE TRIGGER trg_asistencias_actualizado
BEFORE UPDATE ON asistencias
FOR EACH ROW EXECUTE FUNCTION actualizar_fecha_modificacion();

CREATE TRIGGER trg_movimientos_actualizado
BEFORE UPDATE ON movimientos_inscripcion
FOR EACH ROW EXECUTE FUNCTION actualizar_fecha_modificacion();

CREATE VIEW vw_inscripciones_actuales AS
SELECT
  i.id_inscripcion,
  p.dni,
  p.nombres,
  p.apellidos,
  p.ciudad_residencia,
  f.nombre AS filial,
  m.nombre AS materia,
  c.codigo AS codigo_curso,
  g.codigo AS codigo_grupo,
  g.nombre AS grupo,
  i.estado,
  i.fecha_inscripcion
FROM inscripciones i
JOIN personas p ON p.id_persona = i.id_persona
JOIN cursos c ON c.id_curso = i.id_curso
JOIN materias m ON m.id_materia = c.id_materia
LEFT JOIN grupos g ON g.id_grupo = i.id_grupo_actual
LEFT JOIN filiales f ON f.id_filial = p.id_filial;

CREATE VIEW vw_resumen_asistencia_alumno AS
SELECT
  i.id_inscripcion,
  p.dni,
  p.nombres,
  p.apellidos,
  m.nombre AS materia,
  c.codigo AS codigo_curso,
  COUNT(a.id_asistencia) AS sesiones_registradas,
  COUNT(*) FILTER (WHERE a.estado = 'P') AS presentes,
  COUNT(*) FILTER (WHERE a.estado = 'F') AS faltas,
  COUNT(*) FILTER (WHERE a.estado = 'T') AS tardanzas,
  ROUND(
    100.0 * COUNT(*) FILTER (WHERE a.estado IN ('P', 'T'))
    / NULLIF(COUNT(a.id_asistencia), 0),
    2
  ) AS porcentaje_asistencia
FROM inscripciones i
JOIN personas p ON p.id_persona = i.id_persona
JOIN cursos c ON c.id_curso = i.id_curso
JOIN materias m ON m.id_materia = c.id_materia
LEFT JOIN asistencias a ON a.id_inscripcion = i.id_inscripcion
GROUP BY
  i.id_inscripcion,
  p.dni,
  p.nombres,
  p.apellidos,
  m.nombre,
  c.codigo;

CREATE VIEW vw_historial_movimientos AS
SELECT
  mi.id_movimiento,
  p.dni,
  p.nombres,
  p.apellidos,
  m.nombre AS materia,
  c.codigo AS codigo_curso,
  mi.tipo,
  mi.estado,
  go.nombre AS grupo_origen,
  gd.nombre AS grupo_destino,
  mi.fecha_efectiva,
  mi.motivo,
  mi.creado_en,
  pr.nombres || ' ' || pr.apellidos AS reportado_por,
  pe.nombres || ' ' || pe.apellidos AS resuelto_por
FROM movimientos_inscripcion mi
JOIN inscripciones i ON i.id_inscripcion = mi.id_inscripcion
JOIN personas p ON p.id_persona = i.id_persona
JOIN cursos c ON c.id_curso = i.id_curso
JOIN materias m ON m.id_materia = c.id_materia
JOIN usuarios ur ON ur.id_usuario = mi.reportado_por
JOIN personas pr ON pr.id_persona = ur.id_persona
LEFT JOIN usuarios ue ON ue.id_usuario = mi.resuelto_por
LEFT JOIN personas pe ON pe.id_persona = ue.id_persona
LEFT JOIN grupos go ON go.id_grupo = mi.id_grupo_origen
LEFT JOIN grupos gd ON gd.id_grupo = mi.id_grupo_destino;

COMMIT;
