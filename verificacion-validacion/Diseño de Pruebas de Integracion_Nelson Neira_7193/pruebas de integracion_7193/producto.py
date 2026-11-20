"""
Módulo Producto - Sistema de Gestión de Pedidos TechShop
Contiene la clase Producto con información básica y gestión de stock.
"""


class Producto:
    """Representa un producto disponible en el catálogo de TechShop."""

    def __init__(self, codigo: str, nombre: str, precio: float, stock: int):
        if precio < 0:
            raise ValueError(f"El precio no puede ser negativo: {precio}")
        if stock < 0:
            raise ValueError(f"El stock no puede ser negativo: {stock}")

        self.codigo = codigo
        self.nombre = nombre
        self.precio = precio
        self.stock = stock

    def verificar_disponibilidad(self, cantidad: int) -> bool:
        if cantidad <= 0:
            raise ValueError(f"La cantidad solicitada debe ser mayor a cero: {cantidad}")
        return self.stock >= cantidad

    def actualizar_stock(self, cantidad: int) -> None:
        if cantidad <= 0:
            raise ValueError(f"La cantidad a descontar debe ser mayor a cero: {cantidad}")
        if not self.verificar_disponibilidad(cantidad):
            raise ValueError(
                f"Stock insuficiente para '{self.nombre}'. "
                f"Disponible: {self.stock}, Solicitado: {cantidad}"
            )
        self.stock -= cantidad

    def __repr__(self) -> str:
        return (
            f"Producto(codigo='{self.codigo}', nombre='{self.nombre}', "
            f"precio={self.precio}, stock={self.stock})"
        )
