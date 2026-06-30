import 'firebase_options.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'screens/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Conecta la aplicación con Firebase antes de que se abran las pantallas
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,

      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark, // Fondo oscuro industrial por defecto
        scaffoldBackgroundColor: const Color(0xFF1E1E24), // Gris carbón mate
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFFCE462B),      // Naranja óxido oficial de Rust
          secondary: Color(0xFFDE7959),    // Naranja claro / coral metálico
          surface: Color(0xFF2A2A35),      // Gris acero para las tarjetas (Score Cards)
          error: Color(0xFFE05353),        // Rojo para los errores del yunque
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF111115), // Negro profundo para la barra superior
          foregroundColor: Color(0xFFDE7959), // Texto e íconos en naranja óxido claro
          elevation: 0,
        ),
      ),

      // Iniciamos directo en la selección de jugador para probar rápidamente el juego
      home: const HomeScreen(),
    );
  }
}