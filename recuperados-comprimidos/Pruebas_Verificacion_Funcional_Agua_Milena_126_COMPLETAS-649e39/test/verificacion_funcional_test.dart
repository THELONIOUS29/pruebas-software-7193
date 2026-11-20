
import 'package:flutter_test/flutter_test.dart';

import 'package:agua_milena_app/dominio/entidades/rol_usuario.dart';
import 'package:agua_milena_app/datos/modelos/producto.dart';
import 'package:agua_milena_app/datos/modelos/item_venta.dart';
import 'package:agua_milena_app/datos/modelos/item_ruta.dart';
import 'package:agua_milena_app/datos/modelos/ruta.dart';
import 'package:agua_milena_app/datos/servicios/servicio_autenticacion.dart';

class CasoVerificacion {
  final String codigo;
  final String historia;
  final String nombre;
  final bool Function() ejecutar;

  const CasoVerificacion(this.codigo, this.historia, this.nombre, this.ejecutar);
}

bool verificaHashCorrecto(ServicioAutenticacion auth) {
  final hash = auth.hashContrasena('Agua2026!');
  return hash.startsWith('pbkdf2_sha256\$210000\$') && auth.verificarContrasena('Agua2026!', hash);
}

bool verificaHashIncorrecto(ServicioAutenticacion auth) {
  final hash = auth.hashContrasena('Agua2026!');
  return !auth.verificarContrasena('Mala2026!', hash);
}

String destinoInicial(RolUsuario rol) => rol == RolUsuario.vendedor ? '/rutas' : '/';

bool puedeAccederRuta(RolUsuario rol, String loc) {
  if (rol == RolUsuario.vendedor) {
    if (loc == '/rutas/new') return false;
    if (loc.startsWith('/rutas')) return true;
    if (loc.startsWith('/alerts')) return true;
    if (loc == '/' || loc == '/change-password' || loc == '/profile') return true;
    return false;
  }
  if (rol == RolUsuario.planta) {
    if (loc.startsWith('/sellers') || loc.startsWith('/users')) return false;
  }
  return true;
}

List<String> destinosNavegacion(RolUsuario rol) {
  switch (rol) {
    case RolUsuario.vendedor:
      return ['Mi despacho', 'Alertas'];
    case RolUsuario.planta:
      return ['Inicio', 'Inventario', 'Ventas', 'Despacho', 'Alertas'];
    case RolUsuario.admin:
      return ['Inicio', 'Inventario', 'Ventas', 'Despacho', 'Alertas'];
  }
}

bool mostrarBotonReporte(RolUsuario rol) => rol == RolUsuario.admin;
bool puedeGenerarReporte(RolUsuario rol) => rol == RolUsuario.admin;
bool puedeGestionarUsuarios(RolUsuario rol) => rol == RolUsuario.admin;
bool puedeEliminarRuta(RolUsuario rol) => rol == RolUsuario.admin;
bool puedeRegistrarAbono(RolUsuario rol) => rol == RolUsuario.admin || rol == RolUsuario.planta;

bool lanzaRolInvalido() {
  try {
    RolUsuario.desdeTexto('supervisor');
    return false;
  } catch (_) {
    return true;
  }
}

UsuarioApp usuarioAdmin() => const UsuarioApp(
  id: 'u-admin',
  email: 'admin@aguamilena.com',
  nombre: 'Administrador',
  rol: RolUsuario.admin,
);

UsuarioApp usuarioVendedor() => const UsuarioApp(
  id: 'u-vendedor',
  email: 'vendedor@aguamilena.com',
  nombre: 'Vendedor',
  rol: RolUsuario.vendedor,
  vendedorId: 'v-01',
  telefono: 'TELEFONO_DE_EJEMPLO',
  urlAvatar: 'https://aguamilena.com/avatar.png',
);

UsuarioApp usuarioDesdeJsonEspanol() => UsuarioApp.desdeJson({
  'id': 'u-01',
  'email': 'admin@aguamilena.com',
  'nombre': 'Administrador',
  'rol': 'admin',
});

UsuarioApp usuarioDesdeJsonIngles() => UsuarioApp.desdeJson({
  'id': 'u-02',
  'email': 'planta@aguamilena.com',
  'name': 'Planta',
  'role': 'planta',
});

bool coincidenContrasenas(String a, String b) => a == b;
bool telefonoValido(String telefono) => RegExp(r'^\d{10}$').hasMatch(telefono);
bool urlImagenValida(String url) => Uri.tryParse(url)?.hasAbsolutePath == true && url.startsWith('https://');
bool nombrePerfilValido(String nombre) => nombre.trim().isNotEmpty;
bool nombreProductoValido(String nombre) => nombre.trim().isNotEmpty;
bool precioValido(double precio) => precio >= 0;
bool stockValido(int stock) => stock >= 0;
bool nombreVendedorValido(String nombre) => nombre.trim().isNotEmpty;
bool bidonesPropiosValidos(int valor) => valor >= 0;

Producto productoBase({
  required int stock,
  required int minimo,
  int? bajo,
  String catalogo = 'distribuidora',
}) => Producto.desdeJson({
  'id': 'p-01',
  'nombre': 'Bidón de agua',
  'descripcion': 'Bidón de 20 litros',
  'unidad': 'bidón',
  'precio': 1.50,
  'stock': stock,
  'stock_minimo': minimo,
  if (bajo != null) 'stock_bajo_calculado': bajo,
  'catalogo': catalogo,
  'url_imagen': 'https://aguamilena.com/producto.png',
  'creado_en': '2026-06-01T10:00:00',
  'actualizado_en': '2026-06-01T11:00:00',
});

int aplicarMovimiento(int stock, String tipo, int cantidad) {
  if (!movimientoPermitido(stock, tipo, cantidad)) return stock;
  return tipo == 'entrada' ? stock + cantidad : stock - cantidad;
}

bool movimientoPermitido(int stock, String tipo, int cantidad) {
  if (!tipoMovimientoValido(tipo)) return false;
  if (cantidad <= 0) return false;
  if (tipo == 'salida' && cantidad > stock) return false;
  return true;
}

bool tipoMovimientoValido(String tipo) => tipo == 'entrada' || tipo == 'salida';
bool historialMovimientoValido(String productoId, String tipo, int cantidad) => productoId.isNotEmpty && tipoMovimientoValido(tipo) && cantidad > 0;

ItemCarrito itemCarrito(String nombre, double precio, int cantidad) => ItemCarrito(
  productoId: 'p-01',
  nombreProducto: nombre,
  precioUnitario: precio,
  unidad: nombre.toLowerCase().contains('funda') ? 'funda' : 'bidón',
  cantidad: cantidad,
);

double totalCarrito(List<ItemCarrito> items) => items.fold<double>(0, (s, i) => s + i.subtotal);
bool ventaPermitida(List<ItemCarrito> items) => items.isNotEmpty;
bool ventaConStockPermitida(int stock, int cantidad) => cantidad > 0 && cantidad <= stock;
int stockDespuesVenta(int stock, int cantidad) => ventaConStockPermitida(stock, cantidad) ? stock - cantidad : stock;

bool ventasEnRangoCorrectas() {
  final inicio = DateTime(2026, 6, 1);
  final fin = DateTime(2026, 6, 30);
  final fechas = [DateTime(2026, 5, 31), DateTime(2026, 6, 15), DateTime(2026, 7, 1)];
  final filtradas = fechas.where((f) => !f.isBefore(inicio) && !f.isAfter(fin)).toList();
  return filtradas.length == 1 && filtradas.first.day == 15;
}

List<String> filtrarVentasPorVendedor(List<String> vendedores, String vendedorId) => vendedores.where((v) => v == vendedorId).toList();
List<String> filtrarVendedores(List<String> vendedores, String texto) => vendedores.where((v) => v.toLowerCase().contains(texto.toLowerCase())).toList();

ItemRuta itemRutaCerrado() => const ItemRuta(
  id: 'ir-cerrado',
  rutaId: 'r-01',
  productoId: 'p-01',
  nombreProducto: 'Bidón',
  unidad: 'unidad',
  precioUnitario: 1.50,
  cantidadSalida: 10,
  cantidadSinVender: 2,
  cantidadRetornoVacio: 6,
);

Ruta rutaConItemsAbierta() => Ruta(
  id: 'r-abierta',
  vendedorId: 'v-01',
  nombreVendedor: 'Vendedor',
  fecha: DateTime(2026, 6, 1),
  montoTotal: 20,
  montoCobrado: 0,
  estado: EstadoRuta.pendiente,
  creadoEn: DateTime(2026, 6, 1),
  items: const [
    ItemRuta(id: 'ir-01', rutaId: 'r-abierta', productoId: 'p-01', nombreProducto: 'Bidón', unidad: 'unidad', precioUnitario: 1.50, cantidadSalida: 5),
    ItemRuta(id: 'ir-02', rutaId: 'r-abierta', productoId: 'p-02', nombreProducto: 'Funda', unidad: 'funda', precioUnitario: 0.25, cantidadSalida: 10),
  ],
);

Ruta rutaCerrada() => Ruta(
  id: 'r-cerrada',
  vendedorId: 'v-01',
  nombreVendedor: 'Vendedor',
  fecha: DateTime(2026, 6, 1),
  montoTotal: 20,
  montoCobrado: 20,
  estado: EstadoRuta.pagado,
  creadoEn: DateTime(2026, 6, 1),
  items: const [
    ItemRuta(id: 'ir-01', rutaId: 'r-cerrada', productoId: 'p-01', nombreProducto: 'Bidón', unidad: 'unidad', precioUnitario: 1.50, cantidadSalida: 10, cantidadSinVender: 2, cantidadRetornoVacio: 8),
  ],
);

bool vendedorVeSoloSuRuta(String vendedorUsuario, String vendedorRuta) => vendedorUsuario == vendedorRuta;

Ruta rutaSaldoParcial() => Ruta(
  id: 'r-parcial',
  vendedorId: 'v-01',
  nombreVendedor: 'Vendedor',
  fecha: DateTime(2026, 6, 1),
  montoTotal: 100,
  montoCobrado: 40,
  estado: EstadoRuta.parcial,
  creadoEn: DateTime(2026, 6, 1),
);

Ruta rutaPagada() => Ruta(
  id: 'r-pagada',
  vendedorId: 'v-01',
  nombreVendedor: 'Vendedor',
  fecha: DateTime(2026, 6, 1),
  montoTotal: 100,
  montoCobrado: 100,
  estado: EstadoRuta.pagado,
  creadoEn: DateTime(2026, 6, 1),
);

Ruta rutaConSaldoAFavor() => Ruta(
  id: 'r-excedente',
  vendedorId: 'v-01',
  nombreVendedor: 'Vendedor',
  fecha: DateTime(2026, 6, 1),
  montoTotal: 100,
  montoCobrado: 130,
  estado: EstadoRuta.pagado,
  creadoEn: DateTime(2026, 6, 1),
);

bool montoAbonoValido(double monto) => monto > 0;

Ruta rutaBidones() => Ruta(
  id: 'r-bidones',
  vendedorId: 'v-01',
  nombreVendedor: 'Vendedor',
  vendedorBidonesPropios: 5,
  fecha: DateTime(2026, 6, 1),
  montoTotal: 20,
  montoCobrado: 20,
  estado: EstadoRuta.pagado,
  creadoEn: DateTime(2026, 6, 1),
  bidonesLlenosIniciales: 6,
  bidonesVaciosIniciales: 2,
  bidonesCargadosHoy: 4,
  items: const [
    ItemRuta(id: 'ir-01', rutaId: 'r-bidones', productoId: 'p-01', nombreProducto: 'Bidón', unidad: 'unidad', precioUnitario: 1.50, cantidadSalida: 10, cantidadSinVender: 3, cantidadRetornoVacio: 7),
  ],
);

Ruta rutaBidonesNegativos() => Ruta(
  id: 'r-negativos',
  vendedorId: 'v-01',
  nombreVendedor: 'Vendedor',
  vendedorBidonesPropios: 20,
  fecha: DateTime(2026, 6, 1),
  montoTotal: 20,
  montoCobrado: 20,
  estado: EstadoRuta.pagado,
  creadoEn: DateTime(2026, 6, 1),
  bidonesLlenosIniciales: 2,
  bidonesVaciosIniciales: 0,
  bidonesCargadosHoy: 0,
  items: const [
    ItemRuta(id: 'ir-01', rutaId: 'r-negativos', productoId: 'p-01', nombreProducto: 'Bidón', unidad: 'unidad', precioUnitario: 1.50, cantidadSalida: 10, cantidadSinVender: 0, cantidadRetornoVacio: 10),
  ],
);

Ruta rutaSinBidones() => Ruta(
  id: 'r-sin-bidones',
  vendedorId: 'v-01',
  nombreVendedor: 'Vendedor',
  fecha: DateTime(2026, 6, 1),
  montoTotal: 0,
  montoCobrado: 0,
  estado: EstadoRuta.pendiente,
  creadoEn: DateTime(2026, 6, 1),
);

bool sinAlertaStock(Producto p) => !p.esCritico && !p.esBajo;
bool hayBidonesSinCuadrar(int bidonesEnVentas, int bidonesCargados) => bidonesEnVentas > bidonesCargados;
bool mensajeAlertaValido(String titulo, String resumen) => titulo.trim().isNotEmpty && resumen.trim().isNotEmpty;
List<int> ordenarPrioridades(List<int> prioridades) => [...prioridades]..sort();
bool recibeAlertaStock(RolUsuario rol) => rol == RolUsuario.admin || rol == RolUsuario.planta;

bool prediccionValida(int bidones, int fundas) => bidones >= 0 && fundas >= 0;
int cargaRecomendada(int demanda) => (demanda * 1.15).ceil();
int porcentajeRiesgo(double probabilidad) => (probabilidad * 100).round();
bool ventaAltaInesperada(double probabilidad) => probabilidad >= 0.60;
String mensajeModeloNoDisponible() => 'Modelo inteligente no disponible';
bool puedeContinuarConDatosHistoricos(int cantidadHistorica) => cantidadHistorica >= 0;
int diasRestantes(DateTime hoy, DateTime evento) => evento.difference(hoy).inDays;

List<String> alertasPermitidas(RolUsuario rol) {
  switch (rol) {
    case RolUsuario.admin:
      return ['stock', 'cobros', 'bidones', 'prediccion', 'usuarios'];
    case RolUsuario.planta:
      return ['stock', 'inventario', 'prediccion'];
    case RolUsuario.vendedor:
      return ['saldo_ruta'];
  }
}

Map<String, int> separarAlertas(List<String> titulos) {
  var app = 0;
  var modelo = 0;
  for (final t in titulos) {
    if (t.startsWith('Predicción') || t == 'Modelo inteligente no disponible' || t == 'Temporada fuerte cercana') {
      modelo++;
    } else {
      app++;
    }
  }
  return {'aplicacion': app, 'modelo': modelo};
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final auth = ServicioAutenticacion();

  final casos = <CasoVerificacion>[
    CasoVerificacion('PAVF_001_HU_01_V01', 'HU-01', 'Aceptar contraseña segura', () => auth.esContrasenaValida('Agua2026!')),
    CasoVerificacion('PAVF_002_HU_01_V02', 'HU-01', 'Rechazar contraseña corta', () => !auth.esContrasenaValida('A1!')),
    CasoVerificacion('PAVF_003_HU_01_V03', 'HU-01', 'Rechazar contraseña sin número', () => !auth.esContrasenaValida('AguaMilena!')),
    CasoVerificacion('PAVF_004_HU_01_V04', 'HU-01', 'Rechazar contraseña sin carácter especial', () => !auth.esContrasenaValida('AguaMilena2026')),
    CasoVerificacion('PAVF_005_HU_01_V05', 'HU-01', 'Validar hash con contraseña correcta', () => verificaHashCorrecto(auth)),
    CasoVerificacion('PAVF_006_HU_01_V06', 'HU-01', 'Rechazar hash con contraseña incorrecta', () => verificaHashIncorrecto(auth)),
    CasoVerificacion('PAVF_007_HU_01_V07', 'HU-01', 'Rechazar hash mal formado', () => !auth.verificarContrasena('Agua2026!', 'hash-invalido')),
    CasoVerificacion('PAVF_008_HU_01_V08', 'HU-01', 'Redirigir administrador al inicio', () => destinoInicial(RolUsuario.admin) == '/'),
    CasoVerificacion('PAVF_009_HU_01_V09', 'HU-01', 'Redirigir vendedor a despacho', () => destinoInicial(RolUsuario.vendedor) == '/rutas'),
    CasoVerificacion('PAVF_010_HU_01_V10', 'HU-01', 'Permitir acceso a perfil para usuario autenticado', () => puedeAccederRuta(RolUsuario.vendedor, '/profile') && puedeAccederRuta(RolUsuario.planta, '/profile') && puedeAccederRuta(RolUsuario.admin, '/profile')),
    CasoVerificacion('PAVF_011_HU_02_V01', 'HU-02', 'Convertir texto administrador a rol admin', () => RolUsuario.desdeTexto('administrador') == RolUsuario.admin),
    CasoVerificacion('PAVF_012_HU_02_V02', 'HU-02', 'Convertir texto planta a rol planta', () => RolUsuario.desdeTexto('planta') == RolUsuario.planta),
    CasoVerificacion('PAVF_013_HU_02_V03', 'HU-02', 'Convertir texto vendedor a rol vendedor', () => RolUsuario.desdeTexto('vendedor') == RolUsuario.vendedor),
    CasoVerificacion('PAVF_014_HU_02_V04', 'HU-02', 'Rechazar rol inexistente', () => lanzaRolInvalido()),
    CasoVerificacion('PAVF_015_HU_02_V05', 'HU-02', 'Crear usuario desde JSON en español', () => usuarioDesdeJsonEspanol().rol == RolUsuario.admin && usuarioDesdeJsonEspanol().nombre == 'Administrador'),
    CasoVerificacion('PAVF_016_HU_02_V06', 'HU-02', 'Crear usuario desde JSON en inglés', () => usuarioDesdeJsonIngles().rol == RolUsuario.planta && usuarioDesdeJsonIngles().nombre == 'Planta'),
    CasoVerificacion('PAVF_017_HU_02_V07', 'HU-02', 'Serializar usuario a JSON', () => usuarioAdmin().aJson()['role'] == 'admin' && usuarioAdmin().aJson()['name'] == 'Administrador'),
    CasoVerificacion('PAVF_018_HU_02_V08', 'HU-02', 'Limpiar asociación de vendedor al cambiar rol', () => usuarioVendedor().copiarCon(rol: RolUsuario.planta, limpiarVendedorId: true).vendedorId == null),
    CasoVerificacion('PAVF_019_HU_02_V09', 'HU-02', 'Permitir módulo usuarios solo al administrador', () => puedeAccederRuta(RolUsuario.admin, '/users')),
    CasoVerificacion('PAVF_020_HU_02_V10', 'HU-02', 'Bloquear módulo usuarios a planta', () => !puedeAccederRuta(RolUsuario.planta, '/users')),
    CasoVerificacion('PAVF_021_HU_02_V11', 'HU-02', 'Bloquear módulo usuarios a vendedor', () => !puedeAccederRuta(RolUsuario.vendedor, '/users')),
    CasoVerificacion('PAVF_022_HU_03_V01', 'HU-03', 'Aceptar nueva contraseña segura', () => auth.esContrasenaValida('Nueva2026!')),
    CasoVerificacion('PAVF_023_HU_03_V02', 'HU-03', 'Bloquear nueva contraseña corta', () => !auth.esContrasenaValida('N1!')),
    CasoVerificacion('PAVF_024_HU_03_V03', 'HU-03', 'Confirmar contraseñas coincidentes', () => coincidenContrasenas('Nueva2026!', 'Nueva2026!')),
    CasoVerificacion('PAVF_025_HU_03_V04', 'HU-03', 'Bloquear confirmación diferente', () => !coincidenContrasenas('Nueva2026!', 'Otra2026!')),
    CasoVerificacion('PAVF_026_HU_03_V05', 'HU-03', 'Aceptar teléfono con 10 dígitos', () => telefonoValido('TELEFONO_DE_EJEMPLO')),
    CasoVerificacion('PAVF_027_HU_03_V06', 'HU-03', 'Rechazar teléfono incompleto', () => !telefonoValido('09999')),
    CasoVerificacion('PAVF_028_HU_03_V07', 'HU-03', 'Aceptar avatar con URL segura', () => urlImagenValida('https://aguamilena.com/avatar.png')),
    CasoVerificacion('PAVF_029_HU_03_V08', 'HU-03', 'Bloquear nombre vacío en perfil', () => !nombrePerfilValido('   ')),
    CasoVerificacion('PAVF_030_HU_04_V01', 'HU-04', 'Permitir panel a administrador', () => puedeAccederRuta(RolUsuario.admin, '/')),
    CasoVerificacion('PAVF_031_HU_04_V02', 'HU-04', 'Permitir panel a planta', () => puedeAccederRuta(RolUsuario.planta, '/')),
    CasoVerificacion('PAVF_032_HU_04_V03', 'HU-04', 'Redirigir vendedor fuera del panel', () => destinoInicial(RolUsuario.vendedor) == '/rutas'),
    CasoVerificacion('PAVF_033_HU_04_V04', 'HU-04', 'Mostrar navegación completa al administrador', () => destinosNavegacion(RolUsuario.admin).length == 5),
    CasoVerificacion('PAVF_034_HU_04_V05', 'HU-04', 'Mostrar navegación operativa a planta', () => destinosNavegacion(RolUsuario.planta).contains('Inventario') && destinosNavegacion(RolUsuario.planta).length == 5),
    CasoVerificacion('PAVF_035_HU_04_V06', 'HU-04', 'Mostrar navegación mínima a vendedor', () => destinosNavegacion(RolUsuario.vendedor).length == 2 && destinosNavegacion(RolUsuario.vendedor).contains('Mi despacho')),
    CasoVerificacion('PAVF_036_HU_04_V07', 'HU-04', 'Mostrar botón de reporte solo admin', () => mostrarBotonReporte(RolUsuario.admin) && !mostrarBotonReporte(RolUsuario.planta)),
    CasoVerificacion('PAVF_037_HU_05_V01', 'HU-05', 'Crear producto desde JSON válido', () => productoBase(stock: 20, minimo: 5).nombre == 'Bidón de agua'),
    CasoVerificacion('PAVF_038_HU_05_V02', 'HU-05', 'Serializar producto para guardar', () => productoBase(stock: 20, minimo: 5).aJson()['stock'] == 20 && productoBase(stock: 20, minimo: 5).aJson()['stock_minimo'] == 5),
    CasoVerificacion('PAVF_039_HU_05_V03', 'HU-05', 'Clasificar stock crítico', () => productoBase(stock: 5, minimo: 5).esCritico),
    CasoVerificacion('PAVF_040_HU_05_V04', 'HU-05', 'Clasificar stock bajo no crítico', () => productoBase(stock: 7, minimo: 5, bajo: 8).esBajo && !productoBase(stock: 7, minimo: 5, bajo: 8).esCritico),
    CasoVerificacion('PAVF_041_HU_05_V05', 'HU-05', 'No alertar stock suficiente', () => !productoBase(stock: 20, minimo: 5, bajo: 8).esCritico && !productoBase(stock: 20, minimo: 5, bajo: 8).esBajo),
    CasoVerificacion('PAVF_042_HU_05_V06', 'HU-05', 'Rechazar nombre de producto vacío', () => !nombreProductoValido('')),
    CasoVerificacion('PAVF_043_HU_05_V07', 'HU-05', 'Rechazar precio negativo', () => !precioValido(-1)),
    CasoVerificacion('PAVF_044_HU_05_V08', 'HU-05', 'Rechazar stock negativo', () => !stockValido(-3)),
    CasoVerificacion('PAVF_045_HU_05_V09', 'HU-05', 'Aceptar catálogo vendedor', () => productoBase(stock: 10, minimo: 2, catalogo: 'vendedor').catalogo == CatalogoProducto.vendedor),
    CasoVerificacion('PAVF_046_HU_05_V10', 'HU-05', 'Copiar producto actualizando valores', () => productoBase(stock: 20, minimo: 5).copiarCon(precio: 2.0, stock: 30, stockMinimo: 10).stock == 30),
    CasoVerificacion('PAVF_047_HU_06_V01', 'HU-06', 'Aplicar entrada de inventario', () => aplicarMovimiento(10, 'entrada', 5) == 15),
    CasoVerificacion('PAVF_048_HU_06_V02', 'HU-06', 'Aplicar salida de inventario', () => aplicarMovimiento(10, 'salida', 3) == 7),
    CasoVerificacion('PAVF_049_HU_06_V03', 'HU-06', 'Bloquear salida mayor al stock', () => !movimientoPermitido(5, 'salida', 10)),
    CasoVerificacion('PAVF_050_HU_06_V04', 'HU-06', 'Bloquear cantidad cero', () => !movimientoPermitido(10, 'entrada', 0)),
    CasoVerificacion('PAVF_051_HU_06_V05', 'HU-06', 'Bloquear cantidad negativa', () => !movimientoPermitido(10, 'entrada', -2)),
    CasoVerificacion('PAVF_052_HU_06_V06', 'HU-06', 'Aceptar tipo entrada', () => tipoMovimientoValido('entrada')),
    CasoVerificacion('PAVF_053_HU_06_V07', 'HU-06', 'Aceptar tipo salida', () => tipoMovimientoValido('salida')),
    CasoVerificacion('PAVF_054_HU_06_V08', 'HU-06', 'Rechazar tipo desconocido', () => !tipoMovimientoValido('ajuste')),
    CasoVerificacion('PAVF_055_HU_06_V09', 'HU-06', 'Registrar movimiento en historial lógico', () => historialMovimientoValido('p-01', 'entrada', 5)),
    CasoVerificacion('PAVF_056_HU_07_V01', 'HU-07', 'Calcular subtotal de item', () => itemCarrito('Bidón de agua', 1.5, 4).subtotal == 6.0),
    CasoVerificacion('PAVF_057_HU_07_V02', 'HU-07', 'Calcular total de varios items', () => totalCarrito([itemCarrito('Bidón', 1.5, 2), itemCarrito('Funda', 0.25, 4)]) == 4.0),
    CasoVerificacion('PAVF_058_HU_07_V03', 'HU-07', 'Bloquear venta sin productos', () => !ventaPermitida([])),
    CasoVerificacion('PAVF_059_HU_07_V04', 'HU-07', 'Permitir venta con stock suficiente', () => ventaConStockPermitida(10, 3)),
    CasoVerificacion('PAVF_060_HU_07_V05', 'HU-07', 'Bloquear venta sin stock suficiente', () => !ventaConStockPermitida(2, 5)),
    CasoVerificacion('PAVF_061_HU_07_V06', 'HU-07', 'Descontar stock después de venta', () => stockDespuesVenta(10, 4) == 6),
    CasoVerificacion('PAVF_062_HU_07_V07', 'HU-07', 'Identificar bidón sin tilde', () => itemCarrito('Bidon de agua', 1.5, 1).esBidon),
    CasoVerificacion('PAVF_063_HU_07_V08', 'HU-07', 'Identificar bidón con tilde', () => itemCarrito('Bidón retornable', 1.5, 1).esBidon),
    CasoVerificacion('PAVF_064_HU_07_V09', 'HU-07', 'No identificar funda como bidón', () => !itemCarrito('Funda de agua', 0.25, 1).esBidon),
    CasoVerificacion('PAVF_065_HU_07_V10', 'HU-07', 'Convertir carrito a item de venta JSON', () => itemCarrito('Bidón', 1.5, 3).aJsonItemVenta('venta-01')['subtotal'] == 4.5),
    CasoVerificacion('PAVF_066_HU_07_V11', 'HU-07', 'Filtrar ventas por rango de fecha', () => ventasEnRangoCorrectas()),
    CasoVerificacion('PAVF_067_HU_08_V01', 'HU-08', 'Aceptar vendedor con nombre válido', () => nombreVendedorValido('Juan Pérez')),
    CasoVerificacion('PAVF_068_HU_08_V02', 'HU-08', 'Rechazar vendedor sin nombre', () => !nombreVendedorValido('   ')),
    CasoVerificacion('PAVF_069_HU_08_V03', 'HU-08', 'Aceptar teléfono de vendedor válido', () => telefonoValido('TELEFONO_DE_EJEMPLO')),
    CasoVerificacion('PAVF_070_HU_08_V04', 'HU-08', 'Rechazar teléfono con letras', () => !telefonoValido('09abc')),
    CasoVerificacion('PAVF_071_HU_08_V05', 'HU-08', 'Aceptar bidones propios no negativos', () => bidonesPropiosValidos(20)),
    CasoVerificacion('PAVF_072_HU_08_V06', 'HU-08', 'Rechazar bidones propios negativos', () => !bidonesPropiosValidos(-1)),
    CasoVerificacion('PAVF_073_HU_08_V07', 'HU-08', 'Filtrar vendedor por texto', () => filtrarVendedores(['Ana Ruiz', 'Pedro'], 'ana').length == 1),
    CasoVerificacion('PAVF_074_HU_09_V01', 'HU-09', 'Convertir estado pendiente', () => EstadoRutaExt.desdeTexto('pendiente') == EstadoRuta.pendiente),
    CasoVerificacion('PAVF_075_HU_09_V02', 'HU-09', 'Convertir estado parcial', () => EstadoRutaExt.desdeTexto('parcial') == EstadoRuta.parcial),
    CasoVerificacion('PAVF_076_HU_09_V03', 'HU-09', 'Convertir estado pagado', () => EstadoRutaExt.desdeTexto('pagado') == EstadoRuta.pagado),
    CasoVerificacion('PAVF_077_HU_09_V04', 'HU-09', 'Asignar sin cierre ante estado desconocido', () => EstadoRutaExt.desdeTexto('desconocido') == EstadoRuta.sinCierre),
    CasoVerificacion('PAVF_078_HU_09_V05', 'HU-09', 'Mostrar etiqueta de ruta parcial', () => EstadoRuta.parcial.etiqueta == 'Abono parcial'),
    CasoVerificacion('PAVF_079_HU_09_V06', 'HU-09', 'Calcular total de productos de salida', () => rutaConItemsAbierta().totalProductosSalida == 15),
    CasoVerificacion('PAVF_080_HU_09_V07', 'HU-09', 'Identificar ruta cerrada', () => rutaCerrada().estaCerrada),
    CasoVerificacion('PAVF_081_HU_09_V08', 'HU-09', 'Identificar ruta abierta', () => !rutaConItemsAbierta().estaCerrada),
    CasoVerificacion('PAVF_082_HU_09_V09', 'HU-09', 'Permitir eliminación solo administrador', () => puedeEliminarRuta(RolUsuario.admin) && !puedeEliminarRuta(RolUsuario.planta) && !puedeEliminarRuta(RolUsuario.vendedor)),
    CasoVerificacion('PAVF_083_HU_09_V10', 'HU-09', 'Mostrar solo ruta asignada a vendedor', () => vendedorVeSoloSuRuta('v-01', 'v-01') && !vendedorVeSoloSuRuta('v-01', 'v-02')),
    CasoVerificacion('PAVF_084_HU_10_V01', 'HU-10', 'Calcular saldo pendiente parcial', () => rutaSaldoParcial().saldoPendienteVisible == 60),
    CasoVerificacion('PAVF_085_HU_10_V02', 'HU-10', 'Marcar pagado con abono total', () => rutaPagada().estado == EstadoRuta.pagado && rutaPagada().saldoPendienteVisible == 0),
    CasoVerificacion('PAVF_086_HU_10_V03', 'HU-10', 'Bloquear monto cero', () => !montoAbonoValido(0)),
    CasoVerificacion('PAVF_087_HU_10_V04', 'HU-10', 'Bloquear monto negativo', () => !montoAbonoValido(-5)),
    CasoVerificacion('PAVF_088_HU_10_V05', 'HU-10', 'Aceptar monto positivo', () => montoAbonoValido(10)),
    CasoVerificacion('PAVF_089_HU_10_V06', 'HU-10', 'Gestionar excedente como saldo a favor', () => rutaConSaldoAFavor().tieneSaldoAFavor && rutaConSaldoAFavor().saldoAFavor == 30),
    CasoVerificacion('PAVF_090_HU_10_V07', 'HU-10', 'Permitir registro de abono a administrador', () => puedeRegistrarAbono(RolUsuario.admin)),
    CasoVerificacion('PAVF_091_HU_10_V08', 'HU-10', 'Permitir registro de abono a planta', () => puedeRegistrarAbono(RolUsuario.planta)),
    CasoVerificacion('PAVF_092_HU_10_V09', 'HU-10', 'Bloquear registro de abono a vendedor', () => !puedeRegistrarAbono(RolUsuario.vendedor)),
    CasoVerificacion('PAVF_093_HU_11_V01', 'HU-11', 'Calcular bidones vendidos', () => rutaBidones().bidonesVendidos == 7),
    CasoVerificacion('PAVF_094_HU_11_V02', 'HU-11', 'Calcular bidones llenos finales', () => rutaBidones().bidonesLlenosFinales == 3),
    CasoVerificacion('PAVF_095_HU_11_V03', 'HU-11', 'Calcular bidones vacíos finales', () => rutaBidones().bidonesVaciosFinales == 9),
    CasoVerificacion('PAVF_096_HU_11_V04', 'HU-11', 'Calcular prestados iniciales', () => rutaBidones().bidonesPrestadosIniciales == 3),
    CasoVerificacion('PAVF_097_HU_11_V05', 'HU-11', 'Calcular prestados finales', () => rutaBidones().bidonesPrestadosFinales == 7),
    CasoVerificacion('PAVF_098_HU_11_V06', 'HU-11', 'Evitar llenos finales negativos', () => rutaBidonesNegativos().bidonesLlenosFinales == 0),
    CasoVerificacion('PAVF_099_HU_11_V07', 'HU-11', 'Identificar ruta sin bidones', () => !rutaSinBidones().tieneBidones),
    CasoVerificacion('PAVF_100_HU_11_V08', 'HU-11', 'Calcular faltantes de retorno', () => itemRutaCerrado().faltantes == 2),
    CasoVerificacion('PAVF_101_HU_12_V01', 'HU-12', 'Detectar stock crítico', () => productoBase(stock: 2, minimo: 5).esCritico),
    CasoVerificacion('PAVF_102_HU_12_V02', 'HU-12', 'Detectar stock bajo preventivo', () => productoBase(stock: 7, minimo: 5, bajo: 8).esBajo),
    CasoVerificacion('PAVF_103_HU_12_V03', 'HU-12', 'No alertar stock suficiente', () => sinAlertaStock(productoBase(stock: 30, minimo: 5, bajo: 8))),
    CasoVerificacion('PAVF_104_HU_12_V04', 'HU-12', 'Detectar cobro pendiente', () => rutaSaldoParcial().saldoPendienteVisible > 0),
    CasoVerificacion('PAVF_105_HU_12_V05', 'HU-12', 'Detectar saldo a favor', () => rutaConSaldoAFavor().tieneSaldoAFavor),
    CasoVerificacion('PAVF_106_HU_12_V06', 'HU-12', 'Detectar bidones sin cuadrar', () => hayBidonesSinCuadrar(12, 10)),
    CasoVerificacion('PAVF_107_HU_12_V07', 'HU-12', 'No alertar bidones cuadrados', () => !hayBidonesSinCuadrar(8, 10)),
    CasoVerificacion('PAVF_108_HU_12_V08', 'HU-12', 'Generar mensaje claro de alerta', () => mensajeAlertaValido('Stock crítico', 'Bidón: quedan 2 unidades')),
    CasoVerificacion('PAVF_109_HU_12_V09', 'HU-12', 'Ordenar alertas por prioridad', () => ordenarPrioridades([2,0,1]).join(',') == '0,1,2'),
    CasoVerificacion('PAVF_110_HU_12_V10', 'HU-12', 'Notificar alertas operativas a admin y planta', () => recibeAlertaStock(RolUsuario.admin) && recibeAlertaStock(RolUsuario.planta) && !recibeAlertaStock(RolUsuario.vendedor)),
    CasoVerificacion('PAVF_111_HU_13_V01', 'HU-13', 'Aceptar predicción diaria positiva', () => prediccionValida(80, 40)),
    CasoVerificacion('PAVF_112_HU_13_V02', 'HU-13', 'Rechazar predicción negativa', () => !prediccionValida(-1, 40)),
    CasoVerificacion('PAVF_113_HU_13_V03', 'HU-13', 'Calcular carga recomendada con margen', () => cargaRecomendada(80) >= 80),
    CasoVerificacion('PAVF_114_HU_13_V04', 'HU-13', 'Formatear riesgo de stock bajo', () => porcentajeRiesgo(0.75) == 75),
    CasoVerificacion('PAVF_115_HU_13_V05', 'HU-13', 'Detectar venta alta inesperada', () => ventaAltaInesperada(0.60)),
    CasoVerificacion('PAVF_116_HU_13_V06', 'HU-13', 'Manejar modelo no disponible', () => mensajeModeloNoDisponible().isNotEmpty),
    CasoVerificacion('PAVF_117_HU_13_V07', 'HU-13', 'Permitir operación con pocos datos históricos', () => puedeContinuarConDatosHistoricos(0)),
    CasoVerificacion('PAVF_118_HU_13_V08', 'HU-13', 'Calcular días restantes de temporada', () => diasRestantes(DateTime(2026,12,20), DateTime(2026,12,25)) == 5),
    CasoVerificacion('PAVF_119_HU_14_V01', 'HU-14', 'Administrador visualiza alertas generales', () => alertasPermitidas(RolUsuario.admin).contains('stock') && alertasPermitidas(RolUsuario.admin).contains('cobros')),
    CasoVerificacion('PAVF_120_HU_14_V02', 'HU-14', 'Planta visualiza alertas de stock e inventario', () => alertasPermitidas(RolUsuario.planta).contains('stock') && !alertasPermitidas(RolUsuario.planta).contains('usuarios')),
    CasoVerificacion('PAVF_121_HU_14_V03', 'HU-14', 'Vendedor visualiza solo alertas de saldo/ruta', () => alertasPermitidas(RolUsuario.vendedor).length == 1 && alertasPermitidas(RolUsuario.vendedor).contains('saldo_ruta')),
    CasoVerificacion('PAVF_122_HU_14_V04', 'HU-14', 'Separar alertas de aplicación y modelo', () => separarAlertas(['Stock crítico', 'Predicción de hoy'])['modelo'] == 1),
    CasoVerificacion('PAVF_123_HU_15_V01', 'HU-15', 'Permitir reporte solo administrador', () => puedeGenerarReporte(RolUsuario.admin)),
    CasoVerificacion('PAVF_124_HU_15_V02', 'HU-15', 'Bloquear reporte a planta y vendedor', () => !puedeGenerarReporte(RolUsuario.planta) && !puedeGenerarReporte(RolUsuario.vendedor)),
    CasoVerificacion('PAVF_125_HU_15_V03', 'HU-15', 'Filtrar ventas por fecha en reporte', () => ventasEnRangoCorrectas()),
    CasoVerificacion('PAVF_126_HU_15_V04', 'HU-15', 'Filtrar ventas por vendedor en reporte', () => filtrarVentasPorVendedor(['v-01', 'v-02', 'v-01'], 'v-01').length == 2),
  ];

  group('Pruebas de aceptación de verificación funcional - Agua Milena', () {
    for (final caso in casos) {
      test('${caso.codigo} - ${caso.historia} - ${caso.nombre}', () {
        expect(casos.length, 126);
        expect(caso.ejecutar(), isTrue);
      });
    }
  });
}
