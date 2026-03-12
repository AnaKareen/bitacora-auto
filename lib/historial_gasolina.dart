import 'package:flutter/material.dart';
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

class HistorialGasolina extends StatelessWidget {
  const HistorialGasolina({super.key});

  Future<List<Map<String, dynamic>>> _obtenerDatos() async {
    final db = await DatabaseHelper.instance.database;
    // ASC para calcular rendimiento entre pares; invertimos en UI
    final raw = await db.query('gasolina', orderBy: 'id ASC');
    return raw.map((e) => {
      'id':          e['id'],
      'litros':      (e['litros']       as num?)?.toDouble() ?? 0.0,
      'total':       (e['total']        as num?)?.toDouble() ?? 0.0,
      'kilometraje': (e['kilometraje']  as num?)?.toDouble() ?? 0.0,
      'precio_litro':(e['precio_litro'] as num?)?.toDouble() ?? 0.0,
      'fecha':       DateTime.tryParse(e['fecha'] as String? ?? '') ?? DateTime.now(),
    }).toList();
  }

  // ── Estadísticas globales ──────────────────────────────────────────────────
  Map<String, double> _calcStats(List<Map<String, dynamic>> datos) {
    if (datos.isEmpty) return {'gasto': 0, 'litros': 0, 'rendimiento': 0, 'precioProm': 0};

    final gasto   = datos.fold(0.0, (s, r) => s + (r['total'] as double));
    final litros  = datos.fold(0.0, (s, r) => s + (r['litros'] as double));
    final precioProm = datos.fold(0.0, (s, r) => s + (r['precio_litro'] as double)) / datos.length;

    double rendimiento = 0;
    if (datos.length >= 2) {
      final kmTotal     = (datos.last['kilometraje'] as double) - (datos.first['kilometraje'] as double);
      final litrosUsados = datos.skip(1).fold(0.0, (s, r) => s + (r['litros'] as double));
      if (litrosUsados > 0) rendimiento = kmTotal / litrosUsados;
    }

    return {'gasto': gasto, 'litros': litros, 'rendimiento': rendimiento, 'precioProm': precioProm};
  }

  // ── Rendimiento por intervalo ──────────────────────────────────────────────
  double? _rendInterv(List<Map<String, dynamic>> datos, int indexDesc) {
    // datos está en ASC, indexDesc es el índice en la lista invertida (DESC)
    final n       = datos.length;
    final iAsc    = n - 1 - indexDesc;   // posición en el array ASC
    if (iAsc == 0) return null;          // primer registro, sin referencia anterior

    final kmCurr  = datos[iAsc]['kilometraje'] as double;
    final kmPrev  = datos[iAsc - 1]['kilometraje'] as double;
    final litros  = datos[iAsc]['litros'] as double;
    if (litros <= 0 || kmCurr <= kmPrev) return null;
    return (kmCurr - kmPrev) / litros;
  }

  String _fmt(DateTime d) =>
      "${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}";

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
        title: const Text(
          "Historial de Gasolina",
          style: TextStyle(
            color: _textMain, fontWeight: FontWeight.w800,
            fontSize: 18, letterSpacing: -0.3,
          ),
        ),
        centerTitle: false,
      ),

      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _obtenerDatos(),
        builder: (context, snap) {
          // ── Cargando ──────────────────────────────────────────────
          if (!snap.hasData) {
            return const Center(
              child: CircularProgressIndicator(color: _blue, strokeWidth: 2),
            );
          }

          final datos = snap.data!;

          // ── Sin datos ─────────────────────────────────────────────
          if (datos.isEmpty) return _sinDatos();

          final st       = _calcStats(datos);
          final invertidos = datos.reversed.toList(); // mostramos DESC

          return CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              // ── STATS ──────────────────────────────────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(children: [
                        Expanded(child: _statCard(
                          label: "Gasto total",
                          value: "\$${st['gasto']!.toStringAsFixed(0)}",
                          icon: Icons.payments_rounded, color: _blue)),
                        const SizedBox(width: 10),
                        Expanded(child: _statCard(
                          label: "Litros totales",
                          value: "${st['litros']!.toStringAsFixed(1)} L",
                          icon: Icons.water_drop_rounded, color: _orange)),
                      ]),
                      const SizedBox(height: 10),
                      Row(children: [
                        Expanded(child: _statCard(
                          label: "Rendimiento global",
                          value: st['rendimiento']! > 0
                              ? "${st['rendimiento']!.toStringAsFixed(1)} km/L"
                              : "—",
                          icon: Icons.speed_rounded, color: _green)),
                        const SizedBox(width: 10),
                        Expanded(child: _statCard(
                          label: "Precio promedio",
                          value: "\$${st['precioProm']!.toStringAsFixed(2)}/L",
                          icon: Icons.local_gas_station_rounded,
                          color: const Color(0xFF9B59F5))),
                      ]),

                      const SizedBox(height: 24),
                      _sectionLabel("${datos.length} CARGAS REGISTRADAS"),
                      const SizedBox(height: 10),
                    ],
                  ),
                ),
              ),

              // ── LISTA ──────────────────────────────────────────────
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 40),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (ctx, i) {
                      final item   = invertidos[i];
                      final litros = item['litros']      as double;
                      final total  = item['total']       as double;
                      final km     = item['kilometraje'] as double;
                      final precio = item['precio_litro']as double;
                      final fecha  = item['fecha']       as DateTime;
                      final rend   = _rendInterv(datos, i);
                      final esEficiente = rend != null && rend >= (st['rendimiento'] ?? 0);

                      return Container(
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
                            // Número de carga
                            Container(
                              width: 44, height: 44,
                              decoration: BoxDecoration(
                                color: _blueSoft,
                                borderRadius: BorderRadius.circular(13),
                              ),
                              child: Center(
                                child: Text(
                                  "#${datos.length - i}",
                                  style: const TextStyle(
                                    color: _blue, fontSize: 13,
                                    fontWeight: FontWeight.w800),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),

                            // Info
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Litros + total
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        "${litros.toStringAsFixed(1)} L",
                                        style: const TextStyle(
                                          color: _textMain, fontSize: 16,
                                          fontWeight: FontWeight.w800),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 10, vertical: 3),
                                        decoration: BoxDecoration(
                                          color: _greenSoft,
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Text(
                                          "\$${total.toStringAsFixed(0)}",
                                          style: const TextStyle(
                                            color: _green, fontSize: 13,
                                            fontWeight: FontWeight.w700),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),

                                  // KM + precio/L + fecha
                                  Row(children: [
                                    const Icon(Icons.speed_rounded,
                                        size: 11, color: _textSub),
                                    const SizedBox(width: 3),
                                    Text("${km.toStringAsFixed(0)} km",
                                        style: const TextStyle(
                                            color: _textSub, fontSize: 12)),
                                    const SizedBox(width: 10),
                                    const Icon(Icons.attach_money_rounded,
                                        size: 11, color: _textSub),
                                    Text("\$${precio.toStringAsFixed(2)}/L",
                                        style: const TextStyle(
                                            color: _textSub, fontSize: 12)),
                                    const SizedBox(width: 10),
                                    const Icon(Icons.calendar_today_rounded,
                                        size: 11, color: _textSub),
                                    const SizedBox(width: 3),
                                    Text(_fmt(fecha),
                                        style: const TextStyle(
                                            color: _textSub, fontSize: 12)),
                                  ]),

                                  // Rendimiento del intervalo
                                  if (rend != null) ...[
                                    const SizedBox(height: 6),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 10, vertical: 5),
                                      decoration: BoxDecoration(
                                        color: esEficiente
                                            ? _greenSoft
                                            : _orangeSoft,
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            esEficiente
                                                ? Icons.trending_up_rounded
                                                : Icons.trending_down_rounded,
                                            size: 13,
                                            color: esEficiente ? _green : _orange,
                                          ),
                                          const SizedBox(width: 5),
                                          Text(
                                            "${rend.toStringAsFixed(1)} km/L en este tanque",
                                            style: TextStyle(
                                              color: esEficiente ? _green : _orange,
                                              fontSize: 11.5,
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                    childCount: invertidos.length,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  // ─── HELPERS ─────────────────────────────────────────────────────────────
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

  Widget _sinDatos() => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72, height: 72,
              decoration: BoxDecoration(
                  color: _blueSoft,
                  borderRadius: BorderRadius.circular(22)),
              child: const Icon(Icons.local_gas_station_rounded,
                  color: _blue, size: 36),
            ),
            const SizedBox(height: 16),
            const Text("Sin registros aún",
                style: TextStyle(color: _textMain, fontSize: 17,
                    fontWeight: FontWeight.w700)),
            const SizedBox(height: 6),
            const Text("Registra tu primera carga\ndesde la pantalla de Gasolina",
                textAlign: TextAlign.center,
                style: TextStyle(color: _textSub, fontSize: 13, height: 1.5)),
          ],
        ),
      );

  Widget _sectionLabel(String t) => Text(t,
      style: const TextStyle(color: _textSub, fontSize: 11,
          fontWeight: FontWeight.w700, letterSpacing: 2));
}