import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart'; // <-- 1. Importamos Auth

// --- PANTALLA DE GESTIÓN DE EQUIPO ---
class PantallaEquipo extends StatelessWidget {
  PantallaEquipo({super.key});
  final TextEditingController _controladorNombre = TextEditingController();

  // --- 2. MAGIA: IDENTIFICADOR AUTOMÁTICO DE EQUIPO ---
  // --- MAGIA: IDENTIFICADOR AUTOMÁTICO DE EQUIPO ---
  String get nombreEquipo {
    final email = FirebaseAuth.instance.currentUser?.email ?? '';
    final user = email.split('@')[0]; 
    
    // Agrupamos a los usuarios bajo su carpeta de equipo correspondiente
    if (user == 'triana' || user == 'carmen') return 'triana';
    if (user == 'ruben' || user == 'monica') return 'ruben';
    if (user == 'rocio' || user == 'santi') return 'rocio';
    
    return 'general';
  }

  // Esto mantendrá la lista original para Triana, y creará nuevas para el resto
  String get documentoEquipo {
    if (nombreEquipo == 'triana' || nombreEquipo == 'admin') {
      return 'equipo'; // Triana lee sus datos originales
    }
    return 'equipo_$nombreEquipo'; // Los demás tienen su propio documento
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Plantilla', style: TextStyle(fontWeight: FontWeight.bold))),
      body: StreamBuilder<DocumentSnapshot>(
        // --- 3. Usamos documentoEquipo para leer ---
        stream: FirebaseFirestore.instance.collection('config').doc(documentoEquipo).snapshots(),
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
                          // --- 4. Usamos documentoEquipo para guardar ---
                          FirebaseFirestore.instance.collection('config').doc(documentoEquipo).set({'lista': equipoActual});
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
                          // --- 5. Usamos documentoEquipo para borrar ---
                          FirebaseFirestore.instance.collection('config').doc(documentoEquipo).set({'lista': equipoActual});
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