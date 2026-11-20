import 'package:flutter_test/flutter_test.dart';

import 'package:agua_milena_app/dominio/entidades/rol_usuario.dart';
import 'package:agua_milena_app/datos/modelos/producto.dart';
import 'package:agua_milena_app/datos/modelos/item_venta.dart';
import 'package:agua_milena_app/datos/modelos/item_ruta.dart';
import 'package:agua_milena_app/datos/modelos/ruta.dart';
import 'package:agua_milena_app/datos/servicios/servicio_autenticacion.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('HU-01 Inicio de sesión seguro / reglas de seguridad', () {
    test('PAVF_01_HU_01_01 - Acepta contraseña segura', () {
      final servicio = ServicioAutenticacion();
      expect(servicio.esContrasenaValida('Agua2026!'), isTrue);
    });

    test('PAVF_02_HU_01_02 - Rechaza contraseña menor a 8 caracteres', () {
      final servicio = ServicioAutenticacion();
      expect(servicio.esContrasenaValida('A1!'), isFalse);
    });

    test('PAVF_03_HU_01_03 - Rechaza contraseña sin número', () {
      final servicio = ServicioAutenticacion();
      expect(servicio.esContrasenaValida('AguaMilena!'), isFalse);
    });

    test('PAVF_04_HU_01_04 - Rechaza contraseña sin carácter especial', () {
      final servicio = ServicioAutenticacion();
      expect(servicio.esContrasenaValida('AguaMilena2026'), isFalse);
    });

    test('PAVF_05_HU_01_05 - Hash PBKDF2 valida contraseña correcta y rechaza incorrecta', () {
      final servicio = ServicioAutenticacion();
      final hash = servicio.hashContrasena('Agua2026!');
      expect(hash.startsWith('pbkdf2_sha256\$210000\$'), isTrue);
      expect(servicio.verificarContrasena('Agua2026!', hash), isTrue);
      expect(servicio.verificarContrasena('Incorrecta2026!', hash), isFalse);
    });
  });

  group('HU-02 Gestión de usuarios y permisos de acceso', () {
    test('PAVF_06_HU_02_01 - Convierte texto admin/administrador a RolUsuario.admin', () {
      expect(RolUsuario.desdeTexto('admin'), RolUsuario.admin);
      expect(RolUsuario.desdeTexto('administrador'), RolUsuario.admin);
    });

    test('PAVF_07_HU_02_02 - Convierte texto planta y vendedor al rol correcto', () {
      expect(RolUsuario.desdeTexto('planta'), RolUsuario.planta);
      expect(RolUsuario.desdeTexto('vendedor'), RolUsuario.vendedor);
    });

    test('PAVF_08_HU_02_03 - Rechaza rol no reconocido', () {
      expect(() => RolUsuario.desdeTexto('supervisor'), throwsException);
    });

    test('PAVF_09_HU_02_04 - Crea UsuarioApp desde JSON con claves en español', () {
      final usuario = UsuarioApp.desdeJson({
        'id': 'u-01',
        'email': 'admin@aguamilena.com',
        'nombre': 'Administrador',
        'rol': 'admin',
        'telefono': 'TELEFONO_DE_EJEMPLO',
      });
      expect(usuario.id, 'u-01');
      expect(usuario.email, 'admin@aguamilena.com');
      expect(usuario.nombre, 'Administrador');
      expect(usuario.rol, RolUsuario.admin);
      expect(usuario.telefono, 'TELEFONO_DE_EJEMPLO');
    });

    test('PAVF_10_HU_02_05 - Limpia vendedor, teléfono y avatar en copia de usuario', () {
      const usuario = UsuarioApp(
        id: 'u-02',
        email: 'vendedor@aguamilena.com',
        nombre: 'Vendedor',
        rol: RolUsuario.vendedor,
        vendedorId: 'v-01',
        telefono: 'TELEFONO_DE_EJEMPLO',
        urlAvatar: 'https://avatar.png',
      );
      final copia = usuario.copiarCon(
        rol: RolUsuario.planta,
        limpiarVendedorId: true,
        limpiarTelefono: true,
        limpiarUrlAvatar: true,
      );
      expect(copia.rol, RolUsuario.planta);
      expect(copia.vendedorId, isNull);
      expect(copia.telefono, isNull);
      expect(copia.urlAvatar, isNull);
    });
  });

  group('HU-05 Gestión de productos del inventario', () {
    Producto productoBase({
      int stock = 20,
      int stockMinimo = 5,
      int? stockBajoCalculado,
      String catalogo = 'distribuidora',
    }) {
      return Producto.desdeJson({
        'id': 'p-01',
        'nombre': 'Bidón de agua',
        'descripcion': 'Bidón de 20 litros',
        'unidad': 'bidón',
        'precio': 1.50,
        'stock': stock,
        'stock_minimo': stockMinimo,
        'stock_bajo_calculado': stockBajoCalculado,
        'catalogo': catalogo,
        'url_imagen': 'https://imagen.png',
        'creado_en': '2026-06-01T10:00:00',
        'actualizado_en': '2026-06-01T11:00:00',
      });
    }

    test('PAVF_11_HU_05_01 - Crea producto desde JSON con datos válidos', () {
      final producto = productoBase();
      expect(producto.id, 'p-01');
      expect(producto.nombre, 'Bidón de agua');
      expect(producto.precio, 1.50);
      expect(producto.stock, 20);
      expect(producto.catalogo, CatalogoProducto.distribuidora);
    });

    test('PAVF_12_HU_05_02 - Clasifica producto como crítico si stock <= stock mínimo', () {
      final producto = productoBase(stock: 5, stockMinimo: 5);
      expect(producto.esCritico, isTrue);
      expect(producto.esBajo, isFalse);
    });

    test('PAVF_13_HU_05_03 - Clasifica producto como bajo si está cerca del mínimo sin ser crítico', () {
      final producto = productoBase(stock: 7, stockMinimo: 5, stockBajoCalculado: 8);
      expect(producto.esCritico, isFalse);
      expect(producto.esBajo, isTrue);
    });

    test('PAVF_14_HU_05_04 - No clasifica como bajo cuando el stock supera el límite calculado', () {
      final producto = productoBase(stock: 15, stockMinimo: 5, stockBajoCalculado: 8);
      expect(producto.esCritico, isFalse);
      expect(producto.esBajo, isFalse);
    });

    test('PAVF_15_HU_05_05 - Serializa producto a JSON para guardar datos permitidos', () {
      final producto = productoBase(catalogo: 'vendedor');
      final json = producto.aJson();
      expect(json['nombre'], 'Bidón de agua');
      expect(json['precio'], 1.50);
      expect(json['stock'], 20);
      expect(json['stock_minimo'], 5);
      expect(json['catalogo'], 'vendedor');
      expect(json['url_imagen'], 'https://imagen.png');
    });

    test('PAVF_16_HU_05_06 - Copia producto modificando precio, stock y stock mínimo', () {
      final producto = productoBase();
      final actualizado = producto.copiarCon(precio: 2.00, stock: 30, stockMinimo: 10);
      expect(actualizado.precio, 2.00);
      expect(actualizado.stock, 30);
      expect(actualizado.stockMinimo, 10);
      expect(actualizado.nombre, producto.nombre);
    });
  });

  group('HU-07 Registro y consulta de ventas', () {
    test('PAVF_17_HU_07_01 - Calcula subtotal del carrito de venta', () {
      final item = ItemCarrito(productoId: 'p-01', nombreProducto: 'Bidón de agua', precioUnitario: 1.50, unidad: 'bidón', cantidad: 4);
      expect(item.subtotal, 6.00);
    });

    test('PAVF_18_HU_07_02 - Identifica bidón con tilde o sin tilde', () {
      final bidonSinTilde = ItemCarrito(productoId: 'p-01', nombreProducto: 'Bidon de agua', precioUnitario: 1.50, unidad: 'unidad');
      final bidonConTilde = ItemCarrito(productoId: 'p-02', nombreProducto: 'Bidón retornable', precioUnitario: 1.50, unidad: 'unidad');
      expect(bidonSinTilde.esBidon, isTrue);
      expect(bidonConTilde.esBidon, isTrue);
    });

    test('PAVF_19_HU_07_03 - No identifica como bidón un producto de funda', () {
      final item = ItemCarrito(productoId: 'p-03', nombreProducto: 'Funda de agua', precioUnitario: 0.25, unidad: 'funda');
      expect(item.esBidon, isFalse);
    });

    test('PAVF_20_HU_07_04 - Convierte carrito a JSON para item de venta', () {
      final item = ItemCarrito(productoId: 'p-01', nombreProducto: 'Bidón de agua', precioUnitario: 1.50, unidad: 'bidón', cantidad: 3);
      final json = item.aJsonItemVenta('venta-01');
      expect(json['venta_id'], 'venta-01');
      expect(json['producto_id'], 'p-01');
      expect(json['cantidad'], 3);
      expect(json['precio_unitario'], 1.50);
      expect(json['subtotal'], 4.50);
    });

    test('PAVF_21_HU_07_05 - Crea ItemVenta desde JSON y conserva subtotal calculado', () {
      final item = ItemVenta.desdeJson({'id': 'iv-01', 'venta_id': 'venta-01', 'producto_id': 'p-01', 'nombre_producto': 'Bidón de agua', 'cantidad': 2, 'precio_unitario': 1.50, 'subtotal': 3.00});
      expect(item.nombreProducto, 'Bidón de agua');
      expect(item.cantidad, 2);
      expect(item.precioUnitario, 1.50);
      expect(item.subtotal, 3.00);
      expect(item.esBidon, isTrue);
    });
  });

  group('HU-09 Gestión de rutas de distribución', () {
    test('PAVF_22_HU_09_01 - Convierte texto de estado a EstadoRuta correcto', () {
      expect(EstadoRutaExt.desdeTexto('pendiente'), EstadoRuta.pendiente);
      expect(EstadoRutaExt.desdeTexto('parcial'), EstadoRuta.parcial);
      expect(EstadoRutaExt.desdeTexto('pagado'), EstadoRuta.pagado);
      expect(EstadoRutaExt.desdeTexto('otro'), EstadoRuta.sinCierre);
    });

    test('PAVF_23_HU_09_02 - Retorna etiqueta y valor de estado de ruta', () {
      expect(EstadoRuta.pagado.etiqueta, 'Pagado');
      expect(EstadoRuta.parcial.etiqueta, 'Abono parcial');
      expect(EstadoRuta.sinCierre.valor, 'sin_cierre');
      expect(EstadoRuta.pendiente.valor, 'pendiente');
    });

    test('PAVF_24_HU_09_03 - Calcula total de productos de salida en ruta', () {
      final ruta = Ruta(id: 'r-01', vendedorId: 'v-01', nombreVendedor: 'Vendedor', fecha: DateTime(2026, 6, 1), montoTotal: 10, montoCobrado: 0, estado: EstadoRuta.pendiente, creadoEn: DateTime(2026, 6, 1), items: const [
        ItemRuta(id: 'ir-01', rutaId: 'r-01', productoId: 'p-01', nombreProducto: 'Bidón', unidad: 'unidad', precioUnitario: 1.50, cantidadSalida: 5),
        ItemRuta(id: 'ir-02', rutaId: 'r-01', productoId: 'p-02', nombreProducto: 'Funda', unidad: 'funda', precioUnitario: 0.25, cantidadSalida: 10),
      ]);
      expect(ruta.totalProductosSalida, 15);
      expect(ruta.estaCerrada, isFalse);
      expect(ruta.totalVendidos, isNull);
    });

    test('PAVF_25_HU_09_04 - Determina ruta cerrada cuando todos los ítems tienen retorno', () {
      final ruta = Ruta(id: 'r-02', vendedorId: 'v-01', nombreVendedor: 'Vendedor', fecha: DateTime(2026, 6, 1), montoTotal: 10, montoCobrado: 0, estado: EstadoRuta.pendiente, creadoEn: DateTime(2026, 6, 1), items: const [
        ItemRuta(id: 'ir-01', rutaId: 'r-02', productoId: 'p-01', nombreProducto: 'Bidón', unidad: 'unidad', precioUnitario: 1.50, cantidadSalida: 10, cantidadSinVender: 2, cantidadRetornoVacio: 8),
      ]);
      expect(ruta.estaCerrada, isTrue);
      expect(ruta.totalVendidos, 8);
      expect(ruta.totalFaltantes, 0);
    });
  });

  group('HU-10 Registro de abonos o cobros relacionados con rutas', () {
    test('PAVF_26_HU_10_01 - Calcula saldo pendiente cuando el cobro es parcial', () {
      final ruta = Ruta(id: 'r-03', vendedorId: 'v-01', nombreVendedor: 'Vendedor', fecha: DateTime(2026, 6, 1), montoTotal: 100, montoCobrado: 40, estado: EstadoRuta.parcial, creadoEn: DateTime(2026, 6, 1));
      expect(ruta.saldoPendiente, 60);
      expect(ruta.saldoPendienteVisible, 60);
      expect(ruta.tieneSaldoAFavor, isFalse);
      expect(ruta.saldoAFavor, 0);
    });

    test('PAVF_27_HU_10_02 - Calcula saldo a favor cuando el cobro supera el total', () {
      final ruta = Ruta(id: 'r-04', vendedorId: 'v-01', nombreVendedor: 'Vendedor', fecha: DateTime(2026, 6, 1), montoTotal: 100, montoCobrado: 130, estado: EstadoRuta.pagado, creadoEn: DateTime(2026, 6, 1));
      expect(ruta.saldoPendiente, -30);
      expect(ruta.saldoPendienteVisible, 0);
      expect(ruta.tieneSaldoAFavor, isTrue);
      expect(ruta.saldoAFavor, 30);
    });
  });

  group('HU-11 Control de bidones llenos, vacíos, propios y prestados', () {
    test('PAVF_28_HU_11_01 - Calcula bidones finales y prestados al cerrar ruta', () {
      final ruta = Ruta(id: 'r-05', vendedorId: 'v-01', nombreVendedor: 'Vendedor', vendedorBidonesPropios: 5, fecha: DateTime(2026, 6, 1), montoTotal: 10, montoCobrado: 10, estado: EstadoRuta.pagado, creadoEn: DateTime(2026, 6, 1), bidonesLlenosIniciales: 6, bidonesVaciosIniciales: 2, bidonesCargadosHoy: 4, items: const [
        ItemRuta(id: 'ir-01', rutaId: 'r-05', productoId: 'p-01', nombreProducto: 'Bidón', unidad: 'unidad', precioUnitario: 1.50, cantidadSalida: 10, cantidadSinVender: 3, cantidadRetornoVacio: 7),
      ]);
      expect(ruta.bidonesVendidos, 7);
      expect(ruta.bidonesLlenosFinales, 3);
      expect(ruta.bidonesVaciosFinales, 9);
      expect(ruta.bidonesPrestadosIniciales, 3);
      expect(ruta.bidonesPrestadosFinales, 7);
      expect(ruta.tieneBidones, isTrue);
    });

    test('PAVF_29_HU_11_02 - Evita bidones llenos finales negativos', () {
      final ruta = Ruta(id: 'r-06', vendedorId: 'v-01', nombreVendedor: 'Vendedor', vendedorBidonesPropios: 20, fecha: DateTime(2026, 6, 1), montoTotal: 10, montoCobrado: 10, estado: EstadoRuta.pagado, creadoEn: DateTime(2026, 6, 1), bidonesLlenosIniciales: 2, bidonesCargadosHoy: 0, items: const [
        ItemRuta(id: 'ir-01', rutaId: 'r-06', productoId: 'p-01', nombreProducto: 'Bidón', unidad: 'unidad', precioUnitario: 1.50, cantidadSalida: 10, cantidadSinVender: 0, cantidadRetornoVacio: 10),
      ]);
      expect(ruta.bidonesLlenosFinales, 0);
    });
  });

  group('HU-12 y HU-14 Alertas operativas y por rol', () {
    test('PAVF_30_HU_12_01 - Producto crítico activa condición de alerta crítica', () {
      final producto = Producto.desdeJson({'id': 'p-critico', 'nombre': 'Bidón', 'unidad': 'unidad', 'precio': 1.50, 'stock': 2, 'stock_minimo': 5, 'catalogo': 'distribuidora', 'creado_en': '2026-06-01T10:00:00', 'actualizado_en': '2026-06-01T11:00:00'});
      expect(producto.esCritico, isTrue);
    });

    test('PAVF_31_HU_12_02 - Producto bajo activa condición de alerta preventiva', () {
      final producto = Producto.desdeJson({'id': 'p-bajo', 'nombre': 'Funda', 'unidad': 'funda', 'precio': 0.25, 'stock': 7, 'stock_minimo': 5, 'stock_bajo_calculado': 8, 'catalogo': 'distribuidora', 'creado_en': '2026-06-01T10:00:00', 'actualizado_en': '2026-06-01T11:00:00'});
      expect(producto.esCritico, isFalse);
      expect(producto.esBajo, isTrue);
    });

    test('PAVF_32_HU_14_01 - Usuario vendedor conserva asociación con vendedor para filtrar alertas/rutas', () {
      final usuario = UsuarioApp.desdeJson({'id': 'u-vendedor', 'email': 'vendedor@aguamilena.com', 'nombre': 'Vendedor', 'rol': 'vendedor', 'vendedor_id': 'v-01'});
      expect(usuario.rol, RolUsuario.vendedor);
      expect(usuario.vendedorId, 'v-01');
    });
  });

  group('HU-15 Reportes PDF de ventas / datos filtrables', () {
    test('PAVF_33_HU_15_01 - Item de venta conserva datos necesarios para desglose de reporte', () {
      final item = ItemVenta.desdeJson({'id': 'iv-reporte', 'venta_id': 'venta-01', 'producto_id': 'p-01', 'nombre_producto': 'Bidón de agua', 'cantidad': 5, 'precio_unitario': 1.50, 'subtotal': 7.50});
      expect(item.nombreProducto, 'Bidón de agua');
      expect(item.cantidad, 5);
      expect(item.subtotal, 7.50);
    });

    test('PAVF_34_HU_15_02 - Usuario administrador serializa datos para identificación del generador de reporte', () {
      const admin = UsuarioApp(id: 'u-admin', email: 'admin@aguamilena.com', nombre: 'Administrador', rol: RolUsuario.admin);
      final json = admin.aJson();
      expect(json['name'], 'Administrador');
      expect(json['role'], 'admin');
    });
  });
}
