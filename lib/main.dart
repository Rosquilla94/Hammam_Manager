import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'utils/constantes.dart';
import 'screens/pantalla_equipo.dart';
import 'screens/pantalla_bolsa_horas.dart';
import 'screens/pantalla_estadisticas.dart';
import 'screens/pantalla_asignacion.dart';
import 'screens/pantalla_carga.dart';

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
      
      home: const PantallaCarga(), // <-- El home va fuera, al nivel del theme
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
                    if (controladorPin.text == AppConfig.pinJefa) {
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

  // --- FUNCIÓN PARA CREAR EL TEXTO GRIS DEL RESUMEN ---
  String _generarResumenHora(Map<String, dynamic> diaData, String hora) {
    Map<String, dynamic> datosHora = diaData[hora] ?? {};
    if (datosHora.isEmpty) return "";

    List<String> resumen = [];
    List<String> rolesOrdenados = ['Montaje', 'Apoyo', 'A', 'AZ', 'AA', 'AE', 'ASE', 'Despedida', 'ZAH', 'BAY 30', 'BAY 45', 'JZ', 'NAF'];

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
            // --- ¡AQUÍ ESTÁ EL NUEVO STREAMBUILDER! ---
            // Se conecta a Firebase para escuchar los cambios de este día exacto
            child: StreamBuilder<DocumentSnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('turnos')
                  .doc(fechaTexto.replaceAll('/', '-'))
                  .snapshots(),
              builder: (context, snapshot) {
                
                // Mientras carga, mostramos el circulito
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator(color: Color(0xFF004D40)));
                }

                // ¡AQUÍ CREAMOS LA VARIABLE diaData PARA QUE LA LEA EL RECUADRO GRIS!
                Map<String, dynamic> diaData = (snapshot.data?.data() as Map<String, dynamic>?) ?? {};

                return ListView.builder(
                  itemCount: horasMostrar.length,
                  itemBuilder: (context, index) {
                    String hora = horasMostrar[index];
                    String subtitulo = 'Roles y Masajes';

                    if (hora == '09h') {
                      subtitulo = 'Montaje';
                    } else if (['11h', '13h', '15h', '17h', '19h', '21h', '23h'].contains(hora)) {
                      subtitulo = 'Apoyo';
                    }

                    // Ahora sí, esta función ya sabe quién es diaData
                    String resumen = _generarResumenHora(diaData, hora);

                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      elevation: 2,
                      clipBehavior: Clip.antiAlias, 
                      child: InkWell(
                        onTap: () {
                          Navigator.push(
                            context,
                            // ¡Corregido fechaTxt por fechaTexto!
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
                                  style: const TextStyle(
                                    color: Colors.black54, 
                                    fontSize: 14, 
                                    fontStyle: FontStyle.italic,
                                    height: 1.4, 
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    );
                  },
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
    DocumentSnapshot doc = await FirebaseFirestore.instance.collection('turnos').doc(docId).get();
    Map<String, dynamic> datosDeLaFecha = (doc.data() as Map<String, dynamic>?) ?? {};

    String mensaje = "Organización $fechaTxt\n\n";
    bool hayDatos = false;

    // Función auxiliar para leer tanto Strings solos como Listas múltiples
    String formatear(dynamic valor) {
      if (valor == null) return '';
      if (valor is List) return valor.join(' y '); // Une varios nombres con "y"
      return valor.toString();
    }

    List<String> rolesOrdenados = ['Montaje', 'Apoyo', 'A', 'AZ', 'AA', 'AE', 'ASE', 'Despedida', 'ZAH', 'BAY 30', 'BAY 45', 'JZ', 'NAF'];
    
    // --- LA MAGIA ESTÁ AQUÍ ---
    // Le damos la lista completa de horas de la jornada.
    List<String> todasLasHoras = [
      '09h', '10h', '11h', '12h', '13h', '14h', '15h', 
      '16h', '17h', '18h', '19h', '20h', '21h', '22h', '23h'
    ];

    for (String hora in todasLasHoras) {
      var datos = datosDeLaFecha[hora] ?? {};
      List<String> lineas = [];

      for (String r in rolesOrdenados) {
        String val = formatear(datos[r]);
        if (val.isNotEmpty) {
          // Añadimos 'ASE' para que se formatee sin los dos puntos
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