import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// --- PANTALLA DE ASIGNACIÓN (Conectada a la nube) ---
class PantallaAsignacion extends StatelessWidget {
  final String hora;
  final String fecha; 
  const PantallaAsignacion({super.key, required this.hora, required this.fecha});

  @override
  Widget build(BuildContext context) {
    String docId = fecha.replaceAll('/', '-');

    return Scaffold(
      appBar: AppBar(title: Text('Reparto $hora', style: const TextStyle(fontWeight: FontWeight.bold))),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance.collection('config').doc('equipo').snapshots(),
        builder: (context, snapshotEquipo) {
          List<String> equipoGlobal = List<String>.from((snapshotEquipo.data?.data() as Map<String, dynamic>?)?['lista'] ?? []);

          return StreamBuilder<DocumentSnapshot>(
            stream: FirebaseFirestore.instance.collection('turnos').doc(docId).snapshots(),
            builder: (context, snapshotTurnos) {
              if (snapshotTurnos.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator(color: Color(0xFF004D40)));
              }
              Map<String, dynamic> diaData = (snapshotTurnos.data?.data() as Map<String, dynamic>?) ?? {};

              return ListView(
                padding: const EdgeInsets.all(16),
                children: _generarFormularioSegunHora(context, hora, diaData, equipoGlobal, docId),
              );
            }
          );
        }
      )
    );
  }

  List<Widget> _generarFormularioSegunHora(BuildContext context, String hora, Map<String, dynamic> diaData, List<String> equipoGlobal, String docId) {
    if (hora == '09h') {
      return [
        const Text('Montaje', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 10),
        _selectorMultiple(context, 'Montaje', diaData, equipoGlobal, docId, hora), 
      ];
    } else if (hora == '11h' || hora == '13h' || hora == '15h' || hora == '17h' || hora == '19h' || hora == '21h' || hora == '23h') {
      return [
        const Text('Apoyo', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 10),
        _selectorMultiple(context, 'Apoyo', diaData, equipoGlobal, docId, hora),
      ];
    } else {
      return [
        const Text('Roles', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 10),
        _selectorRol('A', diaData, equipoGlobal, docId, hora), 
        _selectorRol('AZ', diaData, equipoGlobal, docId, hora), 
        _selectorRol('AA', diaData, equipoGlobal, docId, hora), 
        _selectorRol('AE', diaData, equipoGlobal, docId, hora), 
        _selectorRol('ASE', diaData, equipoGlobal, docId, hora), 
        _selectorRol('Despedida', diaData, equipoGlobal, docId, hora),
        const Divider(height: 40),
        const Text('Servicios Especiales', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 10),
        _selectorMultiple(context, 'ZAH', diaData, equipoGlobal, docId, hora), 
        _selectorMultiple(context, 'BAY 30', diaData, equipoGlobal, docId, hora), 
        _selectorMultiple(context, 'BAY 45', diaData, equipoGlobal, docId, hora), 
        _selectorMultiple(context, 'JZ', diaData, equipoGlobal, docId, hora), 
        _selectorMultiple(context, 'NAF', diaData, equipoGlobal, docId, hora),
      ];
    }
  }

  Widget _selectorRol(String clave, Map<String, dynamic> diaData, List<String> equipoGlobal, String docId, String hora) {
    Map<String, dynamic> datosHora = diaData[hora] ?? {};
    String? valorActual;
    if (datosHora[clave] is String) valorActual = datosHora[clave];
    
    if (valorActual != null && !equipoGlobal.contains(valorActual)) valorActual = null;

    List<String> ocupados = _obtenerOcupados(clave, datosHora);
    List<String> disponibles = equipoGlobal.where((p) => !ocupados.contains(p)).toList();

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: DropdownButtonFormField<String>(
        value: valorActual,
        decoration: InputDecoration(labelText: clave, border: const OutlineInputBorder()),
        items: [
          const DropdownMenuItem<String>(value: null, child: Text('--- Sin asignar ---', style: TextStyle(color: Colors.grey))),
          ...disponibles.map((n) => DropdownMenuItem(value: n, child: Text(n)))
        ],
        onChanged: (val) {
          FirebaseFirestore.instance.collection('turnos').doc(docId).set({
            hora: { clave: val }
          }, SetOptions(merge: true)); 
        },
      ),
    );
  }

  Widget _selectorMultiple(BuildContext context, String clave, Map<String, dynamic> diaData, List<String> equipoGlobal, String docId, String hora) {
    Map<String, dynamic> datosHora = diaData[hora] ?? {};
    
    List<String> valoresActuales = [];
    if (datosHora[clave] is List) {
      valoresActuales = List<String>.from(datosHora[clave]);
    } else if (datosHora[clave] is String && datosHora[clave].toString().isNotEmpty) {
      valoresActuales = [datosHora[clave].toString()];
    }

    valoresActuales.removeWhere((p) => !equipoGlobal.contains(p));

    List<String> ocupados = _obtenerOcupados(clave, datosHora);
    List<String> disponibles = equipoGlobal.where((p) => !ocupados.contains(p) || valoresActuales.contains(p)).toList();

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: InkWell(
        onTap: () async {
          List<String> seleccionTemporal = List.from(valoresActuales);
          
          await showDialog(
            context: context,
            builder: (context) {
              return StatefulBuilder(
                builder: (context, setStateDialog) {
                  return AlertDialog(
                    title: Text('Seleccionar $clave', style: const TextStyle(fontWeight: FontWeight.bold)),
                    content: SizedBox(
                      width: double.maxFinite,
                      child: ListView(
                        shrinkWrap: true,
                        children: disponibles.map((persona) {
                          bool estaMarcado = seleccionTemporal.contains(persona);
                          return CheckboxListTile(
                            title: Text(persona),
                            value: estaMarcado,
                            activeColor: const Color(0xFF004D40),
                            onChanged: (bool? val) {
                              setStateDialog(() {
                                if (val == true) {
                                  seleccionTemporal.add(persona);
                                } else {
                                  seleccionTemporal.remove(persona);
                                }
                              });
                            },
                          );
                        }).toList(),
                      ),
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('GUARDAR', style: TextStyle(color: Color(0xFF004D40), fontWeight: FontWeight.bold)),
                      )
                    ],
                  );
                }
              );
            }
          );
          
          FirebaseFirestore.instance.collection('turnos').doc(docId).set({
            hora: { clave: seleccionTemporal }
          }, SetOptions(merge: true));
        },
        child: InputDecorator(
          decoration: InputDecoration(
            labelText: clave,
            border: const OutlineInputBorder(),
            suffixIcon: const Icon(Icons.arrow_drop_down),
          ),
          child: Text(
            valoresActuales.isEmpty ? '--- Tocar para asignar ---' : valoresActuales.join(', '),
            style: TextStyle(color: valoresActuales.isEmpty ? Colors.grey : Colors.black, fontSize: 16),
          ),
        ),
      ),
    );
  }

  List<String> _obtenerOcupados(String claveActual, Map<String, dynamic> datosHora) {
    List<String> ocupados = [];
    datosHora.forEach((rol, valor) {
      if (rol != claveActual) {
        if (valor is List) {
          ocupados.addAll(valor.map((e) => e.toString()));
        } else if (valor is String && valor.isNotEmpty) {
          ocupados.add(valor);
        }
      }
    });
    return ocupados;
  }
}