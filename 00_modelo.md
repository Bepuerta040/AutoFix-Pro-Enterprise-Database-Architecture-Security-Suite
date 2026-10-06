Entregable 00: Modelo Entidad-Relación y Modelo Relacional (00_modelo.md / PDF)
# 🚗 AutoFix Pro - Modelado de Datos (Modelo E/R y Relacional)

Este documento describe la fase de diseño conceptual y lógico para el sistema de gestión del taller mecánico **AutoFix Pro**, desarrollado en PostgreSQL.

---

## 1. Descripción del Caso de Negocio
El taller **AutoFix Pro** requiere una solución centralizada para gestionar de manera integrada los siguientes procesos operativos:
* Control de clientes y sus respectivos vehículos.
* Gestión de mecánicos especialistas y su estado operativo.
* Registro y control de órdenes de trabajo asociadas a vehículos y mecánicos.
* Catálogo de servicios de taller y su relación en detalle con las órdenes de trabajo (resolviendo una relación de muchos a muchos).
* Trazabilidad de cambios e importes totales.

---

## 2. Diagrama Entidad-Relación (E/R Conceptual)

### Entidades y Atributos Principales:
1. **`cliente`**
   * `id` (PK): Identificador único autoincremental.
   * `dni_nif` (UK, NOT NULL): Documento de identidad único.
   * `nombre` (NOT NULL): Nombre completo del cliente.
   * `email` (UK, NOT NULL): Correo electrónico de contacto.
   * `telefono` (NOT NULL): Teléfono de contacto.

2. **`vehiculo`**
   * `id` (PK): Identificador único autoincremental.
   * `cliente_id` (FK, NOT NULL): Referencia al propietario del vehículo.
   * `matrícula` (UK, NOT NULL): Matrícula única del vehículo.
   * `marca` (NOT NULL): Marca del automóvil.
   * `modelo` (NOT NULL): Modelo del automóvil.
   * `año` (NOT NULL): Año de matriculación.

3. **`mecanico`**
   * `id` (PK): Identificador único del mecánico.
   * `nombre` (NOT NULL): Nombre completo.
   * `especialidad` (NOT NULL): Área técnica de especialización.
   * `activo` (BOOLEAN, NOT NULL): Indicador de disponibilidad operativa.

4. **`servicio`**
   * `id` (PK): Identificador único del servicio.
   * `código` (UK, NOT NULL): Código corto del servicio (ej. `REV-BAS`).
   * `descripción` (NOT NULL): Detalle de la tarea.
   * `precio_base` (DECIMAL, NOT NULL): Costo base del servicio.

5. **`orden_trabajo`**
   * `id` (PK): Identificador único de la orden.
   * `vehiculo_id` (FK, NOT NULL): Vehículo que ingresa al taller.
   * `mecanico_id` (FK, NULL): Mecánico asignado a la orden.
   * `entrada` (DATE, NOT NULL): Fecha de recepción.
   * `salida` (DATE, NULL): Fecha de entrega final.
   * `estado` (VARCHAR, NOT NULL): Estado actual (`pendiente`, `en_reparacion`, `terminada`, `cancelada`).
   * `importe_total` (DECIMAL, NOT NULL): Costo acumulado de la orden.

6. **`detalle_orden` (Tabla Intermedia N:M)**
   * `orden_id` (PK/FK): Referencia a la orden de trabajo.
   * `servicio_id` (PK/FK): Referencia al servicio prestado.
   * `cantidad` (INT, NOT NULL): Unidades aplicadas del servicio.
   * `precio_aplicado` (DECIMAL, NOT NULL): Precio unitario fijado en el momento.

---

## 3. Relaciones y Cardinalidades

* **`cliente` (1:N) `vehiculo`**: Un cliente puede poseer uno o múltiples vehículos, pero cada vehículo pertenece exclusivamente a un único cliente.
* **`vehiculo` (1:N) `orden_trabajo`**: Un vehículo puede acumular múltiples órdenes de trabajo a lo largo del tiempo; cada orden pertenece a un único vehículo.
* **`mecanico` (1:N) `orden_trabajo`**: Un mecánico puede tener asignadas varias órdenes de trabajo; una orden puede estar asignada a un único mecánico (o quedar sin asignar inicialmente).
* **`orden_trabajo` (N:M) `servicio`**: Una orden de trabajo puede incluir varios servicios del catálogo, y un mismo servicio puede formar parte de diferentes órdenes de trabajo a lo largo del tiempo. Esta relación se resuelve mediante la entidad débil **`detalle_orden`**.

---

## 4. Esquema Relacional Normalizado

```text
cliente (id [PK], dni_nif [UK], nombre, email [UK], telefono)
vehiculo (id [PK], cliente_id [FK -> cliente(id)], matrícula [UK], marca, modelo, año)
mecanico (id [PK], nombre, especialidad, activo)
servicio (id [PK], código [UK], descripción, precio_base)
orden_trabajo (id [PK], vehiculo_id [FK -> vehiculo(id)], mecanico_id [FK -> mecanico(id)], entrada, salida, estado, importe_total)
detalle_orden (orden_id [PK/FK -> orden_trabajo(id)], servicio_id [PK/FK -> servicio(id)], cantidad, precio_aplicado)