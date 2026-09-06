USE banca_riesgo_crediticio;

/*
1. ¿Cuántas solicitudes de crédito se han realizado?
*/

SELECT
    COUNT(*) AS total_solicitudes
FROM solicitudes_credito;

	/*
2. ¿Cuál es la distribución de solicitudes por estado?
*/

SELECT
    estado_solicitud,
    COUNT(*) AS numero_solicitudes,
    ROUND(
        COUNT(*) * 100.0 /
        (SELECT COUNT(*) FROM solicitudes_credito),
        2
    ) AS porcentaje
FROM solicitudes_credito
GROUP BY estado_solicitud
ORDER BY numero_solicitudes DESC;


/*
3. ¿Cuál es la tasa global de aprobación de créditos?
*/

SELECT
    COUNT(*) AS total_solicitudes,

    SUM(
        CASE
            WHEN estado_solicitud = 'aprobada' THEN 1
            ELSE 0
        END
    ) AS solicitudes_aprobadas,

    ROUND(
        100.0 *
        SUM(
            CASE
                WHEN estado_solicitud = 'aprobada' THEN 1
                ELSE 0
            END
        ) / COUNT(*),
        2
    ) AS tasa_aprobacion_pct

FROM solicitudes_credito;


/*
4. ¿Qué tipos de crédito se solicitan con mayor frecuencia?
*/

SELECT
    tipo_credito,
    COUNT(*) AS numero_solicitudes,
    ROUND(AVG(importe_solicitado), 2) AS importe_medio_solicitado,
    ROUND(SUM(importe_solicitado), 2) AS importe_total_solicitado
FROM solicitudes_credito
GROUP BY tipo_credito
ORDER BY numero_solicitudes DESC;


/*
5. ¿Qué tipo de crédito presenta mayor tasa de aprobación?
*/

SELECT
    tipo_credito,
    COUNT(*) AS total_solicitudes,

    SUM(
        CASE
            WHEN estado_solicitud = 'aprobada' THEN 1
            ELSE 0
        END
    ) AS aprobadas,

    ROUND(
        100.0 *
        SUM(
            CASE
                WHEN estado_solicitud = 'aprobada' THEN 1
                ELSE 0
            END
        ) / COUNT(*),
        2
    ) AS tasa_aprobacion_pct

FROM solicitudes_credito
GROUP BY tipo_credito
ORDER BY tasa_aprobacion_pct DESC;

/*
6. ¿Cuáles son los principales motivos de rechazo?
*/

SELECT
    motivo_rechazo,
    COUNT(*) AS numero_rechazos,
    ROUND(
        COUNT(*) * 100.0 /
        (
            SELECT COUNT(*)
            FROM solicitudes_credito
            WHERE estado_solicitud = 'rechazada'
        ),
        2
    ) AS porcentaje_rechazos
FROM solicitudes_credito
WHERE estado_solicitud = 'rechazada'
GROUP BY motivo_rechazo
ORDER BY numero_rechazos DESC;


/*
7. ¿Cómo cambia la aprobación según el score crediticio?
*/

SELECT
    CASE
        WHEN score_solicitud < 550 THEN 'menos_de_550'
        WHEN score_solicitud < 650 THEN '550-649'
        WHEN score_solicitud < 750 THEN '650-749'
        ELSE '750_o_mas'
    END AS rango_score,

    COUNT(*) AS solicitudes,

    ROUND(AVG(score_solicitud), 2) AS score_medio,

    ROUND(
        100.0 *
        SUM(
            CASE
                WHEN estado_solicitud = 'aprobada' THEN 1
                ELSE 0
            END
        ) / COUNT(*),
        2
    ) AS tasa_aprobacion_pct

FROM solicitudes_credito
GROUP BY rango_score
ORDER BY score_medio;


/*
8. ¿Cómo afecta el ratio de endeudamiento a la aprobación?
*/

SELECT
    CASE
        WHEN ratio_endeudamiento < 20 THEN 'menos_20'
        WHEN ratio_endeudamiento < 35 THEN '20-34'
        WHEN ratio_endeudamiento < 50 THEN '35-49'
        ELSE '50_o_mas'
    END AS nivel_endeudamiento,

    COUNT(*) AS solicitudes,

    ROUND(AVG(ratio_endeudamiento), 2) AS endeudamiento_medio,

    ROUND(
        100.0 *
        SUM(
            CASE
                WHEN estado_solicitud = 'aprobada' THEN 1
                ELSE 0
            END
        ) / COUNT(*),
        2
    ) AS tasa_aprobacion_pct

FROM solicitudes_credito
GROUP BY nivel_endeudamiento
ORDER BY endeudamiento_medio;

/*
9. ¿Qué situaciones laborales tienen mayor tasa de aprobación?
*/

SELECT
    c.situacion_laboral,
    COUNT(s.id_solicitud) AS solicitudes,

    ROUND(
        AVG(s.importe_solicitado),
        2
    ) AS importe_medio_solicitado,

    ROUND(
        100.0 *
        SUM(
            CASE
                WHEN s.estado_solicitud = 'aprobada' THEN 1
                ELSE 0
            END
        ) / COUNT(s.id_solicitud),
        2
    ) AS tasa_aprobacion_pct

FROM clientes c
JOIN solicitudes_credito s
    ON c.id_cliente = s.id_cliente

GROUP BY c.situacion_laboral
ORDER BY tasa_aprobacion_pct DESC;


/*
10. ¿Cómo afecta el nivel de ingresos a la aprobación?
*/

SELECT
    CASE
        WHEN c.ingresos_mensuales < 1500 THEN 'bajos'
        WHEN c.ingresos_mensuales < 3000 THEN 'medios'
        WHEN c.ingresos_mensuales < 5000 THEN 'altos'
        ELSE 'muy_altos'
    END AS segmento_ingresos,

    COUNT(s.id_solicitud) AS solicitudes,

    ROUND(
        AVG(c.ingresos_mensuales),
        2
    ) AS ingresos_medios,

    ROUND(
        100.0 *
        SUM(
            CASE
                WHEN s.estado_solicitud = 'aprobada' THEN 1
                ELSE 0
            END
        ) / COUNT(s.id_solicitud),
        2
    ) AS tasa_aprobacion_pct

FROM clientes c
JOIN solicitudes_credito s
    ON c.id_cliente = s.id_cliente

GROUP BY segmento_ingresos
ORDER BY ingresos_medios;


/*
11. ¿Cuánto capital ha concedido el banco?
*/

SELECT
    COUNT(*) AS numero_prestamos,
    ROUND(SUM(importe_concedido), 2) AS capital_total_concedido,
    ROUND(AVG(importe_concedido), 2) AS importe_medio,
    ROUND(AVG(tipo_interes), 2) AS interes_medio
FROM prestamos;


/*
12. ¿Cuánto capital se ha concedido por tipo de crédito?
*/

SELECT
    s.tipo_credito,
    COUNT(p.id_prestamo) AS numero_prestamos,
    ROUND(SUM(p.importe_concedido), 2) AS capital_concedido,
    ROUND(AVG(p.importe_concedido), 2) AS importe_medio,
    ROUND(AVG(p.tipo_interes), 2) AS interes_medio
FROM solicitudes_credito s
JOIN prestamos p
    ON s.id_solicitud = p.id_solicitud
GROUP BY s.tipo_credito
ORDER BY capital_concedido DESC;


/*
13. ¿Qué relación existe entre score crediticio y tipo de interés?
*/

SELECT
    CASE
        WHEN s.score_solicitud < 650 THEN 'menos_de_650'
        WHEN s.score_solicitud < 700 THEN '650-699'
        WHEN s.score_solicitud < 750 THEN '700-749'
        ELSE '750_o_mas'
    END AS rango_score,

    COUNT(*) AS numero_prestamos,

    ROUND(AVG(s.score_solicitud), 2) AS score_medio,

    ROUND(AVG(p.tipo_interes), 2) AS interes_medio

FROM solicitudes_credito s
JOIN prestamos p
    ON s.id_solicitud = p.id_solicitud

GROUP BY rango_score
ORDER BY score_medio;


/*
14. ¿Qué clientes tienen más de un préstamo?
*/

SELECT
    c.id_cliente,
    c.situacion_laboral,
    c.ingresos_mensuales,

    COUNT(p.id_prestamo) AS numero_prestamos,

    ROUND(
        SUM(p.importe_concedido),
        2
    ) AS capital_total_concedido

FROM clientes c
JOIN solicitudes_credito s
    ON c.id_cliente = s.id_cliente
JOIN prestamos p
    ON s.id_solicitud = p.id_solicitud

GROUP BY
    c.id_cliente,
    c.situacion_laboral,
    c.ingresos_mensuales

HAVING COUNT(p.id_prestamo) > 1

ORDER BY numero_prestamos DESC,
         capital_total_concedido DESC;
         
         
         
         /*
15. ¿Qué peso tiene la cuota del préstamo sobre los ingresos mensuales?
*/

SELECT
    c.id_cliente,
    p.id_prestamo,

    c.ingresos_mensuales,
    p.cuota_mensual,

    ROUND(
        p.cuota_mensual /
        NULLIF(c.ingresos_mensuales, 0) * 100,
        2
    ) AS cuota_sobre_ingresos_pct

FROM clientes c
JOIN solicitudes_credito s
    ON c.id_cliente = s.id_cliente
JOIN prestamos p
    ON s.id_solicitud = p.id_solicitud

WHERE c.ingresos_mensuales > 0

ORDER BY cuota_sobre_ingresos_pct DESC;


/*
16. ¿Qué clientes destinan más del 40% de sus ingresos a cuotas?
*/

SELECT
    c.id_cliente,

    c.ingresos_mensuales,

    COUNT(p.id_prestamo) AS numero_prestamos,

    ROUND(
        SUM(p.cuota_mensual),
        2
    ) AS cuotas_mensuales_totales,

    ROUND(
        SUM(p.cuota_mensual) /
        NULLIF(c.ingresos_mensuales, 0) * 100,
        2
    ) AS carga_crediticia_pct

FROM clientes c
JOIN solicitudes_credito s
    ON c.id_cliente = s.id_cliente
JOIN prestamos p
    ON s.id_solicitud = p.id_solicitud

WHERE p.estado_prestamo IN ('activo', 'mora', 'impagado')

GROUP BY
    c.id_cliente,
    c.ingresos_mensuales

HAVING
    SUM(p.cuota_mensual) /
    NULLIF(c.ingresos_mensuales, 0) > 0.40

ORDER BY carga_crediticia_pct DESC;


/*
17. ¿Cuánto capital queda pendiente de devolución?
*/

SELECT
    estado_prestamo,
    COUNT(*) AS numero_prestamos,

    ROUND(
        SUM(saldo_pendiente),
        2
    ) AS saldo_pendiente_total,

    ROUND(
        AVG(saldo_pendiente),
        2
    ) AS saldo_pendiente_medio

FROM prestamos
GROUP BY estado_prestamo
ORDER BY saldo_pendiente_total DESC;


/*
18. ¿Qué clientes tienen mayor exposición crediticia pendiente?
*/

SELECT
    c.id_cliente,
    c.situacion_laboral,
    c.ingresos_mensuales,

    COUNT(p.id_prestamo) AS numero_prestamos,

    ROUND(
        SUM(p.saldo_pendiente),
        2
    ) AS exposicion_crediticia,

    ROUND(
        SUM(p.saldo_pendiente) /
        NULLIF(c.ingresos_mensuales * 12, 0),
        2
    ) AS exposicion_sobre_ingresos_anuales

FROM clientes c
JOIN solicitudes_credito s
    ON c.id_cliente = s.id_cliente
JOIN prestamos p
    ON s.id_solicitud = p.id_solicitud

WHERE p.estado_prestamo IN ('activo', 'mora', 'impagado')

GROUP BY
    c.id_cliente,
    c.situacion_laboral,
    c.ingresos_mensuales

ORDER BY exposicion_crediticia DESC
LIMIT 20;


