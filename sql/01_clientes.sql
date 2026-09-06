USE banca_riesgo_crediticio;

/*
1.¿cuántos clientes están activos, inactivos o bloqueados?
*/
SELECT
    estado_cliente,
    COUNT(*) AS numero_clientes
FROM clientes
GROUP BY estado_cliente
ORDER BY numero_clientes DESC;


/*
2.¿Cuál es la edad de nuestra cartera de clientes?
*/
SELECT
    MIN(TIMESTAMPDIFF(YEAR, fecha_nacimiento, '2026-06-30')) AS edad_minima,
    ROUND(AVG(TIMESTAMPDIFF(YEAR, fecha_nacimiento, '2026-06-30')), 2) AS edad_media,
    MAX(TIMESTAMPDIFF(YEAR, fecha_nacimiento, '2026-06-30')) AS edad_maxima
FROM clientes;

/*
3.¿Cómo se distribuyen los clientes por grupos de edad?
*/

SELECT
    CASE
        WHEN TIMESTAMPDIFF(YEAR, fecha_nacimiento, '2026-06-30') < 30
            THEN '18-29'
        WHEN TIMESTAMPDIFF(YEAR, fecha_nacimiento, '2026-06-30') < 40
            THEN '30-39'
        WHEN TIMESTAMPDIFF(YEAR, fecha_nacimiento, '2026-06-30') < 50
            THEN '40-49'
        WHEN TIMESTAMPDIFF(YEAR, fecha_nacimiento, '2026-06-30') < 60
            THEN '50-59'
        ELSE '60+'
    END AS grupo_edad,
    COUNT(*) AS numero_clientes
FROM clientes
GROUP BY grupo_edad
ORDER BY MIN(TIMESTAMPDIFF(YEAR, fecha_nacimiento, '2026-06-30'));

/*
4.¿Cuál es la situación laboral de los clientes?
*/
SELECT
    situacion_laboral,
    COUNT(*) AS numero_clientes,
    ROUND(COUNT(*) * 100.0 / (SELECT COUNT(*) FROM clientes), 2) AS porcentaje_clientes
FROM clientes
GROUP BY situacion_laboral
ORDER BY numero_clientes DESC;



/*
5.¿Qué perfiles laborales tienen mayores ingresos?
*/

SELECT
    situacion_laboral,
    COUNT(*) AS numero_clientes,
    ROUND(AVG(ingresos_mensuales), 2) AS ingresos_medios,
    ROUND(MIN(ingresos_mensuales), 2) AS ingresos_minimos,
    ROUND(MAX(ingresos_mensuales), 2) AS ingresos_maximos
FROM clientes
GROUP BY situacion_laboral
ORDER BY ingresos_medios DESC;


/*

*/


/*
6.¿En qué provincias tenemos más clientes?
*/

SELECT
    provincia,
    COUNT(*) AS numero_clientes,
    ROUND(
        COUNT(*) * 100.0 / (SELECT COUNT(*) FROM clientes),
        2
    ) AS porcentaje_total
FROM clientes
GROUP BY provincia
ORDER BY numero_clientes DESC;

/*
7.¿Cómo se distribuyen los clientes según su vivienda?
*/

SELECT
    tipo_vivienda,
    COUNT(*) AS numero_clientes,
    ROUND(AVG(ingresos_mensuales), 2) AS ingresos_medios,
    ROUND(AVG(num_dependientes), 2) AS dependientes_medios
FROM clientes
GROUP BY tipo_vivienda
ORDER BY ingresos_medios DESC;

/*
8.Crear segmentos económicos
*/

SELECT
    CASE
        WHEN ingresos_mensuales < 1500 THEN 'bajos'
        WHEN ingresos_mensuales < 3000 THEN 'medios'
        WHEN ingresos_mensuales < 5000 THEN 'altos'
        ELSE 'muy_altos'
    END AS segmento_ingresos,

    COUNT(*) AS numero_clientes,

    ROUND(
        COUNT(*) * 100.0 / (SELECT COUNT(*) FROM clientes),
        2
    ) AS porcentaje_clientes,

    ROUND(AVG(ingresos_mensuales), 2) AS ingreso_medio

FROM clientes
GROUP BY segmento_ingresos
ORDER BY ingreso_medio;


/*
9.¿Cómo afectan las cargas familiares a los ingresos?
*/

SELECT
    num_dependientes,
    COUNT(*) AS numero_clientes,
    ROUND(AVG(ingresos_mensuales), 2) AS ingresos_medios
FROM clientes
GROUP BY num_dependientes
ORDER BY num_dependientes;

/*
10. Clientes con ingresos superiores a la media
*/

SELECT
    id_cliente,
    ingresos_mensuales,
    situacion_laboral,
    provincia,
    tipo_vivienda
FROM clientes
WHERE ingresos_mensuales > (
    SELECT AVG(ingresos_mensuales)
    FROM clientes
)
ORDER BY ingresos_mensuales DESC;

/*
11.Segmentos interesantes para negocio
*/
SELECT
    situacion_laboral,
    tipo_vivienda,
    COUNT(*) AS numero_clientes,
    ROUND(AVG(ingresos_mensuales), 2) AS ingresos_medios,
    ROUND(AVG(num_dependientes), 2) AS dependientes_medios
FROM clientes
WHERE estado_cliente = 'activo'
GROUP BY
    situacion_laboral,
    tipo_vivienda
HAVING COUNT(*) >= 50
ORDER BY ingresos_medios DESC;
