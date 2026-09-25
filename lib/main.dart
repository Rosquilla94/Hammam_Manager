import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'utils/constantes.dart';
import 'screens/pantalla_equipo.dart';
import 'screens/pantalla_bolsa_horas.dart';
import 'screens/pantalla_estadisticas.dart';
import 'screens/pantalla_asignacion.dart';
import 'team_selection.dart';

// --- IMPORTACIONES DE FIREBASE ---
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

// --- ARRANQUE DE LA APP ---
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const HammamApp());
}


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
          seedColor: AppColors.primary,
          primary: AppColors.primary,
          secondary: AppColors.secondary,
        ),
        scaffoldBackgroundColor: AppColors.background,
        useMaterial3: true,
        appBarTheme: const AppBarTheme(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          elevation: 2,
        ),
      ), // <-- Aquí cerramos correctamente el ThemeData con una sola coma
      
      home: const TeamSelectionScreen(), // <-- El home va fuera, al nivel del theme
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

  // Esto creará carpetas separadas, pero respetará el historial de Triana
  String get coleccionTurnos {
    if (nombreEquipo == 'triana' || nombreEquipo == 'admin') {
      return 'turnos'; // Triana (y los admin) leen la base de datos original
    }
    return 'turnos_$nombreEquipo'; // Los demás usan carpetas nuevas (turnos_ruben, etc.)
  }

  // --- NUEVA VARIABLE: ESTADO DEL INTERRUPTOR ---
  bool mostrarHorasImpares = false;

  // --- NUEVA VARIABLE: ESTADO DEL INTERRUPTOR DE COMIDAS ---
  bool mostrarComidas = false;
  
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

  // --- FUNCIÓN PARA CREAR EL TEXTO GRIS DEL RESUMEN ---
  String _generarResumenHora(Map<String, dynamic> diaData, String hora) {
    Map<String, dynamic> datosHora = diaData[hora] ?? {};
    if (datosHora.isEmpty) return "";

    List<String> resumen = [];
    List<String> rolesOrdenados = ['Descanso', 'Montaje', 'Apoyo', 'A', 'AZ', 'AA', 'AE', 'ASE', 'Despedida', 'ZAH', 'BAY 30', 'BAY 45', 'JZ', 'NAF'];

    for (String rol in rolesOrdenados) {
      if (datosHora.containsKey(rol)) {
        var valor = datosHora[rol];
        String textoValor = "";
        
        // Comprobamos si es una lista (varias personas) o un texto solo
        if (valor is List && valor.isNotEmpty) {
          textoValor = valor.join(', ');
        } else if (valor is String && valor.isNotEmpty) {
          textoValor = valor;
        }
        
        if (textoValor.isNotEmpty) {
          resumen.add("$rol: $textoValor");
        }
      }
    }
    return resumen.join('   |   '); // Un separador elegante
  }

  @override
  Widget build(BuildContext context) {

    // --- LÓGICA DE HORAS MOSTRADAS ACTUALIZADA ---
    List<String> horasMostrar = [];

    if (turnoSeleccionado == 'Mañana') {
      horasMostrar.addAll(['09h', '10h']);
      if (mostrarHorasImpares) horasMostrar.add('11h');
      if (mostrarComidas) horasMostrar.add('11:30');
      horasMostrar.add('12h');
      if (mostrarHorasImpares) horasMostrar.add('13h');
      if (mostrarComidas) horasMostrar.add('13:30');
      horasMostrar.add('14h');
      if (mostrarHorasImpares) horasMostrar.add('15h');
      if (mostrarComidas) horasMostrar.add('15:30');
      horasMostrar.add('16h');
    } else {
      // Turno de Tarde
      if (mostrarHorasImpares) horasMostrar.add('17h');
      horasMostrar.add('18h');
      if (mostrarHorasImpares) horasMostrar.add('19h');
      if (mostrarComidas) horasMostrar.add('19:30');
      horasMostrar.add('20h');
      if (mostrarHorasImpares) horasMostrar.add('21h');
      if (mostrarComidas) horasMostrar.add('21:30');
      horasMostrar.add('22h');
      if (mostrarHorasImpares) horasMostrar.add('23h');
      if (mostrarComidas) horasMostrar.add('23:30');
      horasMostrar.add('24h');
    }
    
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            // Image.asset('assets/logo.png', height: 30), 
            // const SizedBox(width: 10),
            Text('Hammam ${nombreEquipo.toUpperCase()}', style: TextStyle(fontWeight: FontWeight.bold)),
          ],
        ), 
        centerTitle: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.schedule, color: Colors.white), 
            tooltip: 'Bolsa de Horas',
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const PantallaBolsaHoras())),
          ),
          IconButton(
            icon: const Icon(Icons.bar_chart, color: Colors.white), 
            tooltip: 'Estadísticas',
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const PantallaEstadisticas())),
          ),
          IconButton(
            icon: const Icon(Icons.people, color: Colors.white), 
            tooltip: 'Gestionar Equipo',
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => PantallaEquipo())),
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
        
        // --- PANEL DE INTERRUPTORES ---
          Container(
            color: Colors.white,
            child: Column(
              children: [
                SwitchListTile(
                  title: const Text('Mostrar horas impares', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF004D40))),
                  value: mostrarHorasImpares,
                  activeColor: const Color(0xFFD4AF37), 
                  onChanged: (bool valor) {
                    setState(() => mostrarHorasImpares = valor);
                  },
                ),
                const Divider(height: 1, indent: 16, endIndent: 16), // Rayita separadora
                SwitchListTile(
                  title: const Text('Mostrar Comida/Descanso', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF004D40))),
                  value: mostrarComidas,
                  activeColor: const Color(0xFFD4AF37), // Dorado también
                  onChanged: (bool valor) {
                    setState(() => mostrarComidas = valor);
                  },
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          // ------------------------------------------
          Expanded(
            // --- ¡AQUÍ ESTÁ EL NUEVO STREAMBUILDER! ---
            // Se conecta a Firebase para escuchar los cambios de este día exacto
            child: StreamBuilder<DocumentSnapshot>(
              stream: FirebaseFirestore.instance
                  .collection(coleccionTurnos) // Usamos la colección específica
                  .doc(fechaTexto.replaceAll('/', '-'))
                  .snapshots(),
              builder: (context, snapshot) {
                
                // Mientras carga, mostramos el circulito
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator(color: Color(0xFF004D40)));
                }

                // ¡AQUÍ CREAMOS LA VARIABLE diaData PARA QUE LA LEA EL RECUADRO GRIS!
                Map<String, dynamic> diaData = (snapshot.data?.data() as Map<String, dynamic>?) ?? {};

                String docId = fechaTexto.replaceAll('/', '-');

                // Cambiamos a un ListView normal para meter cosas antes y después
                return ListView(
                  children: [
                    // --- 1. COMENTARIO SUPERIOR ---
                    CajaComentario(
                      coleccion: coleccionTurnos, // ¡NUEVO!
                      docId: docId, 
                      campo: 'comentarioSuperior', 
                      textoInicial: diaData['comentarioSuperior'] ?? ''
                    ),

                    // --- 2. LISTA DE HORAS ---
                    ...horasMostrar.map((hora) {
                      String subtitulo = 'Roles y Masajes';

                      if (hora == '09h') {
                        subtitulo = 'Montaje';
                      } else if (['11h', '13h', '15h', '17h', '19h', '21h', '23h'].contains(hora)) {
                        subtitulo = 'Apoyo';
                      } else if (hora.contains(':30')) {
                        subtitulo = 'Comida/Descanso';
                      }

                      String resumen = _generarResumenHora(diaData, hora);

                      return Card(
                        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        elevation: 2,
                        clipBehavior: Clip.antiAlias, 
                        child: InkWell(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => PantallaAsignacion(hora: hora, fecha: fechaTexto)), 
                            );
                          },
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              ListTile(
                                title: Text(hora, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF004D40))),
                                subtitle: Text(subtitulo, style: const TextStyle(fontWeight: FontWeight.w500)),
                                trailing: const Icon(Icons.arrow_forward_ios, size: 18, color: Colors.grey),
                              ),
                              if (resumen.isNotEmpty)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                  decoration: BoxDecoration(
                                    color: Colors.grey[100],
                                    border: const Border(top: BorderSide(color: Colors.black12, width: 1)),
                                  ),
                                  child: Text(
                                    resumen,
                                    style: const TextStyle(color: Colors.black54, fontSize: 14, fontStyle: FontStyle.italic, height: 1.4),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),

                    // --- 3. COMENTARIO INFERIOR ---
                    CajaComentario(
                      coleccion: coleccionTurnos, // ¡NUEVO!
                      docId: docId, 
                      campo: 'comentarioSuperior', 
                      textoInicial: diaData['comentarioSuperior'] ?? ''
                    ),
                  ],
                );
              }
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

    // Sacamos los comentarios de la base de datos
    String comentarioSup = datosDeLaFecha['comentarioSuperior'] ?? '';
    String comentarioInf = datosDeLaFecha['comentarioInferior'] ?? '';

    String mensaje = "Organización $fechaTxt\n\n";
    bool hayDatos = false;

    // Si hay un comentario arriba, lo ponemos el primero
    if (comentarioSup.isNotEmpty) {
      hayDatos = true;
      mensaje += " $comentarioSup\n\n";
    }

    String formatear(dynamic valor) {
      if (valor == null) return '';
      if (valor is List) return valor.join(' y ');
      return valor.toString();
    }

    List<String> rolesOrdenados = ['Descanso', 'Montaje', 'Apoyo', 'A', 'AZ', 'AA', 'AE', 'ASE', 'Despedida', 'ZAH', 'BAY 30', 'BAY 45', 'JZ', 'NAF'];
    
    List<String> todasLasHoras = [
      '09h', '10h', '11h', '11:30', '12h', '13h', '13:30', '14h', '15h', '15:30', 
      '16h', '17h', '18h', '19h', '19:30', '20h', '21h', '21:30', '22h', '23h', '23:30', '24h'
    ];

    for (String hora in todasLasHoras) {
      var datos = datosDeLaFecha[hora] ?? {};
      List<String> lineas = [];

      for (String r in rolesOrdenados) {
        String val = formatear(datos[r]);
        if (val.isNotEmpty) {
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

    // Si hay un comentario abajo, lo pegamos al final
    if (comentarioInf.isNotEmpty) {
      hayDatos = true;
      mensaje += " $comentarioInf\n";
    }
    
    if (hayDatos) {
      Share.share(mensaje.trim());
    } else {
      Share.share("No hay turnos asignados para el $fechaTxt.");
    }
  }
}

// --- NUEVO WIDGET PARA LOS COMENTARIOS EN LÍNEA ---
class CajaComentario extends StatefulWidget {
  final String coleccion; // ¡NUEVO!
  final String docId;
  final String campo;
  final String textoInicial;

  const CajaComentario({super.key, required this.coleccion, required this.docId, required this.campo, required this.textoInicial});

  @override
  State<CajaComentario> createState() => _CajaComentarioState();
}

class _CajaComentarioState extends State<CajaComentario> {
  late TextEditingController _controlador;
  bool _modoEdicion = false;

  @override
  void initState() {
    super.initState();
    _controlador = TextEditingController(text: widget.textoInicial);
    if (widget.textoInicial.isNotEmpty) _modoEdicion = true;
  }

  @override
  void didUpdateWidget(CajaComentario oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Si Triana cambia de día en el calendario, reseteamos el cuadro
    if (oldWidget.docId != widget.docId) {
      _controlador.text = widget.textoInicial;
      _modoEdicion = widget.textoInicial.isNotEmpty;
    }
  }

  void _guardarTexto() {
    FirebaseFirestore.instance.collection(widget.coleccion).doc(widget.docId).set({
      widget.campo: _controlador.text
    }, SetOptions(merge: true));
  }

  @override
  Widget build(BuildContext context) {
    if (!_modoEdicion) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: TextButton.icon(
          onPressed: () => setState(() => _modoEdicion = true),
          icon: const Icon(Icons.add, color: Color(0xFF004D40)),
          label: const Text('Añadir comentario', style: TextStyle(color: Color(0xFF004D40), fontWeight: FontWeight.bold, fontSize: 16)),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      child: TextField(
        controller: _controlador,
        maxLines: null, // Crece hacia abajo si escribe un testamento
        decoration: InputDecoration(
          hintText: 'Escribe un comentario...',
          filled: true,
          fillColor: Colors.white,
          border: const OutlineInputBorder(),
          suffixIcon: IconButton(
            icon: const Icon(Icons.check_circle, color: Color(0xFF004D40)),
            tooltip: 'Guardar y cerrar teclado',
            onPressed: () {
              _guardarTexto();
              FocusScope.of(context).unfocus(); // Cierra el teclado del móvil
            },
          ),
        ),
        onChanged: (val) => _guardarTexto(), // Autoguardado mágico con cada letra
      ),
    );
  }
}