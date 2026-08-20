-- CreateEnum
CREATE TYPE "ModalidadGrupo" AS ENUM ('PRESENCIAL', 'VIRTUAL', 'HIBRIDA');

-- CreateEnum
CREATE TYPE "EstadoInscripcion" AS ENUM ('ACTIVA', 'RETIRADA', 'FINALIZADA');

-- CreateEnum
CREATE TYPE "TipoResponsable" AS ENUM ('DOCENTE', 'REGISTRADOR_ASISTENCIA');

-- CreateEnum
CREATE TYPE "EstadoAsistencia" AS ENUM ('PRESENTE', 'FALTA', 'TARDANZA');

-- CreateEnum
CREATE TYPE "EstadoImportacion" AS ENUM ('PENDIENTE', 'PROCESANDO', 'COMPLETADA', 'COMPLETADA_CON_ERRORES', 'FALLIDA');

-- AlterTable
ALTER TABLE "personas" ALTER COLUMN "dni" DROP NOT NULL;

-- CreateTable
CREATE TABLE "cursos" (
    "id" SERIAL NOT NULL,
    "codigo" VARCHAR(30),
    "nombre" VARCHAR(150) NOT NULL,
    "descripcion" TEXT,
    "activo" BOOLEAN NOT NULL DEFAULT true,
    "creado_en" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "actualizado_en" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "cursos_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "cursos_periodos" (
    "id" SERIAL NOT NULL,
    "curso_id" INTEGER NOT NULL,
    "periodo_id" INTEGER NOT NULL,
    "nombre" VARCHAR(150) NOT NULL,
    "fecha_inicio" DATE,
    "fecha_fin" DATE,
    "activo" BOOLEAN NOT NULL DEFAULT true,
    "creado_en" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "actualizado_en" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "cursos_periodos_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "grupos" (
    "id" SERIAL NOT NULL,
    "curso_periodo_id" INTEGER NOT NULL,
    "nombre" VARCHAR(100) NOT NULL,
    "modalidad" "ModalidadGrupo" NOT NULL DEFAULT 'PRESENCIAL',
    "activo" BOOLEAN NOT NULL DEFAULT true,
    "creado_en" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "actualizado_en" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "grupos_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "inscripciones" (
    "id" SERIAL NOT NULL,
    "persona_id" INTEGER NOT NULL,
    "grupo_id" INTEGER NOT NULL,
    "estado" "EstadoInscripcion" NOT NULL DEFAULT 'ACTIVA',
    "fecha_inscripcion" DATE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "fecha_retiro" DATE,
    "motivo_retiro" TEXT,
    "creado_en" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "actualizado_en" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "inscripciones_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "asignaciones_responsables" (
    "id" SERIAL NOT NULL,
    "usuario_id" INTEGER NOT NULL,
    "grupo_id" INTEGER NOT NULL,
    "tipo" "TipoResponsable" NOT NULL,
    "activo" BOOLEAN NOT NULL DEFAULT true,
    "fecha_asignacion" DATE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "fecha_fin" DATE,
    "creado_en" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "actualizado_en" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "asignaciones_responsables_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "sesiones_clase" (
    "id" SERIAL NOT NULL,
    "grupo_id" INTEGER NOT NULL,
    "fecha" DATE NOT NULL,
    "tema" VARCHAR(200),
    "observaciones" TEXT,
    "creada_por_id" INTEGER NOT NULL,
    "creado_en" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "actualizado_en" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "sesiones_clase_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "asistencias" (
    "id" SERIAL NOT NULL,
    "sesion_id" INTEGER NOT NULL,
    "inscripcion_id" INTEGER NOT NULL,
    "estado" "EstadoAsistencia" NOT NULL,
    "observaciones" TEXT,
    "registrado_por_id" INTEGER NOT NULL,
    "registrado_en" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "actualizado_en" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "asistencias_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "evaluaciones" (
    "id" SERIAL NOT NULL,
    "curso_periodo_id" INTEGER NOT NULL,
    "nombre" VARCHAR(100) NOT NULL,
    "descripcion" TEXT,
    "ponderacion" DECIMAL(5,2),
    "nota_maxima" DECIMAL(5,2) NOT NULL DEFAULT 20,
    "fecha" DATE,
    "activo" BOOLEAN NOT NULL DEFAULT true,
    "creado_en" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "actualizado_en" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "evaluaciones_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "calificaciones" (
    "id" SERIAL NOT NULL,
    "evaluacion_id" INTEGER NOT NULL,
    "inscripcion_id" INTEGER NOT NULL,
    "nota" DECIMAL(5,2) NOT NULL,
    "observaciones" TEXT,
    "registrado_por_id" INTEGER NOT NULL,
    "registrado_en" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "actualizado_en" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "calificaciones_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "importaciones_excel" (
    "id" SERIAL NOT NULL,
    "nombre_archivo" VARCHAR(255) NOT NULL,
    "tipo" VARCHAR(50) NOT NULL,
    "estado" "EstadoImportacion" NOT NULL DEFAULT 'PENDIENTE',
    "total_filas" INTEGER NOT NULL DEFAULT 0,
    "filas_exitosas" INTEGER NOT NULL DEFAULT 0,
    "filas_con_error" INTEGER NOT NULL DEFAULT 0,
    "usuario_id" INTEGER NOT NULL,
    "creado_en" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "finalizado_en" TIMESTAMP(3),

    CONSTRAINT "importaciones_excel_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "errores_importacion" (
    "id" SERIAL NOT NULL,
    "importacion_id" INTEGER NOT NULL,
    "numero_fila" INTEGER NOT NULL,
    "columna" VARCHAR(150),
    "valor" TEXT,
    "mensaje" TEXT NOT NULL,
    "creado_en" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "errores_importacion_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE UNIQUE INDEX "cursos_codigo_key" ON "cursos"("codigo");

-- CreateIndex
CREATE UNIQUE INDEX "cursos_nombre_key" ON "cursos"("nombre");

-- CreateIndex
CREATE UNIQUE INDEX "cursos_periodos_curso_id_periodo_id_key" ON "cursos_periodos"("curso_id", "periodo_id");

-- CreateIndex
CREATE UNIQUE INDEX "grupos_curso_periodo_id_nombre_key" ON "grupos"("curso_periodo_id", "nombre");

-- CreateIndex
CREATE INDEX "inscripciones_grupo_id_estado_idx" ON "inscripciones"("grupo_id", "estado");

-- CreateIndex
CREATE UNIQUE INDEX "inscripciones_persona_id_grupo_id_key" ON "inscripciones"("persona_id", "grupo_id");

-- CreateIndex
CREATE INDEX "asignaciones_responsables_grupo_id_activo_idx" ON "asignaciones_responsables"("grupo_id", "activo");

-- CreateIndex
CREATE UNIQUE INDEX "asignaciones_responsables_usuario_id_grupo_id_tipo_key" ON "asignaciones_responsables"("usuario_id", "grupo_id", "tipo");

-- CreateIndex
CREATE INDEX "sesiones_clase_creada_por_id_idx" ON "sesiones_clase"("creada_por_id");

-- CreateIndex
CREATE UNIQUE INDEX "sesiones_clase_grupo_id_fecha_key" ON "sesiones_clase"("grupo_id", "fecha");

-- CreateIndex
CREATE INDEX "asistencias_inscripcion_id_estado_idx" ON "asistencias"("inscripcion_id", "estado");

-- CreateIndex
CREATE INDEX "asistencias_registrado_por_id_idx" ON "asistencias"("registrado_por_id");

-- CreateIndex
CREATE UNIQUE INDEX "asistencias_sesion_id_inscripcion_id_key" ON "asistencias"("sesion_id", "inscripcion_id");

-- CreateIndex
CREATE UNIQUE INDEX "evaluaciones_curso_periodo_id_nombre_key" ON "evaluaciones"("curso_periodo_id", "nombre");

-- CreateIndex
CREATE INDEX "calificaciones_inscripcion_id_idx" ON "calificaciones"("inscripcion_id");

-- CreateIndex
CREATE INDEX "calificaciones_registrado_por_id_idx" ON "calificaciones"("registrado_por_id");

-- CreateIndex
CREATE UNIQUE INDEX "calificaciones_evaluacion_id_inscripcion_id_key" ON "calificaciones"("evaluacion_id", "inscripcion_id");

-- CreateIndex
CREATE INDEX "importaciones_excel_usuario_id_creado_en_idx" ON "importaciones_excel"("usuario_id", "creado_en");

-- CreateIndex
CREATE INDEX "errores_importacion_importacion_id_numero_fila_idx" ON "errores_importacion"("importacion_id", "numero_fila");

-- CreateIndex
CREATE INDEX "personas_apellidos_nombres_idx" ON "personas"("apellidos", "nombres");

-- AddForeignKey
ALTER TABLE "cursos_periodos" ADD CONSTRAINT "cursos_periodos_curso_id_fkey" FOREIGN KEY ("curso_id") REFERENCES "cursos"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "cursos_periodos" ADD CONSTRAINT "cursos_periodos_periodo_id_fkey" FOREIGN KEY ("periodo_id") REFERENCES "periodos_academicos"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "grupos" ADD CONSTRAINT "grupos_curso_periodo_id_fkey" FOREIGN KEY ("curso_periodo_id") REFERENCES "cursos_periodos"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "inscripciones" ADD CONSTRAINT "inscripciones_persona_id_fkey" FOREIGN KEY ("persona_id") REFERENCES "personas"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "inscripciones" ADD CONSTRAINT "inscripciones_grupo_id_fkey" FOREIGN KEY ("grupo_id") REFERENCES "grupos"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "asignaciones_responsables" ADD CONSTRAINT "asignaciones_responsables_usuario_id_fkey" FOREIGN KEY ("usuario_id") REFERENCES "usuarios"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "asignaciones_responsables" ADD CONSTRAINT "asignaciones_responsables_grupo_id_fkey" FOREIGN KEY ("grupo_id") REFERENCES "grupos"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "sesiones_clase" ADD CONSTRAINT "sesiones_clase_grupo_id_fkey" FOREIGN KEY ("grupo_id") REFERENCES "grupos"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "sesiones_clase" ADD CONSTRAINT "sesiones_clase_creada_por_id_fkey" FOREIGN KEY ("creada_por_id") REFERENCES "usuarios"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "asistencias" ADD CONSTRAINT "asistencias_sesion_id_fkey" FOREIGN KEY ("sesion_id") REFERENCES "sesiones_clase"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "asistencias" ADD CONSTRAINT "asistencias_inscripcion_id_fkey" FOREIGN KEY ("inscripcion_id") REFERENCES "inscripciones"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "asistencias" ADD CONSTRAINT "asistencias_registrado_por_id_fkey" FOREIGN KEY ("registrado_por_id") REFERENCES "usuarios"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "evaluaciones" ADD CONSTRAINT "evaluaciones_curso_periodo_id_fkey" FOREIGN KEY ("curso_periodo_id") REFERENCES "cursos_periodos"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "calificaciones" ADD CONSTRAINT "calificaciones_evaluacion_id_fkey" FOREIGN KEY ("evaluacion_id") REFERENCES "evaluaciones"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "calificaciones" ADD CONSTRAINT "calificaciones_inscripcion_id_fkey" FOREIGN KEY ("inscripcion_id") REFERENCES "inscripciones"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "calificaciones" ADD CONSTRAINT "calificaciones_registrado_por_id_fkey" FOREIGN KEY ("registrado_por_id") REFERENCES "usuarios"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "importaciones_excel" ADD CONSTRAINT "importaciones_excel_usuario_id_fkey" FOREIGN KEY ("usuario_id") REFERENCES "usuarios"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "errores_importacion" ADD CONSTRAINT "errores_importacion_importacion_id_fkey" FOREIGN KEY ("importacion_id") REFERENCES "importaciones_excel"("id") ON DELETE CASCADE ON UPDATE CASCADE;
