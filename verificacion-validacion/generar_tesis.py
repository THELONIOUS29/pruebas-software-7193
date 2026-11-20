import docx
from docx.shared import Pt, Inches
from docx.enum.text import WD_ALIGN_PARAGRAPH
from docx.oxml import OxmlElement
from docx.oxml.ns import qn

def set_cell_border(cell, **kwargs):
    """Configura los bordes de una celda estilo académico formal."""
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
    """Aplica bordes horizontales limpios de acuerdo con normas formales de tesis."""
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

# Configuración de márgenes estilo tesis (1 pulgada / 2.54 cm en los 4 lados)
for section in doc.sections:
    section.top_margin = Inches(1)
    section.bottom_margin = Inches(1)
    section.left_margin = Inches(1)
    section.right_margin = Inches(1)

# Estilo Base Arial 12 con interlineado formal
style = doc.styles['Normal']
font = style.font
font.name = 'Arial'
font.size = Pt(12)

# ==========================================
# TÍTULO DEL CAPÍTULO IV
# ==========================================
p = doc.add_paragraph()
p.alignment = WD_ALIGN_PARAGRAPH.CENTER
run = p.add_run("CAPÍTULO IV\nANÁLISIS E INTERPRETACIÓN DE RESULTADOS")
run.bold = True
run.font.size = Pt(14)

doc.add_paragraph(
    "En este capítulo se expone el análisis e interpretación de los resultados obtenidos en la "
    "evaluación de la característica de calidad Adecuación Funcional de la aplicación móvil con "
    "alertas inteligentes desarrollada para la empresa “Agua Milena”. La evaluación se realizó "
    "tomando como referencia la norma ISO/IEC 25010:2023 y las métricas de la ISO/IEC 25023:2016, "
    "con el propósito de comprobar que el producto software entregado cumpla de manera objetiva "
    "con las necesidades operativas del negocio."
)

# ==========================================
# 4.1 FUNCIONALIDADES EVALUADAS
# ==========================================
h1 = doc.add_paragraph()
run = h1.add_run("4.1 Funcionalidades evaluadas")
run.bold = True

doc.add_paragraph(
    "Para la evaluación de la Adecuación Funcional, se estableció una relación directa con la fase de "
    "planificación detallada en el marco metodológico. El proyecto se estructuró a partir de 15 Historias "
    "de Usuario, las cuales corresponden a 15 Requisitos Funcionales Generales del sistema. Sin embargo, "
    "para ejecutar una medición precisa del cumplimiento de la calidad, estos requisitos generales fueron "
    "descompuestos en 63 Requisitos Funcionales Específicos, los cuales representan las acciones concretas "
    "del sistema evaluadas mediante tarjetas de prueba de aceptación de validación."
)

doc.add_paragraph(
    "Por tanto, la unidad de análisis de esta evaluación abarca la totalidad de las 63 especificaciones "
    "lógicas implementadas en la aplicación móvil. A continuación, en la Tabla 41 se presentan las 15 "
    "funcionalidades base del sistema que estructuran el desglose de las pruebas ejecutadas."
)

# Tabla 41
t41 = doc.add_table(rows=16, cols=4)
hdr_cells = t41.rows[0].cells
hdr_cells[0].text = 'Subcaracterísticas'
hdr_cells[1].text = 'Módulo'
hdr_cells[2].text = 'ID'
hdr_cells[3].text = 'Funcionalidad Base del Software'

datos_t41 = [
    ("Completitud Funcional, Corrección Funcional, Pertinencia Funcional", "Autenticación y Usuarios", "F-01", "Iniciar sesión de forma segura en la aplicación móvil."),
    ("", "", "F-02", "Gestionar usuarios y permisos de acceso."),
    ("", "", "F-03", "Gestionar perfil y cambio de contraseña."),
    ("", "", "F-04", "Consultar el panel de control con información resumida."),
    ("", "Inventario", "F-05", "Gestionar productos del inventario."),
    ("", "", "F-06", "Registrar movimientos de entrada y salida de inventario."),
    ("", "Ventas", "F-07", "Registrar y consultar ventas."),
    ("", "Vendedores y Rutas", "F-08", "Gestionar vendedores de la empresa."),
    ("", "", "F-09", "Gestionar rutas de distribución."),
    ("", "", "F-10", "Registrar abonos o cobros relacionados con rutas."),
    ("", "", "F-11", "Controlar bidones llenos, vacíos, propios y prestados."),
    ("", "Alertas inteligentes", "F-12", "Generar alertas operativas de stock, cobros e inconsistencias."),
    ("", "", "F-13", "Generar predicciones de demanda mediante inteligencia artificial."),
    ("", "", "F-14", "Visualizar alertas del sistema."),
    ("", "Reportes", "F-15", "Generar y filtrar reportes operativos.")
]

for idx, fila in enumerate(datos_t41):
    row_cells = t41.rows[idx + 1].cells
    row_cells[0].text = fila[0]
    row_cells[1].text = fila[1]
    row_cells[2].text = fila[2]
    row_cells[3].text = fila[3]

formatear_tabla_normas(t41)
p_ref = doc.add_paragraph()
p_ref.add_run("Realizado por: Neira 2026").font.size = Pt(10)

# ==========================================
# 4.2 EVALUACIÓN DE LA ADECUACIÓN FUNCIONAL
# ==========================================
h2 = doc.add_paragraph()
run = h2.add_run("4.2 Evaluación de la Adecuación Funcional")
run.bold = True

doc.add_paragraph(
    "Para realizar la evaluación de la Adecuación Funcional se hizo uso de las métricas presentadas en la "
    "ISO/IEC 25023, tal como se indica en la sección 3.6.5 del marco metodológico. De esta manera, se "
    "describen a continuación los resultados obtenidos para cada una de las subcaracterísticas que conforman "
    "la Adecuación Funcional de la aplicación móvil."
)

# 4.2.1 Completitud Funcional
h21 = doc.add_paragraph()
run = h21.add_run("4.2.1 Medición de la subcaracterística Completitud Funcional")
run.bold = True

doc.add_paragraph(
    "La medición de Completitud Funcional se realizó mediante la métrica Cobertura Funcional, en la cual se "
    "contrasta la cantidad de funcionalidades que no fueron implementadas con el total de funcionalidades "
    "especificadas a partir de los requerimientos de la aplicación móvil."
)

doc.add_paragraph(
    "Al concluir la revisión sobre las 63 tarjetas de pruebas de aceptación de validación, se constató que "
    "la aplicación móvil contiene e implementa de manera íntegra cada uno de los componentes estipulados en "
    "el alcance técnico. No se evidenciaron omisiones de funcionalidad o exclusiones del diseño lógico "
    "original, por lo que el número de requisitos específicos faltantes se determinó en cero (0), obteniendo "
    "una Cobertura Funcional del 100% de manera global en todos sus bloques de operación, tal como se detalla "
    "en la Tabla 42."
)

# Tabla 42
t42 = doc.add_table(rows=7, cols=4)
hdr_cells = t42.rows[0].cells
hdr_cells[0].text = 'Bloque Operativo Evaluado'
hdr_cells[1].text = 'Requisitos Especificados'
hdr_cells[2].text = 'Requisitos Faltantes'
hdr_cells[3].text = 'Cobertura Funcional (%)'

datos_t42 = [
    ("Módulo Autenticación y usuarios", "15", "0", "100%"),
    ("Módulo Inventario", "7", "0", "100%"),
    ("Módulo Ventas", "6", "0", "100%"),
    ("Módulo Vendedores y rutas", "19", "0", "100%"),
    ("Módulo Alertas inteligentes", "13", "0", "100%"),
    ("Módulo Reportes", "3", "0", "100%")
]

for idx, fila in enumerate(datos_t42):
    row_cells = t42.rows[idx + 1].cells
    row_cells[0].text = fila[0]
    row_cells[1].text = fila[1]
    row_cells[2].text = fila[2]
    row_cells[3].text = fila[3]

formatear_tabla_normas(t42)
total_row = t42.add_row().cells
total_row[0].text = "Completitud Funcional Global (%)"
total_row[1].text = "63 Requisitos"
total_row[2].text = "0 Faltantes"
total_row[3].text = "X = (1 - 0/63) * 100 = 100%"
for cell in total_row:
    cell.paragraphs[0].runs[0].font.bold = True

p_ref = doc.add_paragraph()
p_ref.add_run("Realizado por: Neira 2026").font.size = Pt(10)

# 4.2.2 Corrección Funcional
h22 = doc.add_paragraph()
run = h22.add_run("4.2.2 Medición de la subcaracterística Corrección Funcional")
run.bold = True

doc.add_paragraph(
    "La medición de la Corrección Funcional se realizó mediante la métrica Corrección Funcional, la cual se "
    "calcula con el número de funcionalidades que están incorrectas frente al total de funcionalidades "
    "consideradas a partir de los requerimientos de la aplicación móvil."
)

doc.add_paragraph(
    "Durante las fases de verificación inicial de los sprints de desarrollo, las pruebas funcionales manuales "
    "y automatizadas (ejecutadas a través de archivos .test.dart y descritas en el documento "
    "NELSON_NEIRA_MANUAL_TECNICO_DEL_SISTEMA.docx) detectaron incidencias menores relacionadas con bloqueos "
    "en ventas directas que intentaban procesar transacciones por encima del stock disponible en la planta, "
    "así como diferencias en el cuadre aritmético del retorno de bidones vacíos en las rutas. Estos errores "
    "fueron corregidos inmediatamente mediante el ajuste de restricciones de integridad y funciones RPC en la "
    "base de datos central de Supabase, volviendo a ejecutar los archivos de pruebas hasta lograr un comportamiento "
    "correcto."
)

doc.add_paragraph(
    "La única funcionalidad que registró una observación técnica persistente fue el componente predictivo del módulo "
    "de Alertas Inteligentes implementado con TensorFlow Lite. Al evaluar la generación de predicciones de demanda "
    "diaria y semanal bajo condiciones de datos históricos limitados en la distribuidora, el modelo arrojó una precisión "
    "restringida. Si bien la aplicación móvil manejó la excepción de manera segura y continuó funcionando de forma "
    "reactiva sin bloquear la interfaz, el comportamiento se contabilizó como una prueba con observación frente al "
    "escenario ideal esperado. Al registrarse únicamente este incidente sobre el total de escenarios de verificación "
    "analizados para los requerimientos específicos, la métrica de Corrección Funcional (ID: FCr-1-G) alcanzó un 93,33% "
    "de éxito, tal como se sintetiza en la Tabla 43."
)

# Tabla 43
t43 = doc.add_table(rows=7, cols=4)
hdr_cells = t43.rows[0].cells
hdr_cells[0].text = 'Bloque Funcional Evaluado'
hdr_cells[1].text = 'Escenarios de Verificación Realizados'
hdr_cells[2].text = 'Escenarios con Incidencia Técnica'
hdr_cells[3].text = 'Corrección Funcional (%)'

datos_t43 = [
    ("Autenticación y usuarios", "Verificados con éxito", "0", "100%"),
    ("Inventario", "Verificados con éxito", "0", "100%"),
    ("Ventas", "Verificados con éxito", "0", "100%"),
    ("Vendedores y rutas", "Verificados con éxito", "0", "100%"),
    ("Alertas inteligentes (Predicción IA)", "Verificado con observación", "1", "66,67%"),
    ("Reportes", "Verificados con éxito", "0", "100%")
]

for idx, fila in enumerate(datos_t43):
    row_cells = t43.rows[idx + 1].cells
    row_cells[0].text = fila[0]
    row_cells[1].text = fila[1]
    row_cells[2].text = fila[2]
    row_cells[3].text = fila[3]

formatear_tabla_normas(t43)
total_row_43 = t43.add_row().cells
total_row_43[0].text = "Corrección Funcional Global (%)"
total_row_43[1].text = "15 Bloques de Control"
total_row_43[2].text = "1 Incidencia"
total_row_43[3].text = "X = (1 - 1/15) * 100 = 93,33%"
for cell in total_row_43:
    cell.paragraphs[0].runs[0].font.bold = True

p_ref = doc.add_paragraph()
p_ref.add_run("Realizado por: Neira 2026").font.size = Pt(10)

# ==========================================
# 4.2.3 PERTINENCIA FUNCIONAL (Párrafos introductorios)
# ==========================================
h23 = doc.add_paragraph()
run = h23.add_run("4.2.3 Medición de la subcaracterística Pertinencia Funcional")
run.bold = True

doc.add_paragraph(
    "La Pertinencia Funcional fue evaluada con el propósito de determinar si las funcionalidades implementadas en la "
    "aplicación móvil aportan valor real al proceso operativo de la empresa “Agua Milena”. A diferencia de la Completitud "
    "Funcional, que permitió comprobar la existencia de las funcionalidades requeridas, y de la Corrección Funcional, "
    "que permitió verificar su comportamiento correcto, la Pertinencia Funcional permitió analizar si dichas "
    "funcionalidades son apropiadas para cumplir los objetivos de uso definidos para el sistema."
)

doc.add_paragraph(
    "Para esta evaluación se tomó como referencia el componente “para” de las historias de usuario, debido a que expresa "
    "la finalidad o beneficio esperado por el usuario al utilizar una funcionalidad. En consecuencia, los objetivos "
    "de uso fueron definidos como agrupaciones de funcionalidades que responden a un propósito operativo concreto. "
    "De acuerdo con las especificaciones del estándar de calidad ISO/IEC 25023, la medición se divide en las siguientes dos "
    "submétricas operacionales."
)

# ==========================================
# 4.2.3.1 SUBMÉTRICA A: OBJETIVO DE USO
# ==========================================
h231 = doc.add_paragraph()
run_sm1 = h231.add_run("4.2.3.1 Métrica Pertinencia Funcional del objetivo de uso")
run_sm1.bold = True

doc.add_paragraph(
    "Esta métrica (ID: FAp-1-G) evalúa por cada objetivo de uso individual si las funcionalidades necesarias "
    "están presentes y funcionan correctamente para lograr ese objetivo. En la Tabla 44 se presentan los "
    "objetivos de uso definidos para la evaluación de la Pertinencia Funcional."
)

# Tabla 44: Objetivos de uso
t44 = doc.add_table(rows=11, cols=4)
hdr_cells = t44.rows[0].cells
hdr_cells[0].text = 'Objetivo de uso'
hdr_cells[1].text = 'Finalidad operativa'
hdr_cells[2].text = 'Historias relacionadas'
hdr_cells[3].text = 'Criterio de pertinencia'

datos_t44 = [
    ("OU-01", "Acceder de forma segura a funcionalidades según rol", "HU-01, HU-14", "El usuario accede solo a funciones relacionadas con sus responsabilidades."),
    ("OU-02", "Controlar cuentas, usuarios y permisos de acceso", "HU-02", "El administrador mantiene control de altas, cambios, estados y roles."),
    ("OU-03", "Conocer rápidamente el estado operativo de la empresa", "HU-04", "El panel resume información útil para decisiones operativas rápidas."),
    ("OU-04", "Mantener actualizado el inventario disponible", "HU-05, HU-06, HU-12", "Los movimientos y alertas ayudan a conocer existencias reales y necesidad de reposición."),
    ("OU-05", "Registrar ventas y actualizar información operativa", "HU-07", "La venta actualiza ingresos, inventario e historial de operación."),
    ("OU-06", "Mantener actualizada la información de vendedores", "HU-08, HU-09", "Los vendedores registrados se relacionan correctamente con rutas y ventas."),
    ("OU-07", "Controlar rutas, despachos y cobros", "HU-09, HU-10", "El sistema permite seguimiento de rutas, saldos y pagos registrados por personal autorizado."),
    ("OU-08", "Controlar bidones llenos, vacíos, propios y prestados", "HU-11, HU-12", "La información de envases permite detectar préstamos, retornos e inconsistencias."),
    ("OU-09", "Anticipar problemas operativos mediante alertas y predicciones", "HU-12, HU-13, HU-14", "Las alertas y predicciones apoyan decisiones oportunas ante stock, cobros o demanda futura."),
    ("OU-10", "Generar reportes PDF útiles para la toma de decisiones", "HU-15", "El administrador obtiene información de ventas filtrada y utilizable como respaldo operativo.")
]

for idx, fila in enumerate(datos_t44):
    row_cells = t44.rows[idx + 1].cells
    row_cells[0].text = fila[0]
    row_cells[1].text = fila[1]
    row_cells[2].text = fila[2]
    row_cells[3].text = fila[3]

formatear_tabla_normas(t44)
p_ref = doc.add_paragraph()
p_ref.add_run("Realizado por: Neira 2026").font.size = Pt(10)

doc.add_paragraph(
    "La evaluación se realizó mediante pruebas de aceptación de pertinencia funcional. Estas pruebas no comprobaron "
    "únicamente si la funcionalidad estaba presente o si producía resultados correctos, sino si contribuía al “para qué” "
    "expresado en la historia de usuario. Por ejemplo, en el caso del inicio de sesión, la pertinencia no se limitó a "
    "comprobar el acceso al sistema, sino a verificar que, una vez autenticado, cada usuario visualice únicamente las "
    "funcionalidades relacionadas con su rol."
)

doc.add_paragraph(
    "Para este análisis metodológico se aplicaron un total de 30 escenarios prácticos distribuidos de manera equitativa "
    "a razón de tres (3) escenarios de prueba por cada uno de los 10 objetivos de uso. Los resultados de esta métrica se "
    "agrupan en la Tabla 45."
)

# Tabla 45: Resumen de resultados de Pertinencia Funcional
t45 = doc.add_table(rows=11, cols=4)
hdr_cells = t45.rows[0].cells
hdr_cells[0].text = 'Objetivo de uso'
hdr_cells[1].text = 'Pruebas aplicadas'
hdr_cells[2].text = 'Pruebas aceptadas plenamente'
hdr_cells[3].text = 'Resultado (%)'

datos_t45 = [
    ("OU-01", "3", "3", "100%"),
    ("OU-02", "3", "3", "100%"),
    ("OU-03", "3", "3", "100%"),
    ("OU-04", "3", "3", "100%"),
    ("OU-05", "3", "3", "100%"),
    ("OU-06", "3", "3", "100%"),
    ("OU-07", "3", "3", "100%"),
    ("OU-08", "3", "3", "100%"),
    ("OU-09", "3", "2", "66,67%"),
    ("OU-10", "3", "3", "100%")
]

for idx, fila in enumerate(datos_t45):
    row_cells = t45.rows[idx + 1].cells
    row_cells[0].text = fila[0]
    row_cells[1].text = fila[1]
    row_cells[2].text = fila[2]
    row_cells[3].text = fila[3]

formatear_tabla_normas(t45)
total_row_45 = t45.add_row().cells
total_row_45[0].text = "Total Sistema"
total_row_45[1].text = "30"
total_row_45[2].text = "29"
total_row_45[3].text = "96,67%"
for cell in total_row_45:
    cell.paragraphs[0].runs[0].font.bold = True

p_ref = doc.add_paragraph()
p_ref.add_run("Realizado por: Neira 2026").font.size = Pt(10)

# ==========================================
# 4.2.3.2 SUBMÉTRICA B: SISTEMA
# ==========================================
h232 = doc.add_paragraph()
run_sm2 = h232.add_run("4.2.3.2 Métrica Pertinencia Funcional del Sistema")
run_sm2.bold = True

doc.add_paragraph(
    "Esta métrica (ID: FAp-2-G) cuantifica el grado de pertinencia integral de todo el producto software. "
    "Su valor se determina calculando el promedio aritmético de los resultados obtenidos en las mediciones individuales "
    "de la métrica anterior (FAp-1-G) sobre los 10 objetivos operacionales del sistema."
)

doc.add_paragraph(
    "Para calcular la Pertinencia Funcional global se utilizó la relación entre el número de pruebas aceptadas "
    "plenamente y el número total de pruebas aplicadas, utilizando la siguiente función de medición:"
)

# Fórmula en bloque matemático centralizado
p_form = doc.add_paragraph()
p_form.alignment = WD_ALIGN_PARAGRAPH.CENTER
p_form.add_run("X = A / B\n\nDonde:\nA = número de pruebas de pertinencia aceptadas plenamente.\nB = número total de pruebas de pertinencia aplicadas.\n\nX = 29 / 30 = 0,9667 = 96,67 %").italic = True

doc.add_paragraph(
    "El resultado obtenido para la Pertinencia Funcional del sistema fue de 96,67%, lo que evidencia que la aplicación "
    "móvil cumple en alto grado con los objetivos de uso definidos para la empresa “Agua Milena”. La única observación "
    "corresponde al objetivo OU-09, relacionado con la generación de predicciones de demanda mediante inteligencia "
    "artificial, debido a que la utilidad de la predicción depende de la cantidad y calidad de datos históricos disponibles. "
    "No obstante, el sistema mantiene la funcionalidad y presenta información útil para apoyar la planificación operativa."
)

doc.add_paragraph(
    "El valor alcanzado indica que las funcionalidades implementadas no solo cumplen una acción técnica dentro del sistema, "
    "sino que además responden al propósito operativo para el cual fueron requeridas. En este sentido, el acceso por "
    "roles permite resguardar la información y mostrar funciones pertinentes; el panel principal facilita una lectura rápida "
    "del estado operativo; los módulos de inventario, ventas, rutas, cobros y bidones permiten mantener actualizados los "
    "registros; las alertas apoyan la toma de decisiones oportunas; y los reportes PDF permiten disponer de información útil "
    "para la revisión de ventas."
)

doc.add_paragraph(
    "Por tanto, la Pertinencia Funcional se considera alcanzada en un nivel alto, debido a que la mayoría de objetivos de uso "
    "fueron satisfechos plenamente. La observación registrada en el objetivo relacionado con inteligencia artificial no "
    "invalida la funcionalidad, sino que delimita su alcance actual y evidencia la necesidad de fortalecer la base histórica "
    "de datos para mejorar la precisión y utilidad de las predicciones en futuras versiones."
)

# ==========================================
# 4.3 RESULTADOS DE LA EVALUACIÓN GLOBAL
# ==========================================
h3 = doc.add_paragraph()
run = h3.add_run("4.3 Resultados de la evaluación de la Adecuación Funcional")
run.bold = True

doc.add_paragraph(
    "El resultado de la Adecuación Funcional de la aplicación móvil desarrollada se obtiene de la suma de los valores "
    "ponderados de cada una de las subcaracterísticas: Completitud Funcional, Corrección Funcional y Pertinencia Funcional. "
    "Se trabajó con valores equitativos para cada subcaracterística debido al mismo nivel de importancia que presentan "
    "para certificar el producto, asignando un peso del 33.33% para Completitud Funcional, 33.33% para Corrección Funcional "
    "y 33.34% para Pertinencia Funcional, consolidando los valores en la Tabla 46."
)

# Tabla 46
t46 = doc.add_table(rows=5, cols=4)
hdr_cells = t46.rows[0].cells
hdr_cells[0].text = 'Subcaracterística'
hdr_cells[1].text = 'Resultado obtenido'
hdr_cells[2].text = 'Ponderación'
hdr_cells[3].text = 'Valor ponderado'

datos_t46 = [
    ("Completitud Funcional", "100%", "33,33%", "33,33%"),
    ("Corrección Funcional", "93,33%", "33,33%", "31,11%"),
    ("Pertinencia Funcional", "96,67%", "33,34%", "32,23%")
]

for idx, fila in enumerate(datos_t46):
    row_cells = t46.rows[idx + 1].cells
    row_cells[0].text = fila[0]
    row_cells[1].text = fila[1]
    row_cells[2].text = fila[2]
    row_cells[3].text = fila[3]

formatear_tabla_normas(t46)
total_row_46 = t46.add_row().cells
total_row_46[0].text = "Resultado Adecuación Funcional"
total_row_46[1].text = ""
total_row_46[2].text = ""
total_row_46[3].text = "96,67%"
for cell in total_row_46:
    cell.paragraphs[0].runs[0].font.bold = True

p_ref = doc.add_paragraph()
p_ref.add_run("Realizado por: Neira 2026").font.size = Pt(10)

doc.add_paragraph(
    "Luego de promediar y aplicar la ponderación correspondiente a cada subcaracterística, se obtuvo un resultado final de "
    "96,67% para la característica de calidad Adecuación Funcional. En base al resultado obtenido y situándolo dentro de los "
    "niveles de aceptación planteados por López y Noguera (2016), el nivel de aceptación de la aplicación móvil desarrollada "
    "es “Excelente” en cuanto al cumplimiento de las funcionalidades definidas."
)

doc.add_paragraph(
    "Este resultado permite rechazar la hipótesis nula (H₀) y aceptar la hipótesis alternativa (H₁) de la investigación, "
    "demostrando que la solución tecnológica desarrollada contribuye de manera eficiente a la digitalización del proceso y "
    "a la reducción de errores en los registros de datos en la empresa “Agua Milena”."
)

doc.save("Capitulo_IV_Corregido.docx")
print("¡Archivo 'Capitulo_IV_Corregido.docx' generado con éxito respetando tu estructura exacta!")