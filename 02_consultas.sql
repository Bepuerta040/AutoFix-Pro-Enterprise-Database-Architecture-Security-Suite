-- =====================================================================
-- ARCHIVO: 02_consultas.sql
-- DESCRIPCIÓN: Consultas SELECT de negocio y Consultas de Acción (INSERT, UPDATE, DELETE)
-- =====================================================================

SET search_path TO taller, public;

SELECT v.matrícula, v.marca, v.modelo, v.año, c.nombre AS propietario
FROM vehiculo v
JOIN cliente c ON v.cliente_id = c.id
ORDER BY c.nombre, v.matrícula;


------------------------------------------------------------------------
-- PARTE A: CONSULTAS DE SELECCIÓN (SELECT)
------------------------------------------------------------------------

-- 1. Muestra todos los vehículos junto con el nombre de su propietario. Ordena por cliente y matrícula.
SELECT v.matrícula, v.marca, v.modelo, v.año, c.nombre AS propietario
FROM vehiculo v
JOIN cliente c ON v.cliente_id = c.id
ORDER BY c.nombre, v.matrícula;

-- 2. Muestra las órdenes de trabajo indicando matrícula, cliente, mecánico, fecha de entrada, estado e importe total.
SELECT ot.id AS orden_id, v.matrícula, c.nombre AS cliente, m.nombre AS mecanico, 
       ot.entrada, ot.estado, ot.importe_total
FROM orden_trabajo ot
JOIN vehiculo v ON ot.vehiculo_id = v.id
JOIN cliente c ON v.cliente_id = c.id
LEFT JOIN mecanico m ON ot.mecanico_id = m.id
ORDER BY ot.entrada DESC;

-- 3. Muestra únicamente las órdenes que todavía no están terminadas ni canceladas.
SELECT * FROM orden_trabajo
WHERE estado NOT IN ('terminada', 'cancelada');

-- 4. Indica cuántas órdenes tiene asignadas cada mecánico (nombre y número de órdenes).
SELECT m.nombre AS mecanico, COUNT(ot.id) AS total_ordenes
FROM mecanico m
LEFT JOIN orden_trabajo ot ON m.id = ot.mecanico_id
GROUP BY m.id, m.nombre
ORDER BY total_ordenes DESC;

-- 5. Calcula, para cada orden que tenga servicios registrados, el coste calculado como SUM(cantidad × precio_aplicado).
SELECT do_t.orden_id, SUM(do_t.cantidad * do_t.precio_aplicado) AS coste_calculado
FROM detalle_orden do_t
GROUP BY do_t.orden_id
ORDER BY do_t.orden_id;

-- 6. Muestra los clientes que tengan algún vehículo pero ninguna orden de trabajo asociada a ninguno de sus vehículos.
SELECT c.id, c.nombre, c.dni_nif
FROM cliente c
WHERE EXISTS (
    SELECT 1 FROM vehiculo v WHERE v.cliente_id = c.id
)
AND NOT EXISTS (
    SELECT 1 FROM vehiculo v 
    JOIN orden_trabajo ot ON v.id = ot.vehiculo_id 
    WHERE v.cliente_id = c.id
);


------------------------------------------------------------------------
-- PARTE B: CONSULTAS DE ACCIÓN
------------------------------------------------------------------------

-- 1. INSERT: Registra una nueva orden para el vehículo con matrícula '7890-BCD' (Asignado a mecánico id 2, estado pendiente).
INSERT INTO orden_trabajo (vehiculo_id, mecanico_id, entrada, estado, importe_total)
VALUES (
    (SELECT id FROM vehiculo WHERE matrícula = '7890-BCD'),
    2,
    CURRENT_DATE,
    'pendiente',
    0.00
);
SELECT * FROM orden_trabajo WHERE vehiculo_id = (SELECT id FROM vehiculo WHERE matrícula = '7890-BCD');

-- 2. UPDATE: Cambia la orden 2 a estado 'terminada', asigna fecha de salida y actualiza su importe.
UPDATE orden_trabajo
SET estado = 'terminada',
    salida = CURRENT_DATE,
    importe_total = 110.00
WHERE id = 2;
SELECT * FROM orden_trabajo WHERE id = 2;

-- 3. UPDATE: Incrementa un 5% el precio base de todos los servicios cuyo precio actual sea inferior a 100 €.
UPDATE servicio
SET precio_base = ROUND(precio_base * 1.05, 2)
WHERE precio_base < 100.00;
SELECT * FROM servicio;

-- 4. DELETE: Elimina un servicio del catálogo que no haya sido utilizado en ninguna orden.
-- (Primero aseguramos la existencia de un servicio huérfano de prueba, luego lo eliminamos).
INSERT INTO servicio (código, descripción, precio_base) 
VALUES ('TEMP-DEL', 'Servicio temporal de prueba', 25.00);

DELETE FROM servicio
WHERE código = 'TEMP-DEL' 
  AND id NOT IN (SELECT DISTINCT servicio_id FROM detalle_orden);

SELECT * FROM servicio;