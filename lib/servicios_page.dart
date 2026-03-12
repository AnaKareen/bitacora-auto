import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'database_helper.dart';

// ─── PALETA (consistente con toda la app) ────────────────────────────────────
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
const _orangeSoft= Color(0x1AFF7A2F);
const _red       = Color(0xFFFF3B55);
const _redSoft   = Color(0x1AFF3B55);
const _purple    = Color(0xFF9B59F5);
const _purpleSoft= Color(0x1A9B59F5);

// ─── CONFIGURACIÓN DE TIPOS DE SERVICIO ──────────────────────────────────────
class _TipoServicio {
  final String nombre;
  final IconData icono;
  final Color color;
  const _TipoServicio(this.nombre, this.icono, this.color);
}

const _tipos = [
  _TipoServicio('Cambio de aceite',  Icons.opacity_rounded,           _orange),
  _TipoServicio('Bujías',            Icons.bolt_rounded,               _purple),
  _TipoServicio('Filtro de aire',    Icons.air_rounded,                _blue),
  _TipoServicio('Llantas',           Icons.trip_origin_rounded,        _textMain),
  _TipoServicio('Amortiguadores',    Icons.directions_car_rounded,     _green),
  _TipoServicio('Balatas',           Icons.album_rounded,              _red),
  _TipoServicio('Otro',              Icons.build_circle_rounded,       _textSub),
];

_TipoServicio _tipoInfo(String nombre) =>
    _tipos.firstWhere((t) => t.nombre == nombre,
        orElse: () => _tipos.last);

// ─────────────────────────────────────────────────────────────────────────────
class ServiciosPage extends StatefulWidget {
  const ServiciosPage({super.key});

  @override
  State<ServiciosPage> createState() => _ServiciosPageState();
}

class _ServiciosPageState extends State<ServiciosPage> {
  // Formulario
  String?  _tipoSel;
  DateTime? _fecha;
  final _kmCtrl    = TextEditingController();
  final _costoCtrl = TextEditingController();
  final _lugarCtrl = TextEditingController();
  final _notasCtrl = TextEditingController();

  List<Map<String, dynamic>> _servicios = [];
  bool _cargando = true;

  // Filtro activo
  String? _filtroTipo;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  @override
  void dispose() {
    _kmCtrl.dispose(); _costoCtrl.dispose();
    _lugarCtrl.dispose(); _notasCtrl.dispose();
    super.dispose();
  }

  // ─── DATA ─────────────────────────────────────────────────────────────────
  Future<void> _cargar() async {
    setState(() => _cargando = true);
    final datos = await DatabaseHelper.instance.obtenerServicios();
    setState(() {
      _servicios = datos.map((e) => {
        'id':          e['id'],
        'tipo':        e['tipo'] as String? ?? 'Otro',
        'fecha':       DateTime.tryParse(e['fecha'] as String? ?? '') ?? DateTime.now(),
        'kilometraje': (e['kilometraje'] as num?)?.toDouble() ?? 0.0,
        'costo':       (e['costo']       as num?)?.toDouble() ?? 0.0,
        'lugar':       e['lugar']  as String? ?? '',
        'notas':       e['notas']  as String? ?? '',
      }).toList();
      _cargando = false;
    });
  }

  Future<void> _guardar() async {
    if (!_validar()) return;

    final km    = double.parse(_kmCtrl.text);
    final costo = double.parse(_costoCtrl.text);

    final id = await DatabaseHelper.instance.insertarServicio(
      tipo:        _tipoSel!,
      fecha:       _fecha!.toIso8601String(),
      kilometraje: km,
      costo:       costo,
      lugar:       _lugarCtrl.text,
      notas:       _notasCtrl.text,
    );

    setState(() {
      _servicios.insert(0, {
        'id': id, 'tipo': _tipoSel, 'fecha': _fecha,
        'kilometraje': km, 'costo': costo,
        'lugar': _lugarCtrl.text, 'notas': _notasCtrl.text,
      });
    });

    _limpiar();
    Navigator.pop(context);
    _snack("✓ Servicio registrado");
  }

  Future<void> _guardarEdicion(int index) async {
    if (!_validar()) return;

    final km    = double.parse(_kmCtrl.text);
    final costo = double.parse(_costoCtrl.text);
    final id    = _servicios[index]['id'] as int;

    await DatabaseHelper.instance.actualizarServicio(id,
        tipo: _tipoSel!, fecha: _fecha!.toIso8601String(),
        kilometraje: km, costo: costo,
        lugar: _lugarCtrl.text, notas: _notasCtrl.text);

    setState(() {
      _servicios[index] = {
        'id': id, 'tipo': _tipoSel, 'fecha': _fecha,
        'kilometraje': km, 'costo': costo,
        'lugar': _lugarCtrl.text, 'notas': _notasCtrl.text,
      };
    });

    _limpiar();
    Navigator.pop(context);
    _snack("✓ Servicio actualizado");
  }

  Future<void> _eliminar(int index) async {
    final id = _servicios[index]['id'] as int;
    await DatabaseHelper.instance.eliminarServicio(id);
    setState(() => _servicios.removeAt(index));
    _snack("Servicio eliminado");
  }

  bool _validar() {
    if (_tipoSel == null || _kmCtrl.text.isEmpty ||
        _costoCtrl.text.isEmpty || _lugarCtrl.text.isEmpty ||
        _fecha == null) {
      _snack("Completa todos los campos obligatorios", isError: true);
      return false;
    }
    return true;
  }

  void _limpiar() {
    _tipoSel = null; _fecha = null;
    _kmCtrl.clear(); _costoCtrl.clear();
    _lugarCtrl.clear(); _notasCtrl.clear();
  }

  Future<void> _elegirFecha() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate:  DateTime(2100),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.light(primary: _orange),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _fecha = picked);
  }

  void _snack(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg, style: const TextStyle(fontWeight: FontWeight.w600)),
      backgroundColor: isError ? _red : _green,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.all(16),
      duration: const Duration(seconds: 2),
    ));
  }

  // ─── BOTTOM SHEET ──────────────────────────────────────────────────────────
  void _abrirFormulario({int? editIndex}) {
    if (editIndex != null) {
      final s      = _servicios[editIndex];
      _tipoSel     = s['tipo'] as String;
      _fecha       = s['fecha'] as DateTime;
      _kmCtrl.text    = (s['kilometraje'] as double).toStringAsFixed(0);
      _costoCtrl.text = (s['costo'] as double).toStringAsFixed(2);
      _lugarCtrl.text = s['lugar'] as String;
      _notasCtrl.text = s['notas'] as String;
    } else {
      _limpiar();
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setSheet) => _sheet(ctx, setSheet, editIndex),
      ),
    );
  }

  Widget _sheet(BuildContext ctx, StateSetter setSheet, int? editIndex) {
    final bottomInset = MediaQuery.of(ctx).viewInsets.bottom;

    return Container(
      decoration: const BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: EdgeInsets.fromLTRB(24, 12, 24, 24 + bottomInset),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle
            Center(
              child: Container(
                width: 36, height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFE0E1EA),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Título + botón cerrar
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  editIndex != null ? "Editar servicio" : "Nuevo servicio",
                  style: const TextStyle(
                    color: _textMain, fontSize: 20, fontWeight: FontWeight.w900),
                ),
                GestureDetector(
                  onTap: () { _limpiar(); Navigator.pop(ctx); },
                  child: Container(
                    width: 32, height: 32,
                    decoration: BoxDecoration(
                      color: _bg, borderRadius: BorderRadius.circular(10)),
                    child: const Icon(Icons.close_rounded, color: _textSub, size: 18),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // ── SELECTOR DE TIPO (chips) ──────────────────────────────
            const Text("Tipo de servicio",
                style: TextStyle(color: _textSub, fontSize: 12,
                    fontWeight: FontWeight.w700, letterSpacing: 1)),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8, runSpacing: 8,
              children: _tipos.map((t) {
                final sel = _tipoSel == t.nombre;
                return GestureDetector(
                  onTap: () => setSheet(() => _tipoSel = t.nombre),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: sel ? t.color.withOpacity(0.12) : _bg,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: sel ? t.color : _divider,
                        width: sel ? 1.5 : 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(t.icono, size: 15,
                            color: sel ? t.color : _textSub),
                        const SizedBox(width: 6),
                        Text(t.nombre,
                            style: TextStyle(
                              color: sel ? t.color : _textSub,
                              fontSize: 12.5,
                              fontWeight: sel ? FontWeight.w700 : FontWeight.w500,
                            )),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 20),

            // ── CAMPOS ────────────────────────────────────────────────
            Row(children: [
              Expanded(child: _campo(ctrl: _kmCtrl,
                  label: "Kilometraje", icon: Icons.speed_rounded,
                  hint: "Ej: 98500", numerico: true)),
              const SizedBox(width: 12),
              Expanded(child: _campo(ctrl: _costoCtrl,
                  label: "Costo (\$)", icon: Icons.attach_money_rounded,
                  hint: "Ej: 850.00", numerico: true)),
            ]),
            const SizedBox(height: 12),

            _campo(ctrl: _lugarCtrl,
                label: "Lugar / taller", icon: Icons.location_on_rounded,
                hint: "Ej: Servicio Honda Celaya"),
            const SizedBox(height: 12),

            _campo(ctrl: _notasCtrl,
                label: "Notas (opcional)", icon: Icons.notes_rounded,
                hint: "Ej: Cambio de aceite sintético 5W30",
                maxLines: 2),
            const SizedBox(height: 12),

            // ── FECHA ────────────────────────────────────────────────
            GestureDetector(
              onTap: () async {
                await _elegirFecha();
                setSheet(() {});
              },
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: _bg,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: _fecha != null ? _orange : _divider,
                    width: _fecha != null ? 1.5 : 1,
                  ),
                ),
                child: Row(children: [
                  Icon(Icons.calendar_today_rounded, size: 18,
                      color: _fecha != null ? _orange : _textSub),
                  const SizedBox(width: 10),
                  Text(
                    _fecha == null ? "Seleccionar fecha" : _fmt(_fecha!),
                    style: TextStyle(
                      color: _fecha != null ? _textMain : _textSub,
                      fontSize: 14,
                      fontWeight: _fecha != null ? FontWeight.w600 : FontWeight.normal,
                    ),
                  ),
                ]),
              ),
            ),
            const SizedBox(height: 24),

            // ── BOTÓN GUARDAR ─────────────────────────────────────────
            SizedBox(
              width: double.infinity, height: 52,
              child: ElevatedButton(
                onPressed: editIndex != null
                    ? () => _guardarEdicion(editIndex)
                    : _guardar,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _orange,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                ),
                child: Text(
                  editIndex != null ? "Guardar cambios" : "Registrar servicio",
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── ESTADÍSTICAS ──────────────────────────────────────────────────────────
  Map<String, dynamic> get _stats {
    if (_servicios.isEmpty) return {
      'total': 0.0, 'cantidad': 0, 'tipoFrecuente': '—', 'ultimoKm': 0.0
    };
    final total = _servicios.fold(0.0, (s, r) => s + (r['costo'] as double));
    final frecMap = <String, int>{};
    for (final s in _servicios) {
      frecMap[s['tipo'] as String] = (frecMap[s['tipo'] as String] ?? 0) + 1;
    }
    final tipoFrecuente = frecMap.entries
        .reduce((a, b) => a.value >= b.value ? a : b).key;
    final ultimoKm = _servicios
        .map((s) => s['kilometraje'] as double)
        .reduce((a, b) => a > b ? a : b);
    return {
      'total': total, 'cantidad': _servicios.length,
      'tipoFrecuente': tipoFrecuente, 'ultimoKm': ultimoKm,
    };
  }

  List<Map<String, dynamic>> get _serviciosFiltrados => _filtroTipo == null
      ? _servicios
      : _servicios.where((s) => s['tipo'] == _filtroTipo).toList();

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
        title: const Text("Servicios",
            style: TextStyle(
              color: _textMain, fontWeight: FontWeight.w800,
              fontSize: 18, letterSpacing: -0.3,
            )),
        centerTitle: false,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: TextButton.icon(
              onPressed: () => _abrirFormulario(),
              icon: const Icon(Icons.add_rounded, size: 18, color: _orange),
              label: const Text("Agregar",
                  style: TextStyle(color: _orange,
                      fontWeight: FontWeight.w700, fontSize: 14)),
              style: TextButton.styleFrom(
                backgroundColor: _orangeSoft,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20)),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              ),
            ),
          ),
        ],
      ),

      body: _cargando
          ? const Center(child: CircularProgressIndicator(
              color: _orange, strokeWidth: 2))
          : CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // ── STATS ──────────────────────────────────────
                        Row(children: [
                          Expanded(child: _statCard(
                            label: "Gasto total",
                            value: "\$${(st['total'] as double).toStringAsFixed(0)}",
                            icon: Icons.payments_rounded, color: _orange)),
                          const SizedBox(width: 10),
                          Expanded(child: _statCard(
                            label: "Servicios",
                            value: "${st['cantidad']}",
                            icon: Icons.build_rounded, color: _blue)),
                        ]),
                        const SizedBox(height: 10),
                        Row(children: [
                          Expanded(child: _statCard(
                            label: "Más frecuente",
                            value: st['tipoFrecuente'] as String,
                            icon: Icons.bar_chart_rounded, color: _purple)),
                          const SizedBox(width: 10),
                          Expanded(child: _statCard(
                            label: "Último KM",
                            value: "${(st['ultimoKm'] as double).toStringAsFixed(0)} km",
                            icon: Icons.speed_rounded, color: _green)),
                        ]),

                        const SizedBox(height: 24),

                        // ── FILTROS POR TIPO ───────────────────────────
                        _sectionLabel("FILTRAR POR TIPO"),
                        const SizedBox(height: 8),
                        SizedBox(
                          height: 36,
                          child: ListView(
                            scrollDirection: Axis.horizontal,
                            children: [
                              // Chip "Todos"
                              _filtroChip(null),
                              const SizedBox(width: 6),
                              ..._tipos.map((t) => Padding(
                                    padding: const EdgeInsets.only(right: 6),
                                    child: _filtroChip(t.nombre),
                                  )),
                            ],
                          ),
                        ),

                        const SizedBox(height: 20),
                        _sectionLabel(
                            "${_serviciosFiltrados.length} REGISTRO${_serviciosFiltrados.length != 1 ? 'S' : ''}"),
                        const SizedBox(height: 10),
                      ],
                    ),
                  ),
                ),

                // ── LISTA ─────────────────────────────────────────────
                _serviciosFiltrados.isEmpty
                    ? SliverToBoxAdapter(child: _sinRegistros())
                    : SliverPadding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                        sliver: SliverList(
                          delegate: SliverChildBuilderDelegate(
                            (ctx, i) => _itemServicio(i),
                            childCount: _serviciosFiltrados.length,
                          ),
                        ),
                      ),
              ],
            ),

      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _abrirFormulario(),
        backgroundColor: _orange,
        elevation: 4,
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: const Text("Nuevo servicio",
            style: TextStyle(color: Colors.white,
                fontWeight: FontWeight.w700, fontSize: 14)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }

  // ─── WIDGETS ───────────────────────────────────────────────────────────────

  Widget _filtroChip(String? tipo) {
    final sel     = _filtroTipo == tipo;
    final info    = tipo != null ? _tipoInfo(tipo) : null;
    final color   = info?.color ?? _blue;
    final label   = tipo ?? "Todos";
    final icono   = info?.icono ?? Icons.apps_rounded;

    return GestureDetector(
      onTap: () => setState(() => _filtroTipo = tipo),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: sel ? color.withOpacity(0.12) : _card,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
              color: sel ? color : _divider, width: sel ? 1.5 : 1),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icono, size: 13, color: sel ? color : _textSub),
            const SizedBox(width: 5),
            Text(label,
                style: TextStyle(
                  color: sel ? color : _textSub,
                  fontSize: 12,
                  fontWeight: sel ? FontWeight.w700 : FontWeight.w500,
                )),
          ],
        ),
      ),
    );
  }

  Widget _itemServicio(int filteredIndex) {
    // Buscar índice real para editar/eliminar correctamente con filtro activo
    final item   = _serviciosFiltrados[filteredIndex];
    final realIdx = _servicios.indexOf(item);
    final tipo   = item['tipo'] as String;
    final info   = _tipoInfo(tipo);
    final costo  = item['costo'] as double;
    final km     = item['kilometraje'] as double;
    final fecha  = item['fecha'] as DateTime;
    final lugar  = item['lugar'] as String;
    final notas  = item['notas'] as String;

    return Dismissible(
      key: ValueKey(item['id']),
      direction: DismissDirection.endToStart,
      confirmDismiss: (_) async => await showDialog<bool>(
        context: context,
        builder: (_) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text("¿Eliminar servicio?",
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
                    style: TextStyle(color: _red, fontWeight: FontWeight.w700))),
          ],
        ),
      ) ?? false,
      onDismissed: (_) => _eliminar(realIdx),
      background: Container(
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: _redSoft, borderRadius: BorderRadius.circular(18)),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: const Icon(Icons.delete_outline_rounded, color: _red, size: 24),
      ),
      child: GestureDetector(
        onTap: () => _abrirFormulario(editIndex: realIdx),
        child: Container(
          margin: const EdgeInsets.only(bottom: 10),
          decoration: BoxDecoration(
            color: _card,
            borderRadius: BorderRadius.circular(18),
            boxShadow: [BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 10, offset: const Offset(0, 3))],
          ),
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Ícono del tipo
              Container(
                width: 46, height: 46,
                decoration: BoxDecoration(
                  color: info.color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(info.icono, color: info.color, size: 22),
              ),
              const SizedBox(width: 12),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Tipo + costo
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(tipo,
                            style: const TextStyle(
                              color: _textMain, fontSize: 15,
                              fontWeight: FontWeight.w700)),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 3),
                          decoration: BoxDecoration(
                            color: _greenSoft,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text("\$${costo.toStringAsFixed(0)}",
                              style: const TextStyle(
                                color: _green, fontSize: 13,
                                fontWeight: FontWeight.w700)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 5),

                    // Lugar + km + fecha en una línea
                    Row(children: [
                      const Icon(Icons.location_on_rounded,
                          size: 11, color: _textSub),
                      const SizedBox(width: 3),
                      Expanded(
                        child: Text(lugar,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(color: _textSub, fontSize: 12)),
                      ),
                    ]),
                    const SizedBox(height: 2),
                    Row(children: [
                      const Icon(Icons.speed_rounded,
                          size: 11, color: _textSub),
                      const SizedBox(width: 3),
                      Text("${km.toStringAsFixed(0)} km",
                          style: const TextStyle(color: _textSub, fontSize: 12)),
                      const SizedBox(width: 10),
                      const Icon(Icons.calendar_today_rounded,
                          size: 11, color: _textSub),
                      const SizedBox(width: 3),
                      Text(_fmt(fecha),
                          style: const TextStyle(color: _textSub, fontSize: 12)),
                    ]),

                    // Nota si existe
                    if (notas.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: _bg,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(notas,
                            style: const TextStyle(
                                color: _textSub, fontSize: 11.5),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _statCard({
    required String label,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10, offset: const Offset(0, 3))],
      ),
      child: Row(children: [
        Container(
          width: 36, height: 36,
          decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(11)),
          child: Icon(icon, color: color, size: 17),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: const TextStyle(color: _textSub, fontSize: 10,
                      fontWeight: FontWeight.w600)),
              const SizedBox(height: 1),
              Text(value,
                  style: const TextStyle(color: _textMain, fontSize: 14,
                      fontWeight: FontWeight.w800),
                  overflow: TextOverflow.ellipsis),
            ],
          ),
        ),
      ]),
    );
  }

  Widget _sinRegistros() => Padding(
        padding: const EdgeInsets.all(40),
        child: Column(children: [
          Container(
            width: 72, height: 72,
            decoration: BoxDecoration(
                color: _orangeSoft,
                borderRadius: BorderRadius.circular(22)),
            child: const Icon(Icons.build_rounded, color: _orange, size: 36),
          ),
          const SizedBox(height: 16),
          const Text("Sin servicios registrados",
              style: TextStyle(color: _textMain, fontSize: 17,
                  fontWeight: FontWeight.w700)),
          const SizedBox(height: 6),
          const Text("Toca el botón para registrar\ntu primer servicio",
              textAlign: TextAlign.center,
              style: TextStyle(color: _textSub, fontSize: 13, height: 1.5)),
        ]),
      );

  Widget _sectionLabel(String t) => Text(t,
      style: const TextStyle(color: _textSub, fontSize: 11,
          fontWeight: FontWeight.w700, letterSpacing: 2));

  Widget _campo({
    required TextEditingController ctrl,
    required String label,
    required IconData icon,
    required String hint,
    bool numerico = false,
    int maxLines  = 1,
  }) {
    return TextField(
      controller: ctrl,
      keyboardType: numerico
          ? const TextInputType.numberWithOptions(decimal: true)
          : TextInputType.text,
      inputFormatters: numerico
          ? [FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}'))]
          : null,
      maxLines: maxLines,
      style: const TextStyle(color: _textMain, fontSize: 14,
          fontWeight: FontWeight.w600),
      decoration: InputDecoration(
        labelText:  label,
        hintText:   hint,
        prefixIcon: Icon(icon, color: _textSub, size: 18),
        labelStyle: const TextStyle(color: _textSub, fontSize: 13),
        hintStyle:  const TextStyle(color: Color(0xFFCCCFDA), fontSize: 13),
        filled:     true,
        fillColor:  _bg,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: _divider)),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: _divider)),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: _orange, width: 1.5)),
      ),
    );
  }

  String _fmt(DateTime d) =>
      "${d.day.toString().padLeft(2,'0')}/${d.month.toString().padLeft(2,'0')}/${d.year}";
}