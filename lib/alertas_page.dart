import 'package:flutter/material.dart';
import 'alertas_service.dart';

// ─── PALETA ──────────────────────────────────────────────────────────────────
const _bg       = Color(0xFFF5F6FA);
const _card     = Color(0xFFFFFFFF);
const _textMain = Color(0xFF0F1117);
const _textSub  = Color(0xFF8A8FA8);

const _blue     = Color(0xFF3B7BFF);
const _blueSoft = Color(0x1A3B7BFF);
const _green    = Color(0xFF00C48C);
const _orange   = Color(0xFFFF7A2F);
const _red      = Color(0xFFFF3B55);

class AlertasPage extends StatefulWidget {
  const AlertasPage({super.key});

  @override
  State<AlertasPage> createState() => _AlertasPageState();
}

class _AlertasPageState extends State<AlertasPage> {
  late Future<List<Alerta>> _futureAlertas;

  @override
  void initState() {
    super.initState();
    _futureAlertas = AlertasService.instance.obtenerAlertas();
  }

  void _recargar() {
    setState(() {
      _futureAlertas = AlertasService.instance.obtenerAlertas();
    });
  }

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
        title: const Text("Alertas",
            style: TextStyle(
              color: _textMain, fontWeight: FontWeight.w800,
              fontSize: 18, letterSpacing: -0.3,
            )),
        centerTitle: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: _textSub),
            onPressed: _recargar,
            tooltip: "Actualizar",
          ),
        ],
      ),

      body: FutureBuilder<List<Alerta>>(
        future: _futureAlertas,
        builder: (context, snap) {
          if (!snap.hasData) {
            return const Center(
              child: CircularProgressIndicator(color: _blue, strokeWidth: 2),
            );
          }

          final alertas = snap.data!;

          if (alertas.isEmpty) return _sinAlertas();

          // Agrupar por nivel
          final criticas     = alertas.where((a) => a.nivel == AlertaNivel.critica).toList();
          final advertencias = alertas.where((a) => a.nivel == AlertaNivel.advertencia).toList();
          final info         = alertas.where((a) => a.nivel == AlertaNivel.info).toList();

          return CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              // ── RESUMEN ────────────────────────────────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Chips de resumen
                      Row(children: [
                        if (criticas.isNotEmpty)
                          _chipResumen(
                              "${criticas.length} crítica${criticas.length > 1 ? 's' : ''}",
                              _red),
                        if (criticas.isNotEmpty && advertencias.isNotEmpty)
                          const SizedBox(width: 8),
                        if (advertencias.isNotEmpty)
                          _chipResumen(
                              "${advertencias.length} aviso${advertencias.length > 1 ? 's' : ''}",
                              _orange),
                        if ((criticas.isNotEmpty || advertencias.isNotEmpty) && info.isNotEmpty)
                          const SizedBox(width: 8),
                        if (info.isNotEmpty)
                          _chipResumen(
                              "${info.length} info",
                              _blue),
                      ]),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),

              // ── CRÍTICAS ──────────────────────────────────────────
              if (criticas.isNotEmpty) ...[
                _sliverLabel("🚨  CRÍTICAS"),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (_, i) => _cardAlerta(criticas[i]),
                      childCount: criticas.length,
                    ),
                  ),
                ),
              ],

              // ── ADVERTENCIAS ──────────────────────────────────────
              if (advertencias.isNotEmpty) ...[
                _sliverLabel("⚠️  AVISOS"),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (_, i) => _cardAlerta(advertencias[i]),
                      childCount: advertencias.length,
                    ),
                  ),
                ),
              ],

              // ── INFO ──────────────────────────────────────────────
              if (info.isNotEmpty) ...[
                _sliverLabel("ℹ️  INFORMACIÓN"),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 40),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (_, i) => _cardAlerta(info[i]),
                      childCount: info.length,
                    ),
                  ),
                ),
              ],
            ],
          );
        },
      ),
    );
  }

  // ─── WIDGETS ──────────────────────────────────────────────────────────────

  Widget _cardAlerta(Alerta alerta) {
    final cfg = _config(alerta);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: cfg.color.withOpacity(0.2), width: 1.2),
        boxShadow: [
          BoxShadow(
              color: cfg.color.withOpacity(0.06),
              blurRadius: 12, offset: const Offset(0, 3)),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Ícono
          Container(
            width: 44, height: 44,
            decoration: BoxDecoration(
              color: cfg.color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(13),
            ),
            child: Icon(cfg.icono, color: cfg.color, size: 22),
          ),
          const SizedBox(width: 12),

          // Contenido
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Título + badge categoría
                Row(
                  children: [
                    Expanded(
                      child: Text(alerta.titulo,
                          style: const TextStyle(
                            color: _textMain, fontSize: 14,
                            fontWeight: FontWeight.w800,
                          )),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: cfg.color.withOpacity(0.10),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        _labelCategoria(alerta.categoria),
                        style: TextStyle(
                          color: cfg.color, fontSize: 10,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 5),

                // Descripción
                Text(alerta.descripcion,
                    style: const TextStyle(
                        color: _textSub, fontSize: 12.5, height: 1.5)),

                // Fecha de referencia
                if (alerta.fecha != null) ...[
                  const SizedBox(height: 8),
                  Row(children: [
                    Icon(Icons.calendar_today_rounded,
                        size: 11, color: cfg.color),
                    const SizedBox(width: 4),
                    Text(
                      _fmt(alerta.fecha!),
                      style: TextStyle(
                          color: cfg.color, fontSize: 11,
                          fontWeight: FontWeight.w700),
                    ),
                  ]),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _chipResumen(String label, Color color) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: color.withOpacity(0.10),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withOpacity(0.25)),
        ),
        child: Text(label,
            style: TextStyle(
                color: color, fontSize: 12, fontWeight: FontWeight.w700)),
      );

  SliverToBoxAdapter _sliverLabel(String t) => SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
          child: Text(t,
              style: const TextStyle(
                  color: _textSub, fontSize: 11,
                  fontWeight: FontWeight.w700, letterSpacing: 1.5)),
        ),
      );

  Widget _sinAlertas() => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80, height: 80,
              decoration: BoxDecoration(
                color: const Color(0x1A00C48C),
                borderRadius: BorderRadius.circular(24),
              ),
              child: const Icon(Icons.check_circle_rounded,
                  color: _green, size: 42),
            ),
            const SizedBox(height: 18),
            const Text("Todo en orden 🎉",
                style: TextStyle(color: _textMain, fontSize: 20,
                    fontWeight: FontWeight.w900)),
            const SizedBox(height: 8),
            const Text(
              "Tu Sentra no tiene alertas\npendientes por ahora.",
              textAlign: TextAlign.center,
              style: TextStyle(color: _textSub, fontSize: 14, height: 1.5),
            ),
          ],
        ),
      );

  // ─── HELPERS ──────────────────────────────────────────────────────────────
  ({Color color, IconData icono}) _config(Alerta a) {
    // Color por nivel
    final color = switch (a.nivel) {
      AlertaNivel.critica     => _red,
      AlertaNivel.advertencia => _orange,
      AlertaNivel.info        => _blue,
    };

    // Ícono por categoría
    final icono = switch (a.categoria) {
      'seguro'   => Icons.verified_user_rounded,
      'gasolina' => Icons.local_gas_station_rounded,
      _          => Icons.build_rounded, // servicios
    };

    return (color: color, icono: icono);
  }

  String _labelCategoria(String cat) => switch (cat) {
        'seguro'   => 'SEGURO',
        'gasolina' => 'GASOLINA',
        _          => 'SERVICIO',
      };

  String _fmt(DateTime d) =>
      "${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}";
}