import 'package:flutter/material.dart';
import 'package:hammam_manager/team_selection.dart';
import 'package:share_plus/share_plus.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:flutter_localizations/flutter_localizations.dart';


// --- IMPORTACIONES DE FIREBASE ---
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:cloud_firestore/cloud_firestore.dart';


// --- ARRANQUE DE LA APP ---
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const HammamApp());
}

// 🔒 EL PIN DE LA JEFA 
const String pinJefa = "1234";

class HammamApp extends StatelessWidget {
  const HammamApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      
      // --- CONFIGURACIÓN DE IDIOMA (Español y semanas en Lunes) ---
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('es', 'ES'), // Español de España
      ],
      // -----------------------------------------------------------

      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          // ... (el resto de tu código sigue igual)
          seedColor: const Color(0xFF004D40), 
          primary: const Color(0xFF004D40),
          secondary: const Color(0xFFD4AF37), 
        ), 
        scaffoldBackgroundColor: const Color(0xFFF9F6F0), 
        useMaterial3: true,
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF004D40),
          foregroundColor: Colors.white, 
          elevation: 2,
        ),
      ),
      home: const TeamSelectionScreen(),
    );
  }
}

class PantallaTurnos extends StatefulWidget {
  const PantallaTurnos({super.key});
  @override
  State<PantallaTurnos> createState() => _PantallaTurnosState();
}

class _PantallaTurnosState extends State<PantallaTurnos> {
  String turnoSeleccionado = 'Mañana';
  DateTime fechaSeleccionada = DateTime.now(); 

  // --- NUEVA VARIABLE: MEMORIA DEL CANDADO ---
  bool sesionDesbloqueada = false;

  // --- NUEVA VARIABLE: ESTADO DEL INTERRUPTOR ---
  bool mostrarHorasImpares = false;
  
  // ¡Añadidas las 15h aquí!
  final List<String> horasManana = ['09h', '10h', '11h', '12h', '14h', '15h', '16h'];
  final List<String> horasTarde = ['18h', '20h', '22h', '24h'];

  

  String get fechaTexto => "${fechaSeleccionada.day}/${fechaSeleccionada.month}/${fechaSeleccionada.year}";

  Future<void> _seleccionarFecha(BuildContext context) async {
    final DateTime? seleccion = await showDatePicker(
      context: context,
      initialDate: fechaSeleccionada,
      firstDate: DateTime(2024), 
      lastDate: DateTime(2030),  
    );
    if (seleccion != null && seleccion != fechaSeleccionada) {
      setState(() {
        fechaSeleccionada = seleccion;
      });
    }
  }

  // --- EL PORTERO INTELIGENTE ---
  void _navegarProtegido(Widget pantallaDestino) {
    if (sesionDesbloqueada) {
      // Si ya metió el PIN antes, pasa directo sin preguntar
      Navigator.push(context, MaterialPageRoute(builder: (context) => pantallaDestino));
    } else {
      // Si es la primera vez, le pide el PIN
      _mostrarDialogoPin(context, pantallaDestino);
    }
  }

  // --- FUNCIÓN DEL PIN ACTUALIZADA ---
  Future<void> _mostrarDialogoPin(BuildContext context, Widget pantallaDestino) async {
    TextEditingController controladorPin = TextEditingController();
    String? mensajeError;

    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialogo) {
            return AlertDialog(
              title: const Text('Acceso Restringido 🔒', style: TextStyle(fontWeight: FontWeight.bold)),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Introduce el PIN de coordinación:'),
                  const SizedBox(height: 15),
                  TextField(
                    controller: controladorPin,
                    keyboardType: TextInputType.number,
                    obscureText: true,
                    maxLength: 4,
                    decoration: InputDecoration(
                      border: const OutlineInputBorder(),
                      labelText: 'PIN de 4 dígitos',
                      errorText: mensajeError,
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('CANCELAR', style: TextStyle(color: Colors.grey)),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF004D40), foregroundColor: Colors.white),
                  onPressed: () {
                    if (controladorPin.text == pinJefa) {
                      // AQUÍ ESTÁ LA MAGIA: Memorizamos que ya está desbloqueado
                      setState(() {
                        sesionDesbloqueada = true;
                      });
                      Navigator.pop(context); // Cierra el diálogo
                      Navigator.push(context, MaterialPageRoute(builder: (context) => pantallaDestino));
                    } else {
                      setStateDialogo(() {
                        mensajeError = 'PIN incorrecto. Inténtalo de nuevo.';
                        controladorPin.clear();
                      });
                    }
                  },
                  child: const Text('ENTRAR'),
                ),
              ],
            );
          }
        );
      }
    );
  }

  @override
  Widget build(BuildContext context) {
    // --- LÓGICA DE HORAS MOSTRADAS ---
    List<String> horasMostrar = [];

    if (turnoSeleccionado == 'Mañana') {
      horasMostrar = mostrarHorasImpares
          ? ['09h', '10h', '11h', '12h', '13h', '14h', '15h', '16h'] // Mañana completa
          : ['09h', '10h', '11h', '12h', '14h', '16h']; // Mañana sin las impares extra
    } else {
      // Si el turnoSeleccionado es 'Tarde'
      horasMostrar = mostrarHorasImpares
          ? ['17h', '18h', '19h', '20h', '21h', '22h', '23h', '24h'] // Tarde completa
          : ['18h', '20h', '22h', '24h']; // Tarde sin las impares
    }
    
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            // Image.asset('assets/logo.png', height: 30), 
            // const SizedBox(width: 10),
            const Text('Hammam Triana', style: TextStyle(fontWeight: FontWeight.bold)),
          ],
        ), 
        centerTitle: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.schedule, color: Colors.white), 
            tooltip: 'Bolsa de Horas',
            onPressed: () => _navegarProtegido(const PantallaBolsaHoras()), // Llama al portero
          ),
          IconButton(
            icon: const Icon(Icons.bar_chart, color: Colors.white), 
            tooltip: 'Estadísticas',
            onPressed: () => _navegarProtegido(const PantallaEstadisticas()), // Llama al portero
          ),
          IconButton(
            icon: const Icon(Icons.people, color: Colors.white), 
            tooltip: 'Gestionar Equipo',
            onPressed: () => _navegarProtegido(PantallaEquipo()), // Llama al portero
          )
        ],
      ),
      body: Column(
        children: [
          Container(
            color: const Color(0xFFE0F2F1), 
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.calendar_month, color: Color(0xFF004D40)),
                const SizedBox(width: 10),
                Text("Fecha: $fechaTexto", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF004D40))),
                TextButton(
                  onPressed: () => _seleccionarFecha(context),
                  child: const Text('CAMBIAR', style: TextStyle(color: Color(0xFF004D40))),
                )
              ],
            ),
          ),
          Row(children: [
            _botonTurno('Mañana', '🌞'), 
            _botonTurno('Tarde', '🌙'), 
          ]),
        
        // --- NUEVO INTERRUPTOR DE HORAS IMPARES ---
            Container(
              color: Colors.white,
              child: SwitchListTile(
                title: const Text(
                  'Habilitar/Deshabilitar horas impares', 
                  style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF004D40))
                ),
                value: mostrarHorasImpares,
                activeColor: const Color(0xFFD4AF37), // Dorado cuando está encendido
                onChanged: (bool valor) {
                  setState(() {
                    mostrarHorasImpares = valor;
                  });
                },
              ),
            ),
            const Divider(height: 1),
            // ------------------------------------------
          Expanded(
            child: ListView.builder(
              itemCount: horasMostrar.length,
              itemBuilder: (context, index) {
                String hora = horasMostrar[index];
                String subtitulo = 'Roles y Masajes'; // El valor por defecto

                if (hora == '09h') {
                  subtitulo = 'Montaje';
                } else if (['11h', '13h', '15h', '17h', '19h', '21h', '23h'].contains(hora)) {
                  subtitulo = 'Apoyo';
                }

                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: ListTile(
                    leading: const Icon(Icons.access_time, color: Color(0xFF004D40)), 
                    title: Text(hora, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                    subtitle: Text(subtitulo),
                    trailing: const Icon(Icons.edit, color: Color(0xFFD4AF37)), 
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => PantallaAsignacion(hora: hora, fecha: fechaTexto)),
                      );
                    },
                  ),
                );
              },
            ),
          ),
          // --- BOTÓN DE COMPARTIR CORREGIDO CON SAFEAREA Y NUEVO TEXTO ---
          SafeArea( 
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: ElevatedButton.icon( 
                icon: const Icon(Icons.share),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF004D40), 
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 50)
                ),
                onPressed: () => _compartirDiaCompleto(fechaTexto),
                label: const Text('COMPARTIR DÍA', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _botonTurno(String tipo, String icono) {
    bool activo = turnoSeleccionado == tipo;
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: activo ? const Color(0xFF004D40) : Colors.grey[300]),
          onPressed: () => setState(() => turnoSeleccionado = tipo),
          child: Text('$icono $tipo', style: TextStyle(color: activo ? Colors.white : Colors.black87, fontWeight: FontWeight.bold)),
        ),
      ),
    );
  }

  // --- LÓGICA DE COMPARTIR EL DÍA COMPLETO ---
  Future<void> _compartirDiaCompleto(String fechaTxt) async {
    String docId = fechaTxt.replaceAll('/', '-'); 
    DocumentSnapshot doc = await FirebaseFirestore.instance.collection(coleccionTurnos).doc(docId).get();
    Map<String, dynamic> datosDeLaFecha = (doc.data() as Map<String, dynamic>?) ?? {};

    String mensaje = "Organización $fechaTxt\n\n";
    bool hayDatos = false;

    // Función auxiliar para leer tanto Strings solos como Listas múltiples
    String formatear(dynamic valor) {
      if (valor == null) return '';
      if (valor is List) return valor.join(' y '); // Une varios nombres con "y"
      return valor.toString();
    }

    // Añadimos 'ASE' a la lista de orden
    List<String> rolesOrdenados = ['Montaje', 'Apoyo', 'A', 'AZ', 'AA', 'AE', 'ASE', 'Despedida', 'ZAH', 'BAY 30', 'BAY 45', 'JZ', 'NAF'];
    
    List<String> todasLasHoras = [...horasManana, ...horasTarde];

    for (String hora in todasLasHoras) {
      var datos = datosDeLaFecha[hora] ?? {};
      List<String> lineas = [];

      for (String r in rolesOrdenados) {
        String val = formatear(datos[r]);
        if (val.isNotEmpty) {
          // Añadimos 'ASE' para que se formatee sin los dos puntos (como el resto de la planta)
          if (['A', 'AZ', 'AA', 'AE', 'ASE', 'Despedida'].contains(r)) {
            lineas.add("$r $val");
          } else {
            lineas.add("$r: $val");
          }
        }
      }

      if (lineas.isNotEmpty) {
        hayDatos = true;
        mensaje += "$hora -> ${lineas[0]}\n"; 
        for (int i = 1; i < lineas.length; i++) {
          mensaje += "       ${lineas[i]}\n"; 
        }
        mensaje += "\n";
      }
    }
    
    if (hayDatos) {
      Share.share(mensaje.trim());
    } else {
      Share.share("No hay turnos asignados para el $fechaTxt.");
    }
  }
}

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
      // 09h es exclusivo de Montaje
      return [
        const Text('Montaje', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 10),
        _selectorMultiple(context, 'Montaje', diaData, equipoGlobal, docId, hora), 
      ];
    } else if (hora == '11h' || hora == '13h' || hora == '15h' || hora == '17h' || hora == '19h' || hora == '21h' || hora == '23h') {
      // Todas las demás horas impares son de Apoyo
      return [
        const Text('Apoyo', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 10),
        _selectorMultiple(context, 'Apoyo', diaData, equipoGlobal, docId, hora),
      ];
    } else {
      // Las horas pares mantienen tus roles y servicios especiales intactos
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

  // Desplegable tradicional (para 1 sola persona)
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

  // --- EL NUEVO SELECTOR MÚLTIPLE ---
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

// --- PANTALLA DE ESTADÍSTICAS AVANZADA (Ordenada por total de turnos) ---
class PantallaEstadisticas extends StatefulWidget {
  const PantallaEstadisticas({super.key});
  @override
  State<PantallaEstadisticas> createState() => _PantallaEstadisticasState();
}

class _PantallaEstadisticasState extends State<PantallaEstadisticas> {
  DateTime mesVisualizado = DateTime.now();

  void _cambiarMes(int mesesSuma) {
    setState(() {
      mesVisualizado = DateTime(mesVisualizado.year, mesVisualizado.month + mesesSuma, 1);
    });
  }

  Future<void> _generarYCompartirPDF(String mesTxt, Map<String, Map<String, int>> stats) async {
    if (stats.isEmpty) {
      Share.share("No hay datos de roles registrados en $mesTxt.");
      return;
    }
    
    // Para el PDF también los ordenamos
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
                  pw.Text("RESUMEN DE EQUIPO", style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold, color: PdfColors.teal800)),
                  pw.Text(mesTxt, style: pw.TextStyle(fontSize: 18, color: PdfColors.grey700)),
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
                            pw.Text("Rol de ${entradaRol.key}", style: const pw.TextStyle(fontSize: 12)),
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

    await Printing.sharePdf(bytes: await pdf.save(), filename: 'Resumen_Hammam_$mesTxt.pdf');
  }

  @override
  Widget build(BuildContext context) {
    List<String> nombresMeses = ['', 'Enero', 'Febrero', 'Marzo', 'Abril', 'Mayo', 'Junio', 'Julio', 'Agosto', 'Septiembre', 'Octubre', 'Noviembre', 'Diciembre'];
    String textoMes = "${nombresMeses[mesVisualizado.month]} ${mesVisualizado.year}";

    return FutureBuilder<QuerySnapshot>(
      future: FirebaseFirestore.instance.collection('turnos').get(),
      builder: (context, snapshot) {
        
        Map<String, Map<String, int>> statsPorPersona = {};
        int maximosTurnosDeUnaPersona = 0; 

        if (snapshot.hasData) {
          for (var doc in snapshot.data!.docs) {
            List<String> partes = doc.id.split('-');
            if (partes.length == 3 && int.parse(partes[1]) == mesVisualizado.month && int.parse(partes[2]) == mesVisualizado.year) {
              Map<String, dynamic> horas = doc.data() as Map<String, dynamic>;
              horas.forEach((hora, roles) {
                (roles as Map<String, dynamic>).forEach((rol, asignado) {
                  
                if (rol == 'A' || rol == 'AZ') {
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
              });
            }
          }
        }

        // --- LA MAGIA DEL ORDEN DE MAYOR A MENOR ---
        var listaOrdenada = statsPorPersona.entries.toList();
        listaOrdenada.sort((a, b) {
          // Sumamos todas las horas de 'a' y de 'b'
          int totalA = a.value.values.fold(0, (suma, cantidad) => suma + cantidad);
          int totalB = b.value.values.fold(0, (suma, cantidad) => suma + cantidad);
          // Los ordenamos descendente (el mayor arriba)
          return totalB.compareTo(totalA);
        });
        // ------------------------------------------

        return Scaffold(
          appBar: AppBar(
            title: const Text('Gráficas de Equipo', style: TextStyle(fontWeight: FontWeight.bold)),
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
              Container(
                color: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(icon: const Icon(Icons.arrow_back_ios, color: const Color(0xFF004D40)), onPressed: () => _cambiarMes(-1)),
                    Text(textoMes.toUpperCase(), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF004D40))),
                    IconButton(icon: const Icon(Icons.arrow_forward_ios, color: const Color(0xFF004D40)), onPressed: () => _cambiarMes(1)),
                  ],
                ),
              ),
              
              Expanded(
                child: snapshot.connectionState == ConnectionState.waiting 
                  ? const Center(child: CircularProgressIndicator(color: Color(0xFF004D40)))
                  : listaOrdenada.isEmpty
                    ? const Center(child: Text("No hay roles registrados en este mes.", style: TextStyle(fontSize: 16, color: Colors.grey)))
                    : ListView(
                        padding: const EdgeInsets.all(16),
                        children: listaOrdenada.map((entradaPersona) {
                          String nombre = entradaPersona.key;
                          Map<String, int> rolesDeEstaPersona = entradaPersona.value;

                          // Calculamos el total de esa persona para ponerlo al lado del nombre
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
                                      // Añadimos el Total global en la tarjeta
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

// --- PANTALLA DE GESTIÓN DE EQUIPO (Conectada a la nube) ---
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
// =========================================================
// --- NUEVAS PANTALLAS PARA LA BOLSA DE HORAS ---
// =========================================================

class PantallaBolsaHoras extends StatelessWidget {
  const PantallaBolsaHoras({super.key});

  // Función para generar el PDF del estado actual de la Bolsa de Horas
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

              // Ordenar de mayor a menor
              listaHoras.sort((a, b) => (b['horas'] as int).compareTo(a['horas'] as int));

              DateTime hoy = DateTime.now();
              String fechaTxt = "${hoy.day}/${hoy.month}/${hoy.year}";

              return Column(
                children: [
                  // Botones de acciones extra (Historial y PDF)
                  Container(
                    color: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        TextButton.icon(
                          icon: const Icon(Icons.history, color: Color(0xFF004D40)),
                          label: const Text('VER HISTORIAL', style: TextStyle(color: Color(0xFF004D40), fontWeight: FontWeight.bold)),
                          onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const PantallaHistorialHoras())),
                        ),
                        TextButton.icon(
                          icon: const Icon(Icons.picture_as_pdf, color: Color(0xFF004D40)),
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
                  
                  // 1. CALCULAMOS LOS CAMBIOS PARA EL REGISTRO HISTÓRICO
                  Map<String, int> cambios = {};
                  horasEditadas.forEach((nombre, nuevaHora) {
                    int horaAntigua = (widget.horasActuales[nombre] ?? 0) as int;
                    int diferencia = nuevaHora - horaAntigua;
                    if (diferencia != 0) {
                      cambios[nombre] = diferencia;
                    }
                  });

                  // 2. SI HA HABIDO CAMBIOS, GUARDAMOS EL TICKET EN EL HISTORIAL
                  if (cambios.isNotEmpty) {
                    String idRegistro = DateTime.now().millisecondsSinceEpoch.toString();
                    await FirebaseFirestore.instance.collection('registro_horas').doc(idRegistro).set({
                      'fecha_aplicada': fechaTxt,
                      'timestamp': idRegistro, 
                      'cambios': cambios,
                    });
                  }

                  // 3. GUARDAMOS EL NUEVO TOTAL
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

// --- PANTALLA DEL REGISTRO HISTÓRICO INVISIBLE ---
class PantallaHistorialHoras extends StatelessWidget {
  const PantallaHistorialHoras({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Historial de Cambios', style: TextStyle(fontWeight: FontWeight.bold))),
      body: StreamBuilder<QuerySnapshot>(
        // Pedimos los registros ordenados del más nuevo al más antiguo
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

              // Construimos la lista de cambios de este ticket
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
                          Text("Modificación del: $fechaAplicada", style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF004D40))),
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