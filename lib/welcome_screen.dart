import 'package:flutter/material.dart';
import 'main.dart'; // Importamos PantallaTurnos
// TODO: Aquí tendrás que importar el archivo de tu pantalla principal de turnos
// import 'turnos_screen.dart'; 

class WelcomeScreen extends StatefulWidget {
  final String username; // Recibimos el nombre del usuario

  const WelcomeScreen({super.key, required this.username});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  @override
  void initState() {
    super.initState();
    _navigateToHome();
  }

  // Función que espera 2 segundos y salta a la aplicación principal
  // Función que espera 2 segundos y salta a la aplicación principal
  void _navigateToHome() async {
    await Future.delayed(const Duration(seconds: 2));
    if (!mounted) return;
    
    // Navegamos y eliminamos todas las pantallas anteriores (para que no pueda volver al Login con la flecha atrás)
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const PantallaTurnos()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF004D40), // Fondo verde corporativo
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              // Usamos el nombre que han escrito en el login
              'Bienvenid@\n${widget.username}', 
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 40),
            const Text(
              'Hammam Al Ándalus',
              style: TextStyle(
                fontSize: 20,
                fontStyle: FontStyle.italic,
                color: Colors.white70,
              ),
            ),
            const SizedBox(height: 60),
            const CircularProgressIndicator(
              color: Colors.white, // Una ruedita de carga pequeña
            ),
          ],
        ),
      ),
    );
  }
}