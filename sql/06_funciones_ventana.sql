USE banca_riesgo_crediticio;

/*
1. Numerar cronológicamente las transacciones de cada cuenta.
*/

SELECT
    id_cuenta,
    id_transaccion,
    fecha_transaccion,
    importe,

    ROW_NUMBER() OVER (
        PARTITION BY id_cuenta
        ORDER BY fecha_transaccion
    ) AS numero_transaccion

FROM transacciones
ORDER BY id_cuenta, fecha_transaccion;

/*
2. Obtener la transacción más reciente de cada cuenta.
*/

WITH transacciones_ordenadas AS (
    SELECT
        id_cuenta,
        id_transaccion,
        fecha_transaccion,
        importe,
        saldo_posterior,

        ROW_NUMBER() OVER (
            PARTITION BY id_cuenta
            ORDER BY fecha_transaccion DESC
        ) AS posicion

    FROM transacciones
)

SELECT
    id_cuenta,
    id_transaccion,
    fecha_transaccion,
    importe,
    saldo_posterior

FROM transacciones_ordenadas

WHERE posicion = 1
ORDER BY id_cuenta;

/*
3. Ranking de clientes según el saldo total de sus cuentas.
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
    ROUND(saldo_total, 2) AS saldo_total,

    RANK() OVER (
        ORDER BY saldo_total DESC
    ) AS ranking_saldo

FROM saldo_cliente

ORDER BY ranking_saldo;

/*
4. Comparar RANK y DENSE_RANK en el ranking de ingresos.
*/

SELECT
    id_cliente,
    ingresos_mensuales,

    RANK() OVER (
        ORDER BY ingresos_mensuales DESC
    ) AS ranking,

    DENSE_RANK() OVER (
        ORDER BY ingresos_mensuales DESC
    ) AS ranking_denso

FROM clientes

ORDER BY ingresos_mensuales DESC;

/*
5. Ranking de ingresos dentro de cada situación laboral.
*/

SELECT
    id_cliente,
    situacion_laboral,
    ingresos_mensuales,

    RANK() OVER (
        PARTITION BY situacion_laboral
        ORDER BY ingresos_mensuales DESC
    ) AS ranking_ingresos

FROM clientes

ORDER BY
    situacion_laboral,
    ranking_ingresos;
    
    /*
6. Comparar cada transacción con la transacción anterior
de la misma cuenta.
*/

SELECT
    id_cuenta,
    fecha_transaccion,
    importe,

    LAG(importe) OVER (
        PARTITION BY id_cuenta
        ORDER BY fecha_transaccion
    ) AS importe_anterior

FROM transacciones

ORDER BY id_cuenta, fecha_transaccion;

/*
7. Variación del importe respecto a la transacción anterior.
*/

WITH movimientos AS (
    SELECT
        id_cuenta,
        fecha_transaccion,
        importe,

        LAG(importe) OVER (
            PARTITION BY id_cuenta
            ORDER BY fecha_transaccion
        ) AS importe_anterior

    FROM transacciones
)

SELECT
    id_cuenta,
    fecha_transaccion,
    importe,
    importe_anterior,

    ROUND(
        importe - importe_anterior,
        2
    ) AS variacion_importe

FROM movimientos

ORDER BY id_cuenta, fecha_transaccion;

/*
8. Calcular el flujo acumulado de las transacciones
durante el periodo observado.
*/

SELECT
    id_cuenta,
    fecha_transaccion,
    importe,

    ROUND(
        SUM(importe) OVER (
            PARTITION BY id_cuenta
            ORDER BY fecha_transaccion
            ROWS BETWEEN UNBOUNDED PRECEDING
                     AND CURRENT ROW
        ),
        2
    ) AS flujo_acumulado

FROM transacciones

ORDER BY id_cuenta, fecha_transaccion;

/*
9. ¿Cómo evoluciona el gasto acumulado de cada cliente?
*/

SELECT
    cu.id_cliente,
    t.fecha_transaccion,
    ABS(t.importe) AS gasto,

    ROUND(
        SUM(ABS(t.importe)) OVER (
            PARTITION BY cu.id_cliente
            ORDER BY t.fecha_transaccion
            ROWS BETWEEN UNBOUNDED PRECEDING
                     AND CURRENT ROW
        ),
        2
    ) AS gasto_acumulado

FROM cuentas cu

JOIN transacciones t
    ON cu.id_cuenta = t.id_cuenta

WHERE t.importe < 0

ORDER BY
    cu.id_cliente,
    t.fecha_transaccion;
    
    /*
10. Gasto mensual de cada cliente.
*/

WITH gasto_mensual AS (
    SELECT
        cu.id_cliente,
        DATE_FORMAT(t.fecha_transaccion, '%Y-%m') AS mes,

        SUM(
            CASE
                WHEN t.importe < 0 THEN ABS(t.importe)
                ELSE 0
            END
        ) AS gasto_mes

    FROM cuentas cu

    JOIN transacciones t
        ON cu.id_cuenta = t.id_cuenta

    GROUP BY
        cu.id_cliente,
        DATE_FORMAT(t.fecha_transaccion, '%Y-%m')
)

SELECT
    id_cliente,
    mes,
    ROUND(gasto_mes, 2) AS gasto_mes

FROM gasto_mensual

ORDER BY id_cliente, mes;

/*
11. Calcular la media móvil de gasto de los últimos 3 meses.
*/

WITH gasto_mensual AS (
    SELECT
        cu.id_cliente,
        DATE_FORMAT(t.fecha_transaccion, '%Y-%m') AS mes,

        SUM(
            CASE
                WHEN t.importe < 0 THEN ABS(t.importe)
                ELSE 0
            END
        ) AS gasto_mes

    FROM cuentas cu

    JOIN transacciones t
        ON cu.id_cuenta = t.id_cuenta

    GROUP BY
        cu.id_cliente,
        DATE_FORMAT(t.fecha_transaccion, '%Y-%m')
)

SELECT
    id_cliente,
    mes,

    ROUND(
        gasto_mes,
        2
    ) AS gasto_mes,

    ROUND(
        AVG(gasto_mes) OVER (
            PARTITION BY id_cliente
            ORDER BY mes

            ROWS BETWEEN 2 PRECEDING
                     AND CURRENT ROW
        ),
        2
    ) AS media_movil_3_meses

FROM gasto_mensual

ORDER BY id_cliente, mes;

/*
12. Comparar el score crediticio con la evaluación anterior.
*/

SELECT
    id_cliente,
    fecha_evaluacion,
    score_crediticio,

    LAG(score_crediticio) OVER (
        PARTITION BY id_cliente
        ORDER BY fecha_evaluacion
    ) AS score_anterior

FROM evaluaciones_riesgo

ORDER BY
    id_cliente,
    fecha_evaluacion;
    
    /*
13. ¿Cuánto ha cambiado el score respecto a la evaluación anterior?
*/

WITH evolucion_score AS (
    SELECT
        id_cliente,
        fecha_evaluacion,
        score_crediticio,

        LAG(score_crediticio) OVER (
            PARTITION BY id_cliente
            ORDER BY fecha_evaluacion
        ) AS score_anterior

    FROM evaluaciones_riesgo
)

SELECT
    id_cliente,
    fecha_evaluacion,
    score_crediticio,
    score_anterior,

    CAST(score_crediticio AS SIGNED)
    - CAST(score_anterior AS SIGNED)
        AS variacion_score

FROM evolucion_score

ORDER BY
    id_cliente,
    fecha_evaluacion;
    
/*
14. Clientes cuyo score ha caído al menos 50 puntos
desde la evaluación anterior.
*/

WITH evolucion_score AS (
    SELECT
        id_cliente,
        fecha_evaluacion,
        score_crediticio,

        LAG(score_crediticio) OVER (
            PARTITION BY id_cliente
            ORDER BY fecha_evaluacion
        ) AS score_anterior

    FROM evaluaciones_riesgo
)

SELECT
    id_cliente,
    fecha_evaluacion,
    score_anterior,
    score_crediticio,

    CAST(score_crediticio AS SIGNED)
    - CAST(score_anterior AS SIGNED)
        AS variacion_score

FROM evolucion_score

WHERE
    CAST(score_crediticio AS SIGNED)
    - CAST(score_anterior AS SIGNED) <= -50

ORDER BY variacion_score;

/*
15. Obtener la evaluación más reciente de cada cliente
utilizando ROW_NUMBER.
*/

WITH riesgo_ordenado AS (
    SELECT
        e.*,

        ROW_NUMBER() OVER (
            PARTITION BY id_cliente
            ORDER BY fecha_evaluacion DESC
        ) AS posicion

    FROM evaluaciones_riesgo e
)

SELECT
    id_cliente,
    fecha_evaluacion,
    score_crediticio,
    ratio_endeudamiento,
    utilizacion_credito_pct,
    nivel_riesgo,
    probabilidad_impago

FROM riesgo_ordenado

WHERE posicion = 1

ORDER BY id_cliente;


/*
16. Ranking de riesgo dentro de cada provincia.
*/

WITH riesgo_ordenado AS (
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
    c.provincia,

    ROUND(
        r.probabilidad_impago * 100,
        2
    ) AS probabilidad_impago_pct,

    RANK() OVER (
        PARTITION BY c.provincia
        ORDER BY r.probabilidad_impago DESC
    ) AS ranking_riesgo_provincia

FROM clientes c

JOIN riesgo_actual r
    ON c.id_cliente = r.id_cliente

ORDER BY
    c.provincia,
    ranking_riesgo_provincia;
    
    /*
17. Obtener los 3 clientes con mayor riesgo de cada provincia.
*/

WITH riesgo_ordenado AS (
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
),

ranking_clientes AS (
    SELECT
        c.id_cliente,
        c.provincia,
        r.score_crediticio,
        r.probabilidad_impago,

        ROW_NUMBER() OVER (
            PARTITION BY c.provincia
            ORDER BY r.probabilidad_impago DESC
        ) AS posicion_riesgo

    FROM clientes c

    JOIN riesgo_actual r
        ON c.id_cliente = r.id_cliente
)

SELECT
    id_cliente,
    provincia,
    score_crediticio,

    ROUND(
        probabilidad_impago * 100,
        2
    ) AS probabilidad_impago_pct,

    posicion_riesgo

FROM ranking_clientes

WHERE posicion_riesgo <= 3

ORDER BY
    provincia,
    posicion_riesgo;
    
    /*
18. Ranking de préstamos por importe dentro de cada tipo de crédito.
*/

SELECT
    s.tipo_credito,
    p.id_prestamo,
    s.id_cliente,
    p.importe_concedido,

    RANK() OVER (
        PARTITION BY s.tipo_credito
        ORDER BY p.importe_concedido DESC
    ) AS ranking_importe

FROM prestamos p

JOIN solicitudes_credito s
    ON p.id_solicitud = s.id_solicitud

ORDER BY
    s.tipo_credito,
    ranking_importe;
    
    /*
19. Comparar la exposición de cada cliente con la exposición media.
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

    ROUND(
        exposicion,
        2
    ) AS exposicion,

    ROUND(
        AVG(exposicion) OVER (),
        2
    ) AS exposicion_media,

    ROUND(
        exposicion - AVG(exposicion) OVER (),
        2
    ) AS diferencia_media

FROM exposicion_cliente

ORDER BY exposicion DESC;


/*
20. ¿Qué porcentaje de la exposición crediticia total
representa cada cliente?
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

    ROUND(
        exposicion,
        2
    ) AS exposicion,

    ROUND(
        100.0 * exposicion /
        SUM(exposicion) OVER (),
        4
    ) AS porcentaje_exposicion_total

FROM exposicion_cliente

ORDER BY exposicion DESC;


/*
21. Analizar la concentración acumulada de la exposición crediticia.
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
),

exposicion_ordenada AS (
    SELECT
        id_cliente,
        exposicion,

        SUM(exposicion) OVER (
            ORDER BY exposicion DESC
            ROWS BETWEEN UNBOUNDED PRECEDING
                     AND CURRENT ROW
        ) AS exposicion_acumulada,

        SUM(exposicion) OVER ()
            AS exposicion_total

    FROM exposicion_cliente
)

SELECT
    id_cliente,

    ROUND(
        exposicion,
        2
    ) AS exposicion,

    ROUND(
        100.0 * exposicion_acumulada /
        exposicion_total,
        2
    ) AS porcentaje_exposicion_acumulada

FROM exposicion_ordenada

ORDER BY exposicion DESC;

/*
22. Comparar la primera y última evaluación de riesgo
de cada cliente.
*/

WITH evaluaciones_ordenadas AS (
    SELECT
        id_cliente,
        fecha_evaluacion,
        score_crediticio,

        ROW_NUMBER() OVER (
            PARTITION BY id_cliente
            ORDER BY fecha_evaluacion
        ) AS primera_posicion,

        ROW_NUMBER() OVER (
            PARTITION BY id_cliente
            ORDER BY fecha_evaluacion DESC
        ) AS ultima_posicion

    FROM evaluaciones_riesgo
),

primera_evaluacion AS (
    SELECT
        id_cliente,
        score_crediticio AS score_inicial
    FROM evaluaciones_ordenadas
    WHERE primera_posicion = 1
),

ultima_evaluacion AS (
    SELECT
        id_cliente,
        score_crediticio AS score_actual
    FROM evaluaciones_ordenadas
    WHERE ultima_posicion = 1
)

SELECT
    p.id_cliente,
    p.score_inicial,
    u.score_actual,

    CAST(u.score_actual AS SIGNED)
    - CAST(p.score_inicial AS SIGNED)
        AS variacion_score

FROM primera_evaluacion p

JOIN ultima_evaluacion u
    ON p.id_cliente = u.id_cliente

ORDER BY variacion_score;