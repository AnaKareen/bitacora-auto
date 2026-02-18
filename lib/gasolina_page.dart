import 'package:flutter/material.dart';
import 'database_helper.dart';

class GasolinaPage extends StatefulWidget {
  const GasolinaPage({super.key});

  @override
  State<GasolinaPage> createState() => _GasolinaPageState();
}

class _GasolinaPageState extends State<GasolinaPage> {
  final TextEditingController kmController = TextEditingController();
  final TextEditingController litrosController = TextEditingController();
  final TextEditingController precioController = TextEditingController();

  DateTime? fechaSeleccionada;

  List<Map<String, dynamic>> registros = [];

  @override
  void initState() {
    super.initState();
    cargarRegistros();
  }

  /// Carga los registros de la base de datos al iniciar
  Future<void> cargarRegistros() async {
    final db = await DatabaseHelper.instance.database;
    final datos = await db.query(
      'gasolina',
      orderBy: 'id DESC', // los más recientes primero
    );

    setState(() {
      registros = datos.map((e) {
        return {
          'km': e['kilometraje'],
          'litros': e['litros'],
          'precio': e['precio_litro'],
          'total': e['total'],
          'fecha': DateTime.parse(e['fecha'] as String),
          'id': e['id'], // para eliminar después
        };
      }).toList();
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

  void guardarRegistro() async {
    if (kmController.text.isEmpty ||
        litrosController.text.isEmpty ||
        precioController.text.isEmpty ||
        fechaSeleccionada == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Completa todos los campos")),
      );
      return;
    }

    final double km = double.parse(kmController.text);
    final double litros = double.parse(litrosController.text);
    final double precio = double.parse(precioController.text);
    final double total = litros * precio;

    // Insertar en la base de datos
    final db = await DatabaseHelper.instance.database;
    int id = await db.insert('gasolina', {
      'fecha': fechaSeleccionada!.toIso8601String(),
      'kilometraje': km,
      'litros': litros,
      'precio_litro': precio,
      'total': total,
    });

    // Agregar a la lista local
    setState(() {
      registros.insert(0, {
        'id': id,
        'km': km,
        'litros': litros,
        'precio': precio,
        'total': total,
        'fecha': fechaSeleccionada!,
      });
    });

    kmController.clear();
    litrosController.clear();
    precioController.clear();
    fechaSeleccionada = null;
  }

  void eliminarRegistro(int index) async {
    final db = await DatabaseHelper.instance.database;
    int id = registros[index]['id'];

    await db.delete(
      'gasolina',
      where: 'id = ?',
      whereArgs: [id],
    );

    setState(() {
      registros.removeAt(index);
    });
  }

  void abrirModalEditar(int index) {
    final item = registros[index];

    kmController.text = item['km'].toString();
    litrosController.text = item['litros'].toString();
    precioController.text = item['precio'].toString();
    fechaSeleccionada = item['fecha'];

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Editar Registro"),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: kmController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: "Kilometraje"),
              ),
              TextField(
                controller: litrosController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: "Litros"),
              ),
              TextField(
                controller: precioController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: "Precio por litro"),
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
    if (kmController.text.isEmpty ||
        litrosController.text.isEmpty ||
        precioController.text.isEmpty ||
        fechaSeleccionada == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Completa todos los campos")),
      );
      return;
    }

    final double km = double.parse(kmController.text);
    final double litros = double.parse(litrosController.text);
    final double precio = double.parse(precioController.text);
    final double total = litros * precio;
    final int id = registros[index]['id'];

    await DatabaseHelper.instance.actualizarGasolina(
      id,
      fecha: fechaSeleccionada!.toIso8601String(),
      kilometraje: km,
      litros: litros,
      preciolitro: precio,
      total: total,
    );

    setState(() {
      registros[index] = {
        'id': id,
        'km': km,
        'litros': litros,
        'precio': precio,
        'total': total,
        'fecha': fechaSeleccionada!,
      };
    });

    kmController.clear();
    litrosController.clear();
    precioController.clear();
    fechaSeleccionada = null;

    Navigator.pop(context);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Registro actualizado")),
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
      appBar: AppBar(title: const Text("Carga de Gasolina")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            /// KM
            TextField(
              controller: kmController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: "Kilometraje"),
            ),

            /// LITROS
            TextField(
              controller: litrosController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: "Litros cargados"),
            ),

            /// PRECIO
            TextField(
              controller: precioController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: "Precio por litro"),
            ),

            const SizedBox(height: 12),

            /// FECHA
            Row(
              children: [
                ElevatedButton(
                  onPressed: seleccionarFecha,
                  child: const Text("Seleccionar Fecha"),
                ),
                const SizedBox(width: 10),
                Text(
                  fechaSeleccionada == null
                      ? "Sin fecha seleccionada"
                      : formatearFecha(fechaSeleccionada!),
                ),
              ],
            ),

            const SizedBox(height: 12),

            ElevatedButton(
              onPressed: guardarRegistro,
              child: const Text("Guardar"),
            ),

            const SizedBox(height: 20),

            /// HISTORIAL
            Expanded(
              child: registros.isEmpty
                  ? const Center(child: Text("Sin registros"))
                  : ListView.builder(
                      itemCount: registros.length,
                      itemBuilder: (context, index) {
                        final item = registros[index];

                        return Dismissible(
                          key: ValueKey(item['id']),

                          /// 👉 DESLIZAR A LA IZQUIERDA PARA BORRAR
                          direction: DismissDirection.endToStart,

                          onDismissed: (_) => eliminarRegistro(index),

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
                                title: Text(
                                  "${item['litros']} L  •  \$${item['total'].toStringAsFixed(2)}",
                                ),
                                subtitle: Text(
                                  "KM: ${item['km']}  •  ${formatearFecha(item['fecha'])}",
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
