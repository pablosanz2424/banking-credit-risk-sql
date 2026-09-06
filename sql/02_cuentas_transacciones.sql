USE banca_riesgo_crediticio;

/*
1. ¿Cómo se distribuyen las cuentas por tipo?
*/

SELECT
    tipo_cuenta,
    COUNT(*) AS numero_cuentas,
    ROUND(
        COUNT(*) * 100.0 / (SELECT COUNT(*) FROM cuentas),
        2
    ) AS porcentaje_total
FROM cuentas
GROUP BY tipo_cuenta
ORDER BY numero_cuentas DESC;


/*
2. ¿Cuál es el saldo medio según el tipo de cuenta?
*/

SELECT
    tipo_cuenta,
    COUNT(*) AS numero_cuentas,
    ROUND(AVG(saldo_actual), 2) AS saldo_medio,
    ROUND(MIN(saldo_actual), 2) AS saldo_minimo,
    ROUND(MAX(saldo_actual), 2) AS saldo_maximo
FROM cuentas
GROUP BY tipo_cuenta
ORDER BY saldo_medio DESC;


/*
3. ¿Cuántas cuentas tiene cada cliente?
*/

SELECT
    c.id_cliente,
    COUNT(cu.id_cuenta) AS numero_cuentas
FROM clientes c
JOIN cuentas cu
    ON c.id_cliente = cu.id_cliente
GROUP BY c.id_cliente
ORDER BY numero_cuentas DESC;



/*
4. ¿Cuál es el número medio de cuentas por cliente?
*/

SELECT
    ROUND(AVG(numero_cuentas), 2) AS cuentas_medias_por_cliente
FROM (
    SELECT
        id_cliente,
        COUNT(*) AS numero_cuentas
    FROM cuentas
    GROUP BY id_cliente
) AS cuentas_cliente;


/*
5. ¿Qué clientes tienen mayor saldo total?
*/

SELECT
    c.id_cliente,
    c.situacion_laboral,
    c.ingresos_mensuales,
    COUNT(cu.id_cuenta) AS numero_cuentas,
    ROUND(SUM(cu.saldo_actual), 2) AS saldo_total
FROM clientes c
JOIN cuentas cu
    ON c.id_cliente = cu.id_cliente
GROUP BY
    c.id_cliente,
    c.situacion_laboral,
    c.ingresos_mensuales
ORDER BY saldo_total DESC
LIMIT 20;

/*
6. ¿Qué tipos de transacciones son los más frecuentes?
*/

SELECT
    tipo_transaccion,
    COUNT(*) AS numero_transacciones,
    ROUND(AVG(ABS(importe)), 2) AS importe_medio
FROM transacciones
GROUP BY tipo_transaccion
ORDER BY numero_transacciones DESC;

/*
7. ¿Cuánto dinero entra y sale de las cuentas cada mes?
*/

SELECT
    DATE_FORMAT(fecha_transaccion, '%Y-%m') AS mes,

    ROUND(
        SUM(
            CASE
                WHEN importe > 0 THEN importe
                ELSE 0
            END
        ),
        2
    ) AS ingresos,

    ROUND(
        ABS(
            SUM(
                CASE
                    WHEN importe < 0 THEN importe
                    ELSE 0
                END
            )
        ),
        2
    ) AS gastos,

    ROUND(SUM(importe), 2) AS flujo_neto

FROM transacciones
GROUP BY mes
ORDER BY mes;


/*
8. ¿En qué categorías gastan más los clientes?
*/

SELECT
    categoria,
    COUNT(*) AS numero_transacciones,
    ROUND(SUM(ABS(importe)), 2) AS gasto_total,
    ROUND(AVG(ABS(importe)), 2) AS gasto_medio
FROM transacciones
WHERE importe < 0
GROUP BY categoria
ORDER BY gasto_total DESC;

/*
9. ¿Qué canales utilizan más los clientes?
*/

SELECT
    canal,
    COUNT(*) AS numero_transacciones,
    ROUND(
        COUNT(*) * 100.0 / (SELECT COUNT(*) FROM transacciones),
        2
    ) AS porcentaje_total
FROM transacciones
GROUP BY canal
ORDER BY numero_transacciones DESC;


/*
10. ¿Qué cuentas tienen mayor número de transacciones?
*/

SELECT
    c.id_cuenta,
    c.id_cliente,
    c.tipo_cuenta,
    COUNT(t.id_transaccion) AS numero_transacciones
FROM cuentas c
JOIN transacciones t
    ON c.id_cuenta = t.id_cuenta
GROUP BY
    c.id_cuenta,
    c.id_cliente,
    c.tipo_cuenta
ORDER BY numero_transacciones DESC
LIMIT 20;

/*
11. ¿Qué clientes han gastado más dinero?
*/

SELECT
    c.id_cliente,
    c.situacion_laboral,
    c.ingresos_mensuales,
    ROUND(SUM(ABS(t.importe)), 2) AS gasto_total
FROM clientes c
JOIN cuentas cu
    ON c.id_cliente = cu.id_cliente
JOIN transacciones t
    ON cu.id_cuenta = t.id_cuenta
WHERE t.importe < 0
GROUP BY
    c.id_cliente,
    c.situacion_laboral,
    c.ingresos_mensuales
ORDER BY gasto_total DESC
LIMIT 20;

/*
12. ¿Qué clientes presentan un flujo de dinero negativo?
*/

SELECT
    c.id_cliente,

    ROUND(
        SUM(
            CASE
                WHEN t.importe > 0 THEN t.importe
                ELSE 0
            END
        ),
        2
    ) AS ingresos_totales,

    ROUND(
        ABS(
            SUM(
                CASE
                    WHEN t.importe < 0 THEN t.importe
                    ELSE 0
                END
            )
        ),
        2
    ) AS gastos_totales,

    ROUND(SUM(t.importe), 2) AS flujo_neto

FROM clientes c
JOIN cuentas cu
    ON c.id_cliente = cu.id_cliente
JOIN transacciones t
    ON cu.id_cuenta = t.id_cuenta

GROUP BY c.id_cliente

HAVING SUM(t.importe) < 0

ORDER BY flujo_neto ASC;


/*
13. ¿Qué clientes tienen mayor gasto respecto a sus ingresos?
*/

SELECT
    c.id_cliente,
    c.ingresos_mensuales,

    ROUND(SUM(ABS(t.importe)), 2) AS gasto_total,

    ROUND(
        SUM(ABS(t.importe)) / NULLIF(c.ingresos_mensuales, 0),
        2
    ) AS ratio_gasto_ingreso

FROM clientes c
JOIN cuentas cu
    ON c.id_cliente = cu.id_cliente
JOIN transacciones t
    ON cu.id_cuenta = t.id_cuenta

WHERE t.importe < 0

GROUP BY
    c.id_cliente,
    c.ingresos_mensuales

HAVING c.ingresos_mensuales > 0

ORDER BY ratio_gasto_ingreso DESC
LIMIT 20;


/*
14. ¿Cuántas cuentas tienen saldo negativo?
*/

SELECT
    COUNT(*) AS cuentas_saldo_negativo,
    ROUND(SUM(ABS(saldo_actual)), 2) AS descubierto_total,
    ROUND(AVG(ABS(saldo_actual)), 2) AS descubierto_medio
FROM cuentas
WHERE saldo_actual < 0;


/*
15. ¿Qué cuentas han superado su límite de descubierto?
*/

SELECT
    id_cuenta,
    id_cliente,
    saldo_actual,
    limite_descubierto,
    ROUND(
        ABS(saldo_actual) - limite_descubierto,
        2
    ) AS exceso_descubierto
FROM cuentas
WHERE saldo_actual < -limite_descubierto
ORDER BY exceso_descubierto DESC;