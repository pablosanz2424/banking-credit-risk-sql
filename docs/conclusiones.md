# Conclusiones del análisis

Este documento resume los principales resultados obtenidos en el proyecto **Banking Customer & Credit Risk Analytics — MySQL**.

Los datos utilizados son completamente sintéticos y las conclusiones deben interpretarse dentro del contexto analítico del proyecto.

---

## 1. Resumen ejecutivo

El análisis se ha realizado sobre una base de datos de **375.569 registros**, formada por:

| Tabla | Registros |
|---|---:|
| `clientes` | 5.000 |
| `cuentas` | 6.614 |
| `transacciones` | 288.942 |
| `solicitudes_credito` | 3.839 |
| `prestamos` | 3.027 |
| `pagos_prestamo` | 49.086 |
| `evaluaciones_riesgo` | 19.061 |

La cartera presenta una tasa de aprobación de crédito del **78,85 %**, con **3.027 préstamos concedidos** y un capital total concedido de aproximadamente **115,0 millones**.

La exposición pendiente asciende a aproximadamente **92,6 millones**, equivalente a alrededor del **80,5 %** del capital inicialmente concedido.

Según las definiciones analíticas utilizadas en el proyecto, el **34,79 % de los préstamos** ha registrado al menos una situación de mora superior a 30 días, mientras que el **2,64 %** ha registrado al menos un impago.

---

## 2. Solicitudes y concesión de crédito

Se registraron **3.839 solicitudes de crédito**:

- **3.027 aprobadas**
- **812 rechazadas**
- **78,85 % de tasa de aprobación**
- **46.778,69** de importe medio solicitado

El número de solicitudes aprobadas coincide con el número de préstamos registrados, lo que confirma la coherencia entre ambas tablas dentro del dataset.

---

## 3. Tamaño y situación de la cartera

La cartera contiene:

- **3.027 préstamos**
- **115.012.418,52** de capital total concedido
- aproximadamente **92,6 millones** de exposición pendiente
- **9,41 %** de tipo de interés medio

En términos de comportamiento de pago:

- **1.053 préstamos** registraron al menos una cuota con más de 30 días de retraso
- **80 préstamos** registraron al menos un impago
- tasa de mora por préstamo: **34,79 %**
- tasa de impago por préstamo: **2,64 %**

La elevada diferencia entre mora e impago muestra que una parte importante de los retrasos no termina necesariamente en default.

---

## 4. Perfil de riesgo actual

En la última evaluación disponible se analizaron los **5.000 clientes**.

Los principales indicadores fueron:

- score crediticio medio: **708,88**
- probabilidad de impago media: **26,74 %**
- clientes clasificados como riesgo alto: **2.469**
- porcentaje de clientes de riesgo alto: **49,38 %**

La probabilidad de impago es una variable sintética de riesgo y no debe interpretarse como una probabilidad calibrada frente a la tasa histórica de default sin realizar una validación temporal específica.

---

## 5. Exposición por nivel de riesgo

Entre los clientes con exposición crediticia pendiente:

| Riesgo | Clientes | Score medio | PD media | Exposición | % exposición |
|---|---:|---:|---:|---:|---:|
| Bajo | 306 | 790,53 | 4,91 % | 14.163.000,99 | 15,29 % |
| Medio | 872 | 748,85 | 15,40 % | 38.533.831,36 | 41,60 % |
| Alto | 899 | 680,30 | 34,81 % | 39.930.433,66 | 43,11 % |

El **84,71 % de la exposición** se concentra en clientes clasificados como riesgo medio o alto.

Sin embargo, la exposición media por cliente es relativamente similar entre los tres segmentos. Por tanto, la elevada exposición de los grupos medio y alto se explica principalmente por el número de clientes incluidos en estos segmentos y no por préstamos individualmente mucho mayores.

---

## 6. Relación entre score crediticio e impago

La tasa de impago por rango de score inicial fue:

| Score inicial | Préstamos | Impagos | Tasa de impago |
|---|---:|---:|---:|
| < 650 | 288 | 21 | 7,29 % |
| 650–699 | 702 | 14 | 1,99 % |
| 700–749 | 993 | 25 | 2,52 % |
| >= 750 | 1.044 | 20 | 1,92 % |

El segmento con score inferior a 650 presenta una tasa de impago claramente superior al resto.

A partir de 650, las tasas se sitúan aproximadamente entre el 1,9 % y el 2,5 %, por lo que la relación no es estrictamente monotónica en todos los intervalos.

La principal señal observable es, por tanto, la concentración de riesgo en el tramo de score más bajo.

---

## 7. Endeudamiento e impago

La relación entre ratio de endeudamiento e impago resulta especialmente clara:

| Endeudamiento | Préstamos | Impagos | Tasa de impago |
|---|---:|---:|---:|
| < 20 | 826 | 18 | 2,18 % |
| 20–34 | 1.330 | 24 | 1,80 % |
| 35–49 | 789 | 32 | 4,06 % |
| >= 50 | 82 | 6 | 7,32 % |

Los clientes con un ratio de endeudamiento igual o superior a 50 presentan una tasa de impago del **7,32 %**, más de tres veces superior a la observada en los segmentos con menor endeudamiento.

El aumento del riesgo se vuelve especialmente visible a partir del tramo **35–49**.

Este resultado convierte al ratio de endeudamiento en una de las variables más relevantes del análisis.

---

## 8. Situación laboral e impago

La tasa de impago por situación laboral fue:

| Situación laboral | Préstamos | Impagos | Tasa de impago |
|---|---:|---:|---:|
| Desempleado | 35 | 2 | 5,71 % |
| Empleado | 2.226 | 62 | 2,79 % |
| Estudiante | 37 | 1 | 2,70 % |
| Jubilado | 287 | 6 | 2,09 % |
| Autónomo | 442 | 9 | 2,04 % |

El grupo de desempleados presenta la mayor tasa de impago, con **5,71 %**.

No obstante, este resultado debe interpretarse con cautela debido a que únicamente existen **35 préstamos** en dicho segmento. El reducido tamaño de muestra hace que unos pocos impagos tengan un efecto elevado sobre la tasa observada.

---

## 9. Evolución temporal del riesgo

La evolución agregada del riesgo fue:

| Fecha | Score medio | PD media | Clientes alto riesgo |
|---|---:|---:|---:|
| 2025-09-30 | 710,65 | 26,53 % | 47,99 % |
| 2025-12-31 | 709,90 | 26,34 % | 47,80 % |
| 2026-03-31 | 709,62 | 26,58 % | 50,28 % |
| 2026-06-30 | 708,88 | 26,74 % | 49,38 % |

La cartera se mantiene relativamente estable, aunque se observa un ligero deterioro entre la primera y la última fecha:

- el score medio disminuye aproximadamente **1,77 puntos**
- la probabilidad media de impago aumenta **0,21 puntos porcentuales**
- el porcentaje de clientes de riesgo alto aumenta **1,39 puntos porcentuales**

No se observa un deterioro brusco de la cartera, sino una evolución moderadamente negativa.

---

## 10. Evolución individual del riesgo

Al comparar la primera y la última evaluación de cada cliente:

- **920 clientes (18,40 %)** empeoraron de nivel de riesgo
- **3.234 clientes (64,68 %)** permanecieron en el mismo nivel
- **846 clientes (16,92 %)** mejoraron

La mayoría de los clientes mantiene su clasificación de riesgo.

Existe, sin embargo, un ligero desequilibrio hacia el deterioro: el porcentaje que empeora supera en **1,48 puntos porcentuales** al porcentaje que mejora.

En términos de score:

- variación media: **-1,60 puntos**
- mayor deterioro observado: **-108 puntos**
- mayor mejora observada: **+85 puntos**
- **157 clientes (3,14 %)** sufrieron una caída de al menos 50 puntos

Estos 157 clientes constituyen un grupo especialmente interesante para sistemas de alerta temprana.

---

## 11. Capacidad de segmentación del indicador de riesgo

Al dividir los clientes en quintiles según su probabilidad de impago se obtiene:

| Quintil | PD media | Clientes con impago | Tasa de impago real |
|---|---:|---:|---:|
| 1 | 6,47 % | 4 | 0,80 % |
| 2 | 14,94 % | 11 | 2,03 % |
| 3 | 21,82 % | 20 | 3,91 % |
| 4 | 31,30 % | 19 | 3,82 % |
| 5 | 51,54 % | 25 | 9,19 % |

El quintil de mayor riesgo presenta una tasa de impago del **9,19 %**, frente al **0,80 %** del quintil de menor riesgo.

Esto supone una tasa aproximadamente **11,5 veces superior** en el quintil 5 respecto al quintil 1.

Aunque el quintil 4 presenta una tasa ligeramente inferior al quintil 3, la tendencia general muestra una fuerte capacidad de ordenación del riesgo.

Este análisis debe entenderse como una comprobación descriptiva y no como una validación predictiva formal, ya que utiliza la evaluación de riesgo más reciente junto con el historial de impago y no una separación temporal estricta entre predicción y evento futuro.

---

## 12. Alertas tempranas y watchlist

El sistema de seguimiento construido mediante SQL identifica:

- **2.417 clientes** en alerta temprana
- **2.938 clientes** incluidos en la watchlist
- **965 clientes** con historial de mora
- **79 clientes** con historial de impago

Esto representa aproximadamente:

- **48,34 %** de los clientes en alerta temprana
- **58,76 %** incluidos en la watchlist
- **19,30 %** con historial de mora
- **1,58 %** con historial de impago

La diferencia entre los **80 préstamos con impago** y los **79 clientes con historial de impago** indica que al menos un cliente presenta más de un préstamo afectado.

La watchlist permite combinar riesgo, mora, impago y exposición para priorizar el seguimiento de clientes.

---

## 13. Exposición ponderada por riesgo

Para el conjunto de préstamos con exposición pendiente se obtiene:

- exposición total analizada: **92.627.266,01**
- exposición ponderada por probabilidad de impago: **20.051.844,28**
- ratio ponderado sobre exposición: **21,65 %**

La métrica utilizada es:

`Exposición × Probabilidad de impago`

Este indicador permite combinar tamaño de la exposición y nivel de riesgo en una única medida de priorización.

No debe confundirse con una Expected Loss regulatoria completa, ya que no incorpora LGD ni una definición formal de EAD.

---

## 14. Concentración de la exposición

La cartera presenta una concentración elevada:

- el **10 % de clientes con mayor exposición** concentra el **55,99 %** de la exposición total
- el **20 % de clientes con mayor exposición** concentra el **74,06 %**

Este resultado implica que una proporción relativamente pequeña de clientes representa una parte muy elevada del riesgo económico de la cartera.

Por este motivo, el análisis conjunto de **probabilidad de impago + exposición** resulta más útil para priorizar clientes que analizar únicamente la probabilidad de impago.

---

## 15. Principales conclusiones de negocio

Los resultados del proyecto permiten extraer cinco conclusiones principales:

1. **El endeudamiento elevado es una de las señales de riesgo más claras.**  
   La tasa de impago aumenta hasta el 7,32 % en clientes con ratios de endeudamiento iguales o superiores a 50.

2. **Los scores muy bajos identifican un segmento claramente más problemático.**  
   Los préstamos con score inferior a 650 presentan una tasa de impago del 7,29 %.

3. **El indicador de riesgo presenta una buena capacidad de ordenación descriptiva.**  
   El quintil de mayor riesgo registra una tasa de impago aproximadamente 11,5 veces superior al quintil de menor riesgo.

4. **La exposición está fuertemente concentrada.**  
   El 10 % de clientes con mayor exposición concentra el 55,99 % del total, y el 20 % concentra el 74,06 %.

5. **La cartera muestra estabilidad general, pero existen señales de deterioro individual que justifican una estrategia de early warning.**  
   Un 18,40 % de clientes empeora de categoría y 157 clientes experimentan caídas de score de al menos 50 puntos.

---

## 16. Consideraciones metodológicas

Los resultados proceden de un dataset sintético creado con fines educativos y de portfolio.

Por tanto:

- las tasas obtenidas no representan una cartera bancaria real;
- la probabilidad de impago no ha sido calibrada mediante un modelo regulatorio;
- la definición de mora utilizada en el proyecto es una cuota con más de 30 días de retraso;
- las comparaciones entre probabilidad estimada e impago histórico son descriptivas;
- para validar un modelo predictivo real sería necesario separar temporalmente observaciones, variables predictoras y eventos futuros;
- métricas regulatorias como Expected Loss requerirían, entre otros componentes, PD, LGD y EAD correctamente definidos.

Estas limitaciones no afectan al objetivo principal del proyecto: demostrar el uso de SQL para diseñar, consultar y analizar una base de datos relacional aplicada a un problema de Credit Risk.
