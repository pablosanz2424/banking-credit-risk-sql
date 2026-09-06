USE banca_riesgo_crediticio;

/*
1. Identificar clientes con flujo financiero negativo
y nivel de riesgo actual alto.
*/

WITH movimientos_cliente AS (
    SELECT
        cu.id_cliente,
        SUM(t.importe) AS flujo_neto
    FROM cuentas cu
    JOIN transacciones t
        ON cu.id_cuenta = t.id_cuenta
    GROUP BY cu.id_cliente
),

riesgo_ordenado AS (
    SELECT
        e.*,

        ROW_NUMBER() OVER (
            PARTITION BY id_cliente
            ORDER BY fecha_evaluacion DESC
        ) AS posicion

    FROM evaluaciones_riesgo e
),

riesgo_actual AS (
    SELECT *
    FROM riesgo_ordenado
    WHERE posicion = 1
)

SELECT
    c.id_cliente,
    c.ingresos_mensuales,

    ROUND(m.flujo_neto, 2) AS flujo_neto,

    r.score_crediticio,
    r.nivel_riesgo,

    ROUND(
        r.probabilidad_impago * 100,
        2
    ) AS probabilidad_impago_pct

FROM clientes c

JOIN movimientos_cliente m
    ON c.id_cliente = m.id_cliente

JOIN riesgo_actual r
    ON c.id_cliente = r.id_cliente

WHERE
    m.flujo_neto < 0
    AND r.nivel_riesgo = 'alto'

ORDER BY r.probabilidad_impago DESC;

/*
2. Detectar clientes cuyo score ha empeorado
entre la primera y última evaluación.
*/

WITH evaluaciones_ordenadas AS (
    SELECT
        id_cliente,
        score_crediticio,

        ROW_NUMBER() OVER (
            PARTITION BY id_cliente
            ORDER BY fecha_evaluacion
        ) AS posicion_inicial,

        ROW_NUMBER() OVER (
            PARTITION BY id_cliente
            ORDER BY fecha_evaluacion DESC
        ) AS posicion_actual

    FROM evaluaciones_riesgo
),

score_inicial AS (
    SELECT
        id_cliente,
        score_crediticio AS score_inicial
    FROM evaluaciones_ordenadas
    WHERE posicion_inicial = 1
),

score_actual AS (
    SELECT
        id_cliente,
        score_crediticio AS score_actual
    FROM evaluaciones_ordenadas
    WHERE posicion_actual = 1
)

SELECT
    i.id_cliente,
    i.score_inicial,
    a.score_actual,

    CAST(a.score_actual AS SIGNED)
    - CAST(i.score_inicial AS SIGNED)
        AS variacion_score

FROM score_inicial i

JOIN score_actual a
    ON i.id_cliente = a.id_cliente

WHERE
    CAST(a.score_actual AS SIGNED)
    - CAST(i.score_inicial AS SIGNED) < 0

ORDER BY variacion_score;


/*
3. Clientes con deterioro de score >= 50 puntos
que todavía no han registrado impago.
*/

WITH evolucion AS (
    SELECT
        id_cliente,
        fecha_evaluacion,
        score_crediticio,

        LAG(score_crediticio) OVER (
            PARTITION BY id_cliente
            ORDER BY fecha_evaluacion
        ) AS score_anterior

    FROM evaluaciones_riesgo
),

deterioro AS (
    SELECT
        id_cliente,

        MIN(
            CAST(score_crediticio AS SIGNED)
            - CAST(score_anterior AS SIGNED)
        ) AS peor_variacion

    FROM evolucion

    WHERE score_anterior IS NOT NULL

    GROUP BY id_cliente
),

historial_impago AS (
    SELECT
        s.id_cliente,

        MAX(
            CASE
                WHEN pp.estado_pago = 'impagado'
                THEN 1
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
    d.id_cliente,
    d.peor_variacion

FROM deterioro d

JOIN historial_impago h
    ON d.id_cliente = h.id_cliente

WHERE
    d.peor_variacion <= -50
    AND h.tuvo_impago = 0

ORDER BY d.peor_variacion;

/*
4. ¿Cómo ha evolucionado el riesgo medio de la cartera?
*/

SELECT
    fecha_evaluacion,

    COUNT(*) AS clientes_evaluados,

    ROUND(
        AVG(score_crediticio),
        2
    ) AS score_medio,

    ROUND(
        AVG(probabilidad_impago) * 100,
        2
    ) AS probabilidad_impago_media_pct,

    ROUND(
        100.0 *
        SUM(
            CASE
                WHEN nivel_riesgo = 'alto' THEN 1
                ELSE 0
            END
        ) / COUNT(*),
        2
    ) AS clientes_alto_riesgo_pct

FROM evaluaciones_riesgo

GROUP BY fecha_evaluacion

ORDER BY fecha_evaluacion;


/*
5. Analizar cómo han cambiado los clientes
entre niveles de riesgo.
*/

WITH evaluaciones_ordenadas AS (
    SELECT
        id_cliente,
        nivel_riesgo,

        ROW_NUMBER() OVER (
            PARTITION BY id_cliente
            ORDER BY fecha_evaluacion
        ) AS posicion_inicial,

        ROW_NUMBER() OVER (
            PARTITION BY id_cliente
            ORDER BY fecha_evaluacion DESC
        ) AS posicion_actual

    FROM evaluaciones_riesgo
),

riesgo_inicial AS (
    SELECT
        id_cliente,
        nivel_riesgo AS riesgo_inicial
    FROM evaluaciones_ordenadas
    WHERE posicion_inicial = 1
),

riesgo_actual AS (
    SELECT
        id_cliente,
        nivel_riesgo AS riesgo_actual
    FROM evaluaciones_ordenadas
    WHERE posicion_actual = 1
)

SELECT
    i.riesgo_inicial,
    a.riesgo_actual,
    COUNT(*) AS numero_clientes

FROM riesgo_inicial i

JOIN riesgo_actual a
    ON i.id_cliente = a.id_cliente

GROUP BY
    i.riesgo_inicial,
    a.riesgo_actual

ORDER BY
    i.riesgo_inicial,
    a.riesgo_actual;
    
    

/*
6. Detectar clientes que han pasado recientemente
a nivel de riesgo alto.
*/

WITH evolucion_riesgo AS (
    SELECT
        id_cliente,
        fecha_evaluacion,
        nivel_riesgo,

        LAG(nivel_riesgo) OVER (
            PARTITION BY id_cliente
            ORDER BY fecha_evaluacion
        ) AS riesgo_anterior

    FROM evaluaciones_riesgo
)

SELECT
    id_cliente,
    fecha_evaluacion,
    riesgo_anterior,
    nivel_riesgo AS riesgo_actual

FROM evolucion_riesgo

WHERE
    nivel_riesgo = 'alto'
    AND riesgo_anterior IS NOT NULL
    AND riesgo_anterior <> 'alto'

ORDER BY fecha_evaluacion DESC;

/*
7. Estimar una exposición ponderada por riesgo.

No representa Expected Loss regulatoria completa,
porque no incorporamos LGD.
*/

WITH riesgo_actual AS (
    SELECT *
    FROM (
        SELECT
            e.*,

            ROW_NUMBER() OVER (
                PARTITION BY id_cliente
                ORDER BY fecha_evaluacion DESC
            ) AS posicion

        FROM evaluaciones_riesgo e
    ) r

    WHERE posicion = 1
),

exposicion AS (
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

    ROUND(
        e.exposicion,
        2
    ) AS exposicion,

    ROUND(
        r.probabilidad_impago * 100,
        2
    ) AS probabilidad_impago_pct,

    ROUND(
        e.exposicion * r.probabilidad_impago,
        2
    ) AS exposicion_ponderada_riesgo

FROM riesgo_actual r

JOIN exposicion e
    ON r.id_cliente = e.id_cliente

ORDER BY exposicion_ponderada_riesgo DESC;

/*
8. ¿Cuánta exposición ponderada por riesgo tiene la cartera?
*/

WITH riesgo_actual AS (
    SELECT *
    FROM (
        SELECT
            e.*,

            ROW_NUMBER() OVER (
                PARTITION BY id_cliente
                ORDER BY fecha_evaluacion DESC
            ) AS posicion

        FROM evaluaciones_riesgo e
    ) r

    WHERE posicion = 1
),

exposicion AS (
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
    ROUND(
        SUM(e.exposicion),
        2
    ) AS exposicion_total,

    ROUND(
        SUM(
            e.exposicion * r.probabilidad_impago
        ),
        2
    ) AS exposicion_ponderada_riesgo

FROM riesgo_actual r

JOIN exposicion e
    ON r.id_cliente = e.id_cliente;
    
    
    /*
9. Analizar riesgo y exposición según situación laboral.
*/

WITH riesgo_actual AS (
    SELECT *
    FROM (
        SELECT
            e.*,

            ROW_NUMBER() OVER (
                PARTITION BY id_cliente
                ORDER BY fecha_evaluacion DESC
            ) AS posicion

        FROM evaluaciones_riesgo e
    ) r

    WHERE posicion = 1
),

exposicion AS (
    SELECT
        s.id_cliente,
        SUM(p.saldo_pendiente) AS exposicion

    FROM solicitudes_credito s

    JOIN prestamos p
        ON s.id_solicitud = p.id_solicitud

    GROUP BY s.id_cliente
)

SELECT
    c.situacion_laboral,

    COUNT(*) AS clientes,

    ROUND(
        AVG(r.probabilidad_impago) * 100,
        2
    ) AS probabilidad_impago_media_pct,

    ROUND(
        SUM(e.exposicion),
        2
    ) AS exposicion_total

FROM clientes c

JOIN riesgo_actual r
    ON c.id_cliente = r.id_cliente

JOIN exposicion e
    ON c.id_cliente = e.id_cliente

GROUP BY c.situacion_laboral

ORDER BY probabilidad_impago_media_pct DESC;

/*
10. Comparar el flujo neto medio de clientes
con y sin historial de impago.
*/

WITH movimientos AS (
    SELECT
        cu.id_cliente,
        SUM(t.importe) AS flujo_neto

    FROM cuentas cu

    JOIN transacciones t
        ON cu.id_cuenta = t.id_cuenta

    GROUP BY cu.id_cliente
),

historial AS (
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
    h.tuvo_impago,

    COUNT(*) AS numero_clientes,

    ROUND(
        AVG(m.flujo_neto),
        2
    ) AS flujo_neto_medio

FROM historial h

JOIN movimientos m
    ON h.id_cliente = m.id_cliente

GROUP BY h.tuvo_impago;


/*
11. Obtener la primera fecha de impago observada de cada cliente.
*/

SELECT
    s.id_cliente,
    MIN(pp.fecha_vencimiento) AS primer_impago

FROM solicitudes_credito s

JOIN prestamos p
    ON s.id_solicitud = p.id_solicitud

JOIN pagos_prestamo pp
    ON p.id_prestamo = pp.id_prestamo

WHERE pp.estado_pago = 'impagado'

GROUP BY s.id_cliente

ORDER BY primer_impago;


/*
12. Analizar el gasto de los 90 días previos
al primer impago de cada cliente.
*/

WITH primer_impago AS (
    SELECT
        s.id_cliente,
        MIN(pp.fecha_vencimiento) AS fecha_primer_impago

    FROM solicitudes_credito s

    JOIN prestamos p
        ON s.id_solicitud = p.id_solicitud

    JOIN pagos_prestamo pp
        ON p.id_prestamo = pp.id_prestamo

    WHERE pp.estado_pago = 'impagado'

    GROUP BY s.id_cliente
)

SELECT
    pi.id_cliente,
    pi.fecha_primer_impago,

    ROUND(
        SUM(
            CASE
                WHEN t.importe < 0
                THEN ABS(t.importe)
                ELSE 0
            END
        ),
        2
    ) AS gasto_90_dias_previo

FROM primer_impago pi

JOIN cuentas cu
    ON pi.id_cliente = cu.id_cliente

JOIN transacciones t
    ON cu.id_cuenta = t.id_cuenta

WHERE
    t.fecha_transaccion >=
        DATE_SUB(pi.fecha_primer_impago, INTERVAL 90 DAY)

    AND t.fecha_transaccion <
        pi.fecha_primer_impago

GROUP BY
    pi.id_cliente,
    pi.fecha_primer_impago

ORDER BY gasto_90_dias_previo DESC;

/*
13. Comparar el gasto inmediatamente anterior al impago
con el periodo precedente.
*/

WITH primer_impago AS (
    SELECT
        s.id_cliente,
        MIN(pp.fecha_vencimiento) AS fecha_primer_impago

    FROM solicitudes_credito s

    JOIN prestamos p
        ON s.id_solicitud = p.id_solicitud

    JOIN pagos_prestamo pp
        ON p.id_prestamo = pp.id_prestamo

    WHERE pp.estado_pago = 'impagado'

    GROUP BY s.id_cliente
),

gastos AS (
    SELECT
        pi.id_cliente,
        pi.fecha_primer_impago,

        SUM(
            CASE
                WHEN t.fecha_transaccion >=
                        DATE_SUB(pi.fecha_primer_impago, INTERVAL 90 DAY)
                 AND t.fecha_transaccion <
                        pi.fecha_primer_impago
                 AND t.importe < 0
                THEN ABS(t.importe)
                ELSE 0
            END
        ) AS gasto_ultimos_90,

        SUM(
            CASE
                WHEN t.fecha_transaccion >=
                        DATE_SUB(pi.fecha_primer_impago, INTERVAL 180 DAY)
                 AND t.fecha_transaccion <
                        DATE_SUB(pi.fecha_primer_impago, INTERVAL 90 DAY)
                 AND t.importe < 0
                THEN ABS(t.importe)
                ELSE 0
            END
        ) AS gasto_90_anteriores

    FROM primer_impago pi

    JOIN cuentas cu
        ON pi.id_cliente = cu.id_cliente

    JOIN transacciones t
        ON cu.id_cuenta = t.id_cuenta

    GROUP BY
        pi.id_cliente,
        pi.fecha_primer_impago
)

SELECT
    id_cliente,

    ROUND(
        gasto_90_anteriores,
        2
    ) AS gasto_periodo_anterior,

    ROUND(
        gasto_ultimos_90,
        2
    ) AS gasto_previo_impago,

    ROUND(
        100.0 *
        (gasto_ultimos_90 - gasto_90_anteriores)
        / NULLIF(gasto_90_anteriores, 0),
        2
    ) AS variacion_gasto_pct

FROM gastos

ORDER BY variacion_gasto_pct DESC;


/*
14. Dividir los clientes en 5 grupos según
su probabilidad de impago.
*/

WITH riesgo_actual AS (
    SELECT *
    FROM (
        SELECT
            e.*,

            ROW_NUMBER() OVER (
                PARTITION BY id_cliente
                ORDER BY fecha_evaluacion DESC
            ) AS posicion

        FROM evaluaciones_riesgo e
    ) r

    WHERE posicion = 1
)

SELECT
    id_cliente,
    score_crediticio,

    ROUND(
        probabilidad_impago * 100,
        2
    ) AS probabilidad_impago_pct,

    NTILE(5) OVER (
        ORDER BY probabilidad_impago
    ) AS quintil_riesgo

FROM riesgo_actual

ORDER BY probabilidad_impago;


/*
15. Comparar los quintiles de riesgo con el impago observado.
*/

WITH riesgo_actual AS (
    SELECT *
    FROM (
        SELECT
            e.*,

            ROW_NUMBER() OVER (
                PARTITION BY id_cliente
                ORDER BY fecha_evaluacion DESC
            ) AS posicion

        FROM evaluaciones_riesgo e
    ) r

    WHERE posicion = 1
),

quintiles AS (
    SELECT
        id_cliente,
        probabilidad_impago,

        NTILE(5) OVER (
            ORDER BY probabilidad_impago
        ) AS quintil_riesgo

    FROM riesgo_actual
),

impago AS (
    SELECT
        s.id_cliente,

        MAX(
            CASE
                WHEN pp.estado_pago = 'impagado'
                THEN 1
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
    q.quintil_riesgo,

    COUNT(*) AS clientes,

    ROUND(
        AVG(q.probabilidad_impago) * 100,
        2
    ) AS probabilidad_media_pct,

    ROUND(
        100.0 * SUM(i.tuvo_impago) /
        COUNT(*),
        2
    ) AS tasa_impago_real_pct

FROM quintiles q

JOIN impago i
    ON q.id_cliente = i.id_cliente

GROUP BY q.quintil_riesgo

ORDER BY q.quintil_riesgo;


/*
16. Crear una lista priorizada de clientes
para seguimiento de riesgo.
*/

WITH riesgo_actual AS (
    SELECT *
    FROM (
        SELECT
            e.*,

            ROW_NUMBER() OVER (
                PARTITION BY id_cliente
                ORDER BY fecha_evaluacion DESC
            ) AS posicion

        FROM evaluaciones_riesgo e
    ) r

    WHERE posicion = 1
),

exposicion AS (
    SELECT
        s.id_cliente,
        SUM(p.saldo_pendiente) AS exposicion_total

    FROM solicitudes_credito s

    JOIN prestamos p
        ON s.id_solicitud = p.id_solicitud

    WHERE p.estado_prestamo IN ('activo', 'mora', 'impagado')

    GROUP BY s.id_cliente
),

ranking_riesgo AS (
    SELECT
        r.id_cliente,
        r.probabilidad_impago,
        e.exposicion_total,

        NTILE(5) OVER (
            ORDER BY r.probabilidad_impago
        ) AS quintil_pd,

        NTILE(5) OVER (
            ORDER BY e.exposicion_total
        ) AS quintil_exposicion

    FROM riesgo_actual r

    JOIN exposicion e
        ON r.id_cliente = e.id_cliente
)

SELECT
    id_cliente,

    ROUND(
        probabilidad_impago * 100,
        2
    ) AS probabilidad_impago_pct,

    ROUND(
        exposicion_total,
        2
    ) AS exposicion_total,

    quintil_pd,
    quintil_exposicion,

    quintil_pd + quintil_exposicion
        AS puntuacion_prioridad

FROM ranking_riesgo

ORDER BY
    puntuacion_prioridad DESC,
    probabilidad_impago DESC

LIMIT 20;