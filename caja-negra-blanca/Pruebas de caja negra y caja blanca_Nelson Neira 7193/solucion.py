"""Soluciones para los escenarios de caja negra y caja blanca."""


def asignar_calificacion(examen1, examen2, examen3, examen4):
    """Devuelve la letra final según el promedio de cuatro exámenes."""
    promedio = (examen1 + examen2 + examen3 + examen4) / 4

    if promedio >= 90:
        return "A"
    if promedio >= 80:
        return "B"
    if promedio >= 70:
        return "C"
    return "F"


def aplicar_descuento(total_compra):
    """Aplica el descuento correspondiente y devuelve el total final."""
    if 100 <= total_compra < 200:
        return total_compra * 0.90
    if total_compra >= 200:
        return total_compra * 0.80
    return total_compra
