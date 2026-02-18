import 'package:flutter/material.dart';
import 'database_helper.dart';

class HistorialGasolina extends StatelessWidget {
  const HistorialGasolina({super.key});

  Future<List<Map<String, dynamic>>> obtenerDatos() async {
    final db = await DatabaseHelper.instance.database;
    return db.query('gasolina', orderBy: 'id DESC');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Historial gasolina")),
      body: FutureBuilder(
        future: obtenerDatos(),
        builder: (context, AsyncSnapshot<List<Map<String, dynamic>>> snapshot) {

          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final datos = snapshot.data!;

          if (datos.isEmpty) {
            return const Center(child: Text("No hay registros aún"));
          }

          return ListView.builder(
            itemCount: datos.length,
            itemBuilder: (context, index) {
              final item = datos[index];

              return Card(
                margin: const EdgeInsets.all(10),
                child: ListTile(
                  title: Text("${item['litros']} L  •  \$${item['total']}"),
                  subtitle: Text(
                      "KM: ${item['kilometraje']}  •  ${item['fecha']}"),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
