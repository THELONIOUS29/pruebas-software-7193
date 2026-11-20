class Estudiante:
    def __init__(self, nombre, id_estudiante, edad, promedio):

        # Validación del nombre
        if nombre is None or not isinstance(nombre, str) or nombre.strip() == "":
            raise ValueError("El nombre debe ser una cadena de texto válida")

        # Validación del ID del estudiante
        if not isinstance(id_estudiante, int) or id_estudiante <= 0:
            raise ValueError("El ID del estudiante debe ser un número entero positivo")

        # Validación de la edad
        if not isinstance(edad, int) or edad < 0 or edad > 120:
            raise ValueError("La edad debe estar entre 0 y 120 años")

        # Validación del promedio
        if not isinstance(promedio, (int, float)) or promedio < 0.0 or promedio > 4.0:
            raise ValueError("El promedio debe estar entre 0.0 y 4.0")

        self.nombre = nombre
        self.id_estudiante = id_estudiante
        self.edad = edad
        self.promedio = promedio