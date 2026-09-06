/*
============================================================
BANKING CUSTOMER & CREDIT RISK ANALYTICS
Creación de la base de datos y modelo relacional
Motor: MySQL 8+
============================================================
*/
-- =========================================================
-- 1. CREACIÓN DE LA BASE DE DATOS
-- =========================================================

CREATE DATABASE IF NOT EXISTS banca_riesgo_crediticio
    CHARACTER SET utf8mb4
    COLLATE utf8mb4_0900_ai_ci;

USE banca_riesgo_crediticio;


-- =========================================================
-- 2. TABLA CLIENTES
-- =========================================================

CREATE TABLE clientes (
    id_cliente INT UNSIGNED AUTO_INCREMENT,
    fecha_alta DATE NOT NULL,
    fecha_nacimiento DATE NOT NULL,
    genero VARCHAR(20),
    estado_civil VARCHAR(20),
    nivel_estudios VARCHAR(50),
    situacion_laboral VARCHAR(30) NOT NULL,
    antiguedad_laboral_anios DECIMAL(4,1),
    ingresos_mensuales DECIMAL(12,2) NOT NULL,
    num_dependientes TINYINT UNSIGNED DEFAULT 0,
    tipo_vivienda VARCHAR(30),
    provincia VARCHAR(50) NOT NULL,
    estado_cliente VARCHAR(20) NOT NULL DEFAULT 'activo',

    PRIMARY KEY (id_cliente),

    CONSTRAINT chk_clientes_ingresos
        CHECK (ingresos_mensuales >= 0),

    CONSTRAINT chk_clientes_antiguedad
        CHECK (
            antiguedad_laboral_anios IS NULL
            OR antiguedad_laboral_anios >= 0
        ),

    CONSTRAINT chk_clientes_estado
        CHECK (
            estado_cliente IN ('activo', 'inactivo', 'bloqueado')
        )
);


-- =========================================================
-- 3. TABLA CUENTAS
-- =========================================================

CREATE TABLE cuentas (
    id_cuenta INT UNSIGNED AUTO_INCREMENT,
    id_cliente INT UNSIGNED NOT NULL,
    tipo_cuenta VARCHAR(30) NOT NULL,
    fecha_apertura DATE NOT NULL,
    saldo_actual DECIMAL(14,2) NOT NULL DEFAULT 0,
    limite_descubierto DECIMAL(12,2) NOT NULL DEFAULT 0,
    estado_cuenta VARCHAR(20) NOT NULL DEFAULT 'activa',

    PRIMARY KEY (id_cuenta),

    CONSTRAINT fk_cuentas_clientes
        FOREIGN KEY (id_cliente)
        REFERENCES clientes(id_cliente)
        ON UPDATE CASCADE
        ON DELETE RESTRICT,

    CONSTRAINT chk_cuentas_descubierto
        CHECK (limite_descubierto >= 0),

    CONSTRAINT chk_cuentas_estado
        CHECK (
            estado_cuenta IN ('activa', 'cerrada', 'bloqueada')
        ),

    INDEX idx_cuentas_cliente (id_cliente)
);


-- =========================================================
-- 4. TABLA TRANSACCIONES
-- =========================================================

CREATE TABLE transacciones (
    id_transaccion BIGINT UNSIGNED AUTO_INCREMENT,
    id_cuenta INT UNSIGNED NOT NULL,
    fecha_transaccion DATETIME NOT NULL,
    tipo_transaccion VARCHAR(30) NOT NULL,
    categoria VARCHAR(50),
    importe DECIMAL(12,2) NOT NULL,
    canal VARCHAR(30),
    saldo_posterior DECIMAL(14,2) NOT NULL,

    PRIMARY KEY (id_transaccion),

    CONSTRAINT fk_transacciones_cuentas
        FOREIGN KEY (id_cuenta)
        REFERENCES cuentas(id_cuenta)
        ON UPDATE CASCADE
        ON DELETE RESTRICT,

    CONSTRAINT chk_transacciones_importe
        CHECK (importe <> 0),

    INDEX idx_transacciones_cuenta (id_cuenta),
    INDEX idx_transacciones_fecha (fecha_transaccion),
    INDEX idx_transacciones_categoria (categoria)
);


-- =========================================================
-- 5. TABLA SOLICITUDES_CREDITO
-- =========================================================

CREATE TABLE solicitudes_credito (
    id_solicitud INT UNSIGNED AUTO_INCREMENT,
    id_cliente INT UNSIGNED NOT NULL,
    fecha_solicitud DATE NOT NULL,
    tipo_credito VARCHAR(40) NOT NULL,
    importe_solicitado DECIMAL(14,2) NOT NULL,
    plazo_meses SMALLINT UNSIGNED NOT NULL,
    finalidad VARCHAR(100),
    score_solicitud SMALLINT UNSIGNED NOT NULL,
    ratio_endeudamiento DECIMAL(6,2) NOT NULL,
    estado_solicitud VARCHAR(20) NOT NULL,
    motivo_rechazo VARCHAR(100),

    PRIMARY KEY (id_solicitud),

    CONSTRAINT fk_solicitudes_clientes
        FOREIGN KEY (id_cliente)
        REFERENCES clientes(id_cliente)
        ON UPDATE CASCADE
        ON DELETE RESTRICT,

    CONSTRAINT chk_solicitudes_importe
        CHECK (importe_solicitado > 0),

    CONSTRAINT chk_solicitudes_plazo
        CHECK (plazo_meses > 0),

    CONSTRAINT chk_solicitudes_score
        CHECK (score_solicitud BETWEEN 0 AND 1000),

    CONSTRAINT chk_solicitudes_endeudamiento
        CHECK (ratio_endeudamiento >= 0),

    CONSTRAINT chk_solicitudes_estado
        CHECK (
            estado_solicitud
            IN ('aprobada', 'rechazada', 'pendiente')
        ),

    INDEX idx_solicitudes_cliente (id_cliente),
    INDEX idx_solicitudes_fecha (fecha_solicitud),
    INDEX idx_solicitudes_estado (estado_solicitud)
);


-- =========================================================
-- 6. TABLA PRESTAMOS
-- =========================================================

CREATE TABLE prestamos (
    id_prestamo INT UNSIGNED AUTO_INCREMENT,
    id_solicitud INT UNSIGNED NOT NULL,
    fecha_concesion DATE NOT NULL,
    importe_concedido DECIMAL(14,2) NOT NULL,
    tipo_interes DECIMAL(5,2) NOT NULL,
    plazo_meses SMALLINT UNSIGNED NOT NULL,
    cuota_mensual DECIMAL(12,2) NOT NULL,
    saldo_pendiente DECIMAL(14,2) NOT NULL,
    fecha_vencimiento DATE NOT NULL,
    estado_prestamo VARCHAR(30) NOT NULL DEFAULT 'activo',

    PRIMARY KEY (id_prestamo),

    CONSTRAINT uq_prestamos_solicitud
        UNIQUE (id_solicitud),

    CONSTRAINT fk_prestamos_solicitudes
        FOREIGN KEY (id_solicitud)
        REFERENCES solicitudes_credito(id_solicitud)
        ON UPDATE CASCADE
        ON DELETE RESTRICT,

    CONSTRAINT chk_prestamos_importe
        CHECK (importe_concedido > 0),

    CONSTRAINT chk_prestamos_interes
        CHECK (tipo_interes >= 0),

    CONSTRAINT chk_prestamos_plazo
        CHECK (plazo_meses > 0),

    CONSTRAINT chk_prestamos_cuota
        CHECK (cuota_mensual > 0),

    CONSTRAINT chk_prestamos_saldo
        CHECK (saldo_pendiente >= 0),

    CONSTRAINT chk_prestamos_estado
        CHECK (
            estado_prestamo
            IN ('activo', 'pagado', 'mora', 'impagado')
        ),

    INDEX idx_prestamos_estado (estado_prestamo),
    INDEX idx_prestamos_vencimiento (fecha_vencimiento)
);


-- =========================================================
-- 7. TABLA PAGOS_PRESTAMO
-- =========================================================

CREATE TABLE pagos_prestamo (
    id_pago BIGINT UNSIGNED AUTO_INCREMENT,
    id_prestamo INT UNSIGNED NOT NULL,
    fecha_vencimiento DATE NOT NULL,
    fecha_pago DATE,
    importe_previsto DECIMAL(12,2) NOT NULL,
    importe_pagado DECIMAL(12,2) NOT NULL DEFAULT 0,
    dias_retraso SMALLINT UNSIGNED NOT NULL DEFAULT 0,
    estado_pago VARCHAR(20) NOT NULL,

    PRIMARY KEY (id_pago),

    CONSTRAINT uq_pago_prestamo_vencimiento
        UNIQUE (id_prestamo, fecha_vencimiento),

    CONSTRAINT fk_pagos_prestamos
        FOREIGN KEY (id_prestamo)
        REFERENCES prestamos(id_prestamo)
        ON UPDATE CASCADE
        ON DELETE RESTRICT,

    CONSTRAINT chk_pagos_importe_previsto
        CHECK (importe_previsto > 0),

    CONSTRAINT chk_pagos_importe_pagado
        CHECK (importe_pagado >= 0),

    CONSTRAINT chk_pagos_estado
        CHECK (
            estado_pago
            IN ('pendiente', 'pagado', 'retrasado', 'impagado')
        ),

    INDEX idx_pagos_prestamo (id_prestamo),
    INDEX idx_pagos_vencimiento (fecha_vencimiento),
    INDEX idx_pagos_estado (estado_pago),
    INDEX idx_pagos_retraso (dias_retraso)
);


-- =========================================================
-- 8. TABLA EVALUACIONES_RIESGO
-- =========================================================

CREATE TABLE evaluaciones_riesgo (
    id_evaluacion INT UNSIGNED AUTO_INCREMENT,
    id_cliente INT UNSIGNED NOT NULL,
    fecha_evaluacion DATE NOT NULL,
    score_crediticio SMALLINT UNSIGNED NOT NULL,
    ingresos_mensuales DECIMAL(12,2) NOT NULL,
    deuda_total DECIMAL(14,2) NOT NULL DEFAULT 0,
    ratio_endeudamiento DECIMAL(6,2) NOT NULL,
    num_impagos_12m TINYINT UNSIGNED NOT NULL DEFAULT 0,
    utilizacion_credito_pct DECIMAL(6,2) NOT NULL,
    nivel_riesgo VARCHAR(20) NOT NULL,
    probabilidad_impago DECIMAL(6,5) NOT NULL,

    PRIMARY KEY (id_evaluacion),

    CONSTRAINT fk_evaluaciones_clientes
        FOREIGN KEY (id_cliente)
        REFERENCES clientes(id_cliente)
        ON UPDATE CASCADE
        ON DELETE RESTRICT,

    CONSTRAINT chk_evaluaciones_score
        CHECK (score_crediticio BETWEEN 0 AND 1000),

    CONSTRAINT chk_evaluaciones_ingresos
        CHECK (ingresos_mensuales >= 0),

    CONSTRAINT chk_evaluaciones_deuda
        CHECK (deuda_total >= 0),

    CONSTRAINT chk_evaluaciones_endeudamiento
        CHECK (ratio_endeudamiento >= 0),

    CONSTRAINT chk_evaluaciones_utilizacion
        CHECK (utilizacion_credito_pct >= 0),

    CONSTRAINT chk_evaluaciones_riesgo
        CHECK (
            nivel_riesgo IN ('bajo', 'medio', 'alto')
        ),

    CONSTRAINT chk_evaluaciones_probabilidad
        CHECK (probabilidad_impago BETWEEN 0 AND 1),

    INDEX idx_evaluaciones_cliente (id_cliente),
    INDEX idx_evaluaciones_fecha (fecha_evaluacion),
    INDEX idx_evaluaciones_riesgo (nivel_riesgo),
    INDEX idx_evaluaciones_score (score_crediticio)
);


-- =========================================================
-- 9. COMPROBACIÓN
-- =========================================================

SHOW TABLES;