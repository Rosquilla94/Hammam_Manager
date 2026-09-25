import 'package:flutter/material.dart';
import 'login_screen.dart';

class TeamSelectionScreen extends StatelessWidget {
  const TeamSelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Usamos el color de fondo clarito que ya tenías
      backgroundColor: const Color(0xFFF4F6F5), 
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Hammam Al-Andalus',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF004D40), // Verde oscuro
                ),
              ),
              const SizedBox(height: 48),
              _buildTeamButton(context, 'Equipo Triana'),
              const SizedBox(height: 16),
              _buildTeamButton(context, 'Equipo Rubén'),
              const SizedBox(height: 16),
              _buildTeamButton(context, 'Equipo Rocío'),
              const SizedBox(height: 40),
              // El botón de admin lo hacemos visualmente distinto
              OutlinedButton(
                onPressed: () {
                  // Añadimos la misma navegación, pero le pasamos el nombre de Administrador
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const LoginScreen(teamName: 'Administrador'),
                    ),
                  );
                },
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  side: const BorderSide(color: Color(0xFF004D40)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Raquel / Miguel',
                  style: TextStyle(fontSize: 16, color: Color(0xFF004D40)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTeamButton(BuildContext context, String teamName) {
  return ElevatedButton(
    onPressed: () {
      // Navegamos a la pantalla de Login pasándole el nombre del equipo
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => LoginScreen(teamName: teamName),
        ),
      );
    },
    style: ElevatedButton.styleFrom(
      backgroundColor: const Color(0xFF004D40),
      foregroundColor: Colors.white,
      padding: const EdgeInsets.symmetric(vertical: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
    ),
    child: Text(
      teamName,
      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
    ),
  );
  }
}