import 'package:flutter/material.dart';
import '../utils/constantes.dart'; // Importamos tus colores
import '../main.dart'; // Importa la pantalla a la que vamos a ir (ajusta el nombre si es distinto)

class PantallaCarga extends StatefulWidget {
  const PantallaCarga({super.key});

  @override
  State<PantallaCarga> createState() => _PantallaCargaState();
}

class _PantallaCargaState extends State<PantallaCarga> {
  @override
  void initState() {
    super.initState();
    _iniciarApp();
  }

  // --- EL TEMPORIZADOR MAGNÉTICO ---
  Future<void> _iniciarApp() async {
    // Esperamos 2.5 segundos (puedes ajustar el tiempo)
    await Future.delayed(const Duration(milliseconds: 2500));
    
    // Si la pantalla sigue montada, saltamos a la app principal
    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const PantallaTurnos()), // <-- Sustituye PantallaTurnos por el nombre exacto de tu clase principal
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF9EDAD6), // El fondo verde oscuro elegante
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Aquí puedes poner una imagen si la tienes en tus assets: Image.asset('assets/logo.png', width: 150)
            Image.asset(
              'assets/logo.png', // La ruta de tu imagen
              width: 360, // Puedes cambiar este número para hacerlo más grande o pequeño
            ),
            const SizedBox(height: 20),
            const SizedBox(height: 40),
            // El circulito de carga dorado
            const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.secondary),
            ),
          ],
        ),
      ),
    );
  }
}