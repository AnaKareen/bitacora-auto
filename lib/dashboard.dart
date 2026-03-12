import 'database_helper.dart';
import 'package:flutter/material.dart';
import 'gasolina_page.dart';
import 'historial_gasolina.dart';
import 'servicios_page.dart';
import 'seguro_page.dart';
import 'alertas_page.dart';
import 'alertas_service.dart';
import 'animated_card.dart';
import 'configuracion_page.dart';

// ─── PALETA ──────────────────────────────────────────────────────────────────
const _white      = Color(0xFFFFFFFF);
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

// ─────────────────────────────────────────────────────────────────────────────

class Dashboard extends StatefulWidget {
  const Dashboard({super.key});

  @override
  State<Dashboard> createState() => _DashboardState();
}

class _DashboardState extends State<Dashboard>
    with SingleTickerProviderStateMixin {
  late AnimationController _ac;

  @override
  void initState() {
    super.initState();
    _ac = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..forward();
    DatabaseHelper.instance.database;
  }

  @override
  void dispose() {
    _ac.dispose();
    super.dispose();
  }

  Animation<double> _anim(int i) => CurvedAnimation(
        parent: _ac,
        curve: Interval(
          i * 0.1,
          (i * 0.1) + 0.6,
          curve: Curves.easeOutCubic,
        ),
      );

  // ─── BUILD ────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [

          // ── APP BAR CON IMAGEN ─────────────────────────────────────────────
          SliverAppBar(
            expandedHeight: 230,
            pinned: true,
            stretch: true,
            backgroundColor: _white,
            elevation: 0,
            surfaceTintColor: Colors.transparent,
            title: const Text(
              "Mi Auto",
              style: TextStyle(
                color: _textMain,
                fontWeight: FontWeight.w800,
                fontSize: 18,
                letterSpacing: -0.3,
              ),
            ),
            centerTitle: false,

            // ── BOTÓN DE ALERTAS (campana con badge) ───────────────────────
            actions: [
              FutureBuilder<List<Alerta>>(
                future: AlertasService.instance.obtenerAlertas(),
                builder: (ctx, snap) {
                  final alertas  = snap.data ?? [];
                  final criticas = alertas
                      .where((a) => a.nivel == AlertaNivel.critica)
                      .length;
                  final total = alertas.length;

                  return Padding(
                    padding: const EdgeInsets.only(right: 12),
                    child: GestureDetector(
                      onTap: () => Navigator.push(
                        context,
                        _slide(const AlertasPage()),
                      ).then((_) => setState(() {})),
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            margin: const EdgeInsets.only(top: 8),
                            decoration: BoxDecoration(
                              color: total > 0
                                  ? (criticas > 0 ? _redSoft : _orangeSoft)
                                  : _bg,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              Icons.notifications_rounded,
                              color: total > 0
                                  ? (criticas > 0 ? _red : _orange)
                                  : _textSub,
                              size: 20,
                            ),
                          ),
                          if (total > 0)
                            Positioned(
                              top: 4,
                              right: -2,
                              child: Container(
                                width: 18,
                                height: 18,
                                decoration: BoxDecoration(
                                  color: criticas > 0 ? _red : _orange,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                      color: _white, width: 1.5),
                                ),
                                child: Center(
                                  child: Text(
                                    total > 9 ? "9+" : "$total",
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 9,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ],

            flexibleSpace: FlexibleSpaceBar(
              stretchModes: const [StretchMode.zoomBackground],
              background: Stack(
                fit: StackFit.expand,
                children: [
                  // Imagen del carro
                  Image.asset('assets/sentra.png', fit: BoxFit.cover),

                  // Gradiente blanco hacia abajo
                  Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Color(0xCCFFFFFF),
                          _white,
                        ],
                        stops: [0.4, 0.78, 1.0],
                      ),
                    ),
                  ),

                  // Nombre del auto
                  const Positioned(
                    left: 20,
                    bottom: 16,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          "NISSAN  ·  2006",
                          style: TextStyle(
                            color: _textSub,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 2,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          "Sentra",
                          style: TextStyle(
                            color: _textMain,
                            fontSize: 30,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -1,
                            height: 1,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Badge "Activo"
                  Positioned(
                    right: 20,
                    bottom: 22,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: _blue,
                        borderRadius: BorderRadius.circular(30),
                        boxShadow: [
                          BoxShadow(
                            color: _blue.withOpacity(0.35),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.circle, color: Colors.white, size: 7),
                          SizedBox(width: 6),
                          Text(
                            "Activo",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── CONTENIDO PRINCIPAL ────────────────────────────────────────────
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 40),
            sliver: SliverList(
              delegate: SliverChildListDelegate([

                // ── 1. RESUMEN DE ALERTAS ────────────────────────────────────
                FadeTransition(
                  opacity: _anim(0),
                  child: SlideTransition(
                    position: Tween<Offset>(
                      begin: const Offset(0, 0.15),
                      end: Offset.zero,
                    ).animate(_anim(0)),
                    child: FutureBuilder<List<Alerta>>(
                      future: AlertasService.instance.obtenerAlertas(),
                      builder: (ctx, snap) {
                        if (!snap.hasData) return const SizedBox.shrink();
                        final alertas = snap.data!;
                        return alertas.isEmpty
                            ? _cardTodoOk()
                            : _cardAlertasResumen(alertas);
                      },
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // ── 2. GRÁFICA DE RENDIMIENTO ────────────────────────────────
                FadeTransition(
                  opacity: _anim(1),
                  child: SlideTransition(
                    position: Tween<Offset>(
                      begin: const Offset(0, 0.15),
                      end: Offset.zero,
                    ).animate(_anim(1)),
                    child: FutureBuilder<List<Map<String, dynamic>>>(
                      future: _obtenerConsumos(),
                      builder: (context, snap) {
                        if (snap.connectionState == ConnectionState.waiting) {
                          return _cardSkeleton(height: 210);
                        }
                        if (!snap.hasData || snap.data!.length < 2) {
                          return _cardSinDatos();
                        }
                        return _cardRendimiento(snap.data!);
                      },
                    ),
                  ),
                ),

                const SizedBox(height: 20),
                _sectionLabel("ACCIONES RÁPIDAS"),
                const SizedBox(height: 10),

                // ── 3. GASOLINA ───────────────────────────────────────────────
                FadeTransition(
                  opacity: _anim(2),
                  child: SlideTransition(
                    position: Tween<Offset>(
                      begin: const Offset(0, 0.15),
                      end: Offset.zero,
                    ).animate(_anim(2)),
                    child: _cardAccion(
                      title: "Gasolina",
                      subtitle: "Tap para registrar  ·  Mantén para historial",
                      icon: Icons.local_gas_station_rounded,
                      color: _blue,
                      softColor: _blueSoft,
                      onTap: () => Navigator.push(
                          context, _slide(const GasolinaPage())),
                      onLongPress: () => Navigator.push(
                          context, _slide(const HistorialGasolina())),
                    ),
                  ),
                ),
                const SizedBox(height: 10),

                // ── 4. SERVICIOS ──────────────────────────────────────────────
                FadeTransition(
                  opacity: _anim(3),
                  child: SlideTransition(
                    position: Tween<Offset>(
                      begin: const Offset(0, 0.15),
                      end: Offset.zero,
                    ).animate(_anim(3)),
                    child: _cardAccion(
                      title: "Servicios",
                      subtitle: "Aceite  ·  Bujías  ·  Filtros  ·  Revisiones",
                      icon: Icons.settings_rounded,
                      color: _orange,
                      softColor: _orangeSoft,
                      onTap: () => Navigator.push(
                          context, _slide(const ServiciosPage())),
                    ),
                  ),
                ),
                const SizedBox(height: 10),

                // ── 5. SEGURO ─────────────────────────────────────────────────
                FutureBuilder<Map<String, dynamic>?>(
                  future: DatabaseHelper.instance.obtenerSeguro(),
                  builder: (context, snap) {
                    String subtitle = "Sin registrar";
                    bool vencido    = false;
                    bool proxVencer = false;

                    if (snap.hasData && snap.data != null) {
                      final s    = snap.data!;
                      final fin  = DateTime.parse(s['fin'] as String);
                      final diff = fin.difference(DateTime.now()).inDays;
                      vencido    = diff < 0;
                      proxVencer = diff >= 0 && diff <= 15;
                      subtitle   =
                          "${s['aseguradora']}  ·  Vence ${fin.day}/${fin.month}/${fin.year}";
                    }

                    final color     = vencido
                        ? _red
                        : (proxVencer ? _orange : _green);
                    final softColor = vencido
                        ? _redSoft
                        : (proxVencer ? _orangeSoft : _greenSoft);

                    return FadeTransition(
                      opacity: _anim(4),
                      child: SlideTransition(
                        position: Tween<Offset>(
                          begin: const Offset(0, 0.15),
                          end: Offset.zero,
                        ).animate(_anim(4)),
                        child: _cardAccion(
                          title: "Seguro",
                          subtitle: subtitle,
                          icon: Icons.verified_user_rounded,
                          color: color,
                          softColor: softColor,
                          badge: vencido
                              ? "VENCIDO"
                              : (proxVencer ? "POR VENCER" : null),
                          badgeColor: vencido ? _red : _orange,
                          onTap: () => Navigator.push(
                            context,
                            _slide(const SeguroPage()),
                          ).then((_) => setState(() {})),
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 10),

                // ── 6. ALERTAS ────────────────────────────────────────────────
                FadeTransition(
                  opacity: _anim(5),
                  child: SlideTransition(
                    position: Tween<Offset>(
                      begin: const Offset(0, 0.15),
                      end: Offset.zero,
                    ).animate(_anim(5)),
                    child: _cardAccion(
                      title: "Alertas",
                      subtitle: "Servicios, seguro y gasolina",
                      icon: Icons.notifications_rounded,
                      color: _purple,
                      softColor: _purpleSoft,
                      onTap: () => Navigator.push(
                        context,
                        _slide(const AlertasPage()),
                      ).then((_) => setState(() {})),
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

  // ─── CARD: RESUMEN DE ALERTAS ─────────────────────────────────────────────
  Widget _cardAlertasResumen(List<Alerta> alertas) {
    final criticas     = alertas.where((a) => a.nivel == AlertaNivel.critica).toList();
    final hayCritica   = criticas.isNotEmpty;
    final color        = hayCritica ? _red : _orange;
    final softColor    = hayCritica ? _redSoft : _orangeSoft;
    final preview      = alertas.take(2).toList();

    return GestureDetector(
      onTap: () => Navigator.push(context, _slide(const AlertasPage()))
          .then((_) => setState(() {})),
      child: Container(
        margin: const EdgeInsets.only(bottom: 0),
        decoration: BoxDecoration(
          color: _card,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withOpacity(0.25), width: 1.2),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.08),
              blurRadius: 12,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: softColor,
                    borderRadius: BorderRadius.circular(11),
                  ),
                  child: Icon(Icons.notifications_rounded,
                      color: color, size: 18),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        hayCritica
                            ? "${criticas.length} alerta${criticas.length > 1 ? 's' : ''} crítica${criticas.length > 1 ? 's' : ''}"
                            : "${alertas.length} aviso${alertas.length > 1 ? 's' : ''}",
                        style: TextStyle(
                          color: color,
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      Text(
                        "${alertas.length} alerta${alertas.length != 1 ? 's' : ''} en total",
                        style: const TextStyle(color: _textSub, fontSize: 12),
                      ),
                    ],
                  ),
                ),
                Row(
                  children: [
                    const Text("Ver todas",
                        style: TextStyle(color: _textSub, fontSize: 12)),
                    Icon(Icons.chevron_right_rounded,
                        color: _textSub.withOpacity(0.5), size: 18),
                  ],
                ),
              ],
            ),

            // Preview de las 2 primeras alertas
            if (preview.isNotEmpty) ...[
              const SizedBox(height: 10),
              Container(height: 1, color: _divider),
              const SizedBox(height: 8),
              ...preview.map((a) {
                final dotColor = switch (a.nivel) {
                  AlertaNivel.critica     => _red,
                  AlertaNivel.advertencia => _orange,
                  AlertaNivel.info        => _blue,
                };
                return Padding(
                  padding: const EdgeInsets.only(bottom: 5),
                  child: Row(
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: dotColor,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          a.titulo,
                          style: const TextStyle(
                            color: _textMain,
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ],
          ],
        ),
      ),
    );
  }

  // ─── CARD: TODO OK ────────────────────────────────────────────────────────
  Widget _cardTodoOk() => Container(
        decoration: BoxDecoration(
          color: _greenSoft,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: _green.withOpacity(0.25)),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: _green.withOpacity(0.2),
                borderRadius: BorderRadius.circular(11),
              ),
              child: const Icon(Icons.check_circle_rounded,
                  color: _green, size: 20),
            ),
            const SizedBox(width: 12),
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Todo en orden",
                  style: TextStyle(
                      color: _green,
                      fontSize: 14,
                      fontWeight: FontWeight.w800),
                ),
                Text(
                  "Sin alertas pendientes",
                  style: TextStyle(color: _green, fontSize: 12),
                ),
              ],
            ),
          ],
        ),
      );

  // ─── CARD: RENDIMIENTO KM/L ───────────────────────────────────────────────
  Widget _cardRendimiento(List<Map<String, dynamic>> registros) {
    final List<_Punto> puntos = [];

    for (int i = 1; i < registros.length; i++) {
      final prev   = registros[i - 1];
      final curr   = registros[i];
      final kmPrev = (prev['kilometraje'] as num?)?.toDouble();
      final kmCurr = (curr['kilometraje'] as num?)?.toDouble();
      final litros = (curr['litros']      as num?)?.toDouble();

      if (kmPrev == null || kmCurr == null || litros == null) continue;
      if (litros <= 0 || kmCurr <= kmPrev) continue;

      puntos.add(_Punto(
        rendimiento: (kmCurr - kmPrev) / litros,
        label: _fechaCorta(curr['fecha']?.toString() ?? ''),
      ));
    }

    if (puntos.isEmpty) return _cardSinDatos();

    final ultimos     = puntos.length > 6
        ? puntos.sublist(puntos.length - 6)
        : puntos;
    final ultimo      = ultimos.last.rendimiento;
    final promedio    = ultimos
        .map((p) => p.rendimiento)
        .reduce((a, b) => a + b) / ultimos.length;
    final maxV        = ultimos
        .map((p) => p.rendimiento)
        .reduce((a, b) => a > b ? a : b);
    final minV        = ultimos
        .map((p) => p.rendimiento)
        .reduce((a, b) => a < b ? a : b);
    final esEficiente = ultimo >= promedio;

    return Container(
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Número grande + badge eficiencia
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Rendimiento",
                    style: TextStyle(
                      color: _textSub,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        ultimo.toStringAsFixed(1),
                        style: const TextStyle(
                          color: _textMain,
                          fontSize: 38,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -1.5,
                          height: 1,
                        ),
                      ),
                      const Padding(
                        padding: EdgeInsets.only(bottom: 6, left: 5),
                        child: Text(
                          "km/L",
                          style: TextStyle(
                            color: _textSub,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: esEficiente ? _greenSoft : _orangeSoft,
                  borderRadius: BorderRadius.circular(30),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      esEficiente
                          ? Icons.trending_up_rounded
                          : Icons.trending_down_rounded,
                      color: esEficiente ? _green : _orange,
                      size: 16,
                    ),
                    const SizedBox(width: 5),
                    Text(
                      esEficiente ? "Eficiente" : "Bajo prom.",
                      style: TextStyle(
                        color: esEficiente ? _green : _orange,
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 6),

          // Mini stats: prom / min / max
          Row(
            children: [
              _miniStat("Prom.",
                  "${promedio.toStringAsFixed(1)} km/L", _textSub),
              const SizedBox(width: 16),
              _miniStat("Mín", "${minV.toStringAsFixed(1)}", _red),
              const SizedBox(width: 16),
              _miniStat("Máx", "${maxV.toStringAsFixed(1)}", _green),
            ],
          ),

          const SizedBox(height: 18),

          // Gráfica de línea animada
          SizedBox(
            height: 110,
            child: _GraficaLinea(
              puntos: ultimos,
              accentColor: _blue,
              promedio: promedio,
            ),
          ),
        ],
      ),
    );
  }

  Widget _miniStat(String label, String valor, Color color) => Row(
        children: [
          Text("$label  ",
              style: const TextStyle(color: _textSub, fontSize: 12)),
          Text(valor,
              style: TextStyle(
                  color: color,
                  fontSize: 12,
                  fontWeight: FontWeight.w700)),
        ],
      );

  // ─── HELPERS ──────────────────────────────────────────────────────────────
  Future<List<Map<String, dynamic>>> _obtenerConsumos() async {
    final db = await DatabaseHelper.instance.database;
    return await db.query('gasolina', orderBy: 'id ASC');
  }

  String _fechaCorta(String raw) {
    try {
      final d = DateTime.parse(raw);
      return "${d.day}/${d.month}";
    } catch (_) {
      return raw.length >= 5 ? raw.substring(raw.length - 5) : raw;
    }
  }

  Widget _cardSkeleton({double height = 160}) => Container(
        height: height,
        decoration: BoxDecoration(
          color: _card,
          borderRadius: BorderRadius.circular(24),
        ),
        child: const Center(
          child: SizedBox(
            width: 22,
            height: 22,
            child: CircularProgressIndicator(
                strokeWidth: 2.5, color: _blue),
          ),
        ),
      );

  Widget _cardSinDatos() => Container(
        height: 160,
        decoration: BoxDecoration(
          color: _card,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: _divider),
        ),
        child: const Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.insert_chart_outlined_rounded,
                  color: _textSub, size: 36),
              SizedBox(height: 10),
              Text(
                "Registra al menos 2 cargas\npara ver el rendimiento",
                textAlign: TextAlign.center,
                style: TextStyle(
                    color: _textSub, fontSize: 13, height: 1.5),
              ),
            ],
          ),
        ),
      );

  Widget _sectionLabel(String t) => Text(
        t,
        style: const TextStyle(
          color: _textSub,
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 2,
        ),
      );

  Widget _cardAccion({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required Color softColor,
    String? badge,
    Color? badgeColor,
    VoidCallback? onTap,
    VoidCallback? onLongPress,
  }) {
    return GestureDetector(
      onTap: onTap,
      onLongPress: onLongPress,
      child: Container(
        decoration: BoxDecoration(
          color: _card,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 12,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            // Ícono con fondo suave
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: softColor,
                borderRadius: BorderRadius.circular(15),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 14),

            // Texto
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          color: _textMain,
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      if (badge != null) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: (badgeColor ?? _red).withOpacity(0.12),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            badge,
                            style: TextStyle(
                              color: badgeColor ?? _red,
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.3,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(
                        color: _textSub, fontSize: 12.5),
                  ),
                ],
              ),
            ),

            // Chevron
            Icon(
              Icons.chevron_right_rounded,
              color: _textSub.withOpacity(0.5),
              size: 22,
            ),
          ],
        ),
      ),
    );
  }

  PageRoute _slide(Widget page) => PageRouteBuilder(
        pageBuilder: (_, a, __) => page,
        transitionsBuilder: (_, anim, __, child) => SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(1, 0),
            end: Offset.zero,
          ).animate(
              CurvedAnimation(parent: anim, curve: Curves.easeOutCubic)),
          child: child,
        ),
        transitionDuration: const Duration(milliseconds: 320),
      );
}

// ─── MODELO PUNTO ─────────────────────────────────────────────────────────────
class _Punto {
  final double rendimiento;
  final String label;
  const _Punto({required this.rendimiento, required this.label});
}

// ─── WIDGET GRÁFICA ───────────────────────────────────────────────────────────
class _GraficaLinea extends StatefulWidget {
  final List<_Punto> puntos;
  final Color accentColor;
  final double promedio;

  const _GraficaLinea({
    required this.puntos,
    required this.accentColor,
    required this.promedio,
  });

  @override
  State<_GraficaLinea> createState() => _GraficaLineaState();
}

class _GraficaLineaState extends State<_GraficaLinea>
    with SingleTickerProviderStateMixin {
  late AnimationController _ac;
  late Animation<double> _prog;

  @override
  void initState() {
    super.initState();
    _ac = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..forward();
    _prog = CurvedAnimation(parent: _ac, curve: Curves.easeOutCubic);
  }

  @override
  void dispose() {
    _ac.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
        animation: _prog,
        builder: (_, __) => CustomPaint(
          painter: _LineaPainter(
            puntos: widget.puntos,
            progress: _prog.value,
            accentColor: widget.accentColor,
            promedio: widget.promedio,
          ),
          child: Container(),
        ),
      );
}

// ─── PAINTER ──────────────────────────────────────────────────────────────────
class _LineaPainter extends CustomPainter {
  final List<_Punto> puntos;
  final double progress;
  final double promedio;
  final Color accentColor;

  static const Color _textSub = Color(0xFF8A8FA8);
  static const Color _green   = Color(0xFF00C48C);
  static const Color _orange  = Color(0xFFFF7A2F);
  static const Color _white   = Color(0xFFFFFFFF);

  _LineaPainter({
    required this.puntos,
    required this.progress,
    required this.accentColor,
    required this.promedio,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (puntos.length < 2) return;

    final valores = puntos.map((p) => p.rendimiento).toList();
    final maxV    = valores.reduce((a, b) => a > b ? a : b);
    final minV    = valores.reduce((a, b) => a < b ? a : b);
    final padding = (maxV - minV) * 0.25 + 0.5;
    final vMin    = minV - padding;
    final vMax    = maxV + padding;
    final rango   = (vMax - vMin).clamp(0.01, double.infinity);

    final chartH = size.height - 18.0;
    final n      = puntos.length;
    final stepX  = size.width / (n - 1);

    Offset toOffset(int i) => Offset(
          i * stepX,
          chartH - ((valores[i] - vMin) / rango) * chartH,
        );

    final pts = List.generate(n, toOffset);

    // Línea punteada del promedio
    final yProm    = chartH - ((promedio - vMin) / rango) * chartH;
    final dashPaint = Paint()
      ..color      = const Color(0xFFCCCFDA)
      ..strokeWidth = 1.2;
    double dashX = 0;
    while (dashX < size.width) {
      canvas.drawLine(
        Offset(dashX, yProm),
        Offset((dashX + 5).clamp(0, size.width), yProm),
        dashPaint,
      );
      dashX += 9;
    }

    // Puntos visibles según progreso de animación
    final showUpTo = ((n - 1) * progress).clamp(0.0, (n - 1).toDouble());
    final fullPts  = showUpTo.floor();
    final frac     = showUpTo - fullPts;

    // Construir path de la línea
    final path = Path()..moveTo(pts[0].dx, pts[0].dy);
    for (int i = 1; i <= fullPts; i++) {
      final cp = (pts[i - 1].dx + pts[i].dx) / 2;
      path.cubicTo(
          cp, pts[i - 1].dy, cp, pts[i].dy, pts[i].dx, pts[i].dy);
    }
    if (fullPts < n - 1 && frac > 0) {
      final pX = pts[fullPts].dx +
          (pts[fullPts + 1].dx - pts[fullPts].dx) * frac;
      final pY = pts[fullPts].dy +
          (pts[fullPts + 1].dy - pts[fullPts].dy) * frac;
      final cp = (pts[fullPts].dx + pX) / 2;
      path.cubicTo(cp, pts[fullPts].dy, cp, pY, pX, pY);
    }

    // Área de relleno bajo la línea
    final lastX = fullPts < n - 1
        ? pts[fullPts].dx +
            (pts[fullPts + 1].dx - pts[fullPts].dx) * frac
        : pts[fullPts].dx;
    final fillPath = Path.from(path)
      ..lineTo(lastX, chartH)
      ..lineTo(pts[0].dx, chartH)
      ..close();

    canvas.drawPath(
      fillPath,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            accentColor.withOpacity(0.15),
            accentColor.withOpacity(0.0),
          ],
        ).createShader(Rect.fromLTWH(0, 0, size.width, chartH)),
    );

    // Línea principal
    canvas.drawPath(
      path,
      Paint()
        ..color       = accentColor
        ..strokeWidth = 2.5
        ..style       = PaintingStyle.stroke
        ..strokeCap   = StrokeCap.round
        ..strokeJoin  = StrokeJoin.round,
    );

    // Puntos y etiquetas
    for (int i = 0; i <= fullPts; i++) {
      final p          = pts[i];
      final esUltimo   = i == n - 1;
      final porEncima  = valores[i] >= promedio;
      final dotColor   = porEncima ? _green : _orange;

      if (esUltimo) {
        canvas.drawCircle(
            p, 9, Paint()..color = accentColor.withOpacity(0.12));
      }
      canvas.drawCircle(
          p, esUltimo ? 5.5 : 3.5, Paint()..color = _white);
      canvas.drawCircle(
          p, esUltimo ? 4.0 : 2.5, Paint()..color = dotColor);

      _drawText(
        canvas,
        text:   puntos[i].label,
        x:      p.dx,
        y:      size.height - 14,
        color:  esUltimo ? accentColor : _textSub,
        fontSize: 9.5,
        bold:   esUltimo,
      );

      if (esUltimo) {
        _drawText(
          canvas,
          text:     "${valores[i].toStringAsFixed(1)} km/L",
          x:        p.dx,
          y:        p.dy - 20,
          color:    accentColor,
          fontSize: 11,
          bold:     true,
          withBg:   true,
        );
      }
    }
  }

  void _drawText(
    Canvas canvas, {
    required String text,
    required double x,
    required double y,
    required Color color,
    double fontSize = 10,
    bool bold   = false,
    bool withBg = false,
  }) {
    final tp = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          color:      color,
          fontSize:   fontSize,
          fontWeight: bold ? FontWeight.w700 : FontWeight.w500,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    final dx = x - tp.width / 2;
    final dy = y - tp.height / 2;

    if (withBg) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(
              dx - 6, dy - 3, tp.width + 12, tp.height + 6),
          const Radius.circular(8),
        ),
        Paint()..color = color.withOpacity(0.10),
      );
    }

    tp.paint(canvas, Offset(dx, dy));
  }

  @override
  bool shouldRepaint(_LineaPainter old) =>
      old.progress != progress || old.promedio != promedio;
}