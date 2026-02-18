import 'database_helper.dart';
import 'package:flutter/material.dart';
import 'gasolina_page.dart';
import 'historial_gasolina.dart';
import 'servicios_page.dart';
import 'seguro_page.dart';

class Dashboard extends StatefulWidget {
  const Dashboard({super.key});

  @override
  State<Dashboard> createState() => _DashboardState();
}

class _DashboardState extends State<Dashboard> {
  @override
  Widget build(BuildContext context) {
    DatabaseHelper.instance.database;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Sentra 2006"),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      backgroundColor: const Color(0xFFFFFFFF),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Imagen del carro
          Container(
            height: 200,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Image.asset(
                'assets/sentra.png',
                fit: BoxFit.cover,
              ),
            ),
          ),
          const SizedBox(height: 20),

          // CARD GRAFICA DE CONSUMO + ALERTAS (según datos)
          FutureBuilder<List<Map<String, dynamic>>>(
            future: _obtenerUltimosConsumos(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return _cardVacia();
              }
              final consumos = snapshot.data!;
              return _cardConsumoGasolina(consumos);
            },
          ),

          const SizedBox(height: 16),

          // Card Gasolina
          _cardListTile(
            context,
            title: "Gasolina",
            subtitle: "Tocar para registrar / mantener para ver historial",
            icon: Icons.local_gas_station,
            iconColor: const Color(0xFF007AFF),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const GasolinaPage()),
              );
            },
            onLongPress: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const HistorialGasolina()),
              );
            },
          ),

          // Card Servicios
          _cardListTile(
            context,
            title: "Servicios",
            subtitle: "Cambios de aceite, bujías, filtros, etc.",
            icon: Icons.build,
            iconColor: const Color(0xFF007AFF),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ServiciosPage()),
              );
            },
          ),

          // Card Seguro
          FutureBuilder<Map<String, dynamic>?>(
            future: DatabaseHelper.instance.obtenerSeguro(),
            builder: (context, snapshot) {
              String subtitle = "Sin registrar";
              if (snapshot.hasData && snapshot.data != null) {
                final seguro = snapshot.data!;
                DateTime fin = DateTime.parse(seguro['fin']);
                subtitle =
                    "${seguro['aseguradora']} • Vencimiento: ${fin.day}/${fin.month}/${fin.year}";
              }

              return _cardListTile(
                context,
                title: "Seguro",
                subtitle: subtitle,
                icon: Icons.shield,
                iconColor: const Color(0xFF007AFF),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const SeguroPage()),
                  ).then((_) => setState(() {}));
                },
              );
            },
          ),
        ],
      ),
    );
  }

  // OBTENER LOS 5 ULTIMOS REGISTROS DE GASOLINA
  Future<List<Map<String, dynamic>>> _obtenerUltimosConsumos() async {
    final db = await DatabaseHelper.instance.database;
    return await db.query('gasolina', orderBy: 'id DESC', limit: 5);
  }

  // CARD VACIA
  Widget _cardVacia() {
    return Card(
      color: const Color(0xFFF2F2F7),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: const SizedBox(
        height: 150,
        child: Center(child: Text("No hay datos de consumo")),
      ),
    );
  }

  // CARD CONSUMO GASOLINA + ALERTAS DINAMICO
  Widget _cardConsumoGasolina(List<Map<String, dynamic>> consumos) {
    // Generamos alertas si litros < 10
    final alertas = consumos.where((c) => c['litros'] < 10).toList();

    return Card(
      color: const Color(0xFFF2F2F7),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      margin: const EdgeInsets.only(bottom: 16),
      child: SizedBox(
        height: 150,
        child: Row(
          children: [
            // ALERTAS 1/4 izquierda
            Expanded(
              flex: 1,
              child: Container(
                padding: const EdgeInsets.all(12),
                child: alertas.isEmpty
                    ? const Center(
                        child: Text(
                          "Sin alertas",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: Colors.black87,
                          ),
                        ),
                      )
                    : Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: alertas.map((c) {
                          return Column(
                            children: [
                              const Icon(Icons.warning, color: Colors.orange, size: 28),
                              const SizedBox(height: 4),
                              Text(
                                "Litros bajos: ${c['litros']}",
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                  color: Colors.black87,
                                ),
                              ),
                              const SizedBox(height: 8),
                            ],
                          );
                        }).toList(),
                      ),
              ),
            ),

            // GRAFICA 3/4 derecha
            Expanded(
              flex: 3,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: _graficaConsumo(consumos),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // GRAFICA SIMPLE CON BARRAS SEGUN DATOS
  Widget _graficaConsumo(List<Map<String, dynamic>> consumos) {
    final maxLitros = consumos.map((c) => c['litros'] as double).reduce((a, b) => a > b ? a : b);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          "Consumo de Gasolina (L)",
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: consumos.map((c) {
              final litros = c['litros'] as double;
              final altura = litros / maxLitros * 100; // escala simple
              return Container(
                width: 16,
                height: altura,
                decoration: BoxDecoration(
                  color: Colors.blue,
                  borderRadius: BorderRadius.circular(4),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  // Función reusable para tarjetas modernas
  Widget _cardListTile(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    Color iconColor = Colors.blue,
    VoidCallback? onTap,
    VoidCallback? onLongPress,
  }) {
    return Card(
      color: const Color(0xFFF2F2F7),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      margin: const EdgeInsets.only(bottom: 16),
      child: ListTile(
        title: Text(title,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 18,
              color: Colors.black,
            )),
        subtitle: Text(subtitle, style: const TextStyle(color: Colors.black54)),
        trailing: Icon(icon, color: iconColor),
        onTap: onTap,
        onLongPress: onLongPress,
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      ),
    );
  }
}
