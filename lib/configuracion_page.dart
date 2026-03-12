import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ─── PALETA ──────────────────────────────────────────────────────────────────
const _bg         = Color(0xFFF5F6FA);
const _card       = Color(0xFFFFFFFF);
const _textMain   = Color(0xFF0F1117);
const _textSub    = Color(0xFF8A8FA8);
const _divider    = Color(0xFFEAEBF0);
const _blue       = Color(0xFF3B7BFF);
const _blueSoft   = Color(0x1A3B7BFF);
const _green      = Color(0xFF00C48C);
const _greenSoft  = Color(0x1A00C48C);
const _orange     = Color(0xFFFF7A2F);
const _orangeSoft = Color(0x1AFF7A2F);
const _red        = Color(0xFFFF3B55);
const _redSoft    = Color(0x1AFF3B55);
const _purple     = Color(0xFF9B59F5);
const _purpleSoft = Color(0x1A9B59F5);

// ─── CLAVES SharedPreferences ─────────────────────────────────────────────────
// Vehículo
const _kMarca  = 'cfg_marca';
const _kModelo = 'cfg_modelo';
const _kAnio   = 'cfg_anio';
const _kColor  = 'cfg_color';
const _kPlacas = 'cfg_placas';
const _kVin    = 'cfg_vin';

// Preferencias
const _kAlertasActivas  = 'cfg_alertas_activas';
const _kRecordGasolina  = 'cfg_record_gasolina';
const _kDiasSinGasolina = 'cfg_dias_sin_gasolina';

// Intervalos: se guarda como "cfg_int_<tipo>_meses" y "cfg_int_<tipo>_aviso"
// Ej: cfg_int_Cambio de aceite_meses = 6

// ─── MODELO DE INTERVALO ──────────────────────────────────────────────────────
class IntervaloServicio {
  final String tipo;
  final IconData icono;
  final Color color;
  final int mesesDefault;
  final int mesesAvisoDefault;
  int meses;
  int mesesAviso;

  IntervaloServicio({
    required this.tipo,
    required this.icono,
    required this.color,
    required this.mesesDefault,
    required this.mesesAvisoDefault,
  })  : meses      = mesesDefault,
        mesesAviso = mesesAvisoDefault;

  String get keyMeses => 'cfg_int_${tipo}_meses';
  String get keyAviso => 'cfg_int_${tipo}_aviso';
}

// ─── PÁGINA ───────────────────────────────────────────────────────────────────
class ConfiguracionPage extends StatefulWidget {
  const ConfiguracionPage({super.key});

  @override
  State<ConfiguracionPage> createState() => _ConfiguracionPageState();
}

class _ConfiguracionPageState extends State<ConfiguracionPage> {

  // Controladores de texto
  final _marcaCtrl  = TextEditingController();
  final _modeloCtrl = TextEditingController();
  final _anioCtrl   = TextEditingController();
  final _placasCtrl = TextEditingController();
  final _colorCtrl  = TextEditingController();
  final _vinCtrl    = TextEditingController();

  // Preferencias
  bool _alertasActivas  = true;
  bool _recordGasolina  = true;
  int  _diasSinGasolina = 15;

  // Intervalos
  final List<IntervaloServicio> _intervalos = [
    IntervaloServicio(tipo: "Cambio de aceite", icono: Icons.oil_barrel_rounded,
        color: _orange, mesesDefault: 6,  mesesAvisoDefault: 1),
    IntervaloServicio(tipo: "Bujías",           icono: Icons.electric_bolt_rounded,
        color: _purple, mesesDefault: 12, mesesAvisoDefault: 2),
    IntervaloServicio(tipo: "Filtro de aire",   icono: Icons.air_rounded,
        color: _blue,   mesesDefault: 12, mesesAvisoDefault: 2),
    IntervaloServicio(tipo: "Llantas",          icono: Icons.tire_repair_rounded,
        color: _textMain, mesesDefault: 24, mesesAvisoDefault: 3),
    IntervaloServicio(tipo: "Amortiguadores",   icono: Icons.settings_rounded,
        color: _green,  mesesDefault: 24, mesesAvisoDefault: 3),
    IntervaloServicio(tipo: "Balatas",          icono: Icons.disc_full_rounded,
        color: _red,    mesesDefault: 12, mesesAvisoDefault: 2),
  ];

  bool _cargando            = true;
  bool _cambiosSinGuardar   = false;

  // ─── LIFECYCLE ─────────────────────────────────────────────────────────────
  @override
  void initState() {
    super.initState();
    _cargarDatos();
  }

  @override
  void dispose() {
    _marcaCtrl.dispose();
    _modeloCtrl.dispose();
    _anioCtrl.dispose();
    _placasCtrl.dispose();
    _colorCtrl.dispose();
    _vinCtrl.dispose();
    super.dispose();
  }

  // ─── CARGAR DESDE SharedPreferences ───────────────────────────────────────
  Future<void> _cargarDatos() async {
    final prefs = await SharedPreferences.getInstance();

    // Vehículo
    _marcaCtrl.text  = prefs.getString(_kMarca)  ?? 'Nissan';
    _modeloCtrl.text = prefs.getString(_kModelo) ?? 'Sentra';
    _anioCtrl.text   = prefs.getString(_kAnio)   ?? '2006';
    _colorCtrl.text  = prefs.getString(_kColor)  ?? '';
    _placasCtrl.text = prefs.getString(_kPlacas) ?? '';
    _vinCtrl.text    = prefs.getString(_kVin)    ?? '';

    // Preferencias
    final alertas = prefs.getBool(_kAlertasActivas);
    final record  = prefs.getBool(_kRecordGasolina);
    final dias    = prefs.getInt(_kDiasSinGasolina);

    // Intervalos
    for (final iv in _intervalos) {
      iv.meses      = prefs.getInt(iv.keyMeses) ?? iv.mesesDefault;
      iv.mesesAviso = prefs.getInt(iv.keyAviso) ?? iv.mesesAvisoDefault;
    }

    setState(() {
      _alertasActivas  = alertas ?? true;
      _recordGasolina  = record  ?? true;
      _diasSinGasolina = dias    ?? 15;
      _cargando        = false;
    });
  }

  // ─── GUARDAR EN SharedPreferences ─────────────────────────────────────────
  Future<void> _guardar() async {
    final prefs = await SharedPreferences.getInstance();

    // Vehículo
    await prefs.setString(_kMarca,  _marcaCtrl.text.trim());
    await prefs.setString(_kModelo, _modeloCtrl.text.trim());
    await prefs.setString(_kAnio,   _anioCtrl.text.trim());
    await prefs.setString(_kColor,  _colorCtrl.text.trim());
    await prefs.setString(_kPlacas, _placasCtrl.text.trim());
    await prefs.setString(_kVin,    _vinCtrl.text.trim());

    // Preferencias
    await prefs.setBool(_kAlertasActivas,  _alertasActivas);
    await prefs.setBool(_kRecordGasolina,  _recordGasolina);
    await prefs.setInt(_kDiasSinGasolina,  _diasSinGasolina);

    // Intervalos
    for (final iv in _intervalos) {
      await prefs.setInt(iv.keyMeses, iv.meses);
      await prefs.setInt(iv.keyAviso, iv.mesesAviso);
    }

    if (!mounted) return;

    setState(() => _cambiosSinGuardar = false);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Row(children: [
          Icon(Icons.check_circle_rounded, color: Colors.white, size: 18),
          SizedBox(width: 10),
          Text("Configuración guardada",
              style: TextStyle(fontWeight: FontWeight.w700)),
        ]),
        backgroundColor: _green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _marcarCambio() {
    if (!_cambiosSinGuardar) setState(() => _cambiosSinGuardar = true);
  }

  // ─── BUILD ─────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    if (_cargando) {
      return const Scaffold(
        backgroundColor: _bg,
        body: Center(
          child: CircularProgressIndicator(color: _blue, strokeWidth: 2),
        ),
      );
    }

    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _card,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              size: 18, color: _textMain),
          onPressed: () {
            if (_cambiosSinGuardar) {
              _dialogoSinGuardar();
            } else {
              Navigator.pop(context);
            }
          },
        ),
        title: const Text(
          "Configuración",
          style: TextStyle(
            color: _textMain,
            fontWeight: FontWeight.w800,
            fontSize: 18,
            letterSpacing: -0.3,
          ),
        ),
        centerTitle: false,
        actions: [
          if (_cambiosSinGuardar)
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: TextButton(
                onPressed: _guardar,
                style: TextButton.styleFrom(
                  backgroundColor: _blue,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 8),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
                child: const Text(
                  "Guardar",
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
              ),
            ),
        ],
      ),

      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 24, 16, 40),
            sliver: SliverList(
              delegate: SliverChildListDelegate([

                // ── 1. DATOS DEL VEHÍCULO ──────────────────────────────
                _seccionHeader(
                  icono:     Icons.directions_car_rounded,
                  titulo:    "Datos del Vehículo",
                  color:     _blue,
                  softColor: _blueSoft,
                ),
                const SizedBox(height: 12),

                _cardSeccion(children: [
                  Row(children: [
                    Expanded(child: _campo(
                        label: "Marca", ctrl: _marcaCtrl, hint: "Nissan")),
                    const SizedBox(width: 12),
                    Expanded(child: _campo(
                        label: "Modelo", ctrl: _modeloCtrl, hint: "Sentra")),
                  ]),
                  const SizedBox(height: 14),
                  Row(children: [
                    Expanded(child: _campo(
                        label: "Año", ctrl: _anioCtrl, hint: "2006",
                        teclado: TextInputType.number,
                        formato: [FilteringTextInputFormatter.digitsOnly])),
                    const SizedBox(width: 12),
                    Expanded(child: _campo(
                        label: "Color", ctrl: _colorCtrl, hint: "Blanco")),
                  ]),
                  const SizedBox(height: 14),
                  Row(children: [
                    Expanded(child: _campo(
                        label: "Placas", ctrl: _placasCtrl,
                        hint: "ABC-123-D", mayusculas: true)),
                    const SizedBox(width: 12),
                    Expanded(child: _campo(
                        label: "NIV / VIN", ctrl: _vinCtrl,
                        hint: "Número de serie", mayusculas: true)),
                  ]),
                ]),

                const SizedBox(height: 24),

                // ── 2. INTERVALOS DE MANTENIMIENTO ─────────────────────
                _seccionHeader(
                  icono:     Icons.build_rounded,
                  titulo:    "Intervalos de Mantenimiento",
                  color:     _orange,
                  softColor: _orangeSoft,
                  subtitulo: "Personaliza cada cuánto te avisamos",
                ),
                const SizedBox(height: 12),

                ..._intervalos.map((iv) => _cardIntervalo(iv)),

                const SizedBox(height: 24),

                // ── 3. ALERTAS Y RECORDATORIOS ─────────────────────────
                _seccionHeader(
                  icono:     Icons.notifications_rounded,
                  titulo:    "Alertas y Recordatorios",
                  color:     _purple,
                  softColor: _purpleSoft,
                ),
                const SizedBox(height: 12),

                _cardSeccion(children: [
                  _filaSwitch(
                    titulo:    "Alertas activas",
                    subtitulo: "Mostrar alertas en la app",
                    valor:     _alertasActivas,
                    color:     _purple,
                    onChanged: (v) {
                      setState(() => _alertasActivas = v);
                      _marcarCambio();
                    },
                  ),
                  Container(
                    height: 1,
                    color: _divider,
                    margin: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  _filaSwitch(
                    titulo:    "Recordatorio de gasolina",
                    subtitulo: "Avisa si llevas días sin registrar",
                    valor:     _recordGasolina,
                    color:     _blue,
                    onChanged: (v) {
                      setState(() => _recordGasolina = v);
                      _marcarCambio();
                    },
                  ),
                  if (_recordGasolina) ...[
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text("Avisar después de",
                                style: TextStyle(
                                    color: _textMain,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600)),
                            Text("Días sin registrar carga",
                                style: TextStyle(
                                    color: _textSub, fontSize: 12)),
                          ],
                        ),
                        _selectorDias(),
                      ],
                    ),
                  ],
                ]),

                const SizedBox(height: 24),

                // ── 4. ACERCA DE ───────────────────────────────────────
                _seccionHeader(
                  icono:     Icons.info_rounded,
                  titulo:    "Acerca de",
                  color:     _textSub,
                  softColor: const Color(0x1A8A8FA8),
                ),
                const SizedBox(height: 12),

                _cardSeccion(children: [
                  const _FilaInfoSolo(
                    titulo:    "Versión",
                    subtitulo: "1.0.0",
                    icono:     Icons.tag_rounded,
                    color:     _textSub,
                  ),
                  Container(height: 1, color: _divider,
                      margin: const EdgeInsets.symmetric(vertical: 12)),
                  const _FilaInfoSolo(
                    titulo:    "Desarrollado con",
                    subtitulo: "Flutter + SQLite",
                    icono:     Icons.code_rounded,
                    color:     _blue,
                  ),
                  Container(height: 1, color: _divider,
                      margin: const EdgeInsets.symmetric(vertical: 12)),
                  const _FilaInfoSolo(
                    titulo:    "Base de datos",
                    subtitulo: "Local en el dispositivo",
                    icono:     Icons.storage_rounded,
                    color:     _green,
                  ),
                ]),

                const SizedBox(height: 24),

                // ── BOTÓN GUARDAR (fijo abajo) ─────────────────────────
                if (_cambiosSinGuardar)
                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: ElevatedButton.icon(
                      onPressed: _guardar,
                      icon: const Icon(Icons.save_rounded,
                          color: Colors.white, size: 20),
                      label: const Text(
                        "Guardar cambios",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _blue,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16)),
                      ),
                    ),
                  ),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  // ─── CARD DE INTERVALO ─────────────────────────────────────────────────────
  Widget _cardIntervalo(IntervaloServicio iv) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 8,
              offset: const Offset(0, 2)),
        ],
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header del tipo
          Row(children: [
            Container(
              width: 36, height: 36,
              decoration: BoxDecoration(
                color: iv.color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(iv.icono, color: iv.color, size: 18),
            ),
            const SizedBox(width: 10),
            Text(iv.tipo,
                style: const TextStyle(
                    color: _textMain,
                    fontSize: 14,
                    fontWeight: FontWeight.w700)),
          ]),
          const SizedBox(height: 14),

          // Intervalo principal
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Intervalo recomendado",
                      style: TextStyle(color: _textSub, fontSize: 12)),
                  Text("Cada cuántos meses",
                      style: TextStyle(
                          color: _textMain,
                          fontSize: 13,
                          fontWeight: FontWeight.w600)),
                ],
              ),
              _selectorMeses(
                valor: iv.meses,
                min:   1,
                max:   36,
                color: iv.color,
                onChanged: (v) {
                  setState(() {
                    iv.meses = v;
                    // Si el aviso es mayor que el intervalo, ajustarlo
                    if (iv.mesesAviso >= iv.meses) {
                      iv.mesesAviso = iv.meses - 1 < 1 ? 1 : iv.meses - 1;
                    }
                  });
                  _marcarCambio();
                },
              ),
            ],
          ),

          Container(
            height: 1,
            color: _divider,
            margin: const EdgeInsets.symmetric(vertical: 10),
          ),

          // Aviso previo
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Aviso previo",
                      style: TextStyle(color: _textSub, fontSize: 12)),
                  Text("Meses antes de vencer",
                      style: TextStyle(
                          color: _textMain,
                          fontSize: 13,
                          fontWeight: FontWeight.w600)),
                ],
              ),
              _selectorMeses(
                valor: iv.mesesAviso,
                min:   1,
                max:   iv.meses - 1 < 1 ? 1 : iv.meses - 1,
                color: iv.color,
                onChanged: (v) {
                  setState(() => iv.mesesAviso = v);
                  _marcarCambio();
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ─── SELECTOR +/- MESES ────────────────────────────────────────────────────
  Widget _selectorMeses({
    required int valor,
    required int min,
    required int max,
    required Color color,
    required ValueChanged<int> onChanged,
  }) {
    return Row(children: [
      _botonSelector(
        icono:   Icons.remove_rounded,
        color:   color,
        enabled: valor > min,
        onTap:   () => onChanged((valor - 1).clamp(min, max)),
      ),
      SizedBox(
        width: 52,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text("$valor",
                textAlign: TextAlign.center,
                style: TextStyle(
                    color: color,
                    fontSize: 18,
                    fontWeight: FontWeight.w900)),
            Text(valor == 1 ? "mes" : "meses",
                style: const TextStyle(color: _textSub, fontSize: 10)),
          ],
        ),
      ),
      _botonSelector(
        icono:   Icons.add_rounded,
        color:   color,
        enabled: valor < max,
        onTap:   () => onChanged((valor + 1).clamp(min, max)),
      ),
    ]);
  }

  Widget _botonSelector({
    required IconData icono,
    required Color color,
    required bool enabled,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: Container(
        width: 32, height: 32,
        decoration: BoxDecoration(
          color:  enabled ? color.withOpacity(0.12) : _divider,
          borderRadius: BorderRadius.circular(9),
        ),
        child: Icon(icono,
            size: 16,
            color: enabled ? color : _textSub.withOpacity(0.4)),
      ),
    );
  }

  // ─── SELECTOR DE DÍAS (chips) ──────────────────────────────────────────────
  Widget _selectorDias() {
    final opciones = [7, 10, 15, 20, 30];
    return SizedBox(
      height: 34,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        shrinkWrap: true,
        itemCount: opciones.length,
        separatorBuilder: (_, __) => const SizedBox(width: 6),
        itemBuilder: (_, i) {
          final dias     = opciones[i];
          final selected = dias == _diasSinGasolina;
          return GestureDetector(
            onTap: () {
              setState(() => _diasSinGasolina = dias);
              _marcarCambio();
            },
            child: Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: selected ? _blue : _divider,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                "${dias}d",
                style: TextStyle(
                  color: selected ? Colors.white : _textSub,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // ─── WIDGETS AUXILIARES ────────────────────────────────────────────────────
  Widget _seccionHeader({
    required IconData icono,
    required String titulo,
    required Color color,
    required Color softColor,
    String? subtitulo,
  }) {
    return Row(children: [
      Container(
        width: 34, height: 34,
        decoration: BoxDecoration(
            color: softColor, borderRadius: BorderRadius.circular(10)),
        child: Icon(icono, color: color, size: 17),
      ),
      const SizedBox(width: 10),
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(titulo,
            style: const TextStyle(
                color: _textMain,
                fontSize: 15,
                fontWeight: FontWeight.w800)),
        if (subtitulo != null)
          Text(subtitulo,
              style: const TextStyle(color: _textSub, fontSize: 12)),
      ]),
    ]);
  }

  Widget _cardSeccion({required List<Widget> children}) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: _card,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.03),
                blurRadius: 8,
                offset: const Offset(0, 2)),
          ],
        ),
        child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: children),
      );

  Widget _campo({
    required String label,
    required TextEditingController ctrl,
    required String hint,
    TextInputType teclado = TextInputType.text,
    List<TextInputFormatter> formato = const [],
    bool mayusculas = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(
                color: _textSub,
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.5)),
        const SizedBox(height: 6),
        TextFormField(
          controller: ctrl,
          keyboardType: teclado,
          inputFormatters: [
            ...formato,
            if (mayusculas)
              TextInputFormatter.withFunction((o, n) =>
                  n.copyWith(text: n.text.toUpperCase())),
          ],
          onChanged: (_) => _marcarCambio(),
          style: const TextStyle(
              color: _textMain,
              fontSize: 14,
              fontWeight: FontWeight.w600),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(
                color: _textSub.withOpacity(0.5), fontSize: 14),
            filled: true,
            fillColor: _bg,
            contentPadding: const EdgeInsets.symmetric(
                horizontal: 14, vertical: 12),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: _divider),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: _divider),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: _blue, width: 1.5),
            ),
          ),
        ),
      ],
    );
  }

  Widget _filaSwitch({
    required String titulo,
    required String subtitulo,
    required bool valor,
    required Color color,
    required ValueChanged<bool> onChanged,
  }) {
    return Row(children: [
      Expanded(
        child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(titulo,
                  style: const TextStyle(
                      color: _textMain,
                      fontSize: 14,
                      fontWeight: FontWeight.w600)),
              Text(subtitulo,
                  style: const TextStyle(
                      color: _textSub, fontSize: 12)),
            ]),
      ),
      Switch.adaptive(
          value: valor, onChanged: onChanged, activeColor: color),
    ]);
  }

  // ─── DIÁLOGO SALIR SIN GUARDAR ─────────────────────────────────────────────
  void _dialogoSinGuardar() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20)),
        title: const Text("¿Salir sin guardar?",
            style: TextStyle(fontWeight: FontWeight.w800)),
        content: const Text(
          "Tienes cambios sin guardar. ¿Qué deseas hacer?",
          style: TextStyle(color: _textSub),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancelar",
                style: TextStyle(color: _textSub)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
            },
            child: const Text("Descartar",
                style: TextStyle(
                    color: _red, fontWeight: FontWeight.w700)),
          ),
          TextButton(
            onPressed: () async {
              await _guardar();
              if (mounted) {
                Navigator.pop(context);
                Navigator.pop(context);
              }
            },
            child: const Text("Guardar",
                style: TextStyle(
                    color: _blue, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }
}

// ─── WIDGET AUXILIAR ──────────────────────────────────────────────────────────
class _FilaInfoSolo extends StatelessWidget {
  final String titulo;
  final String subtitulo;
  final IconData icono;
  final Color color;

  const _FilaInfoSolo({
    required this.titulo,
    required this.subtitulo,
    required this.icono,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Container(
        width: 34, height: 34,
        decoration: BoxDecoration(
          color: color.withOpacity(0.10),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icono, color: color, size: 16),
      ),
      const SizedBox(width: 12),
      Expanded(
        child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(titulo,
                  style: const TextStyle(
                      color: _textMain,
                      fontSize: 14,
                      fontWeight: FontWeight.w600)),
              Text(subtitulo,
                  style: const TextStyle(
                      color: _textSub, fontSize: 12)),
            ]),
      ),
    ]);
  }
}