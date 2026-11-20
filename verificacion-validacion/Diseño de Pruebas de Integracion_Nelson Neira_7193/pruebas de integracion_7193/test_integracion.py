"""
Pruebas de integración - Sistema de Gestión de Pedidos TechShop
Verifica la correcta interacción entre los módulos: Producto, Pedido y ProcesadorDePedidos.
"""

import unittest

from producto import Producto
from pedido import Pedido, ItemPedido
from procesador_pedidos import ProcesadorDePedidos

# ---------------------------------------------------------------------------
# Pruebas unitarias del módulo Producto
# ---------------------------------------------------------------------------
class TestProducto(unittest.TestCase):
    """Pruebas del módulo Producto."""

    def setUp(self):
        """Inicializa un producto de prueba antes de cada test."""
        self.laptop = Producto(
            codigo="TECH-001",
            nombre="Laptop ProMax",
            precio=1_200.00,
            stock=10,
        )

    # --- verificar_disponibilidad ---
    def test_disponibilidad_con_stock_suficiente(self):
        """Debe retornar True cuando hay stock suficiente."""
        self.assertTrue(self.laptop.verificar_disponibilidad(5))

    def test_disponibilidad_con_stock_exacto(self):
        """Debe retornar True cuando se solicita exactamente el stock disponible."""
        self.assertTrue(self.laptop.verificar_disponibilidad(10))

    def test_disponibilidad_sin_stock_suficiente(self):
        """Debe retornar False cuando se solicita más del stock disponible."""
        self.assertFalse(self.laptop.verificar_disponibilidad(11))

    def test_disponibilidad_cantidad_invalida(self):
        """Debe lanzar ValueError si la cantidad solicitada es 0 o negativa."""
        with self.assertRaises(ValueError):
            self.laptop.verificar_disponibilidad(0)
        with self.assertRaises(ValueError):
            self.laptop.verificar_disponibilidad(-3)

    # --- actualizar_stock ---
    def test_actualizar_stock_correcto(self):
        """El stock debe decrementarse correctamente tras una actualización válida."""
        self.laptop.actualizar_stock(3)
        self.assertEqual(self.laptop.stock, 7)

    def test_actualizar_stock_completo(self):
        """Debe permitir descontar todo el stock disponible."""
        self.laptop.actualizar_stock(10)
        self.assertEqual(self.laptop.stock, 0)

    def test_actualizar_stock_insuficiente(self):
        """Debe lanzar ValueError cuando se intenta descontar más del stock disponible."""
        with self.assertRaises(ValueError):
            self.laptop.actualizar_stock(15)

    def test_actualizar_stock_cantidad_invalida(self):
        """Debe lanzar ValueError si la cantidad a descontar es 0 o negativa."""
        with self.assertRaises(ValueError):
            self.laptop.actualizar_stock(0)

    # --- Constructor ---
    def test_crear_producto_precio_negativo(self):
        """Debe lanzar ValueError al crear un producto con precio negativo."""
        with self.assertRaises(ValueError):
            Producto("ERR-001", "Producto Malo", -10.0, 5)

    def test_crear_producto_stock_negativo(self):
        """Debe lanzar ValueError al crear un producto con stock negativo."""
        with self.assertRaises(ValueError):
            Producto("ERR-002", "Producto Malo", 10.0, -1)


# ---------------------------------------------------------------------------
# Pruebas unitarias del módulo Pedido
# ---------------------------------------------------------------------------
class TestPedido(unittest.TestCase):
    """Pruebas del módulo Pedido."""

    def setUp(self):
        """Inicializa productos y un pedido de prueba antes de cada test."""
        self.mouse = Producto("TECH-002", "Mouse Inalámbrico", 25.00, 50)
        self.teclado = Producto("TECH-003", "Teclado Mecánico", 75.00, 30)
        self.pedido = Pedido(numero="PED-001", cliente="Carlos Ruiz")

    def test_pedido_vacio_total_cero(self):
        """Un pedido sin ítems debe tener total igual a 0."""
        self.assertEqual(self.pedido.calcular_total(), 0.0)

    def test_agregar_un_item_y_calcular_total(self):
        """Un pedido con un solo ítem debe calcular el subtotal correctamente."""
        self.pedido.agregar_item(self.mouse, 2)
        self.assertEqual(self.pedido.calcular_total(), 50.00)  # 25 * 2

    def test_agregar_multiples_items_y_calcular_total(self):
        """El total debe ser la suma de todos los subtotales."""
        self.pedido.agregar_item(self.mouse, 2)    # 25 * 2 = 50
        self.pedido.agregar_item(self.teclado, 1)  # 75 * 1 = 75
        self.assertEqual(self.pedido.calcular_total(), 125.00)

    def test_estado_inicial_pendiente(self):
        """El estado inicial de un pedido debe ser 'pendiente'."""
        self.assertEqual(self.pedido.estado, "pendiente")

    def test_marcar_como_procesado(self):
        """Debe ser posible cambiar el estado a 'procesado'."""
        self.pedido.marcar_como("procesado")
        self.assertEqual(self.pedido.estado, "procesado")

    def test_marcar_como_rechazado(self):
        """Debe ser posible cambiar el estado a 'rechazado'."""
        self.pedido.marcar_como("rechazado")
        self.assertEqual(self.pedido.estado, "rechazado")

    def test_marcar_como_estado_invalido(self):
        """Debe lanzar ValueError si el estado no es válido."""
        with self.assertRaises(ValueError):
            self.pedido.marcar_como("cancelado")

    def test_item_cantidad_invalida(self):
        """Debe lanzar ValueError al crear un ItemPedido con cantidad 0 o negativa."""
        with self.assertRaises(ValueError):
            ItemPedido(self.mouse, 0)
        with self.assertRaises(ValueError):
            ItemPedido(self.mouse, -1)


# ---------------------------------------------------------------------------
# Pruebas de integración: interacción entre los tres módulos
# ---------------------------------------------------------------------------
class TestIntegracionProcesadorDePedidos(unittest.TestCase):
    """
    Pruebas de integración del ProcesadorDePedidos.
    Verifica el flujo completo: Producto → Pedido → ProcesadorDePedidos.
    """

    def setUp(self):
        """Inicializa el escenario de prueba con productos y procesador."""
        self.procesador = ProcesadorDePedidos()

        self.laptop = Producto("TECH-001", "Laptop ProMax", 1_200.00, stock=5)
        self.auriculares = Producto("TECH-004", "Auriculares HD", 150.00, stock=20)
        self.ssd = Producto("TECH-005", "SSD 1TB", 90.00, stock=3)

    # --- Pedidos válidos (stock suficiente) ---
    def test_procesar_pedido_valido_simple(self):
        """Un pedido con stock suficiente debe procesarse correctamente."""
        pedido = Pedido("PED-001", "Ana García")
        pedido.agregar_item(self.laptop, 2)

        resultado = self.procesador.procesar(pedido)

        self.assertTrue(resultado.exitoso)
        self.assertEqual(pedido.estado, "procesado")
        self.assertEqual(self.laptop.stock, 3)  

    def test_procesar_pedido_valido_multiple(self):
        """Un pedido con múltiples productos y stock suficiente debe procesarse."""
        pedido = Pedido("PED-002", "Luis Torres")
        pedido.agregar_item(self.laptop, 1)        
        pedido.agregar_item(self.auriculares, 5)   

        resultado = self.procesador.procesar(pedido)

        self.assertTrue(resultado.exitoso)
        self.assertEqual(pedido.estado, "procesado")
        self.assertEqual(self.laptop.stock, 4)
        self.assertEqual(self.auriculares.stock, 15)

    def test_procesar_pedido_calcula_total_correcto(self):
        """El total del pedido procesado debe ser la suma de los subtotales."""
        pedido = Pedido("PED-003", "María López")
        pedido.agregar_item(self.laptop, 1)        
        pedido.agregar_item(self.auriculares, 2)   

        resultado = self.procesador.procesar(pedido)

        self.assertTrue(resultado.exitoso)
        self.assertEqual(pedido.calcular_total(), 1_500.00)

    def test_procesar_pedido_stock_exacto(self):
        """Debe procesar correctamente cuando se solicita exactamente el stock disponible."""
        pedido = Pedido("PED-004", "Pedro Sánchez")
        pedido.agregar_item(self.ssd, 3)  

        resultado = self.procesador.procesar(pedido)

        self.assertTrue(resultado.exitoso)
        self.assertEqual(pedido.estado, "procesado")
        self.assertEqual(self.ssd.stock, 0)

    # --- Pedidos rechazados (stock insuficiente) ---
    def test_rechazar_pedido_stock_insuficiente(self):
        """Un pedido rechazado no debe modificar el stock."""
        stock_inicial = self.laptop.stock
        pedido = Pedido("PED-005", "Sofía Ramírez")
        pedido.agregar_item(self.laptop, 10)  

        resultado = self.procesador.procesar(pedido)

        self.assertFalse(resultado.exitoso)
        self.assertEqual(pedido.estado, "rechazado")
        self.assertEqual(self.laptop.stock, stock_inicial)  

    def test_rechazar_pedido_multiples_sin_stock(self):
        """Si varios productos no tienen stock, el pedido debe rechazarse."""
        pedido = Pedido("PED-006", "Diego Morales")
        pedido.agregar_item(self.laptop, 10)      
        pedido.agregar_item(self.ssd, 10)         

        resultado = self.procesador.procesar(pedido)

        self.assertFalse(resultado.exitoso)
        self.assertEqual(pedido.estado, "rechazado")
        # Stocks no deben cambiar
        self.assertEqual(self.laptop.stock, 5)
        self.assertEqual(self.ssd.stock, 3)

    def test_rechazar_pedido_un_producto_sin_stock(self):
        """Si un solo producto del pedido no tiene stock, el pedido completo se rechaza."""
        pedido = Pedido("PED-007", "Elena Vargas")
        pedido.agregar_item(self.auriculares, 2)  
        pedido.agregar_item(self.ssd, 99)         

        resultado = self.procesador.procesar(pedido)

        self.assertFalse(resultado.exitoso)
        self.assertEqual(pedido.estado, "rechazado")
        # Ningún stock debe cambiar dado que el pedido fue rechazado
        self.assertEqual(self.auriculares.stock, 20)
        self.assertEqual(self.ssd.stock, 3)

    # --- Pedido vacío ---
    def test_rechazar_pedido_vacio(self):
        """Un pedido sin ítems debe ser rechazado."""
        pedido = Pedido("PED-008", "Roberto Castro")

        resultado = self.procesador.procesar(pedido)

        self.assertFalse(resultado.exitoso)
        self.assertEqual(pedido.estado, "rechazado")

    # --- Procesamiento secuencial ---
    def test_procesar_multiples_pedidos_secuencialmente(self):
        """
        Procesar más de un pedido debe reflejar el stock actualizado
        en los pedidos subsecuentes.
        """
        # Primer pedido consume 2 laptops (stock: 5 → 3)
        pedido1 = Pedido("PED-009", "Cliente A")
        pedido1.agregar_item(self.laptop, 2)
        resultado1 = self.procesador.procesar(pedido1)

        self.assertTrue(resultado1.exitoso)
        self.assertEqual(self.laptop.stock, 3)

        # Segundo pedido solicita 3 laptops (stock: 3 → 0)
        pedido2 = Pedido("PED-010", "Cliente B")
        pedido2.agregar_item(self.laptop, 3)
        resultado2 = self.procesador.procesar(pedido2)

        self.assertTrue(resultado2.exitoso)
        self.assertEqual(self.laptop.stock, 0)

        # Tercer pedido excede el stock ya agotado
        pedido3 = Pedido("PED-011", "Cliente C")
        pedido3.agregar_item(self.laptop, 1)
        resultado3 = self.procesador.procesar(pedido3)

        self.assertFalse(resultado3.exitoso)
        self.assertEqual(pedido3.estado, "rechazado")
        self.assertEqual(self.laptop.stock, 0)  

if __name__ == "__main__":
    unittest.main(verbosity=2)
