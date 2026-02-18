import 'package:flutter/material.dart';
import 'database_helper.dart';

class SeguroPage extends StatefulWidget {
  const SeguroPage({super.key});

  @override
  State<SeguroPage> createState() => _SeguroPageState();
}

class _SeguroPageState extends State<SeguroPage> {
  final TextEditingController aseguradoraController = TextEditingController();
  final TextEditingController polizaController = TextEditingController();
  final TextEditingController telefonoController = TextEditingController();
  final TextEditingController notasController = TextEditingController();

  DateTime? fechaInicio;
  DateTime? fechaFin;
  Map<String, dynamic>? seguroActual;
  bool cargando = true;

  @override
  void initState() {
    super.initState();
    cargarSeguro();
  }

  Future<void> cargarSeguro() async {
    final datos = await DatabaseHelper.instance.obtenerSeguro();
    setState(() {
      seguroActual = datos;
      cargando = false;
      if (datos != null) {
        aseguradoraController.text = datos['aseguradora'] ?? '';
        polizaController.text = datos['poliza'] ?? '';
        telefonoController.text = datos['telefono'] ?? '';
        notasController.text = datos['notas'] ?? '';
        fechaInicio = DateTime.parse(datos['inicio']);
        fechaFin = DateTime.parse(datos['fin']);
      }
    });
  }

  Future<void> seleccionarFecha({required bool esInicio}) async {
    DateTime? picked = await showDatePicker(
      context: context,
      initialDate: esInicio ? (fechaInicio ?? DateTime.now()) : (fechaFin ?? DateTime.now()),
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );

    if (picked != null) {
      setState(() {
        if (esInicio) {
          fechaInicio = picked;
        } else {
          fechaFin = picked;
        }
      });
    }
  }

  Future<void> guardarSeguro() async {
    if (aseguradoraController.text.isEmpty ||
        polizaController.text.isEmpty ||
        telefonoController.text.isEmpty ||
        fechaInicio == null ||
        fechaFin == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Completa todos los campos obligatorios")),
      );
      return;
    }

    if (seguroActual == null) {
      await DatabaseHelper.instance.insertarSeguro(
        aseguradora: aseguradoraController.text,
        poliza: polizaController.text,
        telefono: telefonoController.text,
        inicio: fechaInicio!.toIso8601String(),
        fin: fechaFin!.toIso8601String(),
        notas: notasController.text,
      );
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Seguro registrado")),
      );
    } else {
      await DatabaseHelper.instance.actualizarSeguro(
        seguroActual!['id'],
        aseguradora: aseguradoraController.text,
        poliza: polizaController.text,
        telefono: telefonoController.text,
        inicio: fechaInicio!.toIso8601String(),
        fin: fechaFin!.toIso8601String(),
        notas: notasController.text,
      );
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Seguro actualizado")),
      );
    }

    await cargarSeguro();
  }

  Future<void> eliminarSeguro() async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Eliminar Seguro"),
        content: const Text("¿Estás seguro de que quieres eliminar el seguro?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancelar"),
          ),
          TextButton(
            onPressed: () async {
              await DatabaseHelper.instance.eliminarSeguro(seguroActual!['id']);
              Navigator.pop(context);
              setState(() {
                seguroActual = null;
                aseguradoraController.clear();
                polizaController.clear();
                telefonoController.clear();
                notasController.clear();
                fechaInicio = null;
                fechaFin = null;
              });
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Seguro eliminado")),
              );
            },
            child: const Text("Eliminar", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  String formatearFecha(DateTime fecha) {
    return "${fecha.day.toString().padLeft(2, '0')}/"
        "${fecha.month.toString().padLeft(2, '0')}/"
        "${fecha.year}";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Seguro")),
      body: cargando
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  if (seguroActual != null)
                    Card(
                      margin: const EdgeInsets.only(bottom: 20),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              seguroActual!['aseguradora'],
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text("Póliza: ${seguroActual!['poliza']}"),
                            Text("Teléfono: ${seguroActual!['telefono']}"),
                            Text(
                              "Vigencia: ${formatearFecha(DateTime.parse(seguroActual!['inicio']))} - ${formatearFecha(DateTime.parse(seguroActual!['fin']))}",
                            ),
                            if (seguroActual!['notas'] != null && seguroActual!['notas'].isNotEmpty)
                              Text("Notas: ${seguroActual!['notas']}"),
                          ],
                        ),
                      ),
                    ),
                  TextField(
                    controller: aseguradoraController,
                    decoration: const InputDecoration(
                      labelText: "Aseguradora",
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: polizaController,
                    decoration: const InputDecoration(
                      labelText: "Número de Póliza",
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: telefonoController,
                    decoration: const InputDecoration(
                      labelText: "Teléfono",
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => seleccionarFecha(esInicio: true),
                          icon: const Icon(Icons.calendar_today),
                          label: Text(
                            fechaInicio != null
                                ? formatearFecha(fechaInicio!)
                                : "Fecha Inicio",
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => seleccionarFecha(esInicio: false),
                          icon: const Icon(Icons.calendar_today),
                          label: Text(
                            fechaFin != null
                                ? formatearFecha(fechaFin!)
                                : "Fecha Fin",
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: notasController,
                    decoration: const InputDecoration(
                      labelText: "Notas (opcional)",
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 3,
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: guardarSeguro,
                          child: Text(
                            seguroActual == null ? "Registrar" : "Actualizar",
                          ),
                        ),
                      ),
                      if (seguroActual != null) ...[
                        const SizedBox(width: 12),
                        ElevatedButton(
                          onPressed: eliminarSeguro,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                          ),
                          child: const Text(
                            "Eliminar",
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
    );
  }

  @override
  void dispose() {
    aseguradoraController.dispose();
    polizaController.dispose();
    telefonoController.dispose();
    notasController.dispose();
    super.dispose();
  }
}
