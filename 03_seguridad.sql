-- =====================================================================
-- ARCHIVO: 03_seguridad.sql
-- DESCRIPCIÓN: Implementación de roles NOLOGIN, usuarios LOGIN, esquemas 
--              y permisos granulares (Principio de Mínimo Privilegio).
-- =====================================================================

SET search_path TO taller, public;

-- 1. CREACIÓN DE ROLES DE GRUPO (NOLOGIN)
CREATE ROLE rol_recepcion NOLOGIN;
CREATE ROLE rol_taller NOLOGIN;
CREATE ROLE rol_facturacion NOLOGIN;
CREATE ROLE rol_auditoria NOLOGIN;

-- 2. CREACIÓN DE USUARIOS DE PRUEBA (LOGIN) CON CONTRASEÑA SEGURA
CREATE USER user_recepcion WITH PASSWORD 'ReceP_2026Secure!';
CREATE USER user_taller WITH PASSWORD 'TalleR_2026Secure!';
CREATE USER user_facturacion WITH PASSWORD 'Fact_2026Secure!';
CREATE USER user_auditoria WITH PASSWORD 'AudiT_2026Secure!';

-- Asociar usuarios a sus respectivos roles de grupo
GRANT rol_recepcion TO user_recepcion;
GRANT rol_taller TO user_taller;
GRANT rol_facturacion TO user_facturacion;
GRANT rol_auditoria TO user_auditoria;

-- Revocar privilegios globales por defecto de creación
ALTER USER user_recepcion NOSUPERUSER NOCREATEDB NOCREATEROLE;
ALTER USER user_taller NOSUPERUSER NOCREATEDB NOCREATEROLE;
ALTER USER user_facturacion NOSUPERUSER NOCREATEDB NOCREATEROLE;
ALTER USER user_auditoria NOSUPERUSER NOCREATEDB NOCREATEROLE;

-- 3. PERMISOS DE CONEXIÓN Y USAGE EN ESQUEMAS
GRANT CONNECT ON DATABASE autofix_final TO rol_recepcion, rol_taller, rol_facturacion, rol_auditoria;
GRANT USAGE ON SCHEMA taller TO rol_recepcion, rol_taller, rol_facturacion;
GRANT USAGE ON SCHEMA audit TO rol_auditoria; -- Esquema de auditoría creado en Tarea 7

-- 4. ASIGNACIÓN DE PRIVILEGIOS GRANULARES (GRANT / REVOKE)

-- PERFILES DE RECEPCIÓN: Consultar clientes/vehículos; crear clientes, vehículos y órdenes.
GRANT SELECT, INSERT ON taller.cliente, taller.vehiculo, taller.orden_trabajo TO rol_recepcion;
GRANT SELECT ON taller.servicio, taller.mecanico TO rol_recepcion;
GRANT USAGE, SELECT ON SEQUENCE taller.cliente_id_seq, taller.vehiculo_id_seq, taller.orden_trabajo_id_seq TO rol_recepcion;

-- PERFILES DE TALLER: Consultar vehículos, órdenes y servicios; actualizar estado de órdenes.
GRANT SELECT ON taller.vehiculo, taller.orden_trabajo, taller.servicio, taller.mecanico TO rol_taller;
GRANT UPDATE (estado) ON taller.orden_trabajo TO rol_taller;

-- PERFILES DE FACTURACIÓN: Consultar órdenes y servicios; actualizar importe total de órdenes terminadas.
GRANT SELECT ON taller.orden_trabajo, taller.servicio, taller.vehiculo, taller.cliente TO rol_facturacion;
GRANT UPDATE (importe_total, salida) ON taller.orden_trabajo TO rol_facturacion;

-- PERFILES DE AUDITORÍA: Consultar todas las tablas operativas y la tabla de auditoría.
GRANT SELECT ON ALL TABLES IN SCHEMA taller TO rol_auditoria;
GRANT SELECT ON ALL TABLES IN SCHEMA audit TO rol_auditoria;

-- 5. PRUEBAS DE VALIDACIÓN (A EJECUTAR CON CADA USUARIO EN CONEXIONES SEPARADAS)
/*
   -- PRUEBA RECEPCIÓN (Permitida creación, denegada modificación de precios)
   SET ROLE user_recepcion;
   INSERT INTO cliente (dni_nif, nombre, email, telefono) VALUES ('99999999Z', 'Test Recep', 'test@rec.es', '600000000'); -- OK
   UPDATE servicio SET precio_base = 999.00 WHERE id = 1; -- ERROR: permission denied
   RESET ROLE;

   -- PRUEBA TALLER (Permitido actualizar estado, denegado modificar datos personales de clientes)
   SET ROLE user_taller;
   UPDATE orden_trabajo SET estado = 'terminada' WHERE id = 4; -- OK
   UPDATE cliente SET nombre = 'Hack' WHERE id = 1; -- ERROR: permission denied
   RESET ROLE;
*/
SELECT 
    rolname AS rol_o_usuario,
    CASE 
        WHEN rolsuper THEN 'Sí (Superusuario)'
        ELSE 'No (Correcto)'
    END AS es_superusuario,
    CASE 
        WHEN rolcanlogin THEN 'Sí'
        ELSE 'No (NOLOGIN / Grupo)'
    END AS puede_iniciar_sesion,
    CASE 
        WHEN rolcreatedb THEN 'Sí'
        ELSE 'No (Correcto)'
    END AS crea_bases_datos,
    CASE 
        WHEN rolcreaterole THEN 'Sí'
        ELSE 'No (Correcto)'
    END AS crea_roles
FROM pg_roles
WHERE rolname IN (
    -- Roles de grupo del proyecto AutoFix Pro
    'rol_recepcion', 'rol_taller', 'rol_facturacion', 'rol_auditoria', 
    -- Usuarios individuales con LOGIN del proyecto AutoFix Pro
    'user_recepcion', 'user_taller', 'user_facturacion', 'user_auditoria'
)
ORDER BY rolcanlogin DESC, rolname ASC;

-- TABLA Tabla de Detalles de Permisos sobre Objetos (information_schema.role_table_grants)
-- Esta consulta lista de forma dinámica todos los permisos exactos (SELECT, INSERT, UPDATE, etc.)
--concedidos a cada rol sobre los esquemas de nuestro taller (taller y audit), evitando tener que documentarlos a mano: --

SELECT 
    grantee AS rol_o_usuario,
    table_schema AS esquema,
    table_name AS objeto,
    string_agg(privilege_type, ', ') AS permisos_otorgados
FROM information_schema.role_table_grants
WHERE table_schema IN ('taller', 'audit')
GROUP BY grantee, table_schema, table_name
ORDER BY grantee, table_schema, table_name;

-- Matriz de Validación de Acceso a Información Sensible (Pruebas Automatizadas)
-- Esta tabla simula validaciones de cumplimiento (compliance) para demostrar que los roles con restricciones
-- estrictas (como rol_taller o rol_recepcion) tienen denegado el acceso a áreas o datos para los que no tienen privilegios:

SELECT 
    'rol_taller' AS rol_evaluado,
    'taller.cliente (Datos personales / DNI)' AS recurso_restringido,
    CASE 
        WHEN NOT EXISTS (
            SELECT 1 FROM information_schema.role_table_grants 
            WHERE grantee = 'rol_taller' 
              AND table_schema = 'taller' 
              AND table_name = 'cliente'
        ) THEN 'ACCESO DENEGADO (Correcto - Mínimo Privilegio)'
        ELSE 'ACCESO PERMITIDO (Advertencia de seguridad)'
    END AS estado_privilegio

UNION ALL

SELECT 
    'rol_recepcion' AS rol_evaluado,
    'taller.servicio (Modificación de precios)' AS recurso_restringido,
    CASE 
        -- Recepción solo tiene SELECT en servicios, no UPDATE
        WHEN NOT EXISTS (
            SELECT 1 FROM information_schema.table_privileges 
            WHERE grantee = 'rol_recepcion' 
              AND table_schema = 'taller' 
              AND table_name = 'servicio'
              AND privilege_type = 'UPDATE'
        ) THEN 'ACCESO DE ESCRITURA DENEGADO (Correcto)'
        ELSE 'ACCESO DE ESCRITURA PERMITIDO (Revisar)'
    END AS estado_privilegio;

