/*
============================================================
03_CARGAR_DATOS.SQL
Banking Customer & Credit Risk Analytics — MySQL
============================================================

Objetivo:
Cargar los archivos CSV generados por scripts/generar_datos.py
en las siete tablas de la base de datos.

Estructura esperada:

banking-credit-risk-sql/
├── data/
│   ├── clientes.csv
│   ├── cuentas.csv
│   ├── transacciones.csv
│   ├── solicitudes_credito.csv
│   ├── prestamos.csv
│   ├── pagos_prestamo.csv
│   └── evaluaciones_riesgo.csv
│
├── scripts/
│   └── 03_cargar_datos.sql
│
└── sql/
    └── 00_creacion_base_datos.sql

IMPORTANTE:
- Las tablas deben estar vacías antes de ejecutar este script.
- Si MySQL Workbench no encuentra las rutas relativas,
  sustituye 'data/...' por la ruta absoluta correspondiente.
============================================================
*/

USE banca_riesgo_crediticio;


-- =========================================================
-- CONFIGURACIÓN DE LOCAL INFILE
-- =========================================================

-- Si MySQL bloquea LOAD DATA LOCAL INFILE,
-- puede ser necesario ejecutar como usuario con permisos:
--
-- SET GLOBAL local_infile = 1;
--
-- En MySQL Workbench también puede ser necesario habilitar
-- OPT_LOCAL_INFILE=1 en la configuración de la conexión.


-- =========================================================
-- 1. CLIENTES
-- =========================================================

LOAD DATA LOCAL INFILE 'data/clientes.csv'
INTO TABLE clientes
CHARACTER SET utf8mb4
FIELDS TERMINATED BY ','
OPTIONALLY ENCLOSED BY '"'
ESCAPED BY '\\'
LINES TERMINATED BY '\n'
IGNORE 1 LINES;


-- =========================================================
-- 2. CUENTAS
-- =========================================================

LOAD DATA LOCAL INFILE 'data/cuentas.csv'
INTO TABLE cuentas
CHARACTER SET utf8mb4
FIELDS TERMINATED BY ','
OPTIONALLY ENCLOSED BY '"'
ESCAPED BY '\\'
LINES TERMINATED BY '\n'
IGNORE 1 LINES;


-- =========================================================
-- 3. TRANSACCIONES
-- =========================================================

LOAD DATA LOCAL INFILE 'data/transacciones.csv'
INTO TABLE transacciones
CHARACTER SET utf8mb4
FIELDS TERMINATED BY ','
OPTIONALLY ENCLOSED BY '"'
ESCAPED BY '\\'
LINES TERMINATED BY '\n'
IGNORE 1 LINES;


-- =========================================================
-- 4. SOLICITUDES DE CRÉDITO
-- =========================================================

LOAD DATA LOCAL INFILE 'data/solicitudes_credito.csv'
INTO TABLE solicitudes_credito
CHARACTER SET utf8mb4
FIELDS TERMINATED BY ','
OPTIONALLY ENCLOSED BY '"'
ESCAPED BY '\\'
LINES TERMINATED BY '\n'
IGNORE 1 LINES;


-- =========================================================
-- 5. PRÉSTAMOS
-- =========================================================

LOAD DATA LOCAL INFILE 'data/prestamos.csv'
INTO TABLE prestamos
CHARACTER SET utf8mb4
FIELDS TERMINATED BY ','
OPTIONALLY ENCLOSED BY '"'
ESCAPED BY '\\'
LINES TERMINATED BY '\n'
IGNORE 1 LINES;


-- =========================================================
-- 6. PAGOS DE PRÉSTAMO
-- =========================================================

LOAD DATA LOCAL INFILE 'data/pagos_prestamo.csv'
INTO TABLE pagos_prestamo
CHARACTER SET utf8mb4
FIELDS TERMINATED BY ','
OPTIONALLY ENCLOSED BY '"'
ESCAPED BY '\\'
LINES TERMINATED BY '\n'
IGNORE 1 LINES;


-- =========================================================
-- 7. EVALUACIONES DE RIESGO
-- =========================================================

LOAD DATA LOCAL INFILE 'data/evaluaciones_riesgo.csv'
INTO TABLE evaluaciones_riesgo
CHARACTER SET utf8mb4
FIELDS TERMINATED BY ','
OPTIONALLY ENCLOSED BY '"'
ESCAPED BY '\\'
LINES TERMINATED BY '\n'
IGNORE 1 LINES;


-- =========================================================
-- 8. COMPROBACIÓN FINAL
-- =========================================================

SELECT 'clientes' AS tabla, COUNT(*) AS registros
FROM clientes

UNION ALL

SELECT 'cuentas', COUNT(*)
FROM cuentas

UNION ALL

SELECT 'transacciones', COUNT(*)
FROM transacciones

UNION ALL

SELECT 'solicitudes_credito', COUNT(*)
FROM solicitudes_credito

UNION ALL

SELECT 'prestamos', COUNT(*)
FROM prestamos

UNION ALL

SELECT 'pagos_prestamo', COUNT(*)
FROM pagos_prestamo

UNION ALL

SELECT 'evaluaciones_riesgo', COUNT(*)
FROM evaluaciones_riesgo;