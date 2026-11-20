import pytest
from estudiante import Estudiante


# Caso 1: Creación Exitosa
def test_creacion_exitosa_estudiante():
    estudiante = Estudiante("Carlos Pérez", 1001, 20, 3.8)

    assert estudiante.nombre == "Carlos Pérez"
    assert estudiante.id_estudiante == 1001
    assert estudiante.edad == 20
    assert estudiante.promedio == 3.8


# Caso 2.1: Nombre nulo
def test_nombre_nulo():
    with pytest.raises(ValueError, match="El nombre debe ser una cadena de texto válida"):
        Estudiante(None, 1001, 20, 3.8)


# Caso 2.2: Nombre no es cadena de texto
def test_nombre_no_es_cadena():
    with pytest.raises(ValueError, match="El nombre debe ser una cadena de texto válida"):
        Estudiante(12345, 1001, 20, 3.8)


# Caso 2.3: Nombre vacío
def test_nombre_vacio():
    with pytest.raises(ValueError, match="El nombre debe ser una cadena de texto válida"):
        Estudiante("", 1001, 20, 3.8)


# Caso 3.1: ID negativo
def test_id_estudiante_negativo():
    with pytest.raises(ValueError, match="El ID del estudiante debe ser un número entero positivo"):
        Estudiante("Carlos Pérez", -5, 20, 3.8)


# Caso 3.2: ID igual a cero
def test_id_estudiante_cero():
    with pytest.raises(ValueError, match="El ID del estudiante debe ser un número entero positivo"):
        Estudiante("Carlos Pérez", 0, 20, 3.8)


# Caso 3.3: ID no entero
def test_id_estudiante_no_entero():
    with pytest.raises(ValueError, match="El ID del estudiante debe ser un número entero positivo"):
        Estudiante("Carlos Pérez", "1001", 20, 3.8)


# Caso 4.1: Edad negativa
def test_edad_negativa():
    with pytest.raises(ValueError, match="La edad debe estar entre 0 y 120 años"):
        Estudiante("Carlos Pérez", 1001, -1, 3.8)


# Caso 4.2: Edad mayor a 120
def test_edad_mayor_a_120():
    with pytest.raises(ValueError, match="La edad debe estar entre 0 y 120 años"):
        Estudiante("Carlos Pérez", 1001, 121, 3.8)


# Caso 4.3: Edad no entera
def test_edad_no_entera():
    with pytest.raises(ValueError, match="La edad debe estar entre 0 y 120 años"):
        Estudiante("Carlos Pérez", 1001, "20", 3.8)


# Caso 5.1: Promedio menor que 0.0
def test_promedio_menor_a_cero():
    with pytest.raises(ValueError, match="El promedio debe estar entre 0.0 y 4.0"):
        Estudiante("Carlos Pérez", 1001, 20, -0.5)


# Caso 5.2: Promedio mayor que 4.0
def test_promedio_mayor_a_4():
    with pytest.raises(ValueError, match="El promedio debe estar entre 0.0 y 4.0"):
        Estudiante("Carlos Pérez", 1001, 20, 4.5)


# Caso 5.3: Promedio no numérico
def test_promedio_no_numerico():
    with pytest.raises(ValueError, match="El promedio debe estar entre 0.0 y 4.0"):
        Estudiante("Carlos Pérez", 1001, 20, "3.8")