"""
Módulo Pedido - Sistema de Gestión de Pedidos TechShop
Representa una orden de compra con productos, cantidades y cálculo de costo total.
"""

from producto import Producto

class ItemPedido:
    """Representa un ítem dentro de un pedido (producto + cantidad)."""

    def __init__(self, producto: Producto, cantidad: int):
        if cantidad <= 0:
            raise ValueError(f"La cantidad debe ser mayor a cero: {cantidad}")
        self.producto = producto
        self.cantidad = cantidad

    @property
    def subtotal(self) -> float:
        """Calcula el subtotal del ítem (precio × cantidad)."""
        return self.producto.precio * self.cantidad

    def __repr__(self) -> str:
        return (
            f"ItemPedido(producto='{self.producto.nombre}', "
            f"cantidad={self.cantidad}, subtotal={self.subtotal:.2f})"
        )

class Pedido:

    ESTADOS_VALIDOS = ("pendiente", "procesado", "rechazado")

    def __init__(self, numero: str, cliente: str):
        self.numero = numero
        self.cliente = cliente
        self.items: list[ItemPedido] = []
        self.estado = "pendiente"

    def agregar_item(self, producto: Producto, cantidad: int) -> None:
        item = ItemPedido(producto, cantidad)
        self.items.append(item)

    def calcular_total(self) -> float:
        return sum(item.subtotal for item in self.items)

    def marcar_como(self, estado: str) -> None:
        if estado not in self.ESTADOS_VALIDOS:
            raise ValueError(
                f"Estado inválido: '{estado}'. "
                f"Valores permitidos: {self.ESTADOS_VALIDOS}"
            )
        self.estado = estado

    def __repr__(self) -> str:
        return (
            f"Pedido(numero='{self.numero}', cliente='{self.cliente}', "
            f"items={len(self.items)}, total={self.calcular_total():.2f}, "
            f"estado='{self.estado}')"
        )
