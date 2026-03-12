import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'database_helper.dart';

// ─── PALETA (consistente con Dashboard) ──────────────────────────────────────
const _bg        = Color(0xFFF5F6FA);
const _card      = Color(0xFFFFFFFF);
const _textMain  = Color(0xFF0F1117);
const _textSub   = Color(0xFF8A8FA8);
const _divider   = Color(0xFFEAEBF0);

const _blue      = Color(0xFF3B7BFF);
const _blueSoft  = Color(0x1A3B7BFF);
const _green     = Color(0xFF00C48C);
const _greenSoft = Color(0x1A00C48C);
const _orange    = Color(0xFFFF7A2F);
const _red       = Color(0xFFFF3B55);
const _redSoft   = Color(0x1AFF3B55);

class GasolinaPage extends StatefulWidget {
  const GasolinaPage({super.key});

  @override
  State<GasolinaPage> createState() => _GasolinaPageState();
}

class _GasolinaPageState extends State<GasolinaPage>
    with SingleTickerProviderStateMixin {
  final _kmCtrl     = TextEditingController();
  final _litrosCtrl = TextEditingController();
  final _precioCtrl = TextEditingController();

  DateTime? _fecha;
  List<Map<String, dynamic>> _registros = [];
  bool _cargando = true;

  // Para preview del total en tiempo real
  double get _totalPreview {
    final l = double.tryParse(_litrosCtrl.text) ?? 0;
    final p = double.tryParse(_precioCtrl.text) ?? 0;
    return l * p;
  }

  @override
  void initState() {
    super.initState();
    _cargar();
    // Recalcular total en tiempo real
    _litrosCtrl.addListener(() => setState(() {}));
    _precioCtrl.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _kmCtrl.dispose();
    _litrosCtrl.dispose();
    _precioCtrl.dispose();
    super.dispose();
  }

  // ─── DATA ──────────────────────────────────────────────────────────────────
  Future<void> _cargar() async {
    setState(() => _cargando = true);
    final db   = await DatabaseHelper.instance.database;
    final datos = await db.query('gasolina', orderBy: 'id DESC');
    setState(() {
      _registros = datos.map((e) => {
        'id':      e['id'],
        'km':      (e['kilometraje'] as num?)?.toDouble() ?? 0.0,
        'litros':  (e['litros']      as num?)?.toDouble() ?? 0.0,
        'precio':  (e['precio_litro']as num?)?.toDouble() ?? 0.0,
        'total':   (e['total']       as num?)?.toDouble() ?? 0.0,
        'fecha':   DateTime.tryParse(e['fecha'] as String? ?? '') ?? DateTime.now(),
      }).toList();
      _cargando = false;
    });
  }

  Future<void> _guardar() async {
    if (_kmCtrl.text.isEmpty || _litrosCtrl.text.isEmpty ||
        _precioCtrl.text.isEmpty || _fecha == null) {
      _snack("Completa todos los campos", isError: true);
      return;
    }
    final km     = double.parse(_kmCtrl.text);
    final litros = double.parse(_litrosCtrl.text);
    final precio = double.parse(_precioCtrl.text);
    final total  = litros * precio;

    final db = await DatabaseHelper.instance.database;
    final id = await db.insert('gasolina', {
      'fecha':        _fecha!.toIso8601String(),
      'kilometraje':  km,
      'litros':       litros,
      'precio_litro': precio,
      'total':        total,
    });

    setState(() {
      _registros.insert(0, {
        'id': id, 'km': km, 'litros': litros,
        'precio': precio, 'total': total, 'fecha': _fecha!,
      });
    });

    _limpiar();
    Navigator.pop(context); // cierra el bottom sheet
    _snack("✓ Carga registrada");
  }

  Future<void> _guardarEdicion(int index, int id) async {
    if (_kmCtrl.text.isEmpty || _litrosCtrl.text.isEmpty ||
        _precioCtrl.text.isEmpty || _fecha == null) {
      _snack("Completa todos los campos", isError: true);
      return;
    }
    final km     = double.parse(_kmCtrl.text);
    final litros = double.parse(_litrosCtrl.text);
    final precio = double.parse(_precioCtrl.text);
    final total  = litros * precio;

    await DatabaseHelper.instance.actualizarGasolina(id,
        fecha: _fecha!.toIso8601String(),
        kilometraje: km, litros: litros,
        preciolitro: precio, total: total);

    setState(() {
      _registros[index] = {
        'id': id, 'km': km, 'litros': litros,
        'precio': precio, 'total': total, 'fecha': _fecha!,
      };
    });

    _limpiar();
    Navigator.pop(context);
    _snack("✓ Registro actualizado");
  }

  Future<void> _eliminar(int index) async {
    final id = _registros[index]['id'] as int;
    final db = await DatabaseHelper.instance.database;
    await db.delete('gasolina', where: 'id = ?', whereArgs: [id]);
    setState(() => _registros.removeAt(index));
    _snack("Registro eliminado");
  }

  void _limpiar() {
    _kmCtrl.clear(); _litrosCtrl.clear(); _precioCtrl.clear();
    setState(() => _fecha = null);
  }

  Future<void> _elegirFecha() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate:   DateTime(2020),
      lastDate:    DateTime(2100),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.light(primary: _blue),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _fecha = picked);
  }

  void _snack(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg,
          style: const TextStyle(fontWeight: FontWeight.w600)),
      backgroundColor: isError ? _red : _green,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.all(16),
      duration: const Duration(seconds: 2),
    ));
  }

  // ─── BOTTOM SHEET FORMULARIO ───────────────────────────────────────────────
  void _abrirFormulario({int? editIndex}) {
    final esEdicion = editIndex != null;

    if (esEdicion) {
      final item       = _registros[editIndex];
      _kmCtrl.text     = item['km'].toString();
      _litrosCtrl.text = item['litros'].toString();
      _precioCtrl.text = item['precio'].toString();
      _fecha           = item['fecha'] as DateTime;
    } else {
      _limpiar();
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _FormularioSheet(
        kmCtrl:      _kmCtrl,
        litrosCtrl:  _litrosCtrl,
        precioCtrl:  _precioCtrl,
        fecha:       _fecha,
        esEdicion:   esEdicion,
        onFecha:     _elegirFecha,
        onGuardar:   esEdicion
            ? () => _guardarEdicion(editIndex, _registros[editIndex]['id'] as int)
            : _guardar,
        onCancel:    () { _limpiar(); Navigator.pop(context); },
        totalPreview: _totalPreview,
        // Pasar setState para recalcular preview dentro del sheet
        onRebuild:   () => setState(() {}),
      ),
    );
  }

  // ─── ESTADÍSTICAS ──────────────────────────────────────────────────────────
  Map<String, double> get _stats {
    if (_registros.isEmpty) {
      return {'totalGastado': 0, 'totalLitros': 0, 'promLitros': 0, 'rendimiento': 0};
    }
    final totalGastado = _registros.fold(0.0, (s, r) => s + (r['total'] as double));
    final totalLitros  = _registros.fold(0.0, (s, r) => s + (r['litros'] as double));
    final promLitros   = totalLitros / _registros.length;

    // Rendimiento: km entre el primer y último odómetro / total litros intermedios
    double rendimiento = 0;
    if (_registros.length >= 2) {
      final sorted = [..._registros]..sort((a, b) =>
          (a['km'] as double).compareTo(b['km'] as double));
      final kmTotal  = (sorted.last['km'] as double) - (sorted.first['km'] as double);
      // Litros de todas las cargas excepto la primera (esa llenó el tanque)
      final litrosUsados = sorted.skip(1)
          .fold(0.0, (s, r) => s + (r['litros'] as double));
      if (litrosUsados > 0) rendimiento = kmTotal / litrosUsados;
    }

    return {
      'totalGastado': totalGastado,
      'totalLitros':  totalLitros,
      'promLitros':   promLitros,
      'rendimiento':  rendimiento,
    };
  }

  // ─── BUILD ─────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final st = _stats;

    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _card,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              size: 18, color: _textMain),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text("Gasolina",
            style: TextStyle(
              color: _textMain,
              fontWeight: FontWeight.w800,
              fontSize: 18,
              letterSpacing: -0.3,
            )),
        centerTitle: false,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: TextButton.icon(
              onPressed: () => _abrirFormulario(),
              icon: const Icon(Icons.add_rounded, size: 18, color: _blue),
              label: const Text("Agregar",
                  style: TextStyle(
                      color: _blue,
                      fontWeight: FontWeight.w700,
                      fontSize: 14)),
              style: TextButton.styleFrom(
                backgroundColor: _blueSoft,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20)),
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              ),
            ),
          ),
        ],
      ),

      body: _cargando
          ? const Center(
              child: CircularProgressIndicator(color: _blue, strokeWidth: 2))
          : CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                // ── RESUMEN ESTADÍSTICO ────────────────────────────────
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Fila 1: gasto total + litros totales
                        Row(children: [
                          Expanded(
                              child: _statCard(
                            label: "Gasto total",
                            value:
                                "\$${st['totalGastado']!.toStringAsFixed(0)}",
                            icon: Icons.payments_rounded,
                            color: _blue,
                          )),
                          const SizedBox(width: 10),
                          Expanded(
                              child: _statCard(
                            label: "Litros totales",
                            value:
                                "${st['totalLitros']!.toStringAsFixed(1)} L",
                            icon: Icons.water_drop_rounded,
                            color: _orange,
                          )),
                        ]),
                        const SizedBox(height: 10),
                        // Fila 2: prom litros + rendimiento global
                        Row(children: [
                          Expanded(
                              child: _statCard(
                            label: "Prom. por carga",
                            value:
                                "${st['promLitros']!.toStringAsFixed(1)} L",
                            icon: Icons.local_gas_station_rounded,
                            color: _green,
                          )),
                          const SizedBox(width: 10),
                          Expanded(
                              child: _statCard(
                            label: "Rendimiento",
                            value: st['rendimiento']! > 0
                                ? "${st['rendimiento']!.toStringAsFixed(1)} km/L"
                                : "—",
                            icon: Icons.speed_rounded,
                            color: const Color(0xFF9B59F5),
                          )),
                        ]),

                        const SizedBox(height: 24),
                        _sectionLabel(
                            "${_registros.length} REGISTRO${_registros.length != 1 ? 'S' : ''}"),
                        const SizedBox(height: 10),
                      ],
                    ),
                  ),
                ),

                // ── LISTA DE REGISTROS ─────────────────────────────────
                _registros.isEmpty
                    ? SliverToBoxAdapter(child: _sinRegistros())
                    : SliverPadding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                        sliver: SliverList(
                          delegate: SliverChildBuilderDelegate(
                            (ctx, i) => _itemRegistro(i),
                            childCount: _registros.length,
                          ),
                        ),
                      ),
              ],
            ),

      // FAB para agregar
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _abrirFormulario(),
        backgroundColor: _blue,
        elevation: 4,
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: const Text("Nueva carga",
            style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 14)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }

  // ─── WIDGETS ───────────────────────────────────────────────────────────────

  Widget _statCard({
    required String label,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 10,
              offset: const Offset(0, 3))
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(11),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: const TextStyle(
                        color: _textSub, fontSize: 10, fontWeight: FontWeight.w600)),
                const SizedBox(height: 1),
                Text(value,
                    style: const TextStyle(
                        color: _textMain,
                        fontSize: 15,
                        fontWeight: FontWeight.w800),
                    overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _itemRegistro(int index) {
    final item   = _registros[index];
    final km     = item['km']     as double;
    final litros = item['litros'] as double;
    final total  = item['total']  as double;
    final fecha  = item['fecha']  as DateTime;

    // Rendimiento respecto al anterior (si existe)
    String? rendStr;
    if (index < _registros.length - 1) {
      final kmPrev = _registros[index + 1]['km'] as double;
      final litPrev = _registros[index + 1]['litros'] as double;
      if (litPrev > 0 && km > kmPrev) {
        rendStr = "${((km - kmPrev) / litPrev).toStringAsFixed(1)} km/L";
      }
    }

    return Dismissible(
      key: ValueKey(item['id']),
      direction: DismissDirection.endToStart,
      confirmDismiss: (_) async {
        return await showDialog<bool>(
          context: context,
          builder: (_) => AlertDialog(
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20)),
            title: const Text("¿Eliminar registro?",
                style: TextStyle(fontWeight: FontWeight.w700)),
            content: const Text("Esta acción no se puede deshacer."),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text("Cancelar",
                      style: TextStyle(color: _textSub))),
              TextButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: const Text("Eliminar",
                      style: TextStyle(
                          color: _red, fontWeight: FontWeight.w700))),
            ],
          ),
        ) ?? false;
      },
      onDismissed: (_) => _eliminar(index),
      background: Container(
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: _redSoft,
          borderRadius: BorderRadius.circular(18),
        ),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: const Icon(Icons.delete_outline_rounded, color: _red, size: 24),
      ),
      child: GestureDetector(
        onTap: () => _abrirFormulario(editIndex: index),
        child: Container(
          margin: const EdgeInsets.only(bottom: 10),
          decoration: BoxDecoration(
            color: _card,
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 10,
                  offset: const Offset(0, 3))
            ],
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              // Ícono de gasolina
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: _blueSoft,
                  borderRadius: BorderRadius.circular(13),
                ),
                child: const Icon(Icons.local_gas_station_rounded,
                    color: _blue, size: 22),
              ),
              const SizedBox(width: 12),

              // Info principal
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          "${litros.toStringAsFixed(1)} L",
                          style: const TextStyle(
                              color: _textMain,
                              fontSize: 16,
                              fontWeight: FontWeight.w800),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: _greenSoft,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            "\$${total.toStringAsFixed(0)}",
                            style: const TextStyle(
                                color: _green,
                                fontSize: 12,
                                fontWeight: FontWeight.w700),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        const Icon(Icons.speed_rounded,
                            size: 12, color: _textSub),
                        const SizedBox(width: 3),
                        Text("${km.toStringAsFixed(0)} km",
                            style: const TextStyle(
                                color: _textSub, fontSize: 12)),
                        const SizedBox(width: 10),
                        const Icon(Icons.calendar_today_rounded,
                            size: 11, color: _textSub),
                        const SizedBox(width: 3),
                        Text(_fmt(fecha),
                            style: const TextStyle(
                                color: _textSub, fontSize: 12)),
                      ],
                    ),
                  ],
                ),
              ),

              // Rendimiento del intervalo (opcional)
              if (rendStr != null)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(rendStr,
                        style: const TextStyle(
                            color: _orange,
                            fontWeight: FontWeight.w700,
                            fontSize: 13)),
                    const Text("rendim.",
                        style: TextStyle(color: _textSub, fontSize: 10)),
                  ],
                )
              else
                const Icon(Icons.chevron_right_rounded,
                    color: _textSub, size: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sinRegistros() => Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                  color: _blueSoft, borderRadius: BorderRadius.circular(22)),
              child: const Icon(Icons.local_gas_station_rounded,
                  color: _blue, size: 36),
            ),
            const SizedBox(height: 16),
            const Text("Sin registros aún",
                style: TextStyle(
                    color: _textMain,
                    fontSize: 17,
                    fontWeight: FontWeight.w700)),
            const SizedBox(height: 6),
            const Text("Toca el botón para registrar\ntu primera carga",
                textAlign: TextAlign.center,
                style: TextStyle(color: _textSub, fontSize: 13, height: 1.5)),
          ],
        ),
      );

  Widget _sectionLabel(String t) => Text(t,
      style: const TextStyle(
          color: _textSub,
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 2));

  String _fmt(DateTime d) =>
      "${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}";
}

// ─── BOTTOM SHEET DEL FORMULARIO ─────────────────────────────────────────────
class _FormularioSheet extends StatefulWidget {
  final TextEditingController kmCtrl;
  final TextEditingController litrosCtrl;
  final TextEditingController precioCtrl;
  final DateTime? fecha;
  final bool esEdicion;
  final VoidCallback onFecha;
  final VoidCallback onGuardar;
  final VoidCallback onCancel;
  final double totalPreview;
  final VoidCallback onRebuild;

  const _FormularioSheet({
    required this.kmCtrl,
    required this.litrosCtrl,
    required this.precioCtrl,
    required this.fecha,
    required this.esEdicion,
    required this.onFecha,
    required this.onGuardar,
    required this.onCancel,
    required this.totalPreview,
    required this.onRebuild,
  });

  @override
  State<_FormularioSheet> createState() => _FormularioSheetState();
}

class _FormularioSheetState extends State<_FormularioSheet> {
  double get _total {
    final l = double.tryParse(widget.litrosCtrl.text) ?? 0;
    final p = double.tryParse(widget.precioCtrl.text) ?? 0;
    return l * p;
  }

  @override
  void initState() {
    super.initState();
    widget.litrosCtrl.addListener(_rebuild);
    widget.precioCtrl.addListener(_rebuild);
  }

  @override
  void dispose() {
    widget.litrosCtrl.removeListener(_rebuild);
    widget.precioCtrl.removeListener(_rebuild);
    super.dispose();
  }

  void _rebuild() => setState(() {});

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      decoration: const BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: EdgeInsets.fromLTRB(24, 12, 24, 24 + bottomInset),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                  color: const Color(0xFFE0E1EA),
                  borderRadius: BorderRadius.circular(2)),
            ),
          ),
          const SizedBox(height: 20),

          // Título
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                widget.esEdicion ? "Editar carga" : "Nueva carga",
                style: const TextStyle(
                    color: _textMain,
                    fontSize: 20,
                    fontWeight: FontWeight.w900),
              ),
              GestureDetector(
                onTap: widget.onCancel,
                child: Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: _bg,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.close_rounded,
                      color: _textSub, size: 18),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Preview de total (si hay datos)
          if (_total > 0)
            Container(
              width: double.infinity,
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: _blueSoft,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                children: [
                  const Icon(Icons.receipt_long_rounded,
                      color: _blue, size: 18),
                  const SizedBox(width: 10),
                  const Text("Total estimado: ",
                      style: TextStyle(color: _textSub, fontSize: 13)),
                  Text(
                    "\$${_total.toStringAsFixed(2)}",
                    style: const TextStyle(
                        color: _blue,
                        fontSize: 15,
                        fontWeight: FontWeight.w800),
                  ),
                ],
              ),
            ),

          // Campos del formulario
          _campo(
            ctrl:  widget.kmCtrl,
            label: "Kilometraje (odómetro)",
            icon:  Icons.speed_rounded,
            hint:  "Ej: 98500",
          ),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(
              child: _campo(
                ctrl:  widget.litrosCtrl,
                label: "Litros",
                icon:  Icons.water_drop_rounded,
                hint:  "Ej: 30.5",
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _campo(
                ctrl:  widget.precioCtrl,
                label: "Precio / litro",
                icon:  Icons.attach_money_rounded,
                hint:  "Ej: 23.50",
              ),
            ),
          ]),
          const SizedBox(height: 12),

          // Selector de fecha
          GestureDetector(
            onTap: widget.onFecha,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: _bg,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: widget.fecha != null ? _blue : _divider,
                  width: widget.fecha != null ? 1.5 : 1,
                ),
              ),
              child: Row(
                children: [
                  Icon(Icons.calendar_today_rounded,
                      size: 18,
                      color: widget.fecha != null ? _blue : _textSub),
                  const SizedBox(width: 10),
                  Text(
                    widget.fecha == null
                        ? "Seleccionar fecha"
                        : "${widget.fecha!.day.toString().padLeft(2, '0')}/${widget.fecha!.month.toString().padLeft(2, '0')}/${widget.fecha!.year}",
                    style: TextStyle(
                      color: widget.fecha != null ? _textMain : _textSub,
                      fontSize: 14,
                      fontWeight: widget.fecha != null
                          ? FontWeight.w600
                          : FontWeight.normal,
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Botón guardar
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: widget.onGuardar,
              style: ElevatedButton.styleFrom(
                backgroundColor: _blue,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
              ),
              child: Text(
                widget.esEdicion ? "Guardar cambios" : "Registrar carga",
                style: const TextStyle(
                    fontSize: 15, fontWeight: FontWeight.w700),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _campo({
    required TextEditingController ctrl,
    required String label,
    required IconData icon,
    required String hint,
  }) {
    return TextField(
      controller: ctrl,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [
        FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
      ],
      style: const TextStyle(
          color: _textMain, fontSize: 14, fontWeight: FontWeight.w600),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon, color: _textSub, size: 18),
        labelStyle: const TextStyle(color: _textSub, fontSize: 13),
        hintStyle: const TextStyle(color: Color(0xFFCCCFDA), fontSize: 13),
        filled: true,
        fillColor: _bg,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: _divider),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: _divider),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: _blue, width: 1.5),
        ),
      ),
    );
  }
}