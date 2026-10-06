# 🚗 AutoFix Pro | Enterprise Database Architecture & Security Suite

> Sistema de gestión integral para talleres mecánicos desarrollado en **PostgreSQL**, diseñado bajo estrictos estándares de integridad referencial, seguridad basada en roles (RBAC) y auditoría automatizada.

---

## 🎯 Resumen del Proyecto
**AutoFix Pro** es una solución de base de datos relacional robusta creada para resolver los retos operativos y de gobernancia de datos de un centro de servicios automotrices. El proyecto abarca desde el modelado conceptual y la normalización hasta la implementación de políticas de seguridad corporativa, control de privilegios de mínimo acceso y auditoría forense de cambios.

Este repositorio forma parte de mi portafolio profesional como **Desarrollador de Bases de Datos y Administrador PostgreSQL**, demostrando habilidades clave en diseño lógico, scripting avanzado, control de acceso y automatización.

---

## 🛠️ Stack Tecnológico y Herramientas
* **Motor de Base de Datos:** PostgreSQL (v15+)
* **Entorno de Gestión y Pruebas:** pgAdmin 4 & Consola `psql`
* **Control de Versiones y Documentación:** Git & GitHub / Markdown
* **Lenguaje:** SQL (DDL, DML, DCL, PL/pgSQL)

---

## 📂 Estructura del Repositorio
El proyecto está modularizado siguiendo los estándares de la industria para facilitar su revisión, mantenimiento y despliegue:

```text
📁 AutoFix_Pro_Portfolio/
├── 📄 README.md                 <-- Documentación principal del proyecto
├── 📄 00_modelo.md              <-- Diagrama E/R y Modelo Relacional
├── 📜 01_creacion_datos.sql     <-- DDL (Esquema, tablas, restricciones) y DML (Datos iniciales)
├── 📜 02_consultas.sql          <-- Consultas analíticas complejas (JOINs, agregaciones, subconsultas)
├── 📜 03_seguridad.sql          <-- Gestión de roles (RBAC), usuarios y matriz de permisos
├── 📜 04_auditoria.sql          <-- Esquema de auditoría, funciones PL/pgSQL y triggers de seguimiento
├── 📊 06_ordenes_terminadas.csv <-- Exportación automatizada de datos en codificación UTF-8
└── 📄 07_evidencias.pdf         <-- Capturas de verificación y pruebas funcionales