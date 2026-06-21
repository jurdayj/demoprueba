import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: DemoTurnosScreen(),
    );
  }
}

class DemoTurnosScreen extends StatelessWidget {
  const DemoTurnosScreen({super.key});

  void cambiarTurno(String siguienteTurno) {
    FirebaseFirestore.instance
        .collection('partidas')
        .doc('sala_prueba')
        .update({'turno_de': siguienteTurno});
  }

  @override
  Widget build(BuildContext context) {
    String miId = "jugador_2";

    return Scaffold(
      appBar: AppBar(title: const Text('Demo de Turnos 1v1')),
      body: Center(
        child: StreamBuilder<DocumentSnapshot>(
          stream: FirebaseFirestore.instance.collection('partidas').doc('sala_prueba').snapshots(),
          builder: (context, snapshot) {
            // 1. Si Firebase rebota la conexión, aquí nos enteraremos al segundo
            if (snapshot.hasError) {
              return Padding(
                padding: const EdgeInsets.all(20.0),
                child: Text(
                  "Error detectado:\n${snapshot.error}",
                  style: const TextStyle(color: Colors.red, fontSize: 18, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
              );
            }

            // 2. Si todavía está conectándose o el documento no responde, muestra el puntito
            if (!snapshot.hasData || !snapshot.data!.exists) {
              return const Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 15),
                  Text("Conectando con Firestore...", style: TextStyle(color: Colors.grey)),
                ],
              );
            }

            // 3. Si todo está bien, extrae el turno
            String turnoDe = snapshot.data!['turno_de'];
            bool esMiTurno = (turnoDe == miId);

            return Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  esMiTurno ? "¡ES TU TURNO! 💣" : "Espera a tu rival... ⏳",
                  style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: esMiTurno ? Colors.green : Colors.red
                  ),
                ),
                const SizedBox(height: 30),
                ElevatedButton(
                  onPressed: esMiTurno ? () {
                    String siguiente = (miId == "jugador_1") ? "jugador_2" : "jugador_1";
                    cambiarTurno(siguiente);
                  } : null,
                  child: const Text('Terminar Turno'),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}