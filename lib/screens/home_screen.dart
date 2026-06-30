import 'package:flutter/material.dart';
import 'game_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Selección de jugador'), centerTitle: true),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const GameScreen(miId: 'jugador_1', roomId: 'sala_prueba'),
                  ),
                );
              },
              child: const Text('Jugador 1'),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const GameScreen(miId: 'jugador_2', roomId: 'sala_prueba'),
                  ),
                );
              },
              child: const Text('Jugador 2'),
            ),
          ],
        ),
      ),
    );
  }
}