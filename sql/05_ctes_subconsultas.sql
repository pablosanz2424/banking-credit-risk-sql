USE banca_riesgo_crediticio;

/*
1. ¿Cuál es el número medio de cuentas por cliente utilizando una CTE?
*/

WITH cuentas_por_cliente AS (
    SELECT
        id_cliente,
        COUNT(*) AS numero_cuentas
    FROM cuentas
    GROUP BY id_cliente
)

SELECT
    ROUND(AVG(numero_cuentas), 2) AS cuentas_medias_por_cliente
FROM cuentas_por_cliente;


/*
2. ¿Qué clientes tienen un saldo total superior al saldo medio por cliente?
*/

WITH saldo_cliente AS (
    SELECT
        id_cliente,
        SUM(saldo_actual) AS saldo_total
    FROM cuentas
    GROUP BY id_cliente
)

SELECT
    id_cliente,
    ROUND(saldo_total, 2) AS saldo_total
FROM saldo_cliente
WHERE saldo_total > (
    SELECT AVG(saldo_total)
    FROM saldo_cliente
)
ORDER BY saldo_total DESC;

/*
3. Resumen de ingresos, gastos y flujo neto por cliente.
*/

WITH movimientos_cliente AS (
    SELECT
        cu.id_cliente,

        SUM(
            CASE
                WHEN t.importe > 0 THEN t.importe
                ELSE 0
            END
        ) AS ingresos,

        ABS(
            SUM(
                CASE
                    WHEN t.importe < 0 THEN t.importe
                    ELSE 0
                END
            )
        ) AS gastos,

        SUM(t.importe) AS flujo_neto

    FROM cuentas cu
    JOIN transacciones t
        ON cu.id_cuenta = t.id_cuenta

    GROUP BY cu.id_cliente
)

SELECT
    id_cliente,
    ROUND(ingresos, 2) AS ingresos,
    ROUND(gastos, 2) AS gastos,
    ROUND(flujo_neto, 2) AS flujo_neto
FROM movimientos_cliente
ORDER BY flujo_neto ASC;


/*
4. ¿Qué clientes gastan más que la media de clientes?
*/

WITH gasto_cliente AS (
    SELECT
        cu.id_cliente,
        SUM(ABS(t.importe)) AS gasto_total
    FROM cuentas cu
    JOIN transacciones t
        ON cu.id_cuenta = t.id_cuenta
    WHERE t.importe < 0
    GROUP BY cu.id_cliente
),

gasto_medio AS (
    SELECT
        AVG(gasto_total) AS media_gasto
    FROM gasto_cliente
)

SELECT
    gc.id_cliente,
    ROUND(gc.gasto_total, 2) AS gasto_total,
    ROUND(gm.media_gasto, 2) AS gasto_medio_clientes
FROM gasto_cliente gc
CROSS JOIN gasto_medio gm
WHERE gc.gasto_total > gm.media_gasto
ORDER BY gc.gasto_total DESC;


/*
5. ¿Qué clientes han realizado más de una solicitud de crédito?
*/

WITH solicitudes_cliente AS (
    SELECT
        id_cliente,
        COUNT(*) AS numero_solicitudes,
        SUM(
            CASE
                WHEN estado_solicitud = 'aprobada' THEN 1
                ELSE 0
            END
        ) AS solicitudes_aprobadas,
        SUM(
            CASE
                WHEN estado_solicitud = 'rechazada' THEN 1
                ELSE 0
            END
        ) AS solicitudes_rechazadas
    FROM solicitudes_credito
    GROUP BY id_cliente
)

SELECT
    id_cliente,
    numero_solicitudes,
    solicitudes_aprobadas,
    solicitudes_rechazadas
FROM solicitudes_cliente
WHERE numero_solicitudes > 1
ORDER BY numero_solicitudes DESC;

/*
6. ¿Qué clientes han solicitado crédito pero nunca han obtenido una aprobación?
*/

SELECT
    c.id_cliente,
    c.situacion_laboral,
    c.ingresos_mensuales
FROM clientes c
WHERE EXISTS (
    SELECT 1
    FROM solicitudes_credito s
    WHERE s.id_cliente = c.id_cliente
)
AND NOT EXISTS (
    SELECT 1
    FROM solicitudes_credito s
    WHERE s.id_cliente = c.id_cliente
      AND s.estado_solicitud = 'aprobada'
)
ORDER BY c.ingresos_mensuales DESC;


/*
7. ¿Qué clientes nunca han solicitado crédito?
*/

SELECT
    c.id_cliente,
    c.situacion_laboral,
    c.ingresos_mensuales,
    c.provincia
FROM clientes c

WHERE NOT EXISTS (
    SELECT 1
    FROM solicitudes_credito s
    WHERE s.id_cliente = c.id_cliente
)

ORDER BY c.ingresos_mensuales DESC;


/*
8. Resumen del comportamiento de pago de cada préstamo.
*/

WITH comportamiento_prestamo AS (
    SELECT
        id_prestamo,

        COUNT(*) AS numero_cuotas,

        SUM(
            CASE
                WHEN dias_retraso > 30 THEN 1
                ELSE 0
            END
        ) AS cuotas_en_mora,

        SUM(
            CASE
                WHEN estado_pago = 'impagado' THEN 1
                ELSE 0
            END
        ) AS cuotas_impagadas,

        MAX(dias_retraso) AS retraso_maximo

    FROM pagos_prestamo
    GROUP BY id_prestamo
)

SELECT
    *
FROM comportamiento_prestamo
ORDER BY cuotas_impagadas DESC,
         retraso_maximo DESC;
         
         
/*
9. ¿Qué préstamos presentan más días de retraso que la media?
*/

WITH comportamiento_prestamo AS (
    SELECT
        id_prestamo,
        AVG(dias_retraso) AS retraso_medio
    FROM pagos_prestamo
    GROUP BY id_prestamo
)

SELECT
    id_prestamo,
    ROUND(retraso_medio, 2) AS retraso_medio
FROM comportamiento_prestamo

WHERE retraso_medio > (
    SELECT AVG(retraso_medio)
    FROM comportamiento_prestamo
)

ORDER BY retraso_medio DESC;

/*
10. ¿Qué clientes han registrado al menos un impago?
*/

WITH clientes_impago AS (
    SELECT
        s.id_cliente,

        MAX(
            CASE
                WHEN pp.estado_pago = 'impagado' THEN 1
                ELSE 0
            END
        ) AS tuvo_impago

    FROM solicitudes_credito s

    JOIN prestamos p
        ON s.id_solicitud = p.id_solicitud

    JOIN pagos_prestamo pp
        ON p.id_prestamo = pp.id_prestamo

    GROUP BY s.id_cliente
)

SELECT
    c.id_cliente,
    c.situacion_laboral,
    c.ingresos_mensuales
FROM clientes c

JOIN clientes_impago ci
    ON c.id_cliente = ci.id_cliente

WHERE ci.tuvo_impago = 1

ORDER BY c.ingresos_mensuales DESC;

/*
11. Obtener la evaluación de riesgo más reciente de cada cliente.
*/

WITH ultima_fecha AS (
    SELECT
        id_cliente,
        MAX(fecha_evaluacion) AS fecha_ultima_evaluacion
    FROM evaluaciones_riesgo
    GROUP BY id_cliente
)

SELECT
    e.*
FROM evaluaciones_riesgo e

JOIN ultima_fecha u
    ON e.id_cliente = u.id_cliente
    AND e.fecha_evaluacion = u.fecha_ultima_evaluacion

ORDER BY e.id_cliente;

/*
12. ¿Qué clientes presentan actualmente un nivel de riesgo alto?
*/

WITH ultima_fecha AS (
    SELECT
        id_cliente,
        MAX(fecha_evaluacion) AS ultima_evaluacion
    FROM evaluaciones_riesgo
    GROUP BY id_cliente
),

riesgo_actual AS (
    SELECT
        e.*
    FROM evaluaciones_riesgo e

    JOIN ultima_fecha u
        ON e.id_cliente = u.id_cliente
        AND e.fecha_evaluacion = u.ultima_evaluacion
)

SELECT
    r.id_cliente,
    c.situacion_laboral,
    c.ingresos_mensuales,
    r.score_crediticio,
    r.ratio_endeudamiento,
    r.utilizacion_credito_pct,
    ROUND(r.probabilidad_impago * 100, 2)
        AS probabilidad_impago_pct

FROM riesgo_actual r

JOIN clientes c
    ON r.id_cliente = c.id_cliente

WHERE r.nivel_riesgo = 'alto'

ORDER BY r.probabilidad_impago DESC;

/*
13. ¿Cuál es la exposición crediticia pendiente de cada cliente?
*/

WITH exposicion_cliente AS (
    SELECT
        s.id_cliente,
        COUNT(p.id_prestamo) AS numero_prestamos,
        SUM(p.saldo_pendiente) AS exposicion_total

    FROM solicitudes_credito s

    JOIN prestamos p
        ON s.id_solicitud = p.id_solicitud

    WHERE p.estado_prestamo IN ('activo', 'mora', 'impagado')

    GROUP BY s.id_cliente
)

SELECT
    c.id_cliente,
    c.ingresos_mensuales,
    ec.numero_prestamos,

    ROUND(
        ec.exposicion_total,
        2
    ) AS exposicion_total,

    ROUND(
        ec.exposicion_total /
        NULLIF(c.ingresos_mensuales * 12, 0),
        2
    ) AS exposicion_sobre_ingresos

FROM exposicion_cliente ec

JOIN clientes c
    ON ec.id_cliente = c.id_cliente

ORDER BY exposicion_total DESC;

/*
14. ¿Qué clientes tienen una exposición crediticia superior a la media?
*/

WITH exposicion_cliente AS (
    SELECT
        s.id_cliente,
        SUM(p.saldo_pendiente) AS exposicion

    FROM solicitudes_credito s

    JOIN prestamos p
        ON s.id_solicitud = p.id_solicitud

    WHERE p.estado_prestamo IN ('activo', 'mora', 'impagado')

    GROUP BY s.id_cliente
)

SELECT
    id_cliente,
    ROUND(exposicion, 2) AS exposicion
FROM exposicion_cliente

WHERE exposicion > (
    SELECT AVG(exposicion)
    FROM exposicion_cliente
)

ORDER BY exposicion DESC;

/*
15. ¿Qué clientes combinan alto riesgo con una exposición
crediticia superior a la media?
*/

WITH ultima_fecha AS (
    SELECT
        id_cliente,
        MAX(fecha_evaluacion) AS ultima_evaluacion
    FROM evaluaciones_riesgo
    GROUP BY id_cliente
),

riesgo_actual AS (
    SELECT
        e.id_cliente,
        e.score_crediticio,
        e.nivel_riesgo,
        e.probabilidad_impago

    FROM evaluaciones_riesgo e

    JOIN ultima_fecha u
        ON e.id_cliente = u.id_cliente
        AND e.fecha_evaluacion = u.ultima_evaluacion
),

exposicion_cliente AS (
    SELECT
        s.id_cliente,
        SUM(p.saldo_pendiente) AS exposicion

    FROM solicitudes_credito s

    JOIN prestamos p
        ON s.id_solicitud = p.id_solicitud

    WHERE p.estado_prestamo IN ('activo', 'mora', 'impagado')

    GROUP BY s.id_cliente
)

SELECT
    r.id_cliente,
    r.score_crediticio,

    ROUND(
        r.probabilidad_impago * 100,
        2
    ) AS probabilidad_impago_pct,

    ROUND(
        e.exposicion,
        2
    ) AS exposicion

FROM riesgo_actual r

JOIN exposicion_cliente e
    ON r.id_cliente = e.id_cliente

WHERE
    r.nivel_riesgo = 'alto'

    AND e.exposicion > (
        SELECT AVG(exposicion)
        FROM exposicion_cliente
    )

ORDER BY
    r.probabilidad_impago DESC,
    e.exposicion DESC;
    
    /*
16. Clientes de alto riesgo que todavía no han registrado impagos.
Posibles clientes para un sistema de alerta temprana.
*/

WITH ultima_fecha AS (
    SELECT
        id_cliente,
        MAX(fecha_evaluacion) AS ultima_evaluacion
    FROM evaluaciones_riesgo
    GROUP BY id_cliente
),

riesgo_actual AS (
    SELECT
        e.id_cliente,
        e.score_crediticio,
        e.nivel_riesgo,
        e.probabilidad_impago,
        e.ratio_endeudamiento,
        e.utilizacion_credito_pct

    FROM evaluaciones_riesgo e

    JOIN ultima_fecha u
        ON e.id_cliente = u.id_cliente
        AND e.fecha_evaluacion = u.ultima_evaluacion
),

historial_impago AS (
    SELECT
        s.id_cliente,

        MAX(
            CASE
                WHEN pp.estado_pago = 'impagado' THEN 1
                ELSE 0
            END
        ) AS tuvo_impago

    FROM solicitudes_credito s

    JOIN prestamos p
        ON s.id_solicitud = p.id_solicitud

    JOIN pagos_prestamo pp
        ON p.id_prestamo = pp.id_prestamo

    GROUP BY s.id_cliente
)

SELECT
    r.id_cliente,
    r.score_crediticio,

    ROUND(
        r.probabilidad_impago * 100,
        2
    ) AS probabilidad_impago_pct,

    r.ratio_endeudamiento,
    r.utilizacion_credito_pct

FROM riesgo_actual r

JOIN historial_impago h
    ON r.id_cliente = h.id_cliente

WHERE
    r.nivel_riesgo = 'alto'
    AND h.tuvo_impago = 0

ORDER BY r.probabilidad_impago DESC;


/*
17. Identificar clientes críticos combinando riesgo,
exposición e historial de impago.
*/

WITH ultima_fecha AS (
    SELECT
        id_cliente,
        MAX(fecha_evaluacion) AS ultima_evaluacion
    FROM evaluaciones_riesgo
    GROUP BY id_cliente
),

riesgo_actual AS (
    SELECT
        e.id_cliente,
        e.score_crediticio,
        e.nivel_riesgo,
        e.probabilidad_impago

    FROM evaluaciones_riesgo e

    JOIN ultima_fecha u
        ON e.id_cliente = u.id_cliente
        AND e.fecha_evaluacion = u.ultima_evaluacion
),

exposicion_cliente AS (
    SELECT
        s.id_cliente,
        SUM(p.saldo_pendiente) AS exposicion

    FROM solicitudes_credito s

    JOIN prestamos p
        ON s.id_solicitud = p.id_solicitud

    WHERE p.estado_prestamo IN ('activo', 'mora', 'impagado')

    GROUP BY s.id_cliente
),

historial_impago AS (
    SELECT
        s.id_cliente,

        MAX(
            CASE
                WHEN pp.estado_pago = 'impagado' THEN 1
                ELSE 0
            END
        ) AS tuvo_impago

    FROM solicitudes_credito s

    JOIN prestamos p
        ON s.id_solicitud = p.id_solicitud

    JOIN pagos_prestamo pp
        ON p.id_prestamo = pp.id_prestamo

    GROUP BY s.id_cliente
)

SELECT
    r.id_cliente,
    r.score_crediticio,
    r.nivel_riesgo,

    ROUND(
        r.probabilidad_impago * 100,
        2
    ) AS probabilidad_impago_pct,

    ROUND(
        e.exposicion,
        2
    ) AS exposicion_crediticia,

    h.tuvo_impago

FROM riesgo_actual r

JOIN exposicion_cliente e
    ON r.id_cliente = e.id_cliente

JOIN historial_impago h
    ON r.id_cliente = h.id_cliente

WHERE
    r.nivel_riesgo = 'alto'
    AND h.tuvo_impago = 1

ORDER BY
    r.probabilidad_impago DESC,
    e.exposicion DESC;
    
    /*
18. Crear una visión resumida financiera y crediticia del cliente.
*/

WITH movimientos AS (
    SELECT
        cu.id_cliente,

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
        ) AS gastos_transaccionales

    FROM cuentas cu

    JOIN transacciones t
        ON cu.id_cuenta = t.id_cuenta

    GROUP BY cu.id_cliente
),

creditos AS (
    SELECT
        s.id_cliente,
        COUNT(p.id_prestamo) AS numero_prestamos,
        SUM(p.saldo_pendiente) AS exposicion_crediticia

    FROM solicitudes_credito s

    JOIN prestamos p
        ON s.id_solicitud = p.id_solicitud

    GROUP BY s.id_cliente
),

ultima_fecha AS (
    SELECT
        id_cliente,
        MAX(fecha_evaluacion) AS ultima_evaluacion
    FROM evaluaciones_riesgo
    GROUP BY id_cliente
),

riesgo AS (
    SELECT
        e.id_cliente,
        e.score_crediticio,
        e.nivel_riesgo,
        e.probabilidad_impago

    FROM evaluaciones_riesgo e

    JOIN ultima_fecha u
        ON e.id_cliente = u.id_cliente
        AND e.fecha_evaluacion = u.ultima_evaluacion
)

SELECT
    c.id_cliente,
    c.situacion_laboral,
    c.ingresos_mensuales,

    ROUND(
        COALESCE(m.ingresos_transaccionales, 0),
        2
    ) AS ingresos_transaccionales,

    ROUND(
        COALESCE(m.gastos_transaccionales, 0),
        2
    ) AS gastos_transaccionales,

    COALESCE(cr.numero_prestamos, 0)
        AS numero_prestamos,

    ROUND(
        COALESCE(cr.exposicion_crediticia, 0),
        2
    ) AS exposicion_crediticia,

    r.score_crediticio,
    r.nivel_riesgo,

    ROUND(
        r.probabilidad_impago * 100,
        2
    ) AS probabilidad_impago_pct

FROM clientes c

LEFT JOIN movimientos m
    ON c.id_cliente = m.id_cliente

LEFT JOIN creditos cr
    ON c.id_cliente = cr.id_cliente

LEFT JOIN riesgo r
    ON c.id_cliente = r.id_cliente

ORDER BY
    r.probabilidad_impago DESC,
    cr.exposicion_crediticia DESC;
    
    