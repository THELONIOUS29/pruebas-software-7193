import docx
from docx.shared import Pt, Inches
from docx.oxml import OxmlElement
from docx.oxml.ns import qn

def set_cell_border(cell, **kwargs):
    tc = cell._tc
    tcPr = tc.get_or_add_tcPr()
    tcBorders = tcPr.first_child_found_in("w:tcBorders")
    if tcBorders is None:
        tcBorders = OxmlElement('w:tcBorders')
        tcPr.append(tcBorders)
    for edge in ('top', 'left', 'bottom', 'right', 'insideH', 'insideV'):
        edge_data = kwargs.get(edge)
        if edge_data:
            tag = 'w:{}'.format(edge)
            element = tcBorders.find(qn(tag))
            if element is None:
                element = OxmlElement(tag)
                tcBorders.append(element)
            for key, val in edge_data.items():
                element.set(qn('w:{}'.format(key)), str(val))

def formatear_tabla_normas(table):
    for i, row in enumerate(table.rows):
        for cell in row.cells:
            if i == 0:
                set_cell_border(cell, 
                                top={"sz": 12, "val": "single", "color": "000000"},
                                bottom={"sz": 12, "val": "single", "color": "000000"})
            elif i == len(table.rows) - 1:
                set_cell_border(cell, bottom={"sz": 12, "val": "single", "color": "000000"})
            else:
                set_cell_border(cell, bottom={"sz": 4, "val": "single", "color": "E0E0E0"})

doc = docx.Document()

# Configurar márgenes y fuente Arial 12
for section in doc.sections:
    section.top_margin = Inches(1)
    section.bottom_margin = Inches(1)
    section.left_margin = Inches(1)
    section.right_margin = Inches(1)

style = doc.styles['Normal']
font = style.font
font.name = 'Arial'
font.size = Pt(12)

# Título
doc.add_paragraph("4.1.1 Requisitos Funcionales Específicos").runs[0].bold = True

doc.add_paragraph("A partir de los 15 Requisitos Funcionales Generales, se derivaron 63 Requisitos Funcionales Específicos (RFE). Estos representan las acciones detalladas que el sistema debe ejecutar y constituyen la base exacta para las pruebas de aceptación de validación.")

# Datos de la tabla
datos_rfe = [
    ("ID", "Requisito Funcional Específico (RFE)", "Asociado a"),
    ("RFE-01", "Validar las credenciales de acceso (correo electrónico y contraseña).", "RF-01"),
    ("RFE-02", "Bloquear el acceso al sistema cuando se ingresen credenciales incorrectas.", "RF-01"),
    ("RFE-03", "Redirigir al usuario a las funcionalidades correspondientes según su rol.", "RF-01"),
    ("RFE-04", "Exigir el cambio obligatorio de contraseña cuando el sistema lo determine.", "RF-01"),
    ("RFE-05", "Mostrar el listado completo de usuarios registrados en el sistema.", "RF-02"),
    ("RFE-06", "Permitir la creación y registro de un nuevo usuario.", "RF-02"),
    ("RFE-07", "Permitir la edición de los datos informativos de un usuario existente.", "RF-02"),
    ("RFE-08", "Permitir la activación y desactivación (eliminación lógica) de un usuario.", "RF-02"),
    ("RFE-09", "Permitir la asignación de un rol de acceso (Administrador, Planta o Vendedor).", "RF-02"),
    ("RFE-10", "Permitir la asociación de una cuenta de usuario con un vendedor del sistema.", "RF-02"),
    ("RFE-11", "Consultar y mostrar la información del perfil del usuario autenticado.", "RF-03"),
    ("RFE-12", "Actualizar los datos personales permitidos del perfil (ej. teléfono).", "RF-03"),
    ("RFE-13", "Permitir el cambio voluntario de la contraseña desde el perfil del usuario.", "RF-03"),
    ("RFE-14", "Permitir la carga y actualización de la imagen de perfil (avatar).", "RF-03"),
    ("RFE-15", "Visualizar indicadores numéricos principales de ventas, rutas y cobros.", "RF-04"),
    ("RFE-16", "Visualizar un resumen rápido de los productos que se encuentran en stock crítico.", "RF-04"),
    ("RFE-17", "Visualizar un resumen de los cobros o saldos pendientes de las rutas.", "RF-04"),
    ("RFE-18", "Acceder rápidamente a los módulos operativos mediante botones de acción directa.", "RF-04"),
    ("RFE-19", "Mostrar el listado de todos los productos registrados en el inventario.", "RF-05"),
    ("RFE-20", "Permitir la creación de un nuevo producto definiendo su stock y stock mínimo.", "RF-05"),
    ("RFE-21", "Permitir la edición de la información de un producto registrado.", "RF-05"),
    ("RFE-22", "Permitir el retiro operativo o eliminación de un producto del catálogo.", "RF-05"),
    ("RFE-23", "Permitir la asociación de una imagen fotográfica al producto.", "RF-05"),
    ("RFE-24", "Registrar movimientos manuales de entrada de productos al inventario.", "RF-06"),
    ("RFE-25", "Registrar movimientos manuales de salida de productos del inventario.", "RF-06"),
    ("RFE-26", "Bloquear el registro de salidas manuales que superen el stock disponible.", "RF-06"),
    ("RFE-27", "Consultar el historial detallado de movimientos de entrada y salida de un producto.", "RF-06"),
    ("RFE-28", "Registrar la información general para la creación de una nueva venta.", "RF-07"),
    ("RFE-29", "Agregar productos y definir sus cantidades dentro del detalle de la venta.", "RF-07"),
    ("RFE-30", "Calcular automáticamente los subtotales por producto y el total general de la venta.", "RF-07"),
    ("RFE-31", "Descontar automáticamente del inventario las cantidades de los productos vendidos.", "RF-07"),
    ("RFE-32", "Consultar el listado histórico y el detalle específico de ventas registradas.", "RF-07"),
    ("RFE-33", "Mostrar el listado de los vendedores registrados en la empresa.", "RF-08"),
    ("RFE-34", "Permitir el registro de un nuevo vendedor con su información base.", "RF-08"),
    ("RFE-35", "Permitir la edición de los datos de un vendedor registrado.", "RF-08"),
    ("RFE-36", "Permitir la activación y desactivación del estado operativo de un vendedor.", "RF-08"),
    ("RFE-37", "Crear una nueva ruta de distribución y asociarla a un vendedor específico.", "RF-09"),
    ("RFE-38", "Seleccionar productos e ingresar las cantidades de carga asignadas a la ruta.", "RF-09"),
    ("RFE-39", "Consultar el detalle general de la ruta (estado, montos y productos cargados).", "RF-09"),
    ("RFE-40", "Permitir ejecutar el cierre operativo de una ruta de distribución.", "RF-09"),
    ("RFE-41", "Filtrar las rutas para que el vendedor visualice únicamente las que tiene asignadas.", "RF-09"),
    ("RFE-42", "Registrar un abono económico parcial sobre el saldo pendiente de una ruta.", "RF-10"),
    ("RFE-43", "Registrar el abono total para cambiar automáticamente la ruta a estado pagado.", "RF-10"),
    ("RFE-44", "Identificar y gestionar un excedente de pago (abono superior al saldo pendiente).", "RF-10"),
    ("RFE-45", "Consultar el historial de abonos y pagos registrados en una ruta.", "RF-10"),
    ("RFE-46", "Registrar la cantidad de bidones llenos despachados o asignados en la operación.", "RF-11"),
    ("RFE-47", "Registrar la cantidad de bidones vacíos retornados por el vendedor o cliente.", "RF-11"),
    ("RFE-48", "Calcular internamente el número de bidones prestados con base en los registros.", "RF-11"),
    ("RFE-49", "Bloquear y advertir sobre el ingreso de valores matemáticamente incoherentes de bidones.", "RF-11"),
    ("RFE-50", "Generar una alerta automática cuando el stock de un producto llegue a cero o estado crítico.", "RF-12"),
    ("RFE-51", "Generar una alerta preventiva cuando el stock de un producto alcance su límite mínimo.", "RF-12"),
    ("RFE-52", "Generar una alerta en el sistema por saldos y cobros pendientes en las rutas.", "RF-12"),
    ("RFE-53", "Generar una alerta por inconsistencias operativas detectadas (ej. descuadre de bidones).", "RF-12"),
    ("RFE-54", "Emitir una notificación push en el dispositivo al activarse una alerta relevante.", "RF-12"),
    ("RFE-55", "Cargar en memoria el modelo TensorFlow Lite para el procesamiento de IA.", "RF-13"),
    ("RFE-56", "Generar una predicción diaria estimando la demanda próxima de los productos.", "RF-13"),
    ("RFE-57", "Generar una predicción y recomendación para períodos más extensos (semanal/mensual).", "RF-13"),
    ("RFE-58", "Manejar excepciones si los datos históricos son insuficientes para el algoritmo predictivo.", "RF-13"),
    ("RFE-59", "Visualizar alertas de stock e inventario (Restringido para roles Planta y Administrador).", "RF-14"),
    ("RFE-60", "Visualizar alertas de saldos y rutas (Restringido para el Vendedor respectivo).", "RF-14"),
    ("RFE-61", "Filtrar la información del reporte operativo de ventas por un rango de fechas.", "RF-15"),
    ("RFE-62", "Filtrar la información del reporte operativo de ventas por un vendedor específico.", "RF-15"),
    ("RFE-63", "Generar el documento PDF y permitir su visualización o compartición externa.", "RF-15")
]

# Crear la tabla
tabla = doc.add_table(rows=64, cols=3)
for idx, fila in enumerate(datos_rfe):
    celdas = tabla.rows[idx].cells
    celdas[0].text = fila[0]
    celdas[1].text = fila[1]
    celdas[2].text = fila[2]
    
    # Poner en negrita la cabecera
    if idx == 0:
        for celda in celdas:
            celda.paragraphs[0].runs[0].bold = True

formatear_tabla_normas(tabla)

# Guardar el documento
doc.save("Tabla_Requisitos_Especificos.docx")
print("El archivo 'Tabla_Requisitos_Especificos.docx' ha sido generado exitosamente.")