import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:math'; //Librería para números al azar

//Usa StatefulWidget para controlar el texto escrito sin perder datos
class GameScreen extends StatefulWidget {
  final String miId; //Guarda si es el jugador 1 o el jugador 2

  const GameScreen({super.key, required this.miId});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  late final TextEditingController palabraController;

  @override
  void initState() {
    super.initState();
    palabraController = TextEditingController();
  }

  @override
  void dispose() {
    //Limpiamos el control de texto de la memoria al salir de la pantalla
    palabraController.dispose();
    super.dispose();
  }

  //Cambia el turno del jugador actual en la base de datos
  void cambiarTurno(String siguienteTurno) {
    FirebaseFirestore.instance
        .collection('partidas')
        .doc('sala_prueba')
        .update({'turno_de': siguienteTurno});
  }

  //Suma 10% de peligro y calcula al azar si el jugador queda eliminado
  void registrarError(String jugadorClave, int riesgoActual, String siguienteTurno) {
    int nuevoRiesgo = riesgoActual + 10;

    int dado = Random().nextInt(100);

    bool esMuerteEfectiva = (dado < nuevoRiesgo);

    if (esMuerteEfectiva) {
      FirebaseFirestore.instance
          .collection('partidas')
          .doc('sala_prueba')
          .update({
        jugadorClave: nuevoRiesgo,
        'estado': 'finalizado',
        'perdedor': widget.miId,
      });
    } else {
      FirebaseFirestore.instance
          .collection('partidas')
          .doc('sala_prueba')
          .update({
        jugadorClave: nuevoRiesgo,
        'turno_de': siguienteTurno,
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sala de juego'),
        centerTitle: true,
      ),
      body: Center(
        child: StreamBuilder<DocumentSnapshot>(
          stream: FirebaseFirestore.instance.collection('partidas').doc('sala_prueba').snapshots(),
          builder: (context, snapshot) {

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

            var datos = snapshot.data!.data() as Map<String, dynamic>;
            String estadoPartida = datos['estado'] ?? 'activa';
            String perdedor = datos['perdedor'] ?? '';

            //Muestra la pantalla de victoria o derrota si la partida terminó
            if (estadoPartida == 'finalizado') {
              bool yoPerdi = (perdedor == widget.miId);
              return Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      yoPerdi ? "❌ ¡ELIMINADO! ❌" : "👑 ¡VICTORIA! 👑",
                      style: TextStyle(
                          fontSize: 34,
                          fontWeight: FontWeight.bold,
                          color: yoPerdi ? Colors.red : Colors.green
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      yoPerdi
                          ? "Tu porcentaje de riesgo te eliminó"
                          : "¡Felicidades! Tu oponente perdió debido a su porcentaje de riesgo",
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 18, color: Colors.grey, fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(height: 40),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                        minimumSize: const Size(220, 48),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      onPressed: () {
                        FirebaseFirestore.instance.collection('partidas').doc('sala_prueba').set({
                          'turno_de': 'jugador_1',
                          'peligro_j1': 0,
                          'peligro_j2': 0,
                          'secuencia': 'TE',
                          'estado': 'activa',
                          'perdedor': ''
                        });
                      },
                      child: const Text('Reiniciar sala de juego', style: TextStyle(fontSize: 16)),
                    )
                  ],
                ),
              );
            }

            String turnoDe = datos['turno_de'] ?? '';
            bool esMiTurno = (turnoDe == widget.miId);

            String secuenciaLetras = datos['secuencia'] ?? 'TE';
            int peligroJ1 = datos['peligro_j1'] ?? 0;
            int peligroJ2 = datos['peligro_j2'] ?? 0;

            return SingleChildScrollView(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                children: [

                  //Tarjetas para ver los porcentajes de ambos jugadores en tiempo real
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: turnoDe == 'jugador_1' ? Colors.green.withValues(alpha: 0.15) : Colors.grey.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: turnoDe == 'jugador_1' ? Colors.green : Colors.transparent, width: 2),
                          ),
                          child: Column(
                            children: [
                              Text('Jugador 1 ${widget.miId == 'jugador_1' ? '(Tú)' : ''}',
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                              const SizedBox(height: 4),
                              Text('$peligroJ1% muerte',
                                  style: TextStyle(color: peligroJ1 > 0 ? Colors.orange[900] : Colors.grey, fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ),
                      ),

                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 10),
                        child: Text('VS', style: TextStyle(fontWeight: FontWeight.w900, color: Colors.grey)),
                      ),

                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: turnoDe == 'jugador_2' ? Colors.deepPurple.withValues(alpha: 0.15) : Colors.grey.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: turnoDe == 'jugador_2' ? Colors.deepPurple : Colors.transparent, width: 2),
                          ),
                          child: Column(
                            children: [
                              Text('Jugador 2 ${widget.miId == 'jugador_2' ? '(Tú)' : ''}',
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                              const SizedBox(height: 4),
                              Text('$peligroJ2% muerte',
                                  style: TextStyle(color: peligroJ2 > 0 ? Colors.orange[900] : Colors.grey, fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 40),

                  Text(
                    esMiTurno ? "¡ES TU TURNO! 💣" : "Espera a tu rival... ⏳",
                    style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: esMiTurno ? Colors.green : Colors.red
                    ),
                  ),
                  const SizedBox(height: 25),

                  Container(
                    width: 140,
                    height: 140,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: esMiTurno ? Colors.green : Colors.grey, width: 4),
                    ),
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text("Palabra con:", style: TextStyle(color: Colors.grey, fontSize: 13)),
                          Text(
                            secuenciaLetras,
                            style: const TextStyle(fontSize: 34, fontWeight: FontWeight.w900, letterSpacing: 2),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 35),

                  TextField(
                    controller: palabraController,
                    enabled: esMiTurno,
                    textCapitalization: TextCapitalization.characters,
                    decoration: InputDecoration(
                      border: const OutlineInputBorder(),
                      labelText: esMiTurno ? 'Escribe tu palabra aquí' : 'Esperando...',
                      hintText: 'Ej. TENEDOR',
                      prefixIcon: const Icon(Icons.abc),
                    ),
                  ),
                  const SizedBox(height: 30),

                  //Botones para simular jugadas durante la exposición de la demo
                  if (esMiTurno)
                    Column(
                      children: [
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            minimumSize: const Size(220, 45),
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                          ),
                          onPressed: () {
                            palabraController.clear();
                            String siguiente = (widget.miId == "jugador_1") ? "jugador_2" : "jugador_1";
                            cambiarTurno(siguiente);
                          },
                          child: const Text('Enviar Palabra (Acierto)'),
                        ),
                        const SizedBox(height: 12),

                        OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            minimumSize: const Size(220, 45),
                            side: const BorderSide(color: Colors.red, width: 2),
                            foregroundColor: Colors.red,
                          ),
                          onPressed: () {
                            palabraController.clear();
                            String jugadorClave = (widget.miId == "jugador_1") ? 'peligro_j1' : 'peligro_j2';
                            int riesgoActual = (widget.miId == "jugador_1") ? peligroJ1 : peligroJ2;
                            String siguiendo = (widget.miId == "jugador_1") ? "jugador_2" : "jugador_1";

                            registrarError(jugadorClave, riesgoActual, siguiendo);
                          },
                          child: const Text('Cometer Error (+10%)', style: TextStyle(fontWeight: FontWeight.bold)),
                        ),
                      ],
                    )
                  else
                    const Text(
                      "El oponente está pensando su palabra",
                      style: TextStyle(color: Colors.grey, fontStyle: FontStyle.italic),
                    ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}