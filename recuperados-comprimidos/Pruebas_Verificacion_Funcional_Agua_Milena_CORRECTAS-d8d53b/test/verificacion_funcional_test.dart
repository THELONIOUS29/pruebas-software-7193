import 'package:flutter_test/flutter_test.dart';

import 'package:agua_milena_app/dominio/entidades/rol_usuario.dart';
import 'package:agua_milena_app/datos/modelos/producto.dart';
import 'package:agua_milena_app/datos/modelos/item_venta.dart';
import 'package:agua_milena_app/datos/modelos/item_ruta.dart';
import 'package:agua_milena_app/datos/modelos/ruta.dart';
import 'package:agua_milena_app/datos/servicios/servicio_autenticacion.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('HU-01 / Seguridad de contraseña y hash', () {
    test('PAVF_001_HU_01_01_V01 - acepta contraseña segura', () {
      final servicio = ServicioAutenticacion();
      expect(servicio.esContrasenaValida('Agua2026!'), isTrue);
    });

    test('PAVF_002_HU_01_01_V02 - rechaza contraseña menor a 8 caracteres', () {
      final servicio = ServicioAutenticacion();
      expect(servicio.esContrasenaValida('A1!'), isFalse);
    });

    test('PAVF_003_HU_01_02_V01 - rechaza contraseña sin número', () {
      final servicio = ServicioAutenticacion();
      expect(servicio.esContrasenaValida('AguaMilena!'), isFalse);
    });

    test('PAVF_004_HU_01_02_V02 - rechaza contraseña sin carácter especial', () {
      final servicio = ServicioAutenticacion();
      expect(servicio.esContrasenaValida('AguaMilena2026'), isFalse);
    });

    test('PAVF_005_HU_01_03_V01 - hash PBKDF2 valida contraseña correcta', () {
      final servicio = ServicioAutenticacion();
      final hash = servicio.hashContrasena('Agua2026!');

      expect(hash.startsWith('pbkdf2_sha256\$210000\$'), isTrue);
      expect(servicio.verificarContrasena('Agua2026!', hash), isTrue);
    });

    test('PAVF_006_HU_01_03_V02 - hash PBKDF2 rechaza contraseña incorrecta', () {
      final servicio = ServicioAutenticacion();
      final hash = servicio.hashContrasena('Agua2026!');

      expect(servicio.verificarContrasena('Incorrecta2026!', hash), isFalse);
    });
  });

  group('HU-02 / Roles, usuario y permisos base', () {
    test('PAVF_011_HU_02_05_V01 - reconoce rol administrador', () {
      expect(RolUsuario.desdeTexto('admin'), RolUsuario.admin);
      expect(RolUsuario.desdeTexto('administrador'), RolUsuario.admin);
    });

    test('PAVF_012_HU_02_05_V02 - rechaza rol no reconocido', () {
      expect(() => RolUsuario.desdeTexto('supervisor'), throwsException);
    });

    test('PAVF_013_HU_02_06_V01 - crea usuario vendedor asociado', () {
      final usuario = UsuarioApp.desdeJson({
        'id': 'u-01',
        'email': 'vendedor@aguamilena.com',
        'nombre': 'Vendedor 1',
        'rol': 'vendedor',
        'vendedor_id': 'v-01',
      });

      expect(usuario.rol, RolUsuario.vendedor);
      expect(usuario.vendedorId, 'v-01');
    });

    test('PAVF_014_HU_02_06_V02 - limpia vendedor_id al cambiar de rol', () {
      const usuario = UsuarioApp(
        id: 'u-01',
        email: 'vendedor@aguamilena.com',
        nombre: 'Vendedor 1',
        rol: RolUsuario.vendedor,
        vendedorId: 'v-01',
      );

      final actualizado = usuario.copiarCon(
        rol: RolUsuario.planta,
        limpiarVendedorId: true,
      );

      expect(actualizado.rol, RolUsuario.planta);
      expect(actualizado.vendedorId, isNull);
    });
  });

  group('HU-05 / Productos e inventario', () {
    Producto producto({
      int stock = 20,
      int stockMinimo = 5,
      int? stockBajoCalculado,
      String catalogo = 'distribuidora',
    }) {
      return Producto.desdeJson({
        'id': 'p-01',
        'nombre': 'Bidón de agua',
        'descripcion': 'Bidón retornable',
        'unidad': 'bidón',
        'precio': 1.50,
        'stock': stock,
        'stock_minimo': stockMinimo,
        'stock_bajo_calculado': stockBajoCalculado,
        'catalogo': catalogo,
        'url_imagen': 'https://example.com/bidon.png',
        'creado_en': '2026-06-01T10:00:00',
        'actualizado_en': '2026-06-01T11:00:00',
      });
    }

    test('PAVF_021_HU_05_01_V01 - crea producto desde JSON válido', () {
      final p = producto();
      expect(p.nombre, 'Bidón de agua');
      expect(p.precio, 1.50);
      expect(p.stock, 20);
      expect(p.catalogo, CatalogoProducto.distribuidora);
    });

    test('PAVF_022_HU_05_01_V02 - reconoce catálogo vendedor', () {
      final p = producto(catalogo: 'vendedor');
      expect(p.catalogo, CatalogoProducto.vendedor);
      expect(p.aJson()['catalogo'], 'vendedor');
    });

    test('PAVF_023_HU_05_02_V01 - clasifica stock crítico', () {
      final p = producto(stock: 5, stockMinimo: 5);
      expect(p.esCritico, isTrue);
      expect(p.esBajo, isFalse);
    });

    test('PAVF_024_HU_05_02_V02 - clasifica stock bajo sin ser crítico', () {
      final p = producto(stock: 7, stockMinimo: 5, stockBajoCalculado: 8);
      expect(p.esCritico, isFalse);
      expect(p.esBajo, isTrue);
    });

    test('PAVF_025_HU_05_03_V01 - stock normal no genera bajo ni crítico', () {
      final p = producto(stock: 15, stockMinimo: 5, stockBajoCalculado: 8);
      expect(p.esCritico, isFalse);
      expect(p.esBajo, isFalse);
    });

    test('PAVF_026_HU_05_03_V02 - copiarCon conserva datos no modificados', () {
      final p = producto();
      final actualizado = p.copiarCon(precio: 2.00, stock: 30);

      expect(actualizado.precio, 2.00);
      expect(actualizado.stock, 30);
      expect(actualizado.nombre, p.nombre);
      expect(actualizado.stockMinimo, p.stockMinimo);
    });
  });

  group('HU-07 / Ventas e ítems de venta', () {
    test('PAVF_041_HU_07_02_V01 - calcula subtotal de carrito', () {
      final item = ItemCarrito(
        productoId: 'p-01',
        nombreProducto: 'Bidón de agua',
        precioUnitario: 1.50,
        unidad: 'bidón',
        cantidad: 4,
      );

      expect(item.subtotal, 6.00);
    });

    test('PAVF_042_HU_07_02_V02 - convierte carrito a JSON de item de venta', () {
      final item = ItemCarrito(
        productoId: 'p-01',
        nombreProducto: 'Bidón de agua',
        precioUnitario: 1.50,
        unidad: 'bidón',
        cantidad: 3,
      );

      final json = item.aJsonItemVenta('venta-01');
      expect(json['venta_id'], 'venta-01');
      expect(json['producto_id'], 'p-01');
      expect(json['cantidad'], 3);
      expect(json['subtotal'], 4.50);
    });

    test('PAVF_043_HU_07_03_V01 - identifica bidón con tilde y sin tilde', () {
      final sinTilde = ItemCarrito(
        productoId: 'p-01',
        nombreProducto: 'Bidon de agua',
        precioUnitario: 1.50,
        unidad: 'unidad',
      );
      final conTilde = ItemCarrito(
        productoId: 'p-02',
        nombreProducto: 'Bidón retornable',
        precioUnitario: 1.50,
        unidad: 'unidad',
      );

      expect(sinTilde.esBidon, isTrue);
      expect(conTilde.esBidon, isTrue);
    });

    test('PAVF_044_HU_07_03_V02 - producto funda no se identifica como bidón', () {
      final item = ItemCarrito(
        productoId: 'p-03',
        nombreProducto: 'Funda de agua',
        precioUnitario: 0.25,
        unidad: 'funda',
      );

      expect(item.esBidon, isFalse);
    });

    test('PAVF_045_HU_07_05_V01 - crea ItemVenta desde JSON', () {
      final item = ItemVenta.desdeJson({
        'id': 'iv-01',
        'venta_id': 'venta-01',
        'producto_id': 'p-01',
        'nombre_producto': 'Bidón de agua',
        'cantidad': 2,
        'precio_unitario': 1.50,
        'subtotal': 3.00,
      });

      expect(item.nombreProducto, 'Bidón de agua');
      expect(item.cantidad, 2);
      expect(item.subtotal, 3.00);
      expect(item.esBidon, isTrue);
    });
  });

  group('HU-09 / Rutas de distribución', () {
    test('PAVF_053_HU_09_01_V01 - convierte estados de ruta', () {
      expect(EstadoRutaExt.desdeTexto('pendiente'), EstadoRuta.pendiente);
      expect(EstadoRutaExt.desdeTexto('parcial'), EstadoRuta.parcial);
      expect(EstadoRutaExt.desdeTexto('pagado'), EstadoRuta.pagado);
      expect(EstadoRutaExt.desdeTexto('otro'), EstadoRuta.sinCierre);
    });

    test('PAVF_054_HU_09_01_V02 - etiquetas y valores de estados son correctos', () {
      expect(EstadoRuta.pagado.etiqueta, 'Pagado');
      expect(EstadoRuta.parcial.etiqueta, 'Abono parcial');
      expect(EstadoRuta.sinCierre.valor, 'sin_cierre');
      expect(EstadoRuta.pendiente.valor, 'pendiente');
    });

    test('PAVF_055_HU_09_03_V01 - calcula productos de salida', () {
      final ruta = Ruta(
        id: 'r-01',
        vendedorId: 'v-01',
        nombreVendedor: 'Vendedor',
        fecha: DateTime(2026, 6, 1),
        montoTotal: 10,
        montoCobrado: 0,
        estado: EstadoRuta.pendiente,
        creadoEn: DateTime(2026, 6, 1),
        items: const [
          ItemRuta(
            id: 'ir-01',
            rutaId: 'r-01',
            productoId: 'p-01',
            nombreProducto: 'Bidón',
            unidad: 'unidad',
            precioUnitario: 1.50,
            cantidadSalida: 5,
          ),
          ItemRuta(
            id: 'ir-02',
            rutaId: 'r-01',
            productoId: 'p-02',
            nombreProducto: 'Funda',
            unidad: 'funda',
            precioUnitario: 0.25,
            cantidadSalida: 10,
          ),
        ],
      );

      expect(ruta.totalProductosSalida, 15);
      expect(ruta.estaCerrada, isFalse);
      expect(ruta.totalVendidos, isNull);
    });

    test('PAVF_056_HU_09_04_V01 - ruta cerrada calcula vendidos y faltantes', () {
      final ruta = Ruta(
        id: 'r-02',
        vendedorId: 'v-01',
        nombreVendedor: 'Vendedor',
        fecha: DateTime(2026, 6, 1),
        montoTotal: 10,
        montoCobrado: 0,
        estado: EstadoRuta.pendiente,
        creadoEn: DateTime(2026, 6, 1),
        items: const [
          ItemRuta(
            id: 'ir-01',
            rutaId: 'r-02',
            productoId: 'p-01',
            nombreProducto: 'Bidón',
            unidad: 'unidad',
            precioUnitario: 1.50,
            cantidadSalida: 10,
            cantidadSinVender: 2,
            cantidadRetornoVacio: 8,
          ),
        ],
      );

      expect(ruta.estaCerrada, isTrue);
      expect(ruta.totalVendidos, 8);
      expect(ruta.totalFaltantes, 0);
    });
  });

  group('HU-10 / Abonos, saldos y excedentes', () {
    test('PAVF_061_HU_10_01_V01 - calcula saldo pendiente parcial', () {
      final ruta = Ruta(
        id: 'r-03',
        vendedorId: 'v-01',
        nombreVendedor: 'Vendedor',
        fecha: DateTime(2026, 6, 1),
        montoTotal: 100,
        montoCobrado: 40,
        estado: EstadoRuta.parcial,
        creadoEn: DateTime(2026, 6, 1),
      );

      expect(ruta.saldoPendiente, 60);
      expect(ruta.saldoPendienteVisible, 60);
      expect(ruta.tieneSaldoAFavor, isFalse);
    });

    test('PAVF_065_HU_10_03_V01 - calcula saldo a favor por excedente', () {
      final ruta = Ruta(
        id: 'r-04',
        vendedorId: 'v-01',
        nombreVendedor: 'Vendedor',
        fecha: DateTime(2026, 6, 1),
        montoTotal: 100,
        montoCobrado: 130,
        estado: EstadoRuta.pagado,
        creadoEn: DateTime(2026, 6, 1),
      );

      expect(ruta.saldoPendiente, -30);
      expect(ruta.saldoPendienteVisible, 0);
      expect(ruta.tieneSaldoAFavor, isTrue);
      expect(ruta.saldoAFavor, 30);
    });
  });

  group('HU-11 / Bidones', () {
    test('PAVF_073_HU_11_03_V01 - calcula bidones prestados finales', () {
      final ruta = Ruta(
        id: 'r-05',
        vendedorId: 'v-01',
        nombreVendedor: 'Vendedor',
        vendedorBidonesPropios: 5,
        fecha: DateTime(2026, 6, 1),
        montoTotal: 10,
        montoCobrado: 10,
        estado: EstadoRuta.pagado,
        creadoEn: DateTime(2026, 6, 1),
        bidonesLlenosIniciales: 6,
        bidonesVaciosIniciales: 2,
        bidonesCargadosHoy: 4,
        items: const [
          ItemRuta(
            id: 'ir-01',
            rutaId: 'r-05',
            productoId: 'p-01',
            nombreProducto: 'Bidón',
            unidad: 'unidad',
            precioUnitario: 1.50,
            cantidadSalida: 10,
            cantidadSinVender: 3,
            cantidadRetornoVacio: 7,
          ),
        ],
      );

      expect(ruta.bidonesVendidos, 7);
      expect(ruta.bidonesLlenosFinales, 3);
      expect(ruta.bidonesVaciosFinales, 9);
      expect(ruta.bidonesPrestadosIniciales, 3);
      expect(ruta.bidonesPrestadosFinales, 7);
    });

    test('PAVF_074_HU_11_03_V02 - evita bidones llenos finales negativos', () {
      final ruta = Ruta(
        id: 'r-06',
        vendedorId: 'v-01',
        nombreVendedor: 'Vendedor',
        vendedorBidonesPropios: 20,
        fecha: DateTime(2026, 6, 1),
        montoTotal: 10,
        montoCobrado: 10,
        estado: EstadoRuta.pagado,
        creadoEn: DateTime(2026, 6, 1),
        bidonesLlenosIniciales: 2,
        bidonesCargadosHoy: 0,
        items: const [
          ItemRuta(
            id: 'ir-01',
            rutaId: 'r-06',
            productoId: 'p-01',
            nombreProducto: 'Bidón',
            unidad: 'unidad',
            precioUnitario: 1.50,
            cantidadSalida: 10,
            cantidadSinVender: 0,
            cantidadRetornoVacio: 10,
          ),
        ],
      );

      expect(ruta.bidonesLlenosFinales, 0);
    });
  });

  group('HU-12, HU-14 y HU-15 / Alertas y datos para reportes', () {
    test('PAVF_081_HU_12_01_V01 - stock crítico activa condición de alerta crítica', () {
      final p = Producto.desdeJson({
        'id': 'p-critico',
        'nombre': 'Bidón',
        'unidad': 'unidad',
        'precio': 1.50,
        'stock': 2,
        'stock_minimo': 5,
        'catalogo': 'distribuidora',
        'creado_en': '2026-06-01T10:00:00',
        'actualizado_en': '2026-06-01T11:00:00',
      });

      expect(p.esCritico, isTrue);
    });

    test('PAVF_083_HU_12_02_V01 - stock bajo activa condición de alerta preventiva', () {
      final p = Producto.desdeJson({
        'id': 'p-bajo',
        'nombre': 'Funda',
        'unidad': 'funda',
        'precio': 0.25,
        'stock': 7,
        'stock_minimo': 5,
        'stock_bajo_calculado': 8,
        'catalogo': 'distribuidora',
        'creado_en': '2026-06-01T10:00:00',
        'actualizado_en': '2026-06-01T11:00:00',
      });

      expect(p.esCritico, isFalse);
      expect(p.esBajo, isTrue);
    });

    test('PAVF_122_HU_15_01_V02 - item venta conserva datos para desglose de reporte', () {
      final item = ItemVenta.desdeJson({
        'id': 'iv-reporte',
        'venta_id': 'venta-01',
        'producto_id': 'p-01',
        'nombre_producto': 'Bidón de agua',
        'cantidad': 5,
        'precio_unitario': 1.50,
        'subtotal': 7.50,
      });

      expect(item.nombreProducto, 'Bidón de agua');
      expect(item.cantidad, 5);
      expect(item.subtotal, 7.50);
    });
  });
}
