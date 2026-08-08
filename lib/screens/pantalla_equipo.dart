import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// --- PANTALLA DE GESTIÓN DE EQUIPO ---
class PantallaEquipo extends StatelessWidget {
  PantallaEquipo({super.key});
  final TextEditingController _controladorNombre = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Plantilla', style: TextStyle(fontWeight: FontWeight.bold))),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance.collection('config').doc('equipo').snapshots(),
        builder: (context, snapshot) {
          
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: Color(0xFF004D40)));
          }

          List<String> equipoActual = List<String>.from((snapshot.data?.data() as Map<String, dynamic>?)?['lista'] ?? []);

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _controladorNombre,
                        decoration: const InputDecoration(labelText: 'Añadir compañero/a', border: OutlineInputBorder()),
                      ),
                    ),
                    const SizedBox(width: 10),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.add), 
                      style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF004D40), foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16)),
                      onPressed: () {
                        if (_controladorNombre.text.isNotEmpty) {
                          equipoActual.add(_controladorNombre.text.trim());
                          FirebaseFirestore.instance.collection('config').doc('equipo').set({'lista': equipoActual});
                          _controladorNombre.clear();
                        }
                      },
                      label: const Text('AÑADIR', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ),
              const Divider(),
              Expanded(
                child: ListView.builder(
                  itemCount: equipoActual.length,
                  itemBuilder: (context, index) {
                    return ListTile(
                      leading: const Icon(Icons.person, color: Color(0xFF004D40)), 
                      title: Text(equipoActual[index], style: const TextStyle(fontSize: 18)),
                      trailing: IconButton( 
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () {
                          equipoActual.removeAt(index);
                          FirebaseFirestore.instance.collection('config').doc('equipo').set({'lista': equipoActual});
                        },
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        }
      ),
    );
  }
}