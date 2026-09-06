import csv
import math
import random
from datetime import date, datetime, timedelta
from pathlib import Path

SEMILLA = 42
random.seed(SEMILLA)

# El script se encuentra en /scripts y los CSV se generan en /data.
RUTA_SALIDA = Path(__file__).resolve().parent.parent / "data"
RUTA_SALIDA.mkdir(parents=True, exist_ok=True)

N_CLIENTES = 5000
FECHA_CORTE = date(2026, 6, 30)

PROVINCIAS = [
    "Madrid", "Barcelona", "Valencia", "Sevilla", "Málaga",
    "Zaragoza", "Alicante", "Murcia", "Vizcaya", "A Coruña"
]
GENEROS = ["hombre", "mujer", "otro"]
ESTADOS_CIVILES = ["soltero", "casado", "divorciado", "viudo"]
ESTUDIOS = ["secundaria", "bachillerato", "formacion_profesional", "universitario", "posgrado"]
SITUACIONES = ["empleado", "autonomo", "desempleado", "estudiante", "jubilado"]
VIVIENDAS = ["propia", "alquiler", "hipotecada", "familiar"]

def escribir_csv(nombre, cabecera, filas):
    ruta = RUTA_SALIDA / nombre
    with ruta.open("w", newline="", encoding="utf-8") as f:
        writer = csv.writer(f, lineterminator="\n")
        writer.writerow(cabecera)
        for fila in filas:
            writer.writerow([r"\N" if x is None else x for x in fila])

def fecha_aleatoria(inicio, fin):
    dias = (fin - inicio).days
    return inicio + timedelta(days=random.randint(0, dias))

def limitar(valor, minimo, maximo):
    return max(minimo, min(maximo, valor))

# -------------------------------------------------------------------
# 1. CLIENTES
# -------------------------------------------------------------------
clientes = []
perfil_cliente = {}

for id_cliente in range(1, N_CLIENTES + 1):
    edad = int(limitar(random.gauss(43, 14), 18, 82))
    nacimiento = FECHA_CORTE - timedelta(days=int(edad * 365.25 + random.randint(0, 364)))
    fecha_alta_min = max(date(2005, 1, 1), nacimiento + timedelta(days=18*365))
    fecha_alta = fecha_aleatoria(fecha_alta_min, FECHA_CORTE)

    situacion = random.choices(
        SITUACIONES,
        weights=[64, 13, 8, 6, 9],
        k=1
    )[0]

    if situacion == "empleado":
        ingresos = limitar(random.lognormvariate(math.log(2200), 0.38), 950, 9000)
        antiguedad = round(limitar(random.gauss(7, 5), 0, max(0, edad - 18)), 1)
    elif situacion == "autonomo":
        ingresos = limitar(random.lognormvariate(math.log(2700), 0.55), 800, 12000)
        antiguedad = round(limitar(random.gauss(8, 6), 0, max(0, edad - 18)), 1)
    elif situacion == "jubilado":
        ingresos = limitar(random.gauss(1750, 500), 700, 4500)
        antiguedad = None
    elif situacion == "estudiante":
        ingresos = limitar(random.gauss(650, 350), 0, 1800)
        antiguedad = 0
    else:
        ingresos = limitar(random.gauss(850, 450), 0, 2500)
        antiguedad = round(limitar(random.gauss(1.5, 2), 0, 10), 1)

    dependientes = random.choices([0,1,2,3,4], weights=[48,23,19,8,2], k=1)[0]
    estado = random.choices(["activo","inactivo","bloqueado"], weights=[94,5,1], k=1)[0]

    fila = (
        id_cliente,
        fecha_alta.isoformat(),
        nacimiento.isoformat(),
        random.choices(GENEROS, weights=[49,49,2], k=1)[0],
        random.choice(ESTADOS_CIVILES),
        random.choices(ESTUDIOS, weights=[12,16,24,34,14], k=1)[0],
        situacion,
        antiguedad,
        round(ingresos, 2),
        dependientes,
        random.choices(VIVIENDAS, weights=[28,31,30,11], k=1)[0],
        random.choice(PROVINCIAS),
        estado
    )
    clientes.append(fila)
    perfil_cliente[id_cliente] = {
        "ingresos": ingresos,
        "situacion": situacion,
        "edad": edad,
        "dependientes": dependientes,
        "fecha_alta": fecha_alta,
    }

escribir_csv(
    "clientes.csv",
    ["id_cliente","fecha_alta","fecha_nacimiento","genero","estado_civil","nivel_estudios",
     "situacion_laboral","antiguedad_laboral_anios","ingresos_mensuales","num_dependientes",
     "tipo_vivienda","provincia","estado_cliente"],
    clientes
)

# -------------------------------------------------------------------
# 2. CUENTAS
# -------------------------------------------------------------------
cuentas = []
cuentas_por_cliente = {}
saldo_inicial_por_cuenta = {}
id_cuenta = 1

for id_cliente in range(1, N_CLIENTES + 1):
    n_cuentas = random.choices([1,2,3], weights=[72,24,4], k=1)[0]
    cuentas_por_cliente[id_cliente] = []
    for _ in range(n_cuentas):
        tipo = random.choices(["corriente","ahorro"], weights=[78,22], k=1)[0]
        fecha_apertura = fecha_aleatoria(perfil_cliente[id_cliente]["fecha_alta"], FECHA_CORTE)
        ingresos = perfil_cliente[id_cliente]["ingresos"]

        if tipo == "ahorro":
            saldo = limitar(random.gauss(ingresos * 2.5, ingresos * 2.2), 0, 50000)
            descubierto = 0
        else:
            saldo = limitar(random.gauss(ingresos * 0.7, ingresos * 0.9), -1000, 20000)
            descubierto = random.choice([0, 300, 500, 1000])

        estado_cuenta = random.choices(["activa","cerrada","bloqueada"], weights=[95,4,1], k=1)[0]

        cuentas.append((
            id_cuenta, id_cliente, tipo, fecha_apertura.isoformat(),
            round(saldo,2), descubierto, estado_cuenta
        ))
        cuentas_por_cliente[id_cliente].append(id_cuenta)
        saldo_inicial_por_cuenta[id_cuenta] = saldo
        id_cuenta += 1

escribir_csv(
    "cuentas.csv",
    ["id_cuenta","id_cliente","tipo_cuenta","fecha_apertura","saldo_actual",
     "limite_descubierto","estado_cuenta"],
    cuentas
)

# -------------------------------------------------------------------
# 3. TRANSACCIONES
# -------------------------------------------------------------------
transacciones = []
id_transaccion = 1

categorias_gasto = [
    ("alimentacion", -1),
    ("vivienda", -1),
    ("transporte", -1),
    ("ocio", -1),
    ("salud", -1),
    ("restauracion", -1),
    ("compras", -1),
    ("suministros", -1)
]

cuentas_lookup = {fila[0]: fila for fila in cuentas}

for id_cta, fila_cuenta in cuentas_lookup.items():
    id_cliente = fila_cuenta[1]
    fecha_apertura = date.fromisoformat(fila_cuenta[3])
    ingresos = perfil_cliente[id_cliente]["ingresos"]
    saldo = max(0, ingresos * random.uniform(0.15, 0.8))

    inicio = max(fecha_apertura, date(2025, 7, 1))
    dias_activos = max(1, (FECHA_CORTE - inicio).days + 1)
    n_tx = max(8, int(dias_activos / 365 * random.randint(28, 60)))

    fechas = sorted(
        datetime.combine(inicio, datetime.min.time()) + timedelta(
            days=random.randint(0, dias_activos - 1),
            seconds=random.randint(0, 86399)
        )
        for _ in range(n_tx)
    )

    # Añadimos nóminas/ingresos regulares en la cuenta principal
    es_principal = cuentas_por_cliente[id_cliente][0] == id_cta
    if es_principal and perfil_cliente[id_cliente]["situacion"] in ("empleado","autonomo","jubilado"):
        mes = date(inicio.year, inicio.month, 1)
        while mes <= FECHA_CORTE:
            dia_pago = min(random.choice([1, 25, 28]), 28)
            f = datetime(mes.year, mes.month, dia_pago, 9, random.randint(0,59), 0)
            if f.date() >= inicio and f.date() <= FECHA_CORTE:
                fechas.append(f)
            if mes.month == 12:
                mes = date(mes.year + 1, 1, 1)
            else:
                mes = date(mes.year, mes.month + 1, 1)

    fechas.sort()

    for f in fechas:
        if es_principal and f.day in (1,25,28) and random.random() < 0.55:
            tipo = "ingreso"
            categoria = "nomina"
            importe = ingresos * random.uniform(0.92, 1.08)
            canal = "transferencia"
        else:
            categoria, _ = random.choice(categorias_gasto)
            tipo = "compra" if categoria not in ("vivienda","suministros") else "cargo"
            factor = {
                "alimentacion": (8, 130),
                "vivienda": (250, 1200),
                "transporte": (5, 180),
                "ocio": (8, 220),
                "salud": (10, 250),
                "restauracion": (8, 120),
                "compras": (10, 350),
                "suministros": (20, 180),
            }[categoria]
            importe = -random.uniform(*factor)
            canal = random.choices(["tarjeta","app","domiciliacion","cajero"], weights=[58,15,18,9], k=1)[0]

        saldo += importe
        transacciones.append((
            id_transaccion, id_cta, f.strftime("%Y-%m-%d %H:%M:%S"),
            tipo, categoria, round(importe,2), canal, round(saldo,2)
        ))
        id_transaccion += 1


# Eliminamos posibles transacciones con importe igual a 0.
# Esto garantiza compatibilidad con CHECK (importe <> 0) en MySQL.
transacciones = [
    t for t in transacciones
    if t[5] != 0
]

assert all(
    t[5] != 0
    for t in transacciones
), "Error: existen transacciones con importe igual a 0"


# Ajustamos saldo_actual al último saldo generado
saldo_final = {}
for t in transacciones:
    saldo_final[t[1]] = t[7]

cuentas_ajustadas = []
for c in cuentas:
    nuevo_saldo = saldo_final.get(c[0], c[4])
    cuentas_ajustadas.append((*c[:4], nuevo_saldo, *c[5:]))

cuentas = cuentas_ajustadas
escribir_csv(
    "cuentas.csv",
    ["id_cuenta","id_cliente","tipo_cuenta","fecha_apertura","saldo_actual",
     "limite_descubierto","estado_cuenta"],
    cuentas
)

escribir_csv(
    "transacciones.csv",
    ["id_transaccion","id_cuenta","fecha_transaccion","tipo_transaccion",
     "categoria","importe","canal","saldo_posterior"],
    transacciones
)

# -------------------------------------------------------------------
# 4. SOLICITUDES DE CRÉDITO
# -------------------------------------------------------------------
solicitudes = []
solicitudes_aprobadas = []
riesgo_base_cliente = {}
id_solicitud = 1

for id_cliente in range(1, N_CLIENTES + 1):
    p = perfil_cliente[id_cliente]

    factor_empleo = {
        "empleado": 45,
        "autonomo": 15,
        "jubilado": 20,
        "estudiante": -35,
        "desempleado": -80
    }[p["situacion"]]

    score_base = limitar(
        610
        + factor_empleo
        + math.log1p(max(p["ingresos"],0)) * 11
        - p["dependientes"] * 8
        + random.gauss(0, 55),
        300, 900
    )
    riesgo_base_cliente[id_cliente] = score_base

    n_solicitudes = random.choices([0,1,2,3], weights=[43,40,14,3], k=1)[0]

    for _ in range(n_solicitudes):
        fecha_sol = fecha_aleatoria(max(p["fecha_alta"], date(2023,1,1)), FECHA_CORTE)
        tipo_credito = random.choices(
            ["personal","vehiculo","hipotecario"],
            weights=[58,27,15], k=1
        )[0]

        if tipo_credito == "personal":
            importe = random.uniform(1500, 30000)
            plazo = random.choice([12,24,36,48,60])
        elif tipo_credito == "vehiculo":
            importe = random.uniform(8000, 45000)
            plazo = random.choice([36,48,60,72,84])
        else:
            importe = random.uniform(70000, 320000)
            plazo = random.choice([180,240,300,360])

        ratio = limitar(
            random.gauss(26, 13)
            + (importe / max(p["ingresos"] * 60, 1)) * 8
            + (10 if p["situacion"] == "desempleado" else 0),
            0, 95
        )

        score = int(limitar(score_base - max(0, ratio - 35) * 1.7 + random.gauss(0, 25), 250, 950))

        aprobada = (
            score >= 610
            and ratio <= 55
            and p["ingresos"] >= 900
            and not (tipo_credito == "hipotecario" and p["ingresos"] < 1800)
        )

        if aprobada:
            estado = "aprobada"
            motivo = None
        else:
            estado = "rechazada"
            if score < 610:
                motivo = "score_crediticio_bajo"
            elif ratio > 55:
                motivo = "endeudamiento_elevado"
            elif p["ingresos"] < 900:
                motivo = "ingresos_insuficientes"
            else:
                motivo = "criterios_riesgo"

        fila = (
            id_solicitud, id_cliente, fecha_sol.isoformat(), tipo_credito,
            round(importe,2), plazo,
            random.choice(["consumo","reforma","vehiculo","vivienda","liquidez"]),
            score, round(ratio,2), estado, motivo
        )
        solicitudes.append(fila)

        if aprobada:
            solicitudes_aprobadas.append(fila)

        id_solicitud += 1

escribir_csv(
    "solicitudes_credito.csv",
    ["id_solicitud","id_cliente","fecha_solicitud","tipo_credito",
     "importe_solicitado","plazo_meses","finalidad","score_solicitud",
     "ratio_endeudamiento","estado_solicitud","motivo_rechazo"],
    solicitudes
)

# -------------------------------------------------------------------
# 5. PRÉSTAMOS
# -------------------------------------------------------------------
prestamos = []
prestamo_cliente = {}
id_prestamo = 1

for s in solicitudes_aprobadas:
    id_sol, id_cliente, fecha_sol, tipo_credito, importe, plazo, _, score, ratio, _, _ = s
    fecha_concesion = date.fromisoformat(fecha_sol) + timedelta(days=random.randint(1, 12))

    if fecha_concesion > FECHA_CORTE:
        fecha_concesion = FECHA_CORTE

    tipo_interes = limitar(12.5 - (score - 550) * 0.018 + random.uniform(-0.8, 1.0), 2.2, 15.0)
    r = (tipo_interes / 100) / 12
    cuota = importe * (r * (1+r)**plazo) / ((1+r)**plazo - 1) if r > 0 else importe / plazo
    vencimiento = fecha_concesion + timedelta(days=int(plazo * 30.44))

    prestamos.append((
        id_prestamo, id_sol, fecha_concesion.isoformat(), round(importe,2),
        round(tipo_interes,2), plazo, round(cuota,2), round(importe,2),
        vencimiento.isoformat(), "activo"
    ))
    prestamo_cliente[id_prestamo] = (id_cliente, score, ratio)
    id_prestamo += 1

# -------------------------------------------------------------------
# 6. PAGOS DE PRÉSTAMO
# -------------------------------------------------------------------
pagos = []
id_pago = 1
impagos_cliente = {i: 0 for i in range(1, N_CLIENTES + 1)}
saldo_prestamo = {}
estado_prestamo = {}

for p in prestamos:
    id_pres, id_sol, fecha_conc, importe, interes, plazo, cuota, _, fecha_venc, _ = p
    id_cliente, score, ratio = prestamo_cliente[id_pres]
    fecha_conc = date.fromisoformat(fecha_conc)

    prob_retraso = limitar(
        0.04 + max(0, 680 - score) / 900 + max(0, ratio - 35) / 280,
        0.02, 0.45
    )

    saldo = importe
    estado = "activo"
    fecha_cuota = fecha_conc + timedelta(days=30)

    numero_cuota = 1
    while fecha_cuota <= FECHA_CORTE and numero_cuota <= plazo:
        u = random.random()

        if u < prob_retraso * 0.18:
            dias = random.randint(61, 150)
            if fecha_cuota + timedelta(days=dias) > FECHA_CORTE:
                fecha_pago = None
                importe_pagado = 0
                estado_pago = "impagado"
                impagos_cliente[id_cliente] += 1
                estado = "impagado"
            else:
                fecha_pago = fecha_cuota + timedelta(days=dias)
                importe_pagado = cuota
                estado_pago = "retrasado"
                impagos_cliente[id_cliente] += 1
                if estado != "impagado":
                    estado = "mora"
        elif u < prob_retraso:
            dias = random.randint(1, 60)
            if fecha_cuota + timedelta(days=dias) > FECHA_CORTE:
                fecha_pago = None
                importe_pagado = 0
                estado_pago = "pendiente"
                dias = (FECHA_CORTE - fecha_cuota).days
            else:
                fecha_pago = fecha_cuota + timedelta(days=dias)
                importe_pagado = cuota
                estado_pago = "retrasado"
                if dias > 30 and estado == "activo":
                    estado = "mora"
        else:
            dias = 0
            fecha_pago = fecha_cuota
            importe_pagado = cuota
            estado_pago = "pagado"

        pagos.append((
            id_pago, id_pres, fecha_cuota.isoformat(),
            fecha_pago.isoformat() if fecha_pago else None,
            round(cuota,2), round(importe_pagado,2), dias, estado_pago
        ))
        id_pago += 1

        if importe_pagado > 0:
            amortizacion_aprox = max(0, cuota - saldo * (interes/100/12))
            saldo = max(0, saldo - amortizacion_aprox)

        fecha_cuota += timedelta(days=30)
        numero_cuota += 1

    if saldo <= 1:
        estado = "pagado"

    saldo_prestamo[id_pres] = saldo
    estado_prestamo[id_pres] = estado

prestamos_ajustados = []
for p in prestamos:
    id_pres = p[0]
    prestamos_ajustados.append((
        *p[:7],
        round(saldo_prestamo.get(id_pres, p[7]),2),
        p[8],
        estado_prestamo.get(id_pres, p[9])
    ))
prestamos = prestamos_ajustados

escribir_csv(
    "prestamos.csv",
    ["id_prestamo","id_solicitud","fecha_concesion","importe_concedido",
     "tipo_interes","plazo_meses","cuota_mensual","saldo_pendiente",
     "fecha_vencimiento","estado_prestamo"],
    prestamos
)

escribir_csv(
    "pagos_prestamo.csv",
    ["id_pago","id_prestamo","fecha_vencimiento","fecha_pago",
     "importe_previsto","importe_pagado","dias_retraso","estado_pago"],
    pagos
)

# -------------------------------------------------------------------
# 7. EVALUACIONES DE RIESGO
# -------------------------------------------------------------------
evaluaciones = []
id_eval = 1
fechas_eval = [date(2025,9,30), date(2025,12,31), date(2026,3,31), date(2026,6,30)]

for id_cliente in range(1, N_CLIENTES + 1):
    p = perfil_cliente[id_cliente]
    base = riesgo_base_cliente[id_cliente]
    impagos = impagos_cliente[id_cliente]

    for i, f_eval in enumerate(fechas_eval):
        if f_eval < p["fecha_alta"]:
            continue

        deterioro = impagos * random.uniform(8, 18) * ((i + 1) / len(fechas_eval))
        score = int(limitar(base - deterioro + random.gauss(0,18), 250, 950))
        deuda = max(0, p["ingresos"] * random.uniform(0, 18) + impagos * p["ingresos"] * 2)
        ratio = limitar((deuda / max(p["ingresos"] * 12, 1)) * 100, 0, 120)
        utilizacion = limitar(random.gauss(35,22) + impagos*9 + max(0,650-score)/12, 0, 120)

        pd = 1 / (1 + math.exp((score - 610) / 55))
        pd = limitar(pd + impagos * 0.025 + max(0,ratio-45)/500, 0.001, 0.95)

        if pd < 0.08:
            nivel = "bajo"
        elif pd < 0.22:
            nivel = "medio"
        else:
            nivel = "alto"

        evaluaciones.append((
            id_eval, id_cliente, f_eval.isoformat(), score,
            round(p["ingresos"],2), round(deuda,2), round(ratio,2),
            min(255, impagos), round(utilizacion,2), nivel, round(pd,5)
        ))
        id_eval += 1

escribir_csv(
    "evaluaciones_riesgo.csv",
    ["id_evaluacion","id_cliente","fecha_evaluacion","score_crediticio",
     "ingresos_mensuales","deuda_total","ratio_endeudamiento",
     "num_impagos_12m","utilizacion_credito_pct","nivel_riesgo",
     "probabilidad_impago"],
    evaluaciones
)

print("Datos generados correctamente.")
print(f"Directorio de salida: {RUTA_SALIDA}")
print(f"Clientes: {len(clientes):,}")
print(f"Cuentas: {len(cuentas):,}")
print(f"Transacciones: {len(transacciones):,}")
print(f"Solicitudes: {len(solicitudes):,}")
print(f"Prestamos: {len(prestamos):,}")
print(f"Pagos: {len(pagos):,}")
print(f"Evaluaciones: {len(evaluaciones):,}")
