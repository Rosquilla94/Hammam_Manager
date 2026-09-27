import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:share_plus/share_plus.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

// --- MAGIA: IDENTIFICADOR AUTOMÁTICO DE EQUIPO ---
String get nombreEquipo {
  final email = FirebaseAuth.instance.currentUser?.email ?? '';
  final user = email.split('@')[0]; 
  
  if (user == 'triana' || user == 'triana2') return 'triana';
  if (user == 'ruben' || user == 'ruben2') return 'ruben';
  if (user == 'rocio' || user == 'rocio2') return 'rocio';
  if (user == 'admin' || user == 'admin2') return 'admin';
  
  return 'general';
}

class PantallaEstadisticas extends StatefulWidget {
  const PantallaEstadisticas({super.key});
  @override
  State<PantallaEstadisticas> createState() => _PantallaEstadisticasState();
}

class _PantallaEstadisticasState extends State<PantallaEstadisticas> {
  DateTime mesVisualizado = DateTime.now();
  String filtroActual = 'Roles'; 
  
  // --- NUEVO: MEMORIA DEL FILTRO DE ADMIN ---
  String equipoAdminFiltro = 'triana'; // Por defecto ven a Triana

  void _cambiarMes(int mesesSuma) {
    setState(() {
      mesVisualizado = DateTime(mesVisualizado.year, mesVisualizado.month + mesesSuma, 1);
    });
  }

  bool _cumpleFiltro(String rol) {
    if (filtroActual == 'Montaje') {
      return rol == 'Montaje';
    } else if (filtroActual == 'Roles') {
      return ['A', 'AZ', 'AE', 'ASE'].contains(rol); 
    } else if (filtroActual == 'AA/Despedida') {
      return ['AA', 'Despedida'].contains(rol);
    } else if (filtroActual == 'Servicios Especiales') {
      return ['ZAH', 'BAY 30', 'BAY 45', 'JZ', 'NAF'].contains(rol);
    }
    return false;
  }

  // --- BOTONES PARA EL FILTRO DE ROLES ---
  Widget _chipFiltro(String titulo) {
    bool activo = filtroActual == titulo;
    return ChoiceChip(
      label: Text(titulo, style: TextStyle(fontWeight: FontWeight.bold, color: activo ? Colors.white : Colors.black87)),
      selected: activo,
      selectedColor: const Color(0xFF004D40), 
      backgroundColor: Colors.grey[200], 
      showCheckmark: false,
      onSelected: (bool seleccionado) {
        if (seleccionado) setState(() => filtroActual = titulo);
      },
    );
  }

  // --- NUEVOS BOTONES PARA EL FILTRO DE EQUIPO (SOLO ADMIN) ---
  Widget _chipEquipoAdmin(String id, String titulo) {
    bool activo = equipoAdminFiltro == id;
    return ChoiceChip(
      label: Text(titulo, style: TextStyle(fontWeight: FontWeight.bold, color: activo ? Colors.white : Colors.black87)),
      selected: activo,
      selectedColor: const Color(0xFFD4AF37), // Dorado para diferenciarlo
      backgroundColor: Colors.white,
      showCheckmark: false,
      onSelected: (bool seleccionado) {
        if (seleccionado) setState(() => equipoAdminFiltro = id);
      },
    );
  }

  Future<void> _generarYCompartirPDF(String mesTxt, Map<String, Map<String, int>> stats) async {
    if (stats.isEmpty) {
      Share.share("No hay datos de $filtroActual registrados en $mesTxt.");
      return;
    }
    
    var listaOrdenadaPDF = stats.entries.toList();
    listaOrdenadaPDF.sort((a, b) {
      int totalA = a.value.values.fold(0, (suma, cant) => suma + cant);
      int totalB = b.value.values.fold(0, (suma, cant) => suma + cant);
      return totalB.compareTo(totalA);
    });

    final pdf = pw.Document();
    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        build: (pw.Context context) {
          return [
            pw.Header(
              level: 0,
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text("RESUMEN: ${filtroActual.toUpperCase()}", style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold, color: PdfColors.teal800)),
                  pw.Text(mesTxt, style: pw.TextStyle(fontSize: 16, color: PdfColors.grey700)),
                ]
              )
            ),
            pw.SizedBox(height: 20),
            ...listaOrdenadaPDF.map((entradaPersona) {
              String nombre = entradaPersona.key;
              Map<String, int> roles = entradaPersona.value;

              return pw.Container(
                margin: const pw.EdgeInsets.only(bottom: 20),
                padding: const pw.EdgeInsets.all(10),
                decoration: pw.BoxDecoration(border: pw.Border.all(color: PdfColors.teal200, width: 1), borderRadius: const pw.BorderRadius.all(pw.Radius.circular(5))),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text("👤 $nombre", style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold, color: PdfColors.teal)),
                    pw.Divider(color: PdfColors.grey300),
                    pw.SizedBox(height: 5),
                    ...roles.entries.map((entradaRol) {
                      return pw.Padding(
                        padding: const pw.EdgeInsets.symmetric(vertical: 2),
                        child: pw.Row(
                          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                          children: [
                            pw.Text(entradaRol.key, style: const pw.TextStyle(fontSize: 12)),
                            pw.Text("${entradaRol.value} turnos", style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
                          ]
                        )
                      );
                    }).toList(),
                  ]
                )
              );
            }).toList(),
            pw.SizedBox(height: 30),
            pw.Center(child: pw.Text("Generado automáticamente por HammamManager", style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey)))
          ];
        }
      )
    );

    await Printing.sharePdf(bytes: await pdf.save(), filename: 'Resumen_${filtroActual}_$mesTxt.pdf');
  }

  @override
  Widget build(BuildContext context) {
    List<String> nombresMeses = ['', 'Enero', 'Febrero', 'Marzo', 'Abril', 'Mayo', 'Junio', 'Julio', 'Agosto', 'Septiembre', 'Octubre', 'Noviembre', 'Diciembre'];
    String textoMes = "${nombresMeses[mesVisualizado.month]} ${mesVisualizado.year}";

    // --- DECIDIMOS QUÉ BASE DE DATOS LEER SEGÚN QUIÉN ESTÉ CONECTADO ---
    String coleccionAUsar;
    if (nombreEquipo == 'admin') {
      coleccionAUsar = equipoAdminFiltro == 'triana' ? 'turnos' : 'turnos_$equipoAdminFiltro';
    } else {
      coleccionAUsar = (nombreEquipo == 'triana') ? 'turnos' : 'turnos_$nombreEquipo';
    }

    return FutureBuilder<QuerySnapshot>(
      future: FirebaseFirestore.instance.collection(coleccionAUsar).get(), // Leemos de la colección correcta
      builder: (context, snapshot) {
        
        Map<String, Map<String, int>> statsPorPersona = {};
        int maximosTurnosDeUnaPersona = 0; 

        if (snapshot.hasData) {
          for (var doc in snapshot.data!.docs) {
            List<String> partes = doc.id.split('-');
            if (partes.length == 3 && int.parse(partes[1]) == mesVisualizado.month && int.parse(partes[2]) == mesVisualizado.year) {
              Map<String, dynamic> horas = doc.data() as Map<String, dynamic>;
              
              horas.forEach((hora, roles) {
                if (roles is Map<String, dynamic>) {
                  roles.forEach((rol, asignado) {
                    if (_cumpleFiltro(rol)) {
                      void sumarRol(String persona) {
                        if (!statsPorPersona.containsKey(persona)) statsPorPersona[persona] = {};
                        statsPorPersona[persona]![rol] = (statsPorPersona[persona]![rol] ?? 0) + 1;
                        if (statsPorPersona[persona]![rol]! > maximosTurnosDeUnaPersona) {
                          maximosTurnosDeUnaPersona = statsPorPersona[persona]![rol]!;
                        }
                      }
                      if (asignado is List) {
                        for (var p in asignado) sumarRol(p.toString());
                      } else if (asignado is String && asignado.isNotEmpty) {
                        sumarRol(asignado);
                      }
                    }
                  });
                }
              });
            }
          }
        }

        var listaOrdenada = statsPorPersona.entries.toList();
        listaOrdenada.sort((a, b) {
          int totalA = a.value.values.fold(0, (suma, cantidad) => suma + cantidad);
          int totalB = b.value.values.fold(0, (suma, cantidad) => suma + cantidad);
          return totalB.compareTo(totalA);
        });

        return Scaffold(
          appBar: AppBar(
            title: Text(nombreEquipo == 'admin' ? 'Estadísticas Globales' : 'Gráficas de Equipo', style: const TextStyle(fontWeight: FontWeight.bold)),
            actions: [
              IconButton(
                icon: const Icon(Icons.picture_as_pdf),
                tooltip: 'Exportar a PDF',
                onPressed: () => _generarYCompartirPDF(textoMes.toUpperCase(), statsPorPersona),
              )
            ],
          ),
          backgroundColor: Colors.grey[100], 
          body: Column(
            children: [
              // --- SECCIÓN NUEVA: BARRA DE EQUIPOS (SOLO PARA ADMINS) ---
              if (nombreEquipo == 'admin')
                Container(
                  color: Colors.grey[300],
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.admin_panel_settings, color: Color(0xFF004D40)),
                      const SizedBox(width: 10),
                      _chipEquipoAdmin('triana', 'Triana'),
                      const SizedBox(width: 8),
                      _chipEquipoAdmin('ruben', 'Rubén'),
                      const SizedBox(width: 8),
                      _chipEquipoAdmin('rocio', 'Rocío'),
                    ],
                  ),
                ),

              Container(
                color: Colors.white,
                padding: const EdgeInsets.only(top: 10, left: 20, right: 20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(icon: const Icon(Icons.arrow_back_ios, color: Color(0xFF004D40)), onPressed: () => _cambiarMes(-1)),
                    Text(textoMes.toUpperCase(), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF004D40))),
                    IconButton(icon: const Icon(Icons.arrow_forward_ios, color: Color(0xFF004D40)), onPressed: () => _cambiarMes(1)),
                  ],
                ),
              ),
              
              // --- BARRA DE BOTONES DE ROLES DESLIZABLE ---
              Container(
                color: Colors.white,
                width: double.infinity,
                padding: const EdgeInsets.only(bottom: 10),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      _chipFiltro('Roles'),
                      const SizedBox(width: 8),
                      _chipFiltro('AA/Despedida'), 
                      const SizedBox(width: 8),
                      _chipFiltro('Montaje'),
                      const SizedBox(width: 8),
                      _chipFiltro('Servicios Especiales'),
                    ],
                  ),
                ),
              ),
              const Divider(height: 1),
              
              Expanded(
                child: snapshot.connectionState == ConnectionState.waiting 
                  ? const Center(child: CircularProgressIndicator(color: Color(0xFF004D40)))
                  : listaOrdenada.isEmpty
                    ? Center(child: Text("No hay datos de $filtroActual en este mes.", style: const TextStyle(fontSize: 16, color: Colors.grey)))
                    : ListView(
                        padding: const EdgeInsets.only(left: 16, right: 16, top: 16, bottom: 80),
                        children: listaOrdenada.map((entradaPersona) {
                          String nombre = entradaPersona.key;
                          Map<String, int> rolesDeEstaPersona = entradaPersona.value;
                          int totalTurnos = rolesDeEstaPersona.values.fold(0, (suma, cantidad) => suma + cantidad);

                          return Card(
                            margin: const EdgeInsets.only(bottom: 16),
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      const Icon(Icons.person, color: Color(0xFF004D40)),
                                      const SizedBox(width: 8),
                                      Expanded(child: Text(nombre, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold))),
                                      Text("$totalTurnos turnos", style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.grey)),
                                    ],
                                  ),
                                  const Divider(),
                                  ...rolesDeEstaPersona.entries.map((entradaRol) {
                                    String rol = entradaRol.key;
                                    int cantidad = entradaRol.value;
                                    double porcentaje = maximosTurnosDeUnaPersona > 0 ? cantidad / maximosTurnosDeUnaPersona : 0;

                                    return Padding(
                                      padding: const EdgeInsets.symmetric(vertical: 6.0),
                                      child: Row(
                                        children: [
                                          SizedBox(width: 90, child: Text(rol, style: const TextStyle(fontWeight: FontWeight.bold))),
                                          Expanded(
                                            child: Stack(
                                              children: [
                                                Container(height: 20, decoration: BoxDecoration(color: Colors.grey[200], borderRadius: BorderRadius.circular(10))),
                                                FractionallySizedBox(
                                                  widthFactor: porcentaje,
                                                  child: Container(height: 20, decoration: BoxDecoration(color: const Color(0xFFE0F2F1), borderRadius: BorderRadius.circular(10))),
                                                ),
                                              ],
                                            ),
                                          ),
                                          SizedBox(width: 40, child: Text("  $cantidad", style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF004D40))))
                                        ],
                                      ),
                                    );
                                  }).toList(),
                                ],
                              ),
                            ),
                          );
                        }).toList(),
                      ),
              ),
            ],
          ),
        );
      }
    );
  }
}