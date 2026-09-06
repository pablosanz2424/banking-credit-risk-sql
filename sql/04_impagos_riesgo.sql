USE banca_riesgo_crediticio;

/*
1. ¿Cómo se distribuyen los pagos según su estado?
*/

SELECT
    estado_pago,
    COUNT(*) AS numero_pagos,
    ROUND(
        COUNT(*) * 100.0 /
        (SELECT COUNT(*) FROM pagos_prestamo),
        2
    ) AS porcentaje
FROM pagos_prestamo
GROUP BY estado_pago
ORDER BY numero_pagos DESC;

/*
2. ¿Cómo se distribuyen los pagos según los días de retraso?
*/

SELECT
    CASE
        WHEN dias_retraso = 0 THEN 'sin_retraso'
        WHEN dias_retraso <= 30 THEN '1-30_dias'
        WHEN dias_retraso <= 60 THEN '31-60_dias'
        WHEN dias_retraso <= 90 THEN '61-90_dias'
        ELSE 'mas_de_90_dias'
    END AS tramo_retraso,

    COUNT(*) AS numero_pagos,

    ROUND(
        COUNT(*) * 100.0 /
        (SELECT COUNT(*) FROM pagos_prestamo),
        2
    ) AS porcentaje

FROM pagos_prestamo
GROUP BY tramo_retraso
ORDER BY MIN(dias_retraso);

/*
3. ¿Cuál es la tasa global de mora e impago?
*/

SELECT
    COUNT(*) AS total_pagos,

    SUM(
        CASE
            WHEN dias_retraso > 30 THEN 1
            ELSE 0
        END
    ) AS pagos_en_mora,

    SUM(
        CASE
            WHEN estado_pago = 'impagado' THEN 1
            ELSE 0
        END
    ) AS pagos_impagados,

    ROUND(
        100.0 *
        SUM(
            CASE
                WHEN dias_retraso > 30 THEN 1
                ELSE 0
            END
        ) / COUNT(*),
        2
    ) AS tasa_mora_pct,

    ROUND(
        100.0 *
        SUM(
            CASE
                WHEN estado_pago = 'impagado' THEN 1
                ELSE 0
            END
        ) / COUNT(*),
        2
    ) AS tasa_impago_pct

FROM pagos_prestamo;

/*
4. ¿Qué importe permanece impagado?
*/

SELECT
    COUNT(*) AS cuotas_impagadas,

    ROUND(
        SUM(importe_previsto - importe_pagado),
        2
    ) AS importe_impagado_total,

    ROUND(
        AVG(importe_previsto - importe_pagado),
        2
    ) AS importe_impagado_medio

FROM pagos_prestamo
WHERE estado_pago = 'impagado';

/*
5. ¿Qué porcentaje de préstamos ha sufrido mora o impago?
*/

SELECT
    COUNT(*) AS prestamos_con_historial,

    SUM(tuvo_mora) AS prestamos_con_mora,

    SUM(tuvo_impago) AS prestamos_con_impago,

    ROUND(
        100.0 * SUM(tuvo_mora) / COUNT(*),
        2
    ) AS tasa_prestamos_mora_pct,

    ROUND(
        100.0 * SUM(tuvo_impago) / COUNT(*),
        2
    ) AS tasa_prestamos_impago_pct

FROM (

    SELECT
        id_prestamo,

        MAX(
            CASE
                WHEN dias_retraso > 30 THEN 1
                ELSE 0
            END
        ) AS tuvo_mora,

        MAX(
            CASE
                WHEN estado_pago = 'impagado' THEN 1
                ELSE 0
            END
        ) AS tuvo_impago

    FROM pagos_prestamo
    GROUP BY id_prestamo

) AS comportamiento_prestamo;


/*
6. ¿Cómo se distribuyen los préstamos según su estado actual?
*/

SELECT
    estado_prestamo,
    COUNT(*) AS numero_prestamos,

    ROUND(
        SUM(saldo_pendiente),
        2
    ) AS saldo_pendiente,

    ROUND(
        AVG(saldo_pendiente),
        2
    ) AS saldo_pendiente_medio

FROM prestamos
GROUP BY estado_prestamo
ORDER BY saldo_pendiente DESC;

/*
7. ¿Qué tipo de crédito presenta mayor tasa de impago?
*/

SELECT
    s.tipo_credito,

    COUNT(*) AS numero_prestamos,

    SUM(cp.tuvo_impago) AS prestamos_con_impago,

    ROUND(
        100.0 * SUM(cp.tuvo_impago) / COUNT(*),
        2
    ) AS tasa_impago_pct

FROM (

    SELECT
        p.id_prestamo,
        p.id_solicitud,

        MAX(
            CASE
                WHEN pp.estado_pago = 'impagado' THEN 1
                ELSE 0
            END
        ) AS tuvo_impago

    FROM prestamos p

    JOIN pagos_prestamo pp
        ON p.id_prestamo = pp.id_prestamo

    GROUP BY
        p.id_prestamo,
        p.id_solicitud

) AS cp

JOIN solicitudes_credito s
    ON cp.id_solicitud = s.id_solicitud

GROUP BY s.tipo_credito
ORDER BY tasa_impago_pct DESC;

/*
8. ¿Cómo cambia la tasa de impago según el score inicial?
*/

SELECT
    CASE
        WHEN s.score_solicitud < 650 THEN 'menos_de_650'
        WHEN s.score_solicitud < 700 THEN '650-699'
        WHEN s.score_solicitud < 750 THEN '700-749'
        ELSE '750_o_mas'
    END AS rango_score,

    COUNT(*) AS numero_prestamos,

    ROUND(
        AVG(s.score_solicitud),
        2
    ) AS score_medio,

    ROUND(
        100.0 * SUM(cp.tuvo_impago) / COUNT(*),
        2
    ) AS tasa_impago_pct

FROM (

    SELECT
        p.id_prestamo,
        p.id_solicitud,

        MAX(
            CASE
                WHEN pp.estado_pago = 'impagado' THEN 1
                ELSE 0
            END
        ) AS tuvo_impago

    FROM prestamos p

    JOIN pagos_prestamo pp
        ON p.id_prestamo = pp.id_prestamo

    GROUP BY
        p.id_prestamo,
        p.id_solicitud

) AS cp

JOIN solicitudes_credito s
    ON cp.id_solicitud = s.id_solicitud

GROUP BY rango_score
ORDER BY score_medio;

/*
9. ¿Cómo cambia el impago según el ratio de endeudamiento?
*/

SELECT
    CASE
        WHEN s.ratio_endeudamiento < 20 THEN 'menos_20'
        WHEN s.ratio_endeudamiento < 35 THEN '20-34'
        WHEN s.ratio_endeudamiento < 50 THEN '35-49'
        ELSE '50_o_mas'
    END AS tramo_endeudamiento,

    COUNT(*) AS numero_prestamos,

    ROUND(
        AVG(s.ratio_endeudamiento),
        2
    ) AS endeudamiento_medio,

    ROUND(
        100.0 * SUM(cp.tuvo_impago) / COUNT(*),
        2
    ) AS tasa_impago_pct

FROM (

    SELECT
        p.id_prestamo,
        p.id_solicitud,

        MAX(
            CASE
                WHEN pp.estado_pago = 'impagado' THEN 1
                ELSE 0
            END
        ) AS tuvo_impago

    FROM prestamos p

    JOIN pagos_prestamo pp
        ON p.id_prestamo = pp.id_prestamo

    GROUP BY
        p.id_prestamo,
        p.id_solicitud

) AS cp

JOIN solicitudes_credito s
    ON cp.id_solicitud = s.id_solicitud

GROUP BY tramo_endeudamiento
ORDER BY endeudamiento_medio;

/*
10. ¿Qué situación laboral presenta mayor tasa de impago?
*/

SELECT
    c.situacion_laboral,

    COUNT(*) AS numero_prestamos,

    SUM(cp.tuvo_impago) AS prestamos_con_impago,

    ROUND(
        100.0 * SUM(cp.tuvo_impago) / COUNT(*),
        2
    ) AS tasa_impago_pct

FROM (

    SELECT
        p.id_prestamo,
        p.id_solicitud,

        MAX(
            CASE
                WHEN pp.estado_pago = 'impagado' THEN 1
                ELSE 0
            END
        ) AS tuvo_impago

    FROM prestamos p

    JOIN pagos_prestamo pp
        ON p.id_prestamo = pp.id_prestamo

    GROUP BY
        p.id_prestamo,
        p.id_solicitud

) AS cp

JOIN solicitudes_credito s
    ON cp.id_solicitud = s.id_solicitud

JOIN clientes c
    ON s.id_cliente = c.id_cliente

GROUP BY c.situacion_laboral
ORDER BY tasa_impago_pct DESC;


/*
11. ¿Cómo se distribuye el riesgo actual de los clientes?
*/

SELECT
    e.nivel_riesgo,

    COUNT(*) AS numero_clientes,

    ROUND(
        AVG(e.score_crediticio),
        2
    ) AS score_medio,

    ROUND(
        AVG(e.probabilidad_impago) * 100,
        2
    ) AS probabilidad_impago_media_pct

FROM evaluaciones_riesgo e

JOIN (
    SELECT
        id_cliente,
        MAX(fecha_evaluacion) AS ultima_evaluacion
    FROM evaluaciones_riesgo
    GROUP BY id_cliente
) AS ult

    ON e.id_cliente = ult.id_cliente
    AND e.fecha_evaluacion = ult.ultima_evaluacion

GROUP BY e.nivel_riesgo
ORDER BY probabilidad_impago_media_pct;

/*
12. ¿La clasificación de riesgo está relacionada con los impagos reales?
*/

SELECT
    e.nivel_riesgo,

    COUNT(*) AS clientes_con_historial,

    ROUND(
        AVG(e.probabilidad_impago) * 100,
        2
    ) AS probabilidad_impago_media_pct,

    ROUND(
        100.0 * SUM(h.tuvo_impago) / COUNT(*),
        2
    ) AS tasa_impago_real_pct

FROM evaluaciones_riesgo e

JOIN (
    SELECT
        id_cliente,
        MAX(fecha_evaluacion) AS ultima_evaluacion
    FROM evaluaciones_riesgo
    GROUP BY id_cliente
) AS ult

    ON e.id_cliente = ult.id_cliente
    AND e.fecha_evaluacion = ult.ultima_evaluacion

JOIN (

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

) AS h
    ON e.id_cliente = h.id_cliente

GROUP BY e.nivel_riesgo
ORDER BY probabilidad_impago_media_pct;

/*
13. ¿Cómo cambia el impago según la utilización del crédito?
*/

SELECT
    CASE
        WHEN e.utilizacion_credito_pct < 30 THEN 'menos_30'
        WHEN e.utilizacion_credito_pct < 60 THEN '30-59'
        WHEN e.utilizacion_credito_pct < 90 THEN '60-89'
        ELSE '90_o_mas'
    END AS tramo_utilizacion,

    COUNT(*) AS clientes,

    ROUND(
        AVG(e.utilizacion_credito_pct),
        2
    ) AS utilizacion_media,

    ROUND(
        100.0 * SUM(h.tuvo_impago) / COUNT(*),
        2
    ) AS tasa_impago_pct

FROM evaluaciones_riesgo e

JOIN (
    SELECT
        id_cliente,
        MAX(fecha_evaluacion) AS ultima_evaluacion
    FROM evaluaciones_riesgo
    GROUP BY id_cliente
) ult

    ON e.id_cliente = ult.id_cliente
    AND e.fecha_evaluacion = ult.ultima_evaluacion

JOIN (

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

) h
    ON e.id_cliente = h.id_cliente

GROUP BY tramo_utilizacion
ORDER BY utilizacion_media;

/*
14. ¿Cuánto capital pendiente está asociado a cada nivel de riesgo?
*/

SELECT
    e.nivel_riesgo,

    COUNT(*) AS numero_clientes,

    ROUND(
        SUM(exp.exposicion),
        2
    ) AS exposicion_total,

    ROUND(
        AVG(exp.exposicion),
        2
    ) AS exposicion_media_cliente

FROM evaluaciones_riesgo e

JOIN (
    SELECT
        id_cliente,
        MAX(fecha_evaluacion) AS ultima_evaluacion
    FROM evaluaciones_riesgo
    GROUP BY id_cliente
) ult

    ON e.id_cliente = ult.id_cliente
    AND e.fecha_evaluacion = ult.ultima_evaluacion

JOIN (

    SELECT
        s.id_cliente,
        SUM(p.saldo_pendiente) AS exposicion

    FROM solicitudes_credito s

    JOIN prestamos p
        ON s.id_solicitud = p.id_solicitud

    WHERE p.estado_prestamo IN ('activo', 'mora', 'impagado')

    GROUP BY s.id_cliente

) exp
    ON e.id_cliente = exp.id_cliente

GROUP BY e.nivel_riesgo
ORDER BY exposicion_total DESC;


/*
15. Top 20 clientes con mayor riesgo y exposición.
*/

SELECT
    e.id_cliente,
    c.situacion_laboral,
    c.ingresos_mensuales,

    e.score_crediticio,
    e.nivel_riesgo,

    ROUND(
        e.probabilidad_impago * 100,
        2
    ) AS probabilidad_impago_pct,

    exp.numero_prestamos,

    ROUND(
        exp.exposicion,
        2
    ) AS exposicion_crediticia,

    ROUND(
        exp.exposicion /
        NULLIF(c.ingresos_mensuales * 12, 0),
        2
    ) AS exposicion_sobre_ingresos_anuales

FROM evaluaciones_riesgo e

JOIN (
    SELECT
        id_cliente,
        MAX(fecha_evaluacion) AS ultima_evaluacion
    FROM evaluaciones_riesgo
    GROUP BY id_cliente
) ult

    ON e.id_cliente = ult.id_cliente
    AND e.fecha_evaluacion = ult.ultima_evaluacion

JOIN clientes c
    ON e.id_cliente = c.id_cliente

JOIN (

    SELECT
        s.id_cliente,
        COUNT(p.id_prestamo) AS numero_prestamos,
        SUM(p.saldo_pendiente) AS exposicion

    FROM solicitudes_credito s

    JOIN prestamos p
        ON s.id_solicitud = p.id_solicitud

    WHERE p.estado_prestamo IN ('activo', 'mora', 'impagado')

    GROUP BY s.id_cliente

) exp
    ON e.id_cliente = exp.id_cliente

ORDER BY
    e.probabilidad_impago DESC,
    exp.exposicion DESC

LIMIT 20;

/*
16. Clientes de alto riesgo que todavía no han registrado impagos.
*/

SELECT
    e.id_cliente,
    e.score_crediticio,
    e.nivel_riesgo,

    ROUND(
        e.probabilidad_impago * 100,
        2
    ) AS probabilidad_impago_pct,

    e.ratio_endeudamiento,
    e.utilizacion_credito_pct

FROM evaluaciones_riesgo e

JOIN (
    SELECT
        id_cliente,
        MAX(fecha_evaluacion) AS ultima_evaluacion
    FROM evaluaciones_riesgo
    GROUP BY id_cliente
) ult

    ON e.id_cliente = ult.id_cliente
    AND e.fecha_evaluacion = ult.ultima_evaluacion

JOIN (

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

) h
    ON e.id_cliente = h.id_cliente

WHERE
    e.nivel_riesgo = 'alto'
    AND h.tuvo_impago = 0

ORDER BY e.probabilidad_impago DESC;


/*
17. Clientes de bajo riesgo que han registrado algún impago.
*/

SELECT
    e.id_cliente,
    e.score_crediticio,

    ROUND(
        e.probabilidad_impago * 100,
        2
    ) AS probabilidad_impago_pct,

    e.ratio_endeudamiento,
    e.utilizacion_credito_pct

FROM evaluaciones_riesgo e

JOIN (
    SELECT
        id_cliente,
        MAX(fecha_evaluacion) AS ultima_evaluacion
    FROM evaluaciones_riesgo
    GROUP BY id_cliente
) ult

    ON e.id_cliente = ult.id_cliente
    AND e.fecha_evaluacion = ult.ultima_evaluacion

JOIN (

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

) h
    ON e.id_cliente = h.id_cliente

WHERE
    e.nivel_riesgo = 'bajo'
    AND h.tuvo_impago = 1

ORDER BY e.probabilidad_impago;


/*
18. KPIs generales de riesgo de la cartera.
*/

SELECT
    COUNT(*) AS total_prestamos,

    SUM(
        COALESCE(cp.tuvo_mora, 0)
    ) AS prestamos_con_mora,

    SUM(
        COALESCE(cp.tuvo_impago, 0)
    ) AS prestamos_con_impago,

    ROUND(
        100.0 *
        SUM(COALESCE(cp.tuvo_mora, 0)) /
        COUNT(*),
        2
    ) AS tasa_mora_pct,

    ROUND(
        100.0 *
        SUM(COALESCE(cp.tuvo_impago, 0)) /
        COUNT(*),
        2
    ) AS tasa_impago_pct,

    ROUND(
        SUM(p.saldo_pendiente),
        2
    ) AS exposicion_total

FROM prestamos p

LEFT JOIN (

    SELECT
        id_prestamo,

        MAX(
            CASE
                WHEN dias_retraso > 30 THEN 1
                ELSE 0
            END
        ) AS tuvo_mora,

        MAX(
            CASE
                WHEN estado_pago = 'impagado' THEN 1
                ELSE 0
            END
        ) AS tuvo_impago

    FROM pagos_prestamo
    GROUP BY id_prestamo

) cp
    ON p.id_prestamo = cp.id_prestamo;