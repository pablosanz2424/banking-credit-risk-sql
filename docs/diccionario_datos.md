# Diccionario de Datos

Este documento describe la estructura de la base de datos del proyecto **Banking Customer & Credit Risk Analytics — MySQL**.

La base de datos está compuesta por siete tablas relacionadas que representan clientes, cuentas, transacciones, solicitudes de crédito, préstamos, pagos y evaluaciones de riesgo.

---

## 1. `clientes`

Tabla maestra con información demográfica, laboral y económica de cada cliente.

| Columna | Tipo de dato | Descripción |
|---|---|---|
| `id_cliente` | `INT UNSIGNED` | Identificador único del cliente. Clave primaria. |
| `fecha_alta` | `DATE` | Fecha de alta del cliente en el banco. |
| `fecha_nacimiento` | `DATE` | Fecha de nacimiento del cliente. |
| `genero` | `VARCHAR(20)` | Género declarado por el cliente. |
| `estado_civil` | `VARCHAR(20)` | Estado civil del cliente. |
| `nivel_estudios` | `VARCHAR(50)` | Nivel educativo alcanzado. |
| `situacion_laboral` | `VARCHAR(30)` | Situación laboral actual. |
| `antiguedad_laboral_anios` | `DECIMAL(4,1)` | Antigüedad laboral expresada en años. |
| `ingresos_mensuales` | `DECIMAL(12,2)` | Ingresos mensuales estimados del cliente. |
| `num_dependientes` | `TINYINT UNSIGNED` | Número de personas económicamente dependientes del cliente. |
| `tipo_vivienda` | `VARCHAR(30)` | Situación residencial: propiedad, alquiler, hipotecada, etc. |
| `provincia` | `VARCHAR(50)` | Provincia de residencia. |
| `estado_cliente` | `VARCHAR(20)` | Estado operativo del cliente: activo, inactivo o bloqueado. |

**Clave primaria:** `id_cliente`

---

## 2. `cuentas`

Contiene las cuentas bancarias asociadas a los clientes.

| Columna | Tipo de dato | Descripción |
|---|---|---|
| `id_cuenta` | `INT UNSIGNED` | Identificador único de la cuenta. Clave primaria. |
| `id_cliente` | `INT UNSIGNED` | Cliente propietario de la cuenta. Clave foránea hacia `clientes`. |
| `tipo_cuenta` | `VARCHAR(30)` | Tipo de cuenta bancaria. |
| `fecha_apertura` | `DATE` | Fecha de apertura de la cuenta. |
| `saldo_actual` | `DECIMAL(14,2)` | Saldo actual de la cuenta. Puede ser negativo. |
| `limite_descubierto` | `DECIMAL(12,2)` | Importe máximo de descubierto permitido. |
| `estado_cuenta` | `VARCHAR(20)` | Estado de la cuenta: activa, cerrada o bloqueada. |

**Clave primaria:** `id_cuenta`  
**Clave foránea:** `id_cliente → clientes.id_cliente`

---

## 3. `transacciones`

Registra los movimientos financieros realizados sobre las cuentas.

| Columna | Tipo de dato | Descripción |
|---|---|---|
| `id_transaccion` | `BIGINT UNSIGNED` | Identificador único de la transacción. Clave primaria. |
| `id_cuenta` | `INT UNSIGNED` | Cuenta sobre la que se realiza el movimiento. Clave foránea hacia `cuentas`. |
| `fecha_transaccion` | `DATETIME` | Fecha y hora de la transacción. |
| `tipo_transaccion` | `VARCHAR(30)` | Tipo de movimiento: ingreso, compra, cargo, transferencia, etc. |
| `categoria` | `VARCHAR(50)` | Categoría económica de la transacción. |
| `importe` | `DECIMAL(12,2)` | Importe de la operación. Positivo para entradas y negativo para salidas. |
| `canal` | `VARCHAR(30)` | Canal utilizado: tarjeta, app, transferencia, domiciliación, cajero, etc. |
| `saldo_posterior` | `DECIMAL(14,2)` | Saldo de la cuenta después de ejecutar la transacción. |

**Clave primaria:** `id_transaccion`  
**Clave foránea:** `id_cuenta → cuentas.id_cuenta`

---

## 4. `solicitudes_credito`

Contiene las solicitudes de financiación realizadas por los clientes, tanto aprobadas como rechazadas.

| Columna | Tipo de dato | Descripción |
|---|---|---|
| `id_solicitud` | `INT UNSIGNED` | Identificador único de la solicitud. Clave primaria. |
| `id_cliente` | `INT UNSIGNED` | Cliente que realiza la solicitud. Clave foránea hacia `clientes`. |
| `fecha_solicitud` | `DATE` | Fecha de solicitud del crédito. |
| `tipo_credito` | `VARCHAR(40)` | Tipo de financiación solicitada. |
| `importe_solicitado` | `DECIMAL(14,2)` | Capital solicitado por el cliente. |
| `plazo_meses` | `SMALLINT UNSIGNED` | Plazo solicitado en meses. |
| `finalidad` | `VARCHAR(100)` | Finalidad declarada del crédito. |
| `score_solicitud` | `SMALLINT UNSIGNED` | Score crediticio del cliente en el momento de la solicitud. |
| `ratio_endeudamiento` | `DECIMAL(6,2)` | Indicador de endeudamiento del cliente en el momento de la solicitud. |
| `estado_solicitud` | `VARCHAR(20)` | Resultado de la solicitud: aprobada, rechazada o pendiente. |
| `motivo_rechazo` | `VARCHAR(100)` | Motivo del rechazo cuando corresponda. |

**Clave primaria:** `id_solicitud`  
**Clave foránea:** `id_cliente → clientes.id_cliente`

---

## 5. `prestamos`

Contiene los créditos concedidos a partir de solicitudes aprobadas.

| Columna | Tipo de dato | Descripción |
|---|---|---|
| `id_prestamo` | `INT UNSIGNED` | Identificador único del préstamo. Clave primaria. |
| `id_solicitud` | `INT UNSIGNED` | Solicitud que dio origen al préstamo. Clave foránea hacia `solicitudes_credito`. |
| `fecha_concesion` | `DATE` | Fecha de concesión del préstamo. |
| `importe_concedido` | `DECIMAL(14,2)` | Capital finalmente concedido. |
| `tipo_interes` | `DECIMAL(5,2)` | Tipo de interés anual aplicado al préstamo. |
| `plazo_meses` | `SMALLINT UNSIGNED` | Duración del préstamo en meses. |
| `cuota_mensual` | `DECIMAL(12,2)` | Cuota mensual estimada del préstamo. |
| `saldo_pendiente` | `DECIMAL(14,2)` | Capital pendiente de devolución. |
| `fecha_vencimiento` | `DATE` | Fecha prevista de finalización del préstamo. |
| `estado_prestamo` | `VARCHAR(30)` | Estado actual: activo, pagado, mora o impagado. |

**Clave primaria:** `id_prestamo`  
**Clave foránea:** `id_solicitud → solicitudes_credito.id_solicitud`  
**Restricción adicional:** `id_solicitud` es único para evitar que una solicitud genere varios préstamos.

---

## 6. `pagos_prestamo`

Contiene el histórico de cuotas y comportamiento de pago de los préstamos.

| Columna | Tipo de dato | Descripción |
|---|---|---|
| `id_pago` | `BIGINT UNSIGNED` | Identificador único del pago. Clave primaria. |
| `id_prestamo` | `INT UNSIGNED` | Préstamo al que corresponde la cuota. Clave foránea hacia `prestamos`. |
| `fecha_vencimiento` | `DATE` | Fecha prevista de pago de la cuota. |
| `fecha_pago` | `DATE` | Fecha real de pago. Puede ser `NULL` si no se ha pagado. |
| `importe_previsto` | `DECIMAL(12,2)` | Importe que debía pagarse. |
| `importe_pagado` | `DECIMAL(12,2)` | Importe efectivamente pagado. |
| `dias_retraso` | `SMALLINT UNSIGNED` | Número de días de retraso respecto al vencimiento. |
| `estado_pago` | `VARCHAR(20)` | Estado de la cuota: pendiente, pagado, retrasado o impagado. |

**Clave primaria:** `id_pago`  
**Clave foránea:** `id_prestamo → prestamos.id_prestamo`  
**Restricción adicional:** combinación única de `id_prestamo` y `fecha_vencimiento`.

---

## 7. `evaluaciones_riesgo`

Contiene evaluaciones periódicas de riesgo para estudiar la evolución financiera y crediticia de cada cliente.

| Columna | Tipo de dato | Descripción |
|---|---|---|
| `id_evaluacion` | `INT UNSIGNED` | Identificador único de la evaluación. Clave primaria. |
| `id_cliente` | `INT UNSIGNED` | Cliente evaluado. Clave foránea hacia `clientes`. |
| `fecha_evaluacion` | `DATE` | Fecha de la evaluación de riesgo. |
| `score_crediticio` | `SMALLINT UNSIGNED` | Score crediticio estimado en la fecha de evaluación. |
| `ingresos_mensuales` | `DECIMAL(12,2)` | Ingresos mensuales considerados en la evaluación. |
| `deuda_total` | `DECIMAL(14,2)` | Deuda total estimada del cliente. |
| `ratio_endeudamiento` | `DECIMAL(6,2)` | Ratio de endeudamiento del cliente. |
| `num_impagos_12m` | `TINYINT UNSIGNED` | Número de impagos observados durante los últimos 12 meses. |
| `utilizacion_credito_pct` | `DECIMAL(6,2)` | Porcentaje de utilización del crédito disponible. |
| `nivel_riesgo` | `VARCHAR(20)` | Clasificación del cliente: bajo, medio o alto. |
| `probabilidad_impago` | `DECIMAL(6,5)` | Probabilidad estimada de impago, expresada entre 0 y 1. |

**Clave primaria:** `id_evaluacion`  
**Clave foránea:** `id_cliente → clientes.id_cliente`

---

## Relaciones principales

El modelo relacional puede resumirse de la siguiente manera:

```text
CLIENTES
   │
   ├── 1:N ── CUENTAS
   │              │
   │              └── 1:N ── TRANSACCIONES
   │
   ├── 1:N ── SOLICITUDES_CREDITO
   │              │
   │              └── 1:0..1 ── PRESTAMOS
   │                              │
   │                              └── 1:N ── PAGOS_PRESTAMO
   │
   └── 1:N ── EVALUACIONES_RIESGO
```

---

## Convenciones relevantes

### Signo de las transacciones

En la tabla `transacciones`:

- `importe > 0` representa una entrada de dinero.
- `importe < 0` representa una salida de dinero.
- No se permiten transacciones con importe igual a cero.

### Probabilidad de impago

La variable `probabilidad_impago` se almacena entre `0` y `1`.

Ejemplo:

```text
0.05 = 5 %
0.20 = 20 %
0.75 = 75 %
```

### Histórico de clientes

Las relaciones utilizan `ON DELETE RESTRICT` para evitar la eliminación accidental de información histórica vinculada a clientes, cuentas, préstamos o pagos.

En un contexto analítico se prioriza cambiar el estado de un cliente a `inactivo` frente a eliminarlo físicamente.

---

## Integridad referencial

El modelo utiliza:

- claves primarias;
- claves foráneas;
- restricciones `CHECK`;
- índices;
- restricciones `UNIQUE`.

Estas reglas permiten mantener la consistencia entre las diferentes entidades de la base de datos y evitar registros inválidos o relaciones huérfanas.
