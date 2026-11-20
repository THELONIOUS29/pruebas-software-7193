"""Escenario 1: Caja Negra - Sistema de calificacion de estudiantes."""


def asignar_calificacion(examen1, examen2, examen3, examen4):
    """Devuelve la letra final segun el promedio de cuatro examenes."""
    promedio = (examen1 + examen2 + examen3 + examen4) / 4

    if promedio >= 90:
        return "A"
    if promedio >= 80:
        return "B"
    if promedio >= 70:
        return "C"
    return "F"


def main():
    print("Sistema de calificacion de estudiantes")
    examen1 = float(input("Ingrese la nota del examen 1: "))
    examen2 = float(input("Ingrese la nota del examen 2: "))
    examen3 = float(input("Ingrese la nota del examen 3: "))
    examen4 = float(input("Ingrese la nota del examen 4: "))

    promedio = (examen1 + examen2 + examen3 + examen4) / 4
    calificacion = asignar_calificacion(examen1, examen2, examen3, examen4)

    print(f"Promedio final: {promedio:.2f}")
    print(f"Calificacion asignada: {calificacion}")


if __name__ == "__main__":
    main()
