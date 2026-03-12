import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'database_helper.dart';
import 'dart:typed_data';

// ─── COLORES PDF ──────────────────────────────────────────────────────────────
const _pdfAzul    = PdfColor.fromInt(0xFF3B7BFF);
const _pdfVerde   = PdfColor.fromInt(0xFF00C48C);
const _pdfNaranja = PdfColor.fromInt(0xFFFF7A2F);
const _pdfRojo    = PdfColor.fromInt(0xFFFF3B55);
const _pdfGris    = PdfColor.fromInt(0xFF8A8FA8);
const _pdfGrisClaro = PdfColor.fromInt(0xFFF5F6FA);
const _pdfNegro   = PdfColor.fromInt(0xFF0F1117);
const _pdfBlanco  = PdfColors.white;

// ─── PÁGINA DE EXPORTACIÓN ────────────────────────────────────────────────────
class ExportarPdfPage extends StatefulWidget {
  const ExportarPdfPage({super.key});

  @override
  State<ExportarPdfPage> createState() => _ExportarPdfPageState();
}

class _ExportarPdfPageState extends State<ExportarPdfPage> {
  bool _gasolina  = true;
  bool _servicios = true;
  bool _seguro    = true;
  bool _generando = false;

  // ─── COLORES UI ────────────────────────────────────────────────────────────
  static const _bg       = Color(0xFFF5F6FA);
  static const _card     = Color(0xFFFFFFFF);
  static const _textMain = Color(0xFF0F1117);
  static const _textSub  = Color(0xFF8A8FA8);
  static const _divider  = Color(0xFFEAEBF0);
  static const _blue     = Color(0xFF3B7BFF);
  static const _blueSoft = Color(0x1A3B7BFF);
  static const _green    = Color(0xFF00C48C);
  static const _orange   = Color(0xFFFF7A2F);
  static const _purple   = Color(0xFF9B59F5);

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
          "Exportar PDF",
          style: TextStyle(
            color: _textMain, fontWeight: FontWeight.w800,
            fontSize: 18, letterSpacing: -0.3,
          ),
        ),
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 24, 16, 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            // ── HEADER DESCRIPTIVO ──────────────────────────────────────────
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: _blue,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [BoxShadow(
                    color: _blue.withOpacity(0.3),
                    blurRadius: 16, offset: const Offset(0, 6))],
              ),
              child: Row(
                children: [
                  Container(
                    width: 52, height: 52,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(Icons.picture_as_pdf_rounded,
                        color: Colors.white, size: 28),
                  ),
                  const SizedBox(width: 16),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Bitácora Vehicular",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18, fontWeight: FontWeight.w900,
                          ),
                        ),
                        SizedBox(height: 3),
                        Text(
                          "Nissan Sentra 2006",
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 13, fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 28),
            _sectionLabel("INCLUIR EN EL PDF"),
            const SizedBox(height: 12),

            // ── OPCIONES DE SECCIONES ───────────────────────────────────────
            _opcionToggle(
              titulo:    "Historial de Gasolina",
              subtitulo: "Cargas, litros, km y rendimiento",
              icono:     Icons.local_gas_station_rounded,
              color:     _blue,
              valor:     _gasolina,
              onChanged: (v) => setState(() => _gasolina = v),
            ),
            const SizedBox(height: 10),

            _opcionToggle(
              titulo:    "Historial de Servicios",
              subtitulo: "Aceite, bujías, filtros y más",
              icono:     Icons.settings_rounded,
              color:     _orange,
              valor:     _servicios,
              onChanged: (v) => setState(() => _servicios = v),
            ),
            const SizedBox(height: 10),

            _opcionToggle(
              titulo:    "Datos del Seguro",
              subtitulo: "Aseguradora, póliza y vigencia",
              icono:     Icons.verified_user_rounded,
              color:     _green,
              valor:     _seguro,
              onChanged: (v) => setState(() => _seguro = v),
            ),

            const SizedBox(height: 32),
            _sectionLabel("VISTA PREVIA DEL PDF"),
            const SizedBox(height: 12),

            // ── PREVIEW VISUAL ──────────────────────────────────────────────
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _card,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: _divider),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _previewRow(Icons.picture_as_pdf_rounded,
                      "Portada con datos del vehículo", _blue),
                  if (_gasolina)
                    _previewRow(Icons.local_gas_station_rounded,
                        "Tabla de cargas de gasolina + estadísticas", _blue),
                  if (_servicios)
                    _previewRow(Icons.settings_rounded,
                        "Tabla de servicios realizados", _orange),
                  if (_seguro)
                    _previewRow(Icons.verified_user_rounded,
                        "Datos del seguro vigente", _green),
                  _previewRow(Icons.bar_chart_rounded,
                      "Resumen financiero total", _purple),
                ],
              ),
            ),

            const SizedBox(height: 32),
            const SizedBox(height: 32),

            // ── BOTÓN GENERAR ───────────────────────────────────────────────
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton.icon(
                onPressed: (!_gasolina && !_servicios && !_seguro) || _generando
                    ? null
                    : _generarPDF,
                icon: _generando
                    ? const SizedBox(
                        width: 18, height: 18,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2))
                    : const Icon(Icons.picture_as_pdf_rounded,
                        color: Colors.white),
                label: Text(
                  _generando ? "Generando PDF..." : "Generar y compartir PDF",
                  style: const TextStyle(
                    fontSize: 15, fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _blue,
                  disabledBackgroundColor: _divider,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                ),
              ),
            ),

            const SizedBox(height: 12),

            // Nota
            const Center(
              child: Text(
                "El PDF se puede compartir por WhatsApp, correo o guardar en tu teléfono",
                textAlign: TextAlign.center,
                style: TextStyle(color: _textSub, fontSize: 12, height: 1.5),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── WIDGETS UI ────────────────────────────────────────────────────────────
  Widget _opcionToggle({
    required String titulo,
    required String subtitulo,
    required IconData icono,
    required Color color,
    required bool valor,
    required ValueChanged<bool> onChanged,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: valor ? color.withOpacity(0.3) : _divider,
          width: valor ? 1.5 : 1,
        ),
        boxShadow: [BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8, offset: const Offset(0, 2))],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          Container(
            width: 42, height: 42,
            decoration: BoxDecoration(
              color: valor ? color.withOpacity(0.12) : const Color(0xFFF5F6FA),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icono,
                color: valor ? color : _textSub, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(titulo,
                    style: TextStyle(
                      color: valor ? _textMain : _textSub,
                      fontSize: 14, fontWeight: FontWeight.w700,
                    )),
                Text(subtitulo,
                    style: const TextStyle(color: _textSub, fontSize: 12)),
              ],
            ),
          ),
          Switch.adaptive(
            value: valor,
            onChanged: onChanged,
            activeColor: color,
          ),
        ],
      ),
    );
  }

  Widget _previewRow(IconData icono, String texto, Color color) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Row(
          children: [
            Icon(icono, size: 14, color: color),
            const SizedBox(width: 8),
            Text(texto,
                style: const TextStyle(color: _textSub, fontSize: 12.5)),
          ],
        ),
      );

  Widget _sectionLabel(String t) => Text(t,
      style: const TextStyle(
          color: _textSub, fontSize: 11,
          fontWeight: FontWeight.w700, letterSpacing: 2));

  // ─── GENERACIÓN DEL PDF ────────────────────────────────────────────────────
  Future<void> _generarPDF() async {
    setState(() => _generando = true);

    try {
      // Obtener datos
      final db = await DatabaseHelper.instance.database;
      List<Map<String, dynamic>> gasolina  = [];
      List<Map<String, dynamic>> servicios = [];
      Map<String, dynamic>? seguro;

      if (_gasolina) {
        gasolina = await db.query('gasolina', orderBy: 'id ASC');
      }
      if (_servicios) {
        servicios = await DatabaseHelper.instance.obtenerServicios();
      }
      if (_seguro) {
        seguro = await DatabaseHelper.instance.obtenerSeguro();
      }

      // Construir PDF
      final pdfBytes = await _construirPDF(gasolina, servicios, seguro);

      // Mostrar diálogo de compartir / imprimir
      await Printing.layoutPdf(
        onLayout: (_) async => Uint8List.fromList(pdfBytes),
        name: 'Bitacora_Sentra_${DateTime.now().year}.pdf',
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text("Error al generar PDF: $e"),
          backgroundColor: const Color(0xFFFF3B55),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.all(16),
        ));
      }
    } finally {
      if (mounted) setState(() => _generando = false);
    }
  }

  // ─── CONSTRUIR DOCUMENTO PDF ───────────────────────────────────────────────
  Future<List<int>> _construirPDF(
    List<Map<String, dynamic>> gasolina,
    List<Map<String, dynamic>> servicios,
    Map<String, dynamic>? seguro,
  ) async {
    final pdf = pw.Document(
      theme: pw.ThemeData.withFont(
        base: await PdfGoogleFonts.nunitoRegular(),
        bold: await PdfGoogleFonts.nunitoBold(),
      ),
    );

    // Calcular estadísticas de gasolina
    double totalGasto   = 0;
    double totalLitros  = 0;
    double rendGlobal   = 0;
    if (gasolina.isNotEmpty) {
      totalGasto  = gasolina.fold(0.0, (s, r) => s + ((r['total'] as num?)?.toDouble() ?? 0));
      totalLitros = gasolina.fold(0.0, (s, r) => s + ((r['litros'] as num?)?.toDouble() ?? 0));
      if (gasolina.length >= 2) {
        final sorted = [...gasolina]..sort((a, b) =>
            ((a['kilometraje'] as num?) ?? 0).compareTo((b['kilometraje'] as num?) ?? 0));
        final kmTotal = ((sorted.last['kilometraje'] as num?)?.toDouble() ?? 0) -
                        ((sorted.first['kilometraje'] as num?)?.toDouble() ?? 0);
        final litUsados = sorted.skip(1).fold(
            0.0, (s, r) => s + ((r['litros'] as num?)?.toDouble() ?? 0));
        if (litUsados > 0) rendGlobal = kmTotal / litUsados;
      }
    }
    final totalServicios = servicios.fold(
        0.0, (s, r) => s + ((r['costo'] as num?)?.toDouble() ?? 0));

    // ── PÁGINA 1: PORTADA + RESUMEN ───────────────────────────────────────
    pdf.addPage(pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(40),
      build: (pw.Context context) {
        final content = <pw.Widget>[];

        // Portada
        content.add(_pdfPortada());
        content.add(pw.SizedBox(height: 24));

        // Tarjetas de resumen
        content.add(_pdfResumen(
          totalGasto:      totalGasto + totalServicios,
          totalLitros:     totalLitros,
          rendimiento:     rendGlobal,
          totalServicios:  totalServicios,
          numCargas:       gasolina.length,
          numServicios:    servicios.length,
        ));
        content.add(pw.SizedBox(height: 24));

        // Seguro
        if (seguro != null) {
          content.add(_pdfSeccionSeguro(seguro));
          content.add(pw.SizedBox(height: 24));
        }

        // Tabla gasolina
        if (gasolina.isNotEmpty) {
          content.add(_pdfTituloSeccion(
              "Historial de Gasolina", gasolina.length, _pdfAzul));
          content.add(pw.SizedBox(height: 8));
          content.add(_pdfTablaGasolina(gasolina));
          content.add(pw.SizedBox(height: 24));
        }

        // Tabla servicios
        if (servicios.isNotEmpty) {
          content.add(_pdfTituloSeccion(
              "Historial de Servicios", servicios.length, _pdfNaranja));
          content.add(pw.SizedBox(height: 8));
          content.add(_pdfTablaServicios(servicios));
        }

        return content;
      },
    ));

    return pdf.save();
  }

  // ─── PORTADA ───────────────────────────────────────────────────────────────
  pw.Widget _pdfPortada() => pw.Container(
        width: double.infinity,
        padding: const pw.EdgeInsets.all(24),
        decoration: pw.BoxDecoration(
          color: _pdfAzul,
          borderRadius: const pw.BorderRadius.all(pw.Radius.circular(16)),
        ),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      "BITÁCORA VEHICULAR",
                      style: pw.TextStyle(
                        color: PdfColors.white,
                        fontSize: 10,
                        fontWeight: pw.FontWeight.bold,
                        letterSpacing: 2,
                      ),
                    ),
                    pw.SizedBox(height: 4),
                    pw.Text(
                      "Nissan Sentra 2006",
                      style: pw.TextStyle(
                        color: _pdfBlanco,
                        fontSize: 26,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                pw.Container(
                  padding: const pw.EdgeInsets.symmetric(
                      horizontal: 14, vertical: 8),
                  decoration: pw.BoxDecoration(
                    color: PdfColors.white,
                    borderRadius: const pw.BorderRadius.all(
                        pw.Radius.circular(20)),
                  ),
                  child: pw.Text(
                    "Generado ${_fmtHoy()}",
                    style: pw.TextStyle(
                        color: _pdfAzul,
                        fontSize: 11,
                        fontWeight: pw.FontWeight.bold),
                  ),
                ),
              ],
            ),
          ],
        ),
      );

  // ─── RESUMEN ───────────────────────────────────────────────────────────────
  pw.Widget _pdfResumen({
    required double totalGasto,
    required double totalLitros,
    required double rendimiento,
    required double totalServicios,
    required int numCargas,
    required int numServicios,
  }) =>
      pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text("RESUMEN GENERAL",
              style: pw.TextStyle(
                  color: _pdfGris,
                  fontSize: 10,
                  fontWeight: pw.FontWeight.bold,
                  letterSpacing: 1.5)),
          pw.SizedBox(height: 10),
          pw.Row(children: [
            _pdfMiniCard("Gasto total",
                "\$${totalGasto.toStringAsFixed(0)}", _pdfAzul),
            pw.SizedBox(width: 10),
            _pdfMiniCard("Gasolina",
                "\$${(totalGasto - totalServicios).toStringAsFixed(0)}",
                _pdfAzul),
            pw.SizedBox(width: 10),
            _pdfMiniCard("Servicios",
                "\$${totalServicios.toStringAsFixed(0)}", _pdfNaranja),
          ]),
          pw.SizedBox(height: 10),
          pw.Row(children: [
            _pdfMiniCard("Litros totales",
                "${totalLitros.toStringAsFixed(1)} L", _pdfVerde),
            pw.SizedBox(width: 10),
            _pdfMiniCard("Rendimiento",
                rendimiento > 0
                    ? "${rendimiento.toStringAsFixed(1)} km/L"
                    : "—",
                _pdfVerde),
            pw.SizedBox(width: 10),
            _pdfMiniCard("Cargas / Servicios",
                "$numCargas / $numServicios", _pdfGris),
          ]),
        ],
      );

  pw.Widget _pdfMiniCard(String label, String valor, PdfColor color) =>
      pw.Expanded(
        child: pw.Container(
          padding: const pw.EdgeInsets.all(12),
          decoration: pw.BoxDecoration(
            color: _pdfGrisClaro,
            borderRadius:
                const pw.BorderRadius.all(pw.Radius.circular(10)),
            border: pw.Border.all(color: PdfColors.grey300),
          ),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(label,
                  style: pw.TextStyle(
                      color: _pdfGris,
                      fontSize: 9,
                      fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 4),
              pw.Text(valor,
                  style: pw.TextStyle(
                      color: color,
                      fontSize: 14,
                      fontWeight: pw.FontWeight.bold)),
            ],
          ),
        ),
      );

  // ─── SEGURO ────────────────────────────────────────────────────────────────
  pw.Widget _pdfSeccionSeguro(Map<String, dynamic> seguro) {
    final fin     = DateTime.tryParse(seguro['fin'] as String? ?? '');
    final inicio  = DateTime.tryParse(seguro['inicio'] as String? ?? '');
    final vencido = fin != null && fin.isBefore(DateTime.now());
    final color   = vencido ? _pdfRojo : _pdfVerde;
    final estado  = vencido ? "VENCIDO" : "VIGENTE";

    return pw.Container(
      padding: const pw.EdgeInsets.all(16),
      decoration: pw.BoxDecoration(
        color: vencido
            ? PdfColor.fromHex('#FFF5F5')
            : PdfColor.fromHex('#F0FDF8'),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(12)),
        border: pw.Border.all(
            color: vencido ? _pdfRojo : _pdfVerde, width: 1.5),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text("SEGURO VEHICULAR",
                  style: pw.TextStyle(
                      color: _pdfGris,
                      fontSize: 10,
                      fontWeight: pw.FontWeight.bold,
                      letterSpacing: 1.5)),
              pw.Container(
                padding: const pw.EdgeInsets.symmetric(
                    horizontal: 10, vertical: 4),
                decoration: pw.BoxDecoration(
                  color: color,
                  borderRadius: const pw.BorderRadius.all(
                      pw.Radius.circular(6)),
                ),
                child: pw.Text(estado,
                    style: pw.TextStyle(
                        color: _pdfBlanco,
                        fontSize: 10,
                        fontWeight: pw.FontWeight.bold)),
              ),
            ],
          ),
          pw.SizedBox(height: 10),
          pw.Row(children: [
            _pdfDatoSeguro("Aseguradora",
                seguro['aseguradora'] as String? ?? '—'),
            pw.SizedBox(width: 20),
            _pdfDatoSeguro("Póliza",
                seguro['poliza'] as String? ?? '—'),
            pw.SizedBox(width: 20),
            _pdfDatoSeguro("Teléfono",
                seguro['telefono'] as String? ?? '—'),
          ]),
          pw.SizedBox(height: 8),
          pw.Row(children: [
            _pdfDatoSeguro("Inicio",
                inicio != null ? _fmt(inicio) : '—'),
            pw.SizedBox(width: 20),
            _pdfDatoSeguro("Vencimiento",
                fin != null ? _fmt(fin) : '—'),
            if ((seguro['notas'] as String? ?? '').isNotEmpty) ...[
              pw.SizedBox(width: 20),
              _pdfDatoSeguro(
                  "Notas", seguro['notas'] as String),
            ],
          ]),
        ],
      ),
    );
  }

  pw.Widget _pdfDatoSeguro(String label, String valor) => pw.Expanded(
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(label,
                style: pw.TextStyle(
                    color: _pdfGris,
                    fontSize: 9,
                    fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 2),
            pw.Text(valor,
                style: pw.TextStyle(
                    color: _pdfNegro,
                    fontSize: 11,
                    fontWeight: pw.FontWeight.bold)),
          ],
        ),
      );

  // ─── TÍTULO DE SECCIÓN ─────────────────────────────────────────────────────
  pw.Widget _pdfTituloSeccion(
          String titulo, int cantidad, PdfColor color) =>
      pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(titulo.toUpperCase(),
              style: pw.TextStyle(
                  color: _pdfGris,
                  fontSize: 10,
                  fontWeight: pw.FontWeight.bold,
                  letterSpacing: 1.5)),
          pw.Container(
            padding: const pw.EdgeInsets.symmetric(
                horizontal: 10, vertical: 3),
            decoration: pw.BoxDecoration(
              color: color,
              borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
            ),
            child: pw.Text("$cantidad registros",
                style: pw.TextStyle(
                    color: _pdfBlanco,
                    fontSize: 9,
                    fontWeight: pw.FontWeight.bold)),
          ),
        ],
      );

  // ─── TABLA GASOLINA ────────────────────────────────────────────────────────
  pw.Widget _pdfTablaGasolina(List<Map<String, dynamic>> datos) {
    final headers = ["#", "Fecha", "Kilometraje", "Litros", "Precio/L", "Total", "Rendim."];
    final rows    = <List<String>>[];

    for (int i = 0; i < datos.length; i++) {
      final r     = datos[i];
      final km    = (r['kilometraje'] as num?)?.toDouble() ?? 0;
      final litros = (r['litros']     as num?)?.toDouble() ?? 0;
      final precio = (r['precio_litro'] as num?)?.toDouble() ?? 0;
      final total  = (r['total']      as num?)?.toDouble() ?? 0;
      final fecha  = DateTime.tryParse(r['fecha'] as String? ?? '');

      String rend = "—";
      if (i > 0) {
        final kmPrev = (datos[i-1]['kilometraje'] as num?)?.toDouble() ?? 0;
        final litPrev = (datos[i-1]['litros']     as num?)?.toDouble() ?? 0; // litros carga anterior
        // Rendimiento real: km recorridos / litros de ESTA carga
        final kmDiff = km - kmPrev;
        if (kmDiff > 0 && litros > 0) {
          rend = "${(kmDiff / litros).toStringAsFixed(1)} km/L";
        }
      }

      rows.add([
        "${i + 1}",
        fecha != null ? _fmt(fecha) : "—",
        "${km.toStringAsFixed(0)} km",
        "${litros.toStringAsFixed(1)} L",
        "\$${precio.toStringAsFixed(2)}",
        "\$${total.toStringAsFixed(0)}",
        rend,
      ]);
    }

    return _pdfTabla(headers: headers, rows: rows, accentColor: _pdfAzul);
  }

  // ─── TABLA SERVICIOS ───────────────────────────────────────────────────────
  pw.Widget _pdfTablaServicios(List<Map<String, dynamic>> datos) {
    final headers = ["#", "Tipo", "Fecha", "Kilometraje", "Lugar", "Costo"];
    final rows    = <List<String>>[];

    for (int i = 0; i < datos.length; i++) {
      final r    = datos[i];
      final km   = (r['kilometraje'] as num?)?.toDouble() ?? 0;
      final costo = (r['costo']      as num?)?.toDouble() ?? 0;
      final fecha = DateTime.tryParse(r['fecha'] as String? ?? '');

      rows.add([
        "${i + 1}",
        r['tipo']  as String? ?? '—',
        fecha != null ? _fmt(fecha) : "—",
        "${km.toStringAsFixed(0)} km",
        r['lugar'] as String? ?? '—',
        "\$${costo.toStringAsFixed(0)}",
      ]);
    }

    return _pdfTabla(headers: headers, rows: rows, accentColor: _pdfNaranja);
  }

  // ─── TABLA GENÉRICA ────────────────────────────────────────────────────────
  pw.Widget _pdfTabla({
    required List<String> headers,
    required List<List<String>> rows,
    required PdfColor accentColor,
  }) {
    return pw.TableHelper.fromTextArray(
      headers: headers,
      data: rows,
      border: pw.TableBorder.all(color: PdfColors.grey200, width: 0.5),
      headerStyle: pw.TextStyle(
        color: _pdfBlanco,
        fontSize: 9,
        fontWeight: pw.FontWeight.bold,
      ),
      headerDecoration: pw.BoxDecoration(color: accentColor),
      cellStyle: pw.TextStyle(color: _pdfNegro, fontSize: 9),
      cellAlignments: {
        0: pw.Alignment.center,
        1: pw.Alignment.centerLeft,
        2: pw.Alignment.center,
        3: pw.Alignment.center,
        4: pw.Alignment.centerLeft,
        5: pw.Alignment.center,
        6: pw.Alignment.center,
      },
      rowDecoration: const pw.BoxDecoration(color: _pdfBlanco),
      oddRowDecoration: pw.BoxDecoration(color: _pdfGrisClaro),
      columnWidths: {
        0: const pw.FixedColumnWidth(24),
      },
    );
  }

  // ─── HELPERS ───────────────────────────────────────────────────────────────
  String _fmt(DateTime d) =>
      "${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}";

  String _fmtHoy() => _fmt(DateTime.now());
}