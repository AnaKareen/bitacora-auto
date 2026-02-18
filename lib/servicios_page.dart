import 'package:flutter/material.dart';
import 'database_helper.dart';

class ServiciosPage extends StatefulWidget {
  const ServiciosPage({super.key});

  @override
  State<ServiciosPage> createState() => _ServiciosPageState();
}

class _ServiciosPageState extends State<ServiciosPage> {
  final List<String> tiposServicios = [
    'Cambio de aceite',
    'Bujías',
    'Filtro de aire',
    'Llantas',
    'Amortiguadores',
    'Balatas',
    'Otro',
  ];

  String? tipoSeleccionado;
  final TextEditingController kmController = TextEditingController();
  final TextEditingController costoController = TextEditingController();
  final TextEditingController lugarController = TextEditingController();
  final TextEditingController notasController = TextEditingController();

  DateTime? fechaSeleccionada;
  List<Map<String, dynamic>> servicios = [];

  @override
  void initState() {
    super.initState();
    cargarServicios();
  }

  Future<void> cargarServicios() async {
    final datos = await DatabaseHelper.instance.obtenerServicios();
    setState(() {
      servicios = datos;
    });
  }

  Future<void> seleccionarFecha() async {
    DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );

    if (picked != null) {
      setState(() {
        fechaSeleccionada = picked;
      });
    }
  }

  void guardarServicio() async {
    if (tipoSeleccionado == null ||
        kmController.text.isEmpty ||
        costoController.text.isEmpty ||
        lugarController.text.isEmpty ||
        fechaSeleccionada == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Completa todos los campos obligatorios")),
      );
      return;
    }

    final double km = double.parse(kmController.text);
    final double costo = double.parse(costoController.text);

    int id = await DatabaseHelper.instance.insertarServicio(
      tipo: tipoSeleccionado!,
      fecha: fechaSeleccionada!.toIso8601String(),
      kilometraje: km,
      costo: costo,
      lugar: lugarController.text,
      notas: notasController.text,
    );

    setState(() {
      servicios.insert(0, {
        'id': id,
        'tipo': tipoSeleccionado,
        'fecha': fechaSeleccionada,
        'kilometraje': km,
        'costo': costo,
        'lugar': lugarController.text,
        'notas': notasController.text,
      });
    });

    tipoSeleccionado = null;
    kmController.clear();
    costoController.clear();
    lugarController.clear();
    notasController.clear();
    fechaSeleccionada = null;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Servicio registrado")),
    );
  }

  void abrirModalEditar(int index) {
    final item = servicios[index];

    tipoSeleccionado = item['tipo'];
    kmController.text = item['kilometraje'].toString();
    costoController.text = item['costo'].toString();
    lugarController.text = item['lugar'];
    notasController.text = item['notas'] ?? '';
    fechaSeleccionada = DateTime.parse(item['fecha']);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Editar Servicio"),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                value: tipoSeleccionado,
                items: tiposServicios
                    .map((tipo) => DropdownMenuItem(
                          value: tipo,
                          child: Text(tipo),
                        ))
                    .toList(),
                onChanged: (value) {
                  setState(() {
                    tipoSeleccionado = value;
                  });
                },
                decoration: const InputDecoration(labelText: "Tipo de Servicio"),
              ),
              TextField(
                controller: kmController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: "Kilometraje"),
              ),
              TextField(
                controller: costoController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: "Costo"),
              ),
              TextField(
                controller: lugarController,
                decoration: const InputDecoration(labelText: "Lugar"),
              ),
              TextField(
                controller: notasController,
                decoration: const InputDecoration(labelText: "Notas"),
                maxLines: 2,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: seleccionarFecha,
                child: Text(
                  fechaSeleccionada == null
                      ? "Seleccionar Fecha"
                      : formatearFecha(fechaSeleccionada!),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancelar"),
          ),
          ElevatedButton(
            onPressed: () => guardarEdicion(index),
            child: const Text("Guardar"),
          ),
        ],
      ),
    );
  }

  void guardarEdicion(int index) async {
    if (tipoSeleccionado == null ||
        kmController.text.isEmpty ||
        costoController.text.isEmpty ||
        lugarController.text.isEmpty ||
        fechaSeleccionada == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Completa todos los campos")),
      );
      return;
    }

    final double km = double.parse(kmController.text);
    final double costo = double.parse(costoController.text);
    final int id = servicios[index]['id'];

    await DatabaseHelper.instance.actualizarServicio(
      id,
      tipo: tipoSeleccionado!,
      fecha: fechaSeleccionada!.toIso8601String(),
      kilometraje: km,
      costo: costo,
      lugar: lugarController.text,
      notas: notasController.text,
    );

    setState(() {
      servicios[index] = {
        'id': id,
        'tipo': tipoSeleccionado,
        'fecha': fechaSeleccionada,
        'kilometraje': km,
        'costo': costo,
        'lugar': lugarController.text,
        'notas': notasController.text,
      };
    });

    tipoSeleccionado = null;
    kmController.clear();
    costoController.clear();
    lugarController.clear();
    notasController.clear();
    fechaSeleccionada = null;

    Navigator.pop(context);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Servicio actualizado")),
    );
  }

  void eliminarServicio(int index) async {
    final id = servicios[index]['id'];
    await DatabaseHelper.instance.eliminarServicio(id);

    setState(() {
      servicios.removeAt(index);
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Servicio eliminado")),
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
      appBar: AppBar(title: const Text("Servicios")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            DropdownButtonFormField<String>(
              value: tipoSeleccionado,
              hint: const Text("Selecciona tipo de servicio"),
              items: tiposServicios
                  .map((tipo) => DropdownMenuItem(
                        value: tipo,
                        child: Text(tipo),
                      ))
                  .toList(),
              onChanged: (value) {
                setState(() {
                  tipoSeleccionado = value;
                });
              },
              decoration: const InputDecoration(labelText: "Tipo de Servicio"),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: kmController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: "Kilometraje"),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: costoController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: "Costo"),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: lugarController,
              decoration: const InputDecoration(labelText: "Lugar"),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: notasController,
              decoration: const InputDecoration(labelText: "Notas (opcional)"),
              maxLines: 2,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                ElevatedButton(
                  onPressed: seleccionarFecha,
                  child: const Text("Seleccionar Fecha"),
                ),
                const SizedBox(width: 10),
                Text(
                  fechaSeleccionada == null
                      ? "Sin fecha"
                      : formatearFecha(fechaSeleccionada!),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: guardarServicio,
              child: const Text("Guardar Servicio"),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: servicios.isEmpty
                  ? const Center(child: Text("Sin servicios registrados"))
                  : ListView.builder(
                      itemCount: servicios.length,
                      itemBuilder: (context, index) {
                        final item = servicios[index];
                        DateTime fecha = DateTime.parse(item['fecha']);

                        return Dismissible(
                          key: ValueKey(item['id']),
                          direction: DismissDirection.endToStart,
                          onDismissed: (_) => eliminarServicio(index),
                          background: Container(
                            color: Colors.red,
                            alignment: Alignment.centerRight,
                            padding: const EdgeInsets.only(right: 20),
                            child: const Icon(
                              Icons.delete,
                              color: Colors.white,
                            ),
                          ),
                          child: GestureDetector(
                            onTap: () => abrirModalEditar(index),
                            child: Card(
                              child: ListTile(
                                title: Text(item['tipo']),
                                subtitle: Text(
                                  "KM: ${item['kilometraje']}  •  \$${item['costo'].toStringAsFixed(2)}  •  ${item['lugar']}",
                                ),
                                trailing: const Icon(Icons.edit),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
