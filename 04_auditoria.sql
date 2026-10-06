-- =====================================================================
-- ARCHIVO: 04_auditoria.sql
-- DESCRIPCIÓN: Sistema de auditoría en esquema separado para registrar
--              cambios de estado e importe en órdenes de trabajo mediante triggers.
-- =====================================================================

-- 1. CREACIÓN DEL ESQUEMA DE AUDITORÍA
CREATE SCHEMA IF NOT EXISTS audit;
SET search_path TO audit, taller, public;

-- 2. CREACIÓN DE LA TABLA DE REGISTRO DE AUDITORÍA
CREATE TABLE audit.orden_trabajo_audit (
    id SERIAL PRIMARY KEY,
    orden_id INT NOT NULL,
    usuario VARCHAR(100) NOT NULL,
    fecha_hora TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    operacion VARCHAR(10) NOT NULL,
    estado_anterior VARCHAR(20),
    estado_nuevo VARCHAR(20),
    importe_anterior NUMERIC(10, 2),
    importe_nuevo NUMERIC(10, 2)
);

-- 3. CREACIÓN DE LA FUNCIÓN DEL TRIGGER DE AUDITORÍA
CREATE OR REPLACE FUNCTION audit.fn_auditar_cambios_orden()
RETURNS TRIGGER AS $$
BEGIN
    -- Solo registramos si hay cambios efectivos en estado o importe_total
    IF (OLD.estado IS DISTINCT FROM NEW.estado) OR (OLD.importe_total IS DISTINCT FROM NEW.importe_total) THEN
        INSERT INTO audit.orden_trabajo_audit (
            orden_id, 
            usuario, 
            fecha_hora, 
            operacion, 
            estado_anterior, 
            estado_nuevo, 
            importe_anterior, 
            importe_nuevo
        ) VALUES (
            NEW.id,
            current_user,
            clock_timestamp(),
            TG_OP,
            OLD.estado,
            NEW.estado,
            OLD.importe_total,
            NEW.importe_total
        );
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- 4. CREACIÓN DEL TRIGGER EN LA TABLA OPERATIVA
DROP TRIGGER IF EXISTS trg_auditoria_orden ON taller.orden_trabajo;

CREATE TRIGGER trg_auditoria_orden
AFTER UPDATE ON taller.orden_trabajo
FOR EACH ROW
EXECUTE FUNCTION audit.fn_auditar_cambios_orden();

-- 5. PRUEBA DE DEMOSTRACIÓN DE AUDITORÍA
/*
   -- Ejecutar cambios con usuarios distintos y consultar la traza:*/
   UPDATE taller.orden_trabajo SET estado = 'terminada' WHERE id = 4;
   UPDATE taller.orden_trabajo SET importe_total = 160.00 WHERE id = 1;

   -- Consultar registro de auditoría:
   SELECT * FROM audit.orden_trabajo_audit ORDER BY fecha_hora DESC;