import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'database_helper.dart';

// ─── PALETA ──────────────────────────────────────────────────────────────────
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

class SeguroPage extends StatefulWidget {
  const SeguroPage({super.key});

  @override
  State<SeguroPage> createState() => _SeguroPageState();
}

class _SeguroPageState extends State<SeguroPage> {
  final _asegCtrl  = TextEditingController();
  final _polizaCtrl= TextEditingController();
  final _telCtrl   = TextEditingController();
  final _notasCtrl = TextEditingController();

  DateTime? _inicio;
  DateTime? _fin;
  Map<String, dynamic>? _seguro;
  bool _cargando = true;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  @override
  void dispose() {
    _asegCtrl.dispose(); _polizaCtrl.dispose();
    _telCtrl.dispose();  _notasCtrl.dispose();
    super.dispose();
  }

  // ─── DATA ─────────────────────────────────────────────────────────────────
  Future<void> _cargar() async {
    setState(() => _cargando = true);
    final datos = await DatabaseHelper.instance.obtenerSeguro();
    setState(() {
      _seguro   = datos;
      _cargando = false;
      if (datos != null) {
        _asegCtrl.text   = datos['aseguradora'] as String? ?? '';
        _polizaCtrl.text = datos['poliza']      as String? ?? '';
        _telCtrl.text    = datos['telefono']    as String? ?? '';
        _notasCtrl.text  = datos['notas']       as String? ?? '';
        _inicio = DateTime.tryParse(datos['inicio'] as String? ?? '');
        _fin    = DateTime.tryParse(datos['fin']    as String? ?? '');
      }
    });
  }

  Future<void> _guardar() async {
    if (_asegCtrl.text.isEmpty || _polizaCtrl.text.isEmpty ||
        _telCtrl.text.isEmpty  || _inicio == null || _fin == null) {
      _snack("Completa todos los campos obligatorios", isError: true);
      return;
    }

    if (_seguro == null) {
      await DatabaseHelper.instance.insertarSeguro(
        aseguradora: _asegCtrl.text,
        poliza:      _polizaCtrl.text,
        telefono:    _telCtrl.text,
        inicio:      _inicio!.toIso8601String(),
        fin:         _fin!.toIso8601String(),
        notas:       _notasCtrl.text,
      );
      _snack("✓ Seguro registrado");
    } else {
      await DatabaseHelper.instance.actualizarSeguro(
        _seguro!['id'] as int,
        aseguradora: _asegCtrl.text,
        poliza:      _polizaCtrl.text,
        telefono:    _telCtrl.text,
        inicio:      _inicio!.toIso8601String(),
        fin:         _fin!.toIso8601String(),
        notas:       _notasCtrl.text,
      );
      _snack("✓ Seguro actualizado");
    }
    await _cargar();
  }

  Future<void> _eliminar() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text("¿Eliminar seguro?",
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
    );
    if (confirm != true) return;

    await DatabaseHelper.instance.eliminarSeguro(_seguro!['id'] as int);
    setState(() {
      _seguro = null;
      _inicio = null; _fin = null;
      _asegCtrl.clear(); _polizaCtrl.clear();
      _telCtrl.clear();  _notasCtrl.clear();
    });
    _snack("Seguro eliminado");
  }

  Future<void> _elegirFecha({required bool esInicio}) async {
    final initial = esInicio ? (_inicio ?? DateTime.now()) : (_fin ?? DateTime.now());
    final picked  = await showDatePicker(
      context:   context,
      initialDate: initial,
      firstDate:   DateTime(2020),
      lastDate:    DateTime(2100),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.light(primary: _green),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => esInicio ? _inicio = picked : _fin = picked);
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

  // ─── ESTADO DEL SEGURO ────────────────────────────────────────────────────
  ({Color color, Color soft, String label, IconData icon, int dias}) _estado() {
    if (_fin == null) {
      return (color: _textSub, soft: const Color(0x1A8A8FA8),
              label: "Sin fecha de vencimiento", icon: Icons.help_outline_rounded, dias: 0);
    }
    final diff = _fin!.difference(DateTime.now()).inDays;
    if (diff < 0) {
      return (color: _red,    soft: _redSoft,    label: "Vencido",
              icon: Icons.cancel_rounded,         dias: diff.abs());
    } else if (diff <= 15) {
      return (color: _orange, soft: _orangeSoft, label: "Por vencer",
              icon: Icons.warning_amber_rounded,  dias: diff);
    } else {
      return (color: _green,  soft: _greenSoft,  label: "Vigente",
              icon: Icons.verified_rounded,       dias: diff);
    }
  }

  // ─── BUILD ────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
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
        title: const Text("Seguro",
            style: TextStyle(
              color: _textMain, fontWeight: FontWeight.w800,
              fontSize: 18, letterSpacing: -0.3,
            )),
        centerTitle: false,
        actions: _seguro != null
            ? [
                Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: TextButton.icon(
                    onPressed: _eliminar,
                    icon: const Icon(Icons.delete_outline_rounded,
                        size: 16, color: _red),
                    label: const Text("Eliminar",
                        style: TextStyle(color: _red,
                            fontWeight: FontWeight.w700, fontSize: 13)),
                    style: TextButton.styleFrom(
                      backgroundColor: _redSoft,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20)),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 7),
                    ),
                  ),
                ),
              ]
            : null,
      ),

      body: _cargando
          ? const Center(child: CircularProgressIndicator(
              color: _green, strokeWidth: 2))
          : SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 40),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [

                  // ── TARJETA DE ESTADO ─────────────────────────────
                  if (_seguro != null) ...[
                    _tarjetaEstado(),
                    const SizedBox(height: 24),
                  ],

                  // ── SECCIÓN FORMULARIO ────────────────────────────
                  _sectionLabel(_seguro == null
                      ? "REGISTRAR SEGURO" : "DATOS DEL SEGURO"),
                  const SizedBox(height: 12),

                  // Aseguradora
                  _campo(ctrl: _asegCtrl,
                      label: "Aseguradora",
                      icon: Icons.business_rounded,
                      hint: "Ej: GNP, AXA, Qualitas"),
                  const SizedBox(height: 12),

                  // Póliza + Teléfono en fila
                  Row(children: [
                    Expanded(child: _campo(ctrl: _polizaCtrl,
                        label: "Núm. de Póliza",
                        icon: Icons.confirmation_number_rounded,
                        hint: "Ej: ABC-123456")),
                    const SizedBox(width: 12),
                    Expanded(child: _campo(ctrl: _telCtrl,
                        label: "Teléfono",
                        icon: Icons.phone_rounded,
                        hint: "Ej: 800 111 2222",
                        tipo: TextInputType.phone)),
                  ]),
                  const SizedBox(height: 12),

                  // Fechas
                  _sectionLabel("VIGENCIA"),
                  const SizedBox(height: 10),
                  Row(children: [
                    Expanded(child: _selectorFecha(
                        label: "Inicio",
                        fecha: _inicio,
                        onTap: () => _elegirFecha(esInicio: true))),
                    const SizedBox(width: 12),
                    Expanded(child: _selectorFecha(
                        label: "Vencimiento",
                        fecha: _fin,
                        onTap: () => _elegirFecha(esInicio: false),
                        isVenc: true)),
                  ]),

                  // Barra de progreso de vigencia
                  if (_inicio != null && _fin != null) ...[
                    const SizedBox(height: 12),
                    _barraVigencia(),
                  ],

                  const SizedBox(height: 12),

                  // Notas
                  _campo(ctrl: _notasCtrl,
                      label: "Notas (opcional)",
                      icon: Icons.notes_rounded,
                      hint: "Cobertura, deducible, observaciones...",
                      maxLines: 3),

                  const SizedBox(height: 24),

                  // Botón guardar
                  SizedBox(
                    width: double.infinity, height: 52,
                    child: ElevatedButton(
                      onPressed: _guardar,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _green,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16)),
                      ),
                      child: Text(
                        _seguro == null ? "Registrar seguro" : "Guardar cambios",
                        style: const TextStyle(
                            fontSize: 15, fontWeight: FontWeight.w700),
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  // ─── TARJETA DE ESTADO VISUAL ─────────────────────────────────────────────
  Widget _tarjetaEstado() {
    final est = _estado();
    final vencido = _fin != null && _fin!.isBefore(DateTime.now());

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: est.color,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(color: est.color.withOpacity(0.3),
              blurRadius: 20, offset: const Offset(0, 6)),
        ],
      ),
      padding: const EdgeInsets.all(22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Aseguradora + estado
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _seguro!['aseguradora'] as String? ?? '',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    "Póliza ${_seguro!['poliza'] as String? ?? ''}",
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.75),
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(est.icon, color: Colors.white, size: 14),
                    const SizedBox(width: 5),
                    Text(est.label,
                        style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 12)),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),
          Container(height: 1, color: Colors.white.withOpacity(0.2)),
          const SizedBox(height: 16),

          // Días restantes + teléfono
          Row(
            children: [
              // Días
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      vencido
                          ? "Venció hace"
                          : "Días restantes",
                      style: TextStyle(
                          color: Colors.white.withOpacity(0.7),
                          fontSize: 11, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      "${est.dias} días",
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 26,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -0.5),
                    ),
                  ],
                ),
              ),

              // Teléfono
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text("Teléfono",
                      style: TextStyle(
                          color: Colors.white.withOpacity(0.7),
                          fontSize: 11, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 2),
                  Text(
                    _seguro!['telefono'] as String? ?? '—',
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w700),
                  ),
                ],
              ),
            ],
          ),

          // Notas si existen
          if ((_seguro!['notas'] as String? ?? '').isNotEmpty) ...[
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  Icon(Icons.notes_rounded,
                      color: Colors.white.withOpacity(0.8), size: 14),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _seguro!['notas'] as String,
                      style: TextStyle(
                          color: Colors.white.withOpacity(0.85),
                          fontSize: 12),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ─── BARRA DE PROGRESO VIGENCIA ───────────────────────────────────────────
  Widget _barraVigencia() {
    final total    = _fin!.difference(_inicio!).inDays;
    final transcurridos = DateTime.now().difference(_inicio!).inDays;
    final progreso = (transcurridos / total).clamp(0.0, 1.0);
    final est      = _estado();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(_fmt(_inicio!),
                style: const TextStyle(color: _textSub, fontSize: 11)),
            Text("${(progreso * 100).toStringAsFixed(0)}% transcurrido",
                style: TextStyle(
                    color: est.color, fontSize: 11, fontWeight: FontWeight.w700)),
            Text(_fmt(_fin!),
                style: const TextStyle(color: _textSub, fontSize: 11)),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: LinearProgressIndicator(
            value: progreso,
            minHeight: 8,
            backgroundColor: _divider,
            valueColor: AlwaysStoppedAnimation<Color>(est.color),
          ),
        ),
      ],
    );
  }

  // ─── SELECTOR DE FECHA ────────────────────────────────────────────────────
  Widget _selectorFecha({
    required String label,
    required DateTime? fecha,
    required VoidCallback onTap,
    bool isVenc = false,
  }) {
    final color = fecha != null
        ? (isVenc ? _green : _blue)
        : _textSub;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: _card,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: fecha != null ? color : _divider,
            width: fecha != null ? 1.5 : 1,
          ),
          boxShadow: [BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 8, offset: const Offset(0, 2))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                style: TextStyle(
                    color: fecha != null ? color : _textSub,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5)),
            const SizedBox(height: 4),
            Row(children: [
              Icon(Icons.calendar_today_rounded,
                  size: 14, color: fecha != null ? color : _textSub),
              const SizedBox(width: 6),
              Text(
                fecha != null ? _fmt(fecha) : "Sin definir",
                style: TextStyle(
                  color: fecha != null ? _textMain : _textSub,
                  fontSize: 13,
                  fontWeight: fecha != null ? FontWeight.w700 : FontWeight.normal,
                ),
              ),
            ]),
          ],
        ),
      ),
    );
  }

  // ─── CAMPO DE TEXTO ───────────────────────────────────────────────────────
  Widget _campo({
    required TextEditingController ctrl,
    required String label,
    required IconData icon,
    required String hint,
    TextInputType tipo = TextInputType.text,
    int maxLines = 1,
  }) {
    return TextField(
      controller: ctrl,
      keyboardType: tipo,
      maxLines: maxLines,
      style: const TextStyle(
          color: _textMain, fontSize: 14, fontWeight: FontWeight.w600),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon, color: _textSub, size: 18),
        labelStyle: const TextStyle(color: _textSub, fontSize: 13),
        hintStyle: const TextStyle(color: Color(0xFFCCCFDA), fontSize: 13),
        filled: true,
        fillColor: _card,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: _divider)),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: _divider)),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: _green, width: 1.5)),
      ),
    );
  }

  Widget _sectionLabel(String t) => Text(t,
      style: const TextStyle(color: _textSub, fontSize: 11,
          fontWeight: FontWeight.w700, letterSpacing: 2));

  String _fmt(DateTime d) =>
      "${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}";
}