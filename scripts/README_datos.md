# Generación de datos sintéticos

Este proyecto utiliza un dataset bancario **completamente sintético** generado con Python. No contiene información personal ni bancaria real.

## Estructura esperada

El generador está preparado para utilizar la siguiente estructura:

```text
banking-credit-risk-sql/
├── data/
├── scripts/
│   ├── generar_datos.py
│   ├── cargar_datos.sql
│   └── README_datos.md
└── sql/
    └── 00_creacion_base_datos.sql
```

Los archivos CSV se generan automáticamente dentro de la carpeta `data/`.

## Cómo generar los datos

Desde la raíz del proyecto, ejecuta:

```bash
python scripts/generar_datos.py
```

También puedes ejecutar `generar_datos.py` directamente desde tu editor de Python.

El script utiliza una semilla fija:

```python
SEMILLA = 42
```

Esto permite reproducir el dataset utilizado en el proyecto.

## Archivos generados

El script crea los siguientes CSV dentro de `data/`:

```text
data/
├── clientes.csv
├── cuentas.csv
├── transacciones.csv
├── solicitudes_credito.csv
├── prestamos.csv
├── pagos_prestamo.csv
└── evaluaciones_riesgo.csv
```

Con la configuración utilizada en el proyecto, el dataset final contiene:

| Tabla | Registros |
|---|---:|
| `clientes` | 5.000 |
| `cuentas` | 6.614 |
| `transacciones` | 288.942 |
| `solicitudes_credito` | 3.839 |
| `prestamos` | 3.027 |
| `pagos_prestamo` | 49.086 |
| `evaluaciones_riesgo` | 19.061 |

## Control de integridad de las transacciones

La tabla MySQL `transacciones` incluye la restricción:

```sql
CHECK (importe <> 0)
```

El generador elimina automáticamente cualquier transacción sintética cuyo importe sea igual a `0` antes de escribir el CSV y realiza una comprobación adicional mediante `assert`.

De esta forma, `transacciones.csv` puede cargarse directamente respetando la restricción definida en el modelo relacional.

## Carga en MySQL

1. Ejecuta primero:

```text
sql/00_creacion_base_datos.sql
```

Esto crea la base de datos `banca_riesgo_crediticio` y sus siete tablas.

2. Genera los CSV:

```bash
python scripts/generar_datos.py
```

3. Revisa las rutas de los archivos en:

```text
scripts/cargar_datos.sql
```

`LOAD DATA LOCAL INFILE` puede necesitar rutas absolutas dependiendo de la configuración local de MySQL.

4. Si MySQL tiene deshabilitada la carga de archivos locales, puede ser necesario habilitar:

```sql
SET GLOBAL local_infile = 1;
```

y permitir `LOCAL INFILE` en la configuración de la conexión de MySQL Workbench.

5. Ejecuta `cargar_datos.sql`.

## Convenciones

En `transacciones.csv`:

- un importe positivo representa una entrada de dinero;
- un importe negativo representa una salida de dinero;
- no se permiten importes iguales a cero.

Los valores nulos se escriben como:

```text
\N
```

para facilitar su carga en MySQL.

## Nota metodológica

Los datos han sido diseñados con fines educativos y de portfolio para simular una cartera bancaria realista.

Las probabilidades de impago, scores y niveles de riesgo son variables sintéticas y no representan modelos regulatorios ni estimaciones de una entidad financiera real.