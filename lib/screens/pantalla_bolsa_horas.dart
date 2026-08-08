import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

// =========================================================
// --- PANTALLAS PARA LA BOLSA DE HORAS ---
// =========================================================

class PantallaBolsaHoras extends StatelessWidget {
  const PantallaBolsaHoras({super.key});

  Future<void> _generarPDFBolsa(List<Map<String, dynamic>> listaHoras, String fechaHoy) async {
    final pdf = pw.Document();
    
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Header(
                level: 0,
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text("ESTADO DE BOLSA DE HORAS", style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold, color: PdfColors.teal800)),
                    pw.Text(fechaHoy, style: pw.TextStyle(fontSize: 16, color: PdfColors.grey700)),
                  ]
                )
              ),
              pw.SizedBox(height: 20),
              pw.TableHelper.fromTextArray(
                context: context,
                headerDecoration: const pw.BoxDecoration(color: PdfColors.teal100),
                headerHeight: 30,
                cellHeight: 25,
                cellAlignments: {
                  0: pw.Alignment.centerLeft,
                  1: pw.Alignment.centerRight,
                },
                headers: ['Compañero/a', 'Balance de Horas'],
                data: listaHoras.map((item) => [
                  item['nombre'], 
                  "${item['horas']} h"
                ]).toList(),
              ),
              pw.SizedBox(height: 40),
              pw.Center(child: pw.Text("Generado automáticamente por HammamManager", style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey)))
            ],
          );
        }
      )
    );

    await Printing.sharePdf(bytes: await pdf.save(), filename: 'Bolsa_Horas_$fechaHoy.pdf');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Bolsa de Horas', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance.collection('config').doc('equipo').snapshots(),
        builder: (context, snapshotEquipo) {
          return StreamBuilder<DocumentSnapshot>(
            stream: FirebaseFirestore.instance.collection('config').doc('bolsa_horas').snapshots(),
            builder: (context, snapshotHoras) {
              if (!snapshotEquipo.hasData || !snapshotHoras.hasData) {
                return const Center(child: CircularProgressIndicator(color: Color(0xFF004D40)));
              }

              List<String> equipo = List<String>.from((snapshotEquipo.data?.data() as Map<String, dynamic>?)?['lista'] ?? []);
              Map<String, dynamic> horasData = (snapshotHoras.data?.data() as Map<String, dynamic>?) ?? {};

              List<Map<String, dynamic>> listaHoras = equipo.map((nombre) {
                return {
                  'nombre': nombre,
                  'horas': horasData[nombre] ?? 0, 
                };
              }).toList();

              listaHoras.sort((a, b) => (b['horas'] as int).compareTo(a['horas'] as int));

              DateTime hoy = DateTime.now();
              String fechaTxt = "${hoy.day}/${hoy.month}/${hoy.year}";

              return Column(
                children: [
                  Container(
                    color: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        TextButton.icon(
                          icon: const Icon(Icons.history, color: const Color(0xFF004D40)),
                          label: const Text('VER HISTORIAL', style: TextStyle(color: Color(0xFF004D40), fontWeight: FontWeight.bold)),
                          onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const PantallaHistorialHoras())),
                        ),
                        TextButton.icon(
                          icon: const Icon(Icons.picture_as_pdf, color: const Color(0xFF004D40)),
                          label: const Text('EXPORTAR PDF', style: TextStyle(color: Color(0xFF004D40), fontWeight: FontWeight.bold)),
                          onPressed: () => _generarPDFBolsa(listaHoras, fechaTxt),
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 1),
                  Expanded(
                    child: ListView.builder(
                      itemCount: listaHoras.length,
                      itemBuilder: (context, index) {
                        var item = listaHoras[index];
                        return ListTile(
                          leading: const Icon(Icons.person, color: Color(0xFF004D40)),
                          title: Text(item['nombre'], style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                          trailing: Text(
                            '${item['horas']} h', 
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: item['horas'] < 0 ? Colors.red : const Color(0xFF004D40))
                          ),
                        );
                      },
                    ),
                  ),
                  SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.edit_calendar),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF004D40),
                          foregroundColor: Colors.white,
                          minimumSize: const Size(double.infinity, 50)
                        ),
                        onPressed: () async {
                          final DateTime? seleccion = await showDatePicker(
                            context: context,
                            initialDate: DateTime.now(),
                            firstDate: DateTime(2024),
                            lastDate: DateTime(2030),
                          );
                          if (seleccion != null && context.mounted) {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => PantallaEditarHoras(fecha: seleccion, equipo: equipo, horasActuales: horasData)),
                            );
                          }
                        },
                        label: const Text('AÑADIR / QUITAR HORAS', style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ),
                ],
              );
            }
          );
        }
      ),
    );
  }
}

class PantallaEditarHoras extends StatefulWidget {
  final DateTime fecha;
  final List<String> equipo;
  final Map<String, dynamic> horasActuales;

  const PantallaEditarHoras({super.key, required this.fecha, required this.equipo, required this.horasActuales});

  @override
  State<PantallaEditarHoras> createState() => _PantallaEditarHorasState();
}

class _PantallaEditarHorasState extends State<PantallaEditarHoras> {
  late Map<String, int> horasEditadas;
  late List<String> equipoAlfabetico;

  @override
  void initState() {
    super.initState();
    horasEditadas = {};
    for (var nombre in widget.equipo) {
      horasEditadas[nombre] = (widget.horasActuales[nombre] ?? 0) as int;
    }
    equipoAlfabetico = List.from(widget.equipo)..sort();
  }

  void _modificarHora(String nombre, int cantidad) {
    setState(() {
      horasEditadas[nombre] = (horasEditadas[nombre] ?? 0) + cantidad;
    });
  }

  @override
  Widget build(BuildContext context) {
    String fechaTxt = "${widget.fecha.day}/${widget.fecha.month}/${widget.fecha.year}";

    return Scaffold(
      appBar: AppBar(title: Text('Modificar: $fechaTxt', style: const TextStyle(fontWeight: FontWeight.bold))),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              itemCount: equipoAlfabetico.length,
              itemBuilder: (context, index) {
                String nombre = equipoAlfabetico[index];
                int horas = horasEditadas[nombre]!;

                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
                    child: Row(
                      children: [
                        Expanded(child: Text(nombre, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold))),
                        IconButton(
                          icon: const Icon(Icons.remove_circle_outline, color: Colors.red, size: 32),
                          onPressed: () => _modificarHora(nombre, -1),
                        ),
                        SizedBox(
                          width: 45,
                          child: Center(child: Text('$horas', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)))
                        ),
                        IconButton(
                          icon: const Icon(Icons.add_circle_outline, color: Colors.green, size: 32),
                          onPressed: () => _modificarHora(nombre, 1),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: ElevatedButton.icon(
                icon: const Icon(Icons.save),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFD4AF37),
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 50)
                ),
                onPressed: () async {
                  Map<String, int> cambios = {};
                  horasEditadas.forEach((nombre, nuevaHora) {
                    int horaAntigua = (widget.horasActuales[nombre] ?? 0) as int;
                    int diferencia = nuevaHora - horaAntigua;
                    if (diferencia != 0) {
                      cambios[nombre] = diferencia;
                    }
                  });

                  if (cambios.isNotEmpty) {
                    String idRegistro = DateTime.now().millisecondsSinceEpoch.toString();
                    await FirebaseFirestore.instance.collection('registro_horas').doc(idRegistro).set({
                      'fecha_aplicada': fechaTxt,
                      'timestamp': idRegistro, 
                      'cambios': cambios,
                    });
                  }

                  await FirebaseFirestore.instance.collection('config').doc('bolsa_horas').set(horasEditadas, SetOptions(merge: true));
                  
                  if (context.mounted) {
                    Navigator.pop(context); 
                  }
                },
                label: const Text('GUARDAR', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class PantallaHistorialHoras extends StatelessWidget {
  const PantallaHistorialHoras({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Historial de Cambios', style: TextStyle(fontWeight: FontWeight.bold))),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('registro_horas').orderBy('timestamp', descending: true).snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: Color(0xFF004D40)));
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text("Aún no hay movimientos registrados.", style: TextStyle(fontSize: 16, color: Colors.grey)));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              var doc = snapshot.data!.docs[index];
              Map<String, dynamic> datos = doc.data() as Map<String, dynamic>;
              String fechaAplicada = datos['fecha_aplicada'] ?? 'Desconocida';
              Map<String, dynamic> cambios = datos['cambios'] ?? {};

              List<Widget> lineasCambios = cambios.entries.map((entrada) {
                int variacion = entrada.value as int;
                String signo = variacion > 0 ? "+" : "";
                Color color = variacion > 0 ? Colors.green : Colors.red;

                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(entrada.key, style: const TextStyle(fontSize: 16)),
                      Text("$signo$variacion h", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color)),
                    ],
                  ),
                );
              }).toList();

              return Card(
                margin: const EdgeInsets.only(bottom: 16),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.receipt_long, color: Color(0xFF004D40)),
                          const SizedBox(width: 8),
                          Text("Modificación del: $fechaAplicada", style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: const Color(0xFF004D40))),
                        ],
                      ),
                      const Divider(),
                      ...lineasCambios,
                    ],
                  ),
                ),
              );
            },
          );
        }
      ),
    );
  }
}