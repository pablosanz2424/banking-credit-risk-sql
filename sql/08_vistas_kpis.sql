USE banca_riesgo_crediticio;


/*
1. Vista con la evaluación de riesgo más reciente
de cada cliente.
*/

CREATE OR REPLACE VIEW vw_riesgo_actual AS

SELECT
    e.id_cliente,
    e.fecha_evaluacion,
    e.score_crediticio,
    e.ingresos_mensuales,
    e.deuda_total,
    e.ratio_endeudamiento,
    e.num_impagos_12m,
    e.utilizacion_credito_pct,
    e.nivel_riesgo,
    e.probabilidad_impago

FROM evaluaciones_riesgo e

JOIN (
    SELECT
        id_cliente,
        MAX(fecha_evaluacion) AS ultima_evaluacion
    FROM evaluaciones_riesgo
    GROUP BY id_cliente
) u
    ON e.id_cliente = u.id_cliente
    AND e.fecha_evaluacion = u.ultima_evaluacion;
    
    SELECT *
FROM vw_riesgo_actual
WHERE nivel_riesgo = 'alto';



/*
2. Vista resumen del comportamiento de pago
de cada préstamo.
*/

CREATE OR REPLACE VIEW vw_comportamiento_prestamo AS

SELECT
    p.id_prestamo,
    p.id_solicitud,

    COUNT(pp.id_pago) AS numero_cuotas,

    SUM(
        CASE
            WHEN pp.dias_retraso > 30 THEN 1
            ELSE 0
        END
    ) AS cuotas_en_mora,

    SUM(
        CASE
            WHEN pp.estado_pago = 'impagado' THEN 1
            ELSE 0
        END
    ) AS cuotas_impagadas,

    MAX(
        CASE
            WHEN pp.dias_retraso > 30 THEN 1
            ELSE 0
        END
    ) AS tuvo_mora,

    MAX(
        CASE
            WHEN pp.estado_pago = 'impagado' THEN 1
            ELSE 0
        END
    ) AS tuvo_impago,

    COALESCE(
        MAX(pp.dias_retraso),
        0
    ) AS retraso_maximo

FROM prestamos p

LEFT JOIN pagos_prestamo pp
    ON p.id_prestamo = pp.id_prestamo

GROUP BY
    p.id_prestamo,
    p.id_solicitud;
    
    SELECT *
FROM vw_comportamiento_prestamo
WHERE tuvo_impago = 1;


/*
3. Vista con la exposición crediticia pendiente
por cliente.
*/

CREATE OR REPLACE VIEW vw_exposicion_cliente AS

SELECT
    s.id_cliente,

    COUNT(p.id_prestamo) AS numero_prestamos,

    SUM(p.saldo_pendiente) AS exposicion_total,

    AVG(p.saldo_pendiente) AS exposicion_media_prestamo,

    SUM(
        CASE
            WHEN p.estado_prestamo IN ('mora', 'impagado')
            THEN p.saldo_pendiente
            ELSE 0
        END
    ) AS exposicion_problematicos

FROM solicitudes_credito s

JOIN prestamos p
    ON s.id_solicitud = p.id_solicitud

WHERE p.estado_prestamo IN (
    'activo',
    'mora',
    'impagado'
)

GROUP BY s.id_cliente;

SELECT *
FROM vw_exposicion_cliente
ORDER BY exposicion_total DESC
LIMIT 20;

/*
4. Vista resumen del comportamiento financiero
de cada cliente.
*/

CREATE OR REPLACE VIEW vw_movimientos_cliente AS

SELECT
    c.id_cliente,

    COUNT(t.id_transaccion) AS numero_transacciones,

    SUM(
        CASE
            WHEN t.importe > 0 THEN t.importe
            ELSE 0
        END
    ) AS ingresos_transaccionales,

    ABS(
        SUM(
            CASE
                WHEN t.importe < 0 THEN t.importe
                ELSE 0
            END
        )
    ) AS gastos_transaccionales,

    SUM(
        COALESCE(t.importe, 0)
    ) AS flujo_neto

FROM clientes c

LEFT JOIN cuentas cu
    ON c.id_cliente = cu.id_cliente

LEFT JOIN transacciones t
    ON cu.id_cuenta = t.id_cuenta

GROUP BY c.id_cliente;

SELECT *
FROM vw_movimientos_cliente
WHERE flujo_neto < 0
ORDER BY flujo_neto;

/*
5. Vista con el historial de problemas de pago
de cada cliente.
*/

CREATE OR REPLACE VIEW vw_historial_pago_cliente AS

SELECT
    s.id_cliente,

    COUNT(DISTINCT p.id_prestamo)
        AS numero_prestamos,

    MAX(
        COALESCE(cp.tuvo_mora, 0)
    ) AS tuvo_mora,

    MAX(
        COALESCE(cp.tuvo_impago, 0)
    ) AS tuvo_impago,

    SUM(
        COALESCE(cp.cuotas_en_mora, 0)
    ) AS cuotas_en_mora,

    SUM(
        COALESCE(cp.cuotas_impagadas, 0)
    ) AS cuotas_impagadas,

    MAX(
        COALESCE(cp.retraso_maximo, 0)
    ) AS retraso_maximo

FROM solicitudes_credito s

JOIN prestamos p
    ON s.id_solicitud = p.id_solicitud

LEFT JOIN vw_comportamiento_prestamo cp
    ON p.id_prestamo = cp.id_prestamo

GROUP BY s.id_cliente;

SELECT *
FROM vw_historial_pago_cliente
WHERE tuvo_impago = 1;


/*
6. Vista analítica 360º del cliente.
*/

CREATE OR REPLACE VIEW vw_cliente_360 AS

SELECT
    c.id_cliente,
    c.fecha_alta,
    c.fecha_nacimiento,
    c.genero,
    c.estado_civil,
    c.nivel_estudios,
    c.situacion_laboral,
    c.ingresos_mensuales,
    c.num_dependientes,
    c.tipo_vivienda,
    c.provincia,
    c.estado_cliente,

    COALESCE(
        m.numero_transacciones,
        0
    ) AS numero_transacciones,

    ROUND(
        COALESCE(m.ingresos_transaccionales, 0),
        2
    ) AS ingresos_transaccionales,

    ROUND(
        COALESCE(m.gastos_transaccionales, 0),
        2
    ) AS gastos_transaccionales,

    ROUND(
        COALESCE(m.flujo_neto, 0),
        2
    ) AS flujo_neto,

    COALESCE(
        ex.numero_prestamos,
        0
    ) AS numero_prestamos,

    ROUND(
        COALESCE(ex.exposicion_total, 0),
        2
    ) AS exposicion_crediticia,

    COALESCE(
        hp.tuvo_mora,
        0
    ) AS tuvo_mora,

    COALESCE(
        hp.tuvo_impago,
        0
    ) AS tuvo_impago,

    r.score_crediticio,
    r.ratio_endeudamiento,
    r.utilizacion_credito_pct,
    r.nivel_riesgo,

    ROUND(
        r.probabilidad_impago * 100,
        2
    ) AS probabilidad_impago_pct

FROM clientes c

LEFT JOIN vw_movimientos_cliente m
    ON c.id_cliente = m.id_cliente

LEFT JOIN vw_exposicion_cliente ex
    ON c.id_cliente = ex.id_cliente

LEFT JOIN vw_historial_pago_cliente hp
    ON c.id_cliente = hp.id_cliente

LEFT JOIN vw_riesgo_actual r
    ON c.id_cliente = r.id_cliente;
    
    SELECT
    id_cliente,
    ingresos_mensuales,
    flujo_neto,
    exposicion_crediticia,
    score_crediticio,
    probabilidad_impago_pct,
    tuvo_impago

FROM vw_cliente_360

WHERE nivel_riesgo = 'alto'

ORDER BY probabilidad_impago_pct DESC;

/*
7. Clientes en posible situación de alerta temprana:
riesgo alto pero sin impago registrado.
*/

CREATE OR REPLACE VIEW vw_alerta_temprana AS

SELECT
    id_cliente,
    situacion_laboral,
    ingresos_mensuales,
    flujo_neto,
    exposicion_crediticia,
    score_crediticio,
    ratio_endeudamiento,
    utilizacion_credito_pct,
    probabilidad_impago_pct

FROM vw_cliente_360

WHERE
    nivel_riesgo = 'alto'
    AND tuvo_impago = 0;
    
    SELECT *
FROM vw_alerta_temprana
ORDER BY probabilidad_impago_pct DESC;


/*
8. KPIs de solicitudes de crédito.
*/

CREATE OR REPLACE VIEW vw_kpi_solicitudes AS

SELECT
    COUNT(*) AS total_solicitudes,

    SUM(
        CASE
            WHEN estado_solicitud = 'aprobada'
            THEN 1
            ELSE 0
        END
    ) AS solicitudes_aprobadas,

    SUM(
        CASE
            WHEN estado_solicitud = 'rechazada'
            THEN 1
            ELSE 0
        END
    ) AS solicitudes_rechazadas,

    ROUND(
        100.0 *
        SUM(
            CASE
                WHEN estado_solicitud = 'aprobada'
                THEN 1
                ELSE 0
            END
        ) /
        NULLIF(COUNT(*), 0),
        2
    ) AS tasa_aprobacion_pct,

    ROUND(
        AVG(importe_solicitado),
        2
    ) AS importe_medio_solicitado

FROM solicitudes_credito;

SELECT *
FROM vw_kpi_solicitudes;

/*
9. KPIs generales de la cartera crediticia.
*/

CREATE OR REPLACE VIEW vw_kpi_cartera AS

SELECT
    COUNT(*) AS total_prestamos,

    ROUND(
        SUM(p.importe_concedido),
        2
    ) AS capital_total_concedido,

    ROUND(
        SUM(p.saldo_pendiente),
        2
    ) AS exposicion_total,

    ROUND(
        AVG(p.tipo_interes),
        2
    ) AS tipo_interes_medio,

    SUM(
        COALESCE(cp.tuvo_mora, 0)
    ) AS prestamos_con_mora,

    SUM(
        COALESCE(cp.tuvo_impago, 0)
    ) AS prestamos_con_impago,

    ROUND(
        100.0 *
        SUM(COALESCE(cp.tuvo_mora, 0))
        / NULLIF(COUNT(*), 0),
        2
    ) AS tasa_mora_pct,

    ROUND(
        100.0 *
        SUM(COALESCE(cp.tuvo_impago, 0))
        / NULLIF(COUNT(*), 0),
        2
    ) AS tasa_impago_pct

FROM prestamos p

LEFT JOIN vw_comportamiento_prestamo cp
    ON p.id_prestamo = cp.id_prestamo;
    
    SELECT *
FROM vw_kpi_cartera;


/*
10. KPIs generales del riesgo actual.
*/

CREATE OR REPLACE VIEW vw_kpi_riesgo AS

SELECT
    COUNT(*) AS clientes_evaluados,

    ROUND(
        AVG(score_crediticio),
        2
    ) AS score_medio,

    ROUND(
        AVG(probabilidad_impago) * 100,
        2
    ) AS probabilidad_impago_media_pct,

    SUM(
        CASE
            WHEN nivel_riesgo = 'alto'
            THEN 1
            ELSE 0
        END
    ) AS clientes_riesgo_alto,

    ROUND(
        100.0 *
        SUM(
            CASE
                WHEN nivel_riesgo = 'alto'
                THEN 1
                ELSE 0
            END
        ) /
        NULLIF(COUNT(*), 0),
        2
    ) AS clientes_riesgo_alto_pct

FROM vw_riesgo_actual;

SELECT *
FROM vw_kpi_riesgo;

/*
11. Flujo financiero mensual del banco.
*/

CREATE OR REPLACE VIEW vw_kpi_transacciones_mensuales AS

SELECT
    DATE_FORMAT(
        fecha_transaccion,
        '%Y-%m'
    ) AS mes,

    COUNT(*) AS numero_transacciones,

    ROUND(
        SUM(
            CASE
                WHEN importe > 0
                THEN importe
                ELSE 0
            END
        ),
        2
    ) AS ingresos,

    ROUND(
        ABS(
            SUM(
                CASE
                    WHEN importe < 0
                    THEN importe
                    ELSE 0
                END
            )
        ),
        2
    ) AS gastos,

    ROUND(
        SUM(importe),
        2
    ) AS flujo_neto

FROM transacciones

GROUP BY
    DATE_FORMAT(fecha_transaccion, '%Y-%m');
    
    SELECT *
FROM vw_kpi_transacciones_mensuales
ORDER BY mes;

/*
12. Distribución de exposición crediticia
según nivel de riesgo.
*/

CREATE OR REPLACE VIEW vw_cartera_por_riesgo AS

SELECT
    r.nivel_riesgo,

    COUNT(*) AS numero_clientes,

    ROUND(
        AVG(r.score_crediticio),
        2
    ) AS score_medio,

    ROUND(
        AVG(r.probabilidad_impago) * 100,
        2
    ) AS probabilidad_impago_media_pct,

    ROUND(
        SUM(ex.exposicion_total),
        2
    ) AS exposicion_total,

    ROUND(
        AVG(ex.exposicion_total),
        2
    ) AS exposicion_media_cliente

FROM vw_riesgo_actual r

JOIN vw_exposicion_cliente ex
    ON r.id_cliente = ex.id_cliente

GROUP BY r.nivel_riesgo;

SELECT *
FROM vw_cartera_por_riesgo
ORDER BY probabilidad_impago_media_pct;


/*
13. Exposición ponderada por probabilidad de impago.

Métrica analítica:
exposición × PD

No constituye Expected Loss regulatoria completa.
*/

CREATE OR REPLACE VIEW vw_exposicion_ponderada_riesgo AS

SELECT
    r.id_cliente,

    ex.exposicion_total,

    r.probabilidad_impago,

    ROUND(
        ex.exposicion_total *
        r.probabilidad_impago,
        2
    ) AS exposicion_ponderada_riesgo

FROM vw_riesgo_actual r

JOIN vw_exposicion_cliente ex
    ON r.id_cliente = ex.id_cliente;
    
    SELECT *
FROM vw_exposicion_ponderada_riesgo
ORDER BY exposicion_ponderada_riesgo DESC
LIMIT 20;


/*
14. Lista de clientes prioritarios para revisión
según riesgo y exposición.
*/

CREATE OR REPLACE VIEW vw_watchlist_riesgo AS

SELECT
    id_cliente,
    ingresos_mensuales,
    flujo_neto,
    numero_prestamos,
    exposicion_crediticia,
    score_crediticio,
    ratio_endeudamiento,
    utilizacion_credito_pct,
    nivel_riesgo,
    probabilidad_impago_pct,
    tuvo_mora,
    tuvo_impago

FROM vw_cliente_360

WHERE
    nivel_riesgo = 'alto'
    OR tuvo_impago = 1
    OR tuvo_mora = 1;
    
    SELECT *
FROM vw_watchlist_riesgo

ORDER BY
    tuvo_impago DESC,
    probabilidad_impago_pct DESC,
    exposicion_crediticia DESC;
    
    
    /*
15. Ranking de clientes de la watchlist
según probabilidad de impago.
*/

SELECT
    id_cliente,
    nivel_riesgo,
    probabilidad_impago_pct,
    exposicion_crediticia,
    tuvo_impago,

    RANK() OVER (
        ORDER BY probabilidad_impago_pct DESC
    ) AS ranking_riesgo

FROM vw_watchlist_riesgo

ORDER BY ranking_riesgo;

/*
16. Dashboard principal del proyecto
*/

SELECT *
FROM vw_kpi_solicitudes;

SELECT *
FROM vw_kpi_cartera;

SELECT *
FROM vw_kpi_riesgo;

SELECT *
FROM vw_kpi_transacciones_mensuales
ORDER BY mes;

SELECT *
FROM vw_cartera_por_riesgo
ORDER BY probabilidad_impago_media_pct;

SELECT *
FROM vw_watchlist_riesgo
ORDER BY
    probabilidad_impago_pct DESC,
    exposicion_crediticia DESC

LIMIT 20;


/*
17. Mostrar todas las vistas de la base de datos.
*/

SHOW FULL TABLES
WHERE Table_type = 'VIEW';