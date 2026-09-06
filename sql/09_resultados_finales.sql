/*
============================================================
09_RESULTADOS_FINALES.SQL
Banking Customer & Credit Risk Analytics — MySQL
============================================================

Objetivo:
Obtener los KPIs y resultados finales del proyecto para
documentar conclusiones reales en GitHub.

Requisitos:
- Haber ejecutado previamente 00_creacion_base_datos.sql
- Haber cargado los datos
- Haber ejecutado 08_vistas_kpis.sql
============================================================
*/

USE banca_riesgo_crediticio;


-- =========================================================
-- 1. KPIs GENERALES DE SOLICITUDES DE CRÉDITO
-- =========================================================
/*
Pregunta:
¿Cuántas solicitudes se han realizado y cuál es la tasa de aprobación?
*/

SELECT *
FROM vw_kpi_solicitudes;


-- =========================================================
-- 2. KPIs GENERALES DE LA CARTERA DE PRÉSTAMOS
-- =========================================================
/*
Pregunta:
¿Cuál es el tamaño de la cartera y cuáles son sus tasas de mora e impago?
*/

SELECT *
FROM vw_kpi_cartera;


-- =========================================================
-- 3. KPIs GENERALES DE RIESGO ACTUAL
-- =========================================================
/*
Pregunta:
¿Cuál es el nivel de riesgo actual de la cartera de clientes?
*/

SELECT *
FROM vw_kpi_riesgo;


-- =========================================================
-- 4. DISTRIBUCIÓN DE EXPOSICIÓN POR NIVEL DE RIESGO
-- =========================================================
/*
Pregunta:
¿Qué parte de la exposición crediticia está asociada
a clientes de riesgo bajo, medio y alto?
*/

WITH cartera_riesgo AS (
    SELECT
        nivel_riesgo,
        numero_clientes,
        score_medio,
        probabilidad_impago_media_pct,
        exposicion_total,
        exposicion_media_cliente
    FROM vw_cartera_por_riesgo
)

SELECT
    nivel_riesgo,
    numero_clientes,
    score_medio,
    probabilidad_impago_media_pct,
    exposicion_total,
    exposicion_media_cliente,

    ROUND(
        100.0 * exposicion_total /
        SUM(exposicion_total) OVER (),
        2
    ) AS porcentaje_exposicion_total

FROM cartera_riesgo

ORDER BY probabilidad_impago_media_pct;


-- =========================================================
-- 5. TASA DE IMPAGO SEGÚN RANGO DE SCORE INICIAL
-- =========================================================
/*
Pregunta:
¿Los préstamos concedidos a clientes con menor score inicial
presentan una mayor tasa de impago?
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

    SUM(
        COALESCE(cp.tuvo_impago, 0)
    ) AS prestamos_con_impago,

    ROUND(
        100.0 *
        SUM(COALESCE(cp.tuvo_impago, 0)) /
        COUNT(*),
        2
    ) AS tasa_impago_pct

FROM prestamos p

JOIN solicitudes_credito s
    ON p.id_solicitud = s.id_solicitud

LEFT JOIN vw_comportamiento_prestamo cp
    ON p.id_prestamo = cp.id_prestamo

GROUP BY rango_score

ORDER BY score_medio;


-- =========================================================
-- 6. TASA DE IMPAGO SEGÚN ENDEUDAMIENTO INICIAL
-- =========================================================
/*
Pregunta:
¿Cómo cambia la tasa de impago cuando aumenta
el ratio de endeudamiento del solicitante?
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

    SUM(
        COALESCE(cp.tuvo_impago, 0)
    ) AS prestamos_con_impago,

    ROUND(
        100.0 *
        SUM(COALESCE(cp.tuvo_impago, 0)) /
        COUNT(*),
        2
    ) AS tasa_impago_pct

FROM prestamos p

JOIN solicitudes_credito s
    ON p.id_solicitud = s.id_solicitud

LEFT JOIN vw_comportamiento_prestamo cp
    ON p.id_prestamo = cp.id_prestamo

GROUP BY tramo_endeudamiento

ORDER BY endeudamiento_medio;


-- =========================================================
-- 7. TASA DE IMPAGO SEGÚN SITUACIÓN LABORAL
-- =========================================================
/*
Pregunta:
¿Qué perfiles laborales presentan mayores tasas de impago?
La unidad de análisis de esta consulta es el préstamo.
*/

SELECT
    c.situacion_laboral,

    COUNT(p.id_prestamo) AS numero_prestamos,

    SUM(
        COALESCE(cp.tuvo_impago, 0)
    ) AS prestamos_con_impago,

    ROUND(
        100.0 *
        SUM(COALESCE(cp.tuvo_impago, 0)) /
        COUNT(p.id_prestamo),
        2
    ) AS tasa_impago_pct

FROM clientes c

JOIN solicitudes_credito s
    ON c.id_cliente = s.id_cliente

JOIN prestamos p
    ON s.id_solicitud = p.id_solicitud

LEFT JOIN vw_comportamiento_prestamo cp
    ON p.id_prestamo = cp.id_prestamo

GROUP BY c.situacion_laboral

ORDER BY tasa_impago_pct DESC;


-- =========================================================
-- 8. EVOLUCIÓN TEMPORAL DEL RIESGO DE LA CARTERA
-- =========================================================
/*
Pregunta:
¿Está aumentando o disminuyendo el riesgo medio
de los clientes a lo largo del tiempo?
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


-- =========================================================
-- 9. QUINTILES DE RIESGO VS IMPAGO REAL
-- =========================================================
/*
Pregunta:
¿La probabilidad de impago ordena correctamente a los clientes?

Idealmente, la tasa de impago real debería aumentar
desde el quintil 1 hasta el quintil 5.
*/

WITH quintiles AS (
    SELECT
        id_cliente,
        probabilidad_impago,

        NTILE(5) OVER (
            ORDER BY probabilidad_impago
        ) AS quintil_riesgo

    FROM vw_riesgo_actual
),

historial AS (
    SELECT
        id_cliente,
        tuvo_impago
    FROM vw_historial_pago_cliente
)

SELECT
    q.quintil_riesgo,

    COUNT(*) AS clientes_con_historial,

    ROUND(
        AVG(q.probabilidad_impago) * 100,
        2
    ) AS probabilidad_impago_media_pct,

    SUM(h.tuvo_impago) AS clientes_con_impago,

    ROUND(
        100.0 * SUM(h.tuvo_impago) /
        COUNT(*),
        2
    ) AS tasa_impago_real_pct

FROM quintiles q

JOIN historial h
    ON q.id_cliente = h.id_cliente

GROUP BY q.quintil_riesgo

ORDER BY q.quintil_riesgo;


-- =========================================================
-- 10. ALERTA TEMPRANA Y WATCHLIST
-- =========================================================
/*
Pregunta:
¿Cuántos clientes requieren atención desde una perspectiva
preventiva o de seguimiento de riesgo?
*/

SELECT
    (SELECT COUNT(*) FROM vw_alerta_temprana)
        AS clientes_alerta_temprana,

    (SELECT COUNT(*) FROM vw_watchlist_riesgo)
        AS clientes_watchlist,

    (SELECT COUNT(*)
     FROM vw_cliente_360
     WHERE tuvo_mora = 1)
        AS clientes_con_historial_mora,

    (SELECT COUNT(*)
     FROM vw_cliente_360
     WHERE tuvo_impago = 1)
        AS clientes_con_historial_impago;


-- =========================================================
-- 11. EXPOSICIÓN PONDERADA POR RIESGO
-- =========================================================
/*
Métrica analítica:
Exposición pendiente × probabilidad de impago.

No representa Expected Loss regulatoria completa,
ya que no incorpora LGD.
*/

SELECT
    ROUND(
        SUM(exposicion_total),
        2
    ) AS exposicion_total,

    ROUND(
        SUM(exposicion_ponderada_riesgo),
        2
    ) AS exposicion_ponderada_riesgo,

    ROUND(
        100.0 *
        SUM(exposicion_ponderada_riesgo) /
        NULLIF(SUM(exposicion_total), 0),
        2
    ) AS exposicion_ponderada_sobre_total_pct

FROM vw_exposicion_ponderada_riesgo;


-- =========================================================
-- 12. CONCENTRACIÓN DE LA EXPOSICIÓN CREDITICIA
-- =========================================================
/*
Pregunta:
¿Qué porcentaje de la exposición total está concentrado
en el 10% y 20% de clientes con mayor exposición?
*/

WITH ranking_exposicion AS (
    SELECT
        id_cliente,
        exposicion_total,

        ROW_NUMBER() OVER (
            ORDER BY exposicion_total DESC
        ) AS posicion,

        COUNT(*) OVER () AS total_clientes

    FROM vw_exposicion_cliente
),

concentracion AS (
    SELECT
        SUM(exposicion_total) AS exposicion_total,

        SUM(
            CASE
                WHEN posicion <= CEIL(total_clientes * 0.10)
                THEN exposicion_total
                ELSE 0
            END
        ) AS exposicion_top_10,

        SUM(
            CASE
                WHEN posicion <= CEIL(total_clientes * 0.20)
                THEN exposicion_total
                ELSE 0
            END
        ) AS exposicion_top_20

    FROM ranking_exposicion
)

SELECT
    ROUND(exposicion_total, 2)
        AS exposicion_total,

    ROUND(exposicion_top_10, 2)
        AS exposicion_top_10_pct_clientes,

    ROUND(
        100.0 * exposicion_top_10 /
        NULLIF(exposicion_total, 0),
        2
    ) AS porcentaje_exposicion_top_10,

    ROUND(exposicion_top_20, 2)
        AS exposicion_top_20_pct_clientes,

    ROUND(
        100.0 * exposicion_top_20 /
        NULLIF(exposicion_total, 0),
        2
    ) AS porcentaje_exposicion_top_20

FROM concentracion;


-- =========================================================
-- 13. CAMBIO ENTRE RIESGO INICIAL Y RIESGO ACTUAL
-- =========================================================
/*
Pregunta:
¿Cuántos clientes han mejorado, empeorado o mantenido
su nivel de riesgo desde su primera evaluación?
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
        nivel_riesgo AS nivel_inicial
    FROM evaluaciones_ordenadas
    WHERE posicion_inicial = 1
),

riesgo_actual AS (
    SELECT
        id_cliente,
        nivel_riesgo AS nivel_actual
    FROM evaluaciones_ordenadas
    WHERE posicion_actual = 1
),

comparacion AS (
    SELECT
        i.id_cliente,
        i.nivel_inicial,
        a.nivel_actual,

        CASE i.nivel_inicial
            WHEN 'bajo' THEN 1
            WHEN 'medio' THEN 2
            WHEN 'alto' THEN 3
        END AS valor_inicial,

        CASE a.nivel_actual
            WHEN 'bajo' THEN 1
            WHEN 'medio' THEN 2
            WHEN 'alto' THEN 3
        END AS valor_actual

    FROM riesgo_inicial i

    JOIN riesgo_actual a
        ON i.id_cliente = a.id_cliente
)

SELECT
    CASE
        WHEN valor_actual > valor_inicial THEN 'empeora'
        WHEN valor_actual < valor_inicial THEN 'mejora'
        ELSE 'sin_cambio'
    END AS evolucion_riesgo,

    COUNT(*) AS numero_clientes,

    ROUND(
        100.0 * COUNT(*) /
        SUM(COUNT(*)) OVER (),
        2
    ) AS porcentaje_clientes

FROM comparacion

GROUP BY evolucion_riesgo

ORDER BY
    CASE evolucion_riesgo
        WHEN 'empeora' THEN 1
        WHEN 'sin_cambio' THEN 2
        WHEN 'mejora' THEN 3
    END;


-- =========================================================
-- 14. CAMBIO DEL SCORE ENTRE PRIMERA Y ÚLTIMA EVALUACIÓN
-- =========================================================
/*
Pregunta:
¿Cuánto ha variado el score crediticio desde la primera
hasta la última evaluación?

CAST AS SIGNED es necesario porque score_crediticio es UNSIGNED
y la variación puede ser negativa.
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
),

variaciones AS (
    SELECT
        i.id_cliente,

        CAST(a.score_actual AS SIGNED)
        - CAST(i.score_inicial AS SIGNED)
            AS variacion_score

    FROM score_inicial i

    JOIN score_actual a
        ON i.id_cliente = a.id_cliente
)

SELECT
    ROUND(
        AVG(variacion_score),
        2
    ) AS variacion_media_score,

    MIN(variacion_score)
        AS mayor_deterioro_score,

    MAX(variacion_score)
        AS mayor_mejora_score,

    SUM(
        CASE
            WHEN variacion_score <= -50 THEN 1
            ELSE 0
        END
    ) AS clientes_caida_50_o_mas,

    ROUND(
        100.0 *
        SUM(
            CASE
                WHEN variacion_score <= -50 THEN 1
                ELSE 0
            END
        ) / COUNT(*),
        2
    ) AS clientes_caida_50_o_mas_pct

FROM variaciones;


-- =========================================================
-- 15. TOP 20 CLIENTES PRIORITARIOS PARA SEGUIMIENTO
-- =========================================================
/*
Resultado operativo final:
clientes con mayor riesgo y exposición dentro de la watchlist.
*/

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

FROM vw_watchlist_riesgo

ORDER BY
    tuvo_impago DESC,
    probabilidad_impago_pct DESC,
    exposicion_crediticia DESC

LIMIT 20;


-- =========================================================
-- 16. RESUMEN FINAL DE VOLUMEN DE DATOS
-- =========================================================
/*
Control final del dataset utilizado en el proyecto.
*/

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
