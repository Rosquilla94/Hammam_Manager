import 'package:flutter/material.dart';
import 'welcome_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';

class LoginScreen extends StatefulWidget {
  final String teamName; // Aquí guardamos qué equipo se ha seleccionado

  const LoginScreen({super.key, required this.teamName});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  // Estos controladores nos permitirán leer lo que escriba el usuario luego
  final TextEditingController _userController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F5),
      appBar: AppBar(
        title: Text(widget.teamName), // Muestra el nombre del equipo arriba
        backgroundColor: const Color(0xFF004D40),
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Caja de texto para el Usuario
            TextField(
              controller: _userController,
              decoration: InputDecoration(
                labelText: 'Usuario',
                prefixIcon: const Icon(Icons.person),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 24),
            // Caja de texto para la Contraseña
            TextField(
              controller: _passwordController,
              obscureText: true, // Oculta el texto con puntitos
              decoration: InputDecoration(
                labelText: 'Contraseña',
                prefixIcon: const Icon(Icons.lock),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 40),
            // Botón de Entrar
            ElevatedButton(
            onPressed: () async {
                final userText = _userController.text.trim().toLowerCase(); // Lo pasamos a minúsculas por si acaso
                final passwordText = _passwordController.text.trim();

                if (userText.isEmpty || passwordText.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Por favor, rellena usuario y contraseña')),
                  );
                  return;
                }

                // --- 1. NUEVO: CANDADO DE EQUIPOS ---
                String equipoSeleccionado = widget.teamName.toLowerCase();
                bool accesoPermitido = false;
                
                // Comprobamos si el usuario escrito tiene permiso para entrar al botón que ha pulsado
                if (equipoSeleccionado.contains('triana') && (userText == 'triana' || userText == 'carmen')) accesoPermitido = true;
                else if (equipoSeleccionado.contains('rubén') && (userText == 'ruben' || userText == 'monica')) accesoPermitido = true;
                else if (equipoSeleccionado.contains('rocío') && (userText == 'rocio' || userText == 'santi')) accesoPermitido = true;
                else if (equipoSeleccionado.contains('administrador') && (userText == 'admin')) accesoPermitido = true;

                if (!accesoPermitido) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Este usuario no tiene permiso para acceder a este equipo.', style: TextStyle(color: Colors.white)),
                      backgroundColor: Colors.red,
                    ),
                  );
                  return; // Cortamos en seco, no le dejamos intentar entrar
                }
                // ------------------------------------

                final email = userText.contains('@') ? userText : '$userText@hammam.com';

                try {
                  await FirebaseAuth.instance.signInWithEmailAndPassword(
                    email: email,
                    password: passwordText,
                  );

                  if (mounted) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => WelcomeScreen(username: userText),
                      ),
                    );
                  }
                } on FirebaseAuthException catch (e) {
                  // --- ¡NUEVO CHIVATO! ---
                  print("🔥 ERROR DE FIREBASE: ${e.code} - ${e.message}"); 
                  
                  String errorMsg = 'Error al iniciar sesión';
                  if (e.code == 'user-not-found' || e.code == 'invalid-email' || e.code == 'invalid-credential') {
                    errorMsg = 'Usuario o contraseña incorrectos';
                  } 
                  
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(errorMsg, style: const TextStyle(color: Colors.white)),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                } catch (e) {
                  // --- ¡NUEVO CHIVATO! ---
                  print("🔥 ERROR DESCONOCIDO: $e"); 
                  
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Error interno al iniciar sesión', style: TextStyle(color: Colors.white)),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF004D40),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                minimumSize: const Size(double.infinity, 50), // Ancho completo
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Entrar',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }
}