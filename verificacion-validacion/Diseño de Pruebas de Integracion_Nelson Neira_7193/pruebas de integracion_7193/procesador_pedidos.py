"""
Módulo ProcesadorDePedidos - Sistema de Gestión de Pedidos TechShop
Valida y procesa pedidos, gestionando el stock de productos.
"""

from pedido import Pedido

class ResultadoProcesamiento:
    """Encapsula el resultado de procesar un pedido."""

    def __init__(self, exitoso: bool, mensaje: str, pedido: Pedido):
        self.exitoso = exitoso
        self.mensaje = mensaje
        self.pedido = pedido

    def __repr__(self) -> str:
        return (
            f"ResultadoProcesamiento(exitoso={self.exitoso}, "
            f"mensaje='{self.mensaje}', pedido={self.pedido.numero})"
        )

class ProcesadorDePedidos:
    def procesar(self, pedido: Pedido) -> ResultadoProcesamiento:
        if not pedido.items:
            pedido.marcar_como("rechazado")
            return ResultadoProcesamiento(
                exitoso=False,
                mensaje="El pedido no contiene productos.",
                pedido=pedido,
            )

        # Fase 1: Validar disponibilidad de todos los ítems antes de tocar el stock
        productos_sin_stock = []
        for item in pedido.items:
            if not item.producto.verificar_disponibilidad(item.cantidad):
                productos_sin_stock.append(
                    f"'{item.producto.nombre}' "
                    f"(solicitado: {item.cantidad}, disponible: {item.producto.stock})"
                )

        # Fase 2: Si hay productos sin stock suficiente, rechazar el pedido
        if productos_sin_stock:
            pedido.marcar_como("rechazado")
            detalle = "; ".join(productos_sin_stock)
            return ResultadoProcesamiento(
                exitoso=False,
                mensaje=f"Pedido rechazado. Stock insuficiente para: {detalle}.",
                pedido=pedido,
            )

        # Fase 3: Descontar stock de todos los productos y marcar como procesado
        for item in pedido.items:
            item.producto.actualizar_stock(item.cantidad)

        pedido.marcar_como("procesado")
        return ResultadoProcesamiento(
            exitoso=True,
            mensaje=(
                f"Pedido procesado correctamente. "
                f"Total: ${pedido.calcular_total():.2f}"
            ),
            pedido=pedido,
        )
