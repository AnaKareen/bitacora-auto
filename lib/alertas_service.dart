import 'database_helper.dart';

// ─── MODELO DE ALERTA ─────────────────────────────────────────────────────────
enum AlertaNivel { info, advertencia, critica }

class Alerta {
  final String titulo;
  final String descripcion;
  final AlertaNivel nivel;
  final String categoria; // 'servicio' | 'seguro' | 'gasolina'
  final DateTime? fecha;  // fecha de referencia (último servicio, vencimiento, etc.)

  const Alerta({
    required this.titulo,
    required this.descripcion,
    required this.nivel,
    required this.categoria,
    this.fecha,
  });
}

// ─── CONFIGURACIÓN DE INTERVALOS POR TIPO DE SERVICIO ────────────────────────
class _IntervaloServicio {
  final String tipo;
  final int meses;         // intervalo recomendado en meses
  final int mesesAviso;    // cuántos meses antes avisar
  const _IntervaloServicio(this.tipo, this.meses, this.mesesAviso);
}

const _intervalos = [
  _IntervaloServicio('Cambio de aceite',  6,  1),
  _IntervaloServicio('Bujías',            12, 2),
  _IntervaloServicio('Filtro de aire',    12, 2),
  _IntervaloServicio('Llantas',           24, 3),
  _IntervaloServicio('Amortiguadores',    24, 3),
  _IntervaloServicio('Balatas',           12, 2),
];

// ─── SERVICIO DE ALERTAS ──────────────────────────────────────────────────────
class AlertasService {
  AlertasService._();
  static final instance = AlertasService._();

  /// Genera TODAS las alertas activas en este momento
  Future<List<Alerta>> obtenerAlertas() async {
    final alertas = <Alerta>[];

    alertas.addAll(await _alertasServicios());
    alertas.addAll(await _alertasSeguro());
    alertas.addAll(await _alertasGasolina());

    // Ordenar: críticas primero, luego advertencias, luego info
    alertas.sort((a, b) => b.nivel.index.compareTo(a.nivel.index));
    return alertas;
  }

  // ─── ALERTAS DE SERVICIOS POR TIEMPO ───────────────────────────────────────
  Future<List<Alerta>> _alertasServicios() async {
    final alertas = <Alerta>[];
    final db      = await DatabaseHelper.instance.database;
    final ahora   = DateTime.now();

    for (final intervalo in _intervalos) {
      // Buscar el último registro de este tipo de servicio
      final rows = await db.query(
        'servicios',
        where: 'tipo = ?',
        whereArgs: [intervalo.tipo],
        orderBy: 'fecha DESC',
        limit: 1,
      );

      if (rows.isEmpty) {
        // Nunca se ha hecho este servicio → alerta informativa
        alertas.add(Alerta(
          titulo:      "Sin registro: ${intervalo.tipo}",
          descripcion: "No tienes ningún ${intervalo.tipo.toLowerCase()} registrado. "
                       "Se recomienda cada ${intervalo.meses} meses.",
          nivel:       AlertaNivel.info,
          categoria:   'servicio',
        ));
        continue;
      }

      final ultimaFecha = DateTime.tryParse(rows.first['fecha'] as String? ?? '');
      if (ultimaFecha == null) continue;

      final proximaFecha = DateTime(
        ultimaFecha.year,
        ultimaFecha.month + intervalo.meses,
        ultimaFecha.day,
      );
      final diasRestantes = proximaFecha.difference(ahora).inDays;
      final diasAviso     = intervalo.mesesAviso * 30;

      if (diasRestantes < 0) {
        // Ya venció
        final diasVencido = diasRestantes.abs();
        alertas.add(Alerta(
          titulo:      "${intervalo.tipo} vencido",
          descripcion: "Tu último ${intervalo.tipo.toLowerCase()} fue el "
                       "${_fmt(ultimaFecha)}. "
                       "Lleva $diasVencido día${diasVencido != 1 ? 's' : ''} de retraso.",
          nivel:       AlertaNivel.critica,
          categoria:   'servicio',
          fecha:       ultimaFecha,
        ));
      } else if (diasRestantes <= diasAviso) {
        // Próximo a vencer
        alertas.add(Alerta(
          titulo:      "${intervalo.tipo} próximo",
          descripcion: "Tu próximo ${intervalo.tipo.toLowerCase()} es en "
                       "$diasRestantes día${diasRestantes != 1 ? 's' : ''} "
                       "(${_fmt(proximaFecha)}).",
          nivel:       AlertaNivel.advertencia,
          categoria:   'servicio',
          fecha:       proximaFecha,
        ));
      }
      // Si diasRestantes > diasAviso → sin alerta, todo bien
    }

    return alertas;
  }

  // ─── ALERTAS DE SEGURO ────────────────────────────────────────────────────
  Future<List<Alerta>> _alertasSeguro() async {
    final alertas = <Alerta>[];
    final seguro  = await DatabaseHelper.instance.obtenerSeguro();

    if (seguro == null) {
      alertas.add(const Alerta(
        titulo:      "Sin seguro registrado",
        descripcion: "No tienes ningún seguro registrado en la app.",
        nivel:       AlertaNivel.advertencia,
        categoria:   'seguro',
      ));
      return alertas;
    }

    final fin = DateTime.tryParse(seguro['fin'] as String? ?? '');
    if (fin == null) return alertas;

    final diff = fin.difference(DateTime.now()).inDays;

    if (diff < 0) {
      alertas.add(Alerta(
        titulo:      "Seguro VENCIDO",
        descripcion: "Tu seguro con ${seguro['aseguradora']} venció el "
                     "${_fmt(fin)}. Renuévalo cuanto antes.",
        nivel:       AlertaNivel.critica,
        categoria:   'seguro',
        fecha:       fin,
      ));
    } else if (diff <= 30) {
      alertas.add(Alerta(
        titulo:      "Seguro por vencer",
        descripcion: "Tu seguro con ${seguro['aseguradora']} vence en "
                     "$diff día${diff != 1 ? 's' : ''} (${_fmt(fin)}). "
                     "Considera renovarlo pronto.",
        nivel:       diff <= 7 ? AlertaNivel.critica : AlertaNivel.advertencia,
        categoria:   'seguro',
        fecha:       fin,
      ));
    }

    return alertas;
  }

  // ─── ALERTAS DE GASOLINA SIN REGISTRAR ───────────────────────────────────
  Future<List<Alerta>> _alertasGasolina() async {
    final alertas = <Alerta>[];
    final db      = await DatabaseHelper.instance.database;

    final rows = await db.query(
      'gasolina',
      orderBy: 'fecha DESC',
      limit: 1,
    );

    if (rows.isEmpty) {
      alertas.add(const Alerta(
        titulo:      "Sin registros de gasolina",
        descripcion: "Aún no has registrado ninguna carga de gasolina.",
        nivel:       AlertaNivel.info,
        categoria:   'gasolina',
      ));
      return alertas;
    }

    final ultimaFecha = DateTime.tryParse(rows.first['fecha'] as String? ?? '');
    if (ultimaFecha == null) return alertas;

    final diasSinRegistro = DateTime.now().difference(ultimaFecha).inDays;

    if (diasSinRegistro >= 30) {
      alertas.add(Alerta(
        titulo:      "Gasolina sin registrar",
        descripcion: "Llevas $diasSinRegistro días sin registrar una carga "
                     "de gasolina. Tu último registro fue el ${_fmt(ultimaFecha)}.",
        nivel:       AlertaNivel.advertencia,
        categoria:   'gasolina',
        fecha:       ultimaFecha,
      ));
    } else if (diasSinRegistro >= 15) {
      alertas.add(Alerta(
        titulo:      "¿Cargaste gasolina?",
        descripcion: "Han pasado $diasSinRegistro días desde tu última carga "
                     "registrada (${_fmt(ultimaFecha)}). ¿Olvidaste registrar?",
        nivel:       AlertaNivel.info,
        categoria:   'gasolina',
        fecha:       ultimaFecha,
      ));
    }

    return alertas;
  }

  String _fmt(DateTime d) =>
      "${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}";
}