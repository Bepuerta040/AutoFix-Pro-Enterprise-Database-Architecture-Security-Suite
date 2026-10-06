-- =====================================================================
-- PROYECTO: AutoFix Pro - Gestión de Taller Mecánico
-- ARCHIVO: 01_creacion_datos.sql
-- DESCRIPCIÓN: Creación de base de datos, esquema, tablas con restricciones
--              avanzadas (CHECK, FK con borrado lógico/restringido) e inserciones.
-- =====================================================================

-- =====================================================================
-- SCRIPT MAESTRO UNIFICADO: AutoFix Pro
-- =====================================================================

-- Asegurar esquema
CREATE SCHEMA IF NOT EXISTS taller;
SET search_path TO taller, public;

-- Limpieza previa por seguridad (evita duplicados si ya corrías algo)
DROP TABLE IF EXISTS detalle_orden CASCADE;
DROP TABLE IF EXISTS orden_trabajo CASCADE;
DROP TABLE IF EXISTS servicio CASCADE;
DROP TABLE IF EXISTS mecanico CASCADE;
DROP TABLE IF EXISTS vehiculo CASCADE;
DROP TABLE IF EXISTS cliente CASCADE;

-- 1. CREACIÓN DE TABLAS
CREATE TABLE cliente (
    id SERIAL PRIMARY KEY,
    dni_nif VARCHAR(20) NOT NULL UNIQUE,
    nombre VARCHAR(100) NOT NULL,
    email VARCHAR(150) NOT NULL UNIQUE,
    telefono VARCHAR(20) NOT NULL,
    CONSTRAINT chk_cliente_dni CHECK (length(trim(dni_nif)) >= 8),
    CONSTRAINT chk_cliente_email CHECK (email LIKE '%@%._%')
);

CREATE TABLE vehiculo (
    id SERIAL PRIMARY KEY,
    cliente_id INT NOT NULL,
    matrícula VARCHAR(15) NOT NULL UNIQUE,
    marca VARCHAR(50) NOT NULL,
    modelo VARCHAR(50) NOT NULL,
    año INT NOT NULL,
    CONSTRAINT fk_vehiculo_cliente FOREIGN KEY (cliente_id) 
        REFERENCES cliente(id) ON UPDATE CASCADE ON DELETE RESTRICT,
    CONSTRAINT chk_vehiculo_anio CHECK (año >= 1900 AND año <= 2100)
);

CREATE TABLE mecanico (
    id SERIAL PRIMARY KEY,
    nombre VARCHAR(100) NOT NULL,
    especialidad VARCHAR(100) NOT NULL,
    activo BOOLEAN NOT NULL DEFAULT TRUE
);

CREATE TABLE servicio (
    id SERIAL PRIMARY KEY,
    código VARCHAR(20) NOT NULL UNIQUE,
    descripción TEXT NOT NULL,
    precio_base NUMERIC(10, 2) NOT NULL,
    CONSTRAINT chk_precio_base_positivo CHECK (precio_base >= 0)
);

CREATE TABLE orden_trabajo (
    id SERIAL PRIMARY KEY,
    vehiculo_id INT NOT NULL,
    mecanico_id INT,
    entrada DATE NOT NULL DEFAULT CURRENT_DATE,
    salida DATE,
    estado VARCHAR(20) NOT NULL,
    importe_total NUMERIC(10, 2) NOT NULL DEFAULT 0.00,
    CONSTRAINT fk_orden_vehiculo FOREIGN KEY (vehiculo_id) 
        REFERENCES vehiculo(id) ON UPDATE CASCADE ON DELETE RESTRICT,
    CONSTRAINT fk_orden_mecanico FOREIGN KEY (mecanico_id) 
        REFERENCES mecanico(id) ON UPDATE CASCADE ON DELETE SET NULL,
    CONSTRAINT chk_orden_estado CHECK (estado IN ('pendiente', 'en_reparacion', 'terminada', 'cancelada')),
    CONSTRAINT chk_importe_no_negativo CHECK (importe_total >= 0)
);

CREATE TABLE detalle_orden (
    orden_id INT NOT NULL,
    servicio_id INT NOT NULL,
    cantidad INT NOT NULL,
    precio_aplicado NUMERIC(10, 2) NOT NULL,
    PRIMARY KEY (orden_id, servicio_id),
    CONSTRAINT fk_detalle_orden FOREIGN KEY (orden_id) 
        REFERENCES orden_trabajo(id) ON UPDATE CASCADE ON DELETE CASCADE,
    CONSTRAINT fk_detalle_servicio FOREIGN KEY (servicio_id) 
        REFERENCES servicio(id) ON UPDATE CASCADE ON DELETE RESTRICT,
    CONSTRAINT chk_cantidad_positiva CHECK (cantidad > 0)
);

-- 2. INSERCIÓN DE DATOS DE PRUEBA
INSERT INTO cliente (id, dni_nif, nombre, email, telefono) VALUES
(1, '11111111A', 'Ana Molina', 'ana.molina@autofix.test', '600111111'),
(2, '22222222B', 'Carlos Ríos', 'carlos.rios@autofix.test', '600222222'),
(3, '33333333C', 'Laura Pérez', 'laura.perez@autofix.test', '600333333'),
(4, 'B44444444', 'Distribuciones Norte SL', 'taller@distnorte.test', '600444444');
SELECT setval('cliente_id_seq', (SELECT MAX(id) FROM cliente));

INSERT INTO vehiculo (id, cliente_id, matrícula, marca, modelo, año) VALUES
(1, 1, '1234-KLM', 'Toyota', 'Corolla', 2019),
(2, 1, '5678-MNP', 'Seat', 'Ibiza', 2017),
(3, 2, '9012-RST', 'Renault', 'Clio', 2020),
(4, 3, '3456-VWX', 'Ford', 'Focus', 2018),
(5, 4, '7890-BCD', 'Volkswagen', 'Caddy', 2021);
SELECT setval('vehiculo_id_seq', (SELECT MAX(id) FROM vehiculo));

INSERT INTO mecanico (id, nombre, especialidad, activo) VALUES
(1, 'Miguel Torres', 'Mecánica general', TRUE),
(2, 'Sara Vidal', 'Electricidad', TRUE),
(3, 'Óscar León', 'Diagnosis', TRUE);
SELECT setval('mecanico_id_seq', (SELECT MAX(id) FROM mecanico));

INSERT INTO servicio (id, código, descripción, precio_base) VALUES
(1, 'REV-BAS', 'Revisión básica', 60.00),
(2, 'FRENOS', 'Cambio de pastillas de freno', 140.00),
(3, 'BATERIA', 'Sustitución de batería', 110.00),
(4, 'DIAG', 'Diagnosis electrónica', 75.00),
(5, 'ACEITE', 'Cambio de aceite y filtro', 85.00);
SELECT setval('servicio_id_seq', (SELECT MAX(id) FROM servicio));

INSERT INTO orden_trabajo (id, vehiculo_id, mecanico_id, entrada, salida, estado, importe_total) VALUES
(1, 1, 1, '2026-09-01', '2026-09-02', 'terminada', 145.00),
(2, 3, 2, '2026-09-03', NULL, 'en_reparacion', 110.00),
(3, 4, 3, '2026-09-04', '2026-09-04', 'terminada', 75.00),
(4, 5, 1, '2026-09-05', NULL, 'pendiente', 0.00),
(5, 2, 2, '2026-09-06', NULL, 'en_reparacion', 140.00);
SELECT setval('orden_trabajo_id_seq', (SELECT MAX(id) FROM orden_trabajo));

INSERT INTO detalle_orden (orden_id, servicio_id, cantidad, precio_aplicado) VALUES
(1, 1, 1, 60.00),
(1, 5, 1, 85.00),
(2, 3, 1, 110.00),
(3, 4, 1, 75.00),
(5, 2, 1, 140.00);

SET search_path TO taller, public;

SELECT v.matrícula, v.marca, v.modelo, v.año, c.nombre AS propietario
FROM vehiculo v
JOIN cliente c ON v.cliente_id = c.id
ORDER BY c.nombre, v.matrícula;