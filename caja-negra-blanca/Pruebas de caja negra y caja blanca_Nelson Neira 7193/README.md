# Escenarios de Pruebas Separados

Este proyecto ahora esta organizado por escenario, de forma independiente.

## Escenario 1: Caja Negra - Sistema de Calificacion de Estudiantes

Archivo principal: `escenario1_caja_negra.py`

### Funcion

`asignar_calificacion(examen1, examen2, examen3, examen4)`

Reglas:

- Promedio mayor o igual a 90: `"A"`
- Promedio mayor o igual a 80 y menor a 90: `"B"`
- Promedio mayor o igual a 70 y menor a 80: `"C"`
- Promedio menor a 70: `"F"`

### Pruebas

Archivo de pruebas: `test_escenario1_caja_negra.py`

Como es caja negra, los casos de prueba se diseñan desde la especificacion, sin analizar la logica interna:

| Caso | Entradas | Promedio esperado | Salida esperada |
| --- | --- | --- | --- |
| 1 | 95, 92, 94, 91 | 93.0 | A |
| 2 | 90, 90, 90, 90 | 90.0 | A |
| 3 | 80, 85, 82, 83 | 82.5 | B |
| 4 | 90, 90, 90, 89 | 89.75 | B |
| 5 | 70, 72, 75, 78 | 73.75 | C |
| 6 | 80, 80, 80, 79 | 79.75 | C |
| 7 | 60, 65, 68, 69 | 65.5 | F |
| 8 | 70, 70, 70, 69 | 69.75 | F |

### Ingreso de datos

En este archivo se incluyen dos cosas:

- La funcion `asignar_calificacion(...)`, que sirve para hacer pruebas automaticamente.
- Un `main()` interactivo, para que el usuario escriba las 4 notas por teclado.

Ejecutar modo interactivo:

```bash
python escenario1_caja_negra.py
```

Ejecutar pruebas:

```bash
python -m unittest test_escenario1_caja_negra.py -v
```

## Escenario 2: Caja Blanca - Calculo de Descuento en Carrito de Compras

Archivo principal: `escenario2_caja_blanca.py`

### Funcion

`aplicar_descuento(total_compra)`

Reglas:

- Si `total_compra < 100`, no hay descuento.
- Si `100 <= total_compra < 200`, se aplica 10% de descuento.
- Si `total_compra >= 200`, se aplica 20% de descuento.

### Rutas del codigo

Como es caja blanca, aqui si se cubren todos los caminos posibles de ejecucion:

1. Ruta sin descuento.
2. Ruta con descuento del 10%.
3. Ruta con descuento del 20%.

### Pruebas

Archivo de pruebas: `test_escenario2_caja_blanca.py`

| Ruta | Caso | Entrada | Salida esperada |
| --- | --- | --- | --- |
| Sin descuento | Limite superior del rango | 99.99 | 99.99 |
| 10% descuento | Limite inferior del rango | 100 | 90.0 |
| 10% descuento | Valor intermedio | 150 | 135.0 |
| 10% descuento | Justo debajo del siguiente rango | 199.99 | 179.991 |
| 20% descuento | Limite inferior del rango | 200 | 160.0 |
| 20% descuento | Valor alto | 350 | 280.0 |

### Ingreso de datos

En este archivo tambien se incluyen dos cosas:

- La funcion `aplicar_descuento(...)`, util para pruebas.
- Un `main()` interactivo, para que el usuario escriba el total de la compra.

Ejecutar modo interactivo:

```bash
python escenario2_caja_blanca.py
```

Ejecutar pruebas:

```bash
python -m unittest test_escenario2_caja_blanca.py -v
```

## Respuesta a tu duda

No es obligatorio que el usuario ingrese los datos para que las funciones existan o para hacer pruebas unitarias.

De hecho, para probar correctamente, es mejor que las funciones reciban parametros directamente, por ejemplo:

- `asignar_calificacion(90, 80, 70, 100)`
- `aplicar_descuento(150)`

Pero si tu profesor o la entrega espera un programa mas completo para usarlo manualmente, entonces si conviene agregar entrada por teclado. Por eso en esta solucion deje ambas opciones:

- funciones puras para probar;
- version interactiva para que el usuario ingrese los datos.
