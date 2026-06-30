import 'package:flutter/material.dart';
import '../models/game_room_model.dart';
import '../viewmodels/game_viewmodel.dart';

class GameScreen extends StatefulWidget {
  final String miId;    // 'jugador_1' o 'jugador_2'
  final String roomId;  // ID dinámico de la sala

  const GameScreen({
    super.key,
    required this.miId,
    required this.roomId,
  });

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  late final TextEditingController palabraController;

  // Instanciamos el ViewModel (Cerebro de la arquitectura MVVM)
  final GameViewModel _viewModel = GameViewModel();

  @override
  void initState() {
    super.initState();
    palabraController = TextEditingController();

    // 🎵 ¡QUE EMPIECE EL REVENTÓN DE MVC2!
    // Esto arranca tu playlist automática en bucle apenas entras a la partida
    _viewModel.startBackgroundMusic();
  }

  @override
  void dispose() {
    palabraController.dispose();
    _viewModel.stopMusic(); // 🔇 Apagamos el reproductor para que la música no siga sonando en los menús
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Sala: ${widget.roomId}'),
        centerTitle: true,
      ),
      body: Center(
        child: StreamBuilder<GameRoom>(
          // MVVM: La vista le pide el Stream de datos al ViewModel, no a Firebase ni al Repo
          stream: _viewModel.getRoomStream(widget.roomId),
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return Padding(
                padding: const EdgeInsets.all(20.0),
                child: Text(
                  "Error en la sala:\n${snapshot.error}",
                  style: const TextStyle(color: Colors.red, fontSize: 18, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
              );
            }

            if (!snapshot.hasData) {
              return const Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 15),
                  Text("Sincronizando partida...", style: TextStyle(color: Colors.grey)),
                ],
              );
            }

            final GameRoom room = snapshot.data!;
            final bool esMiTurno = room.isMyTurn(widget.miId);

            if (room.status == RoomStatus.finished) {
              final bool yoPerdi = (room.loserId == widget.miId);
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
                          ? "El yunque cayó sobre ti. ¡Suerte la próxima!"
                          : "¡Felicidades! Tu oponente fue aplastado por el yunque.",
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 18, color: Colors.grey),
                    ),
                    const SizedBox(height: 40),
                    ElevatedButton(
                      onPressed: () {
                        // Acción al terminar partida
                      },
                      child: const Text('Partida Terminada'),
                    )
                  ],
                ),
              );
            }

            // Usamos ListenableBuilder para escuchar el estado de carga (isLoading) del ViewModel
            return ListenableBuilder(
                listenable: _viewModel,
                builder: (context, _) {
                  return Stack(
                    children: [
                      SingleChildScrollView(
                        padding: const EdgeInsets.all(20.0),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: _PlayerScoreCard(
                                    title: 'Jugador 1 ${widget.miId == 'jugador_1' ? '(Tú)' : ''}',
                                    danger: room.dangerJ1,
                                    isActive: room.currentTurn == 'jugador_1',
                                    color: Colors.green,
                                  ),
                                ),
                                const Padding(
                                  padding: EdgeInsets.symmetric(horizontal: 10),
                                  child: Text('VS', style: TextStyle(fontWeight: FontWeight.w900, color: Colors.grey)),
                                ),
                                Expanded(
                                  child: _PlayerScoreCard(
                                    title: 'Jugador 2 ${widget.miId == 'jugador_2' ? '(Tú)' : ''}',
                                    danger: room.dangerJ2,
                                    isActive: room.currentTurn == 'jugador_2',
                                    color: Colors.deepPurple,
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
                                      room.currentSequence,
                                      style: const TextStyle(fontSize: 34, fontWeight: FontWeight.w900, letterSpacing: 2),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 35),

                            TextField(
                              controller: palabraController,
                              enabled: esMiTurno && !_viewModel.isLoading,
                              textCapitalization: TextCapitalization.characters,
                              decoration: InputDecoration(
                                border: const OutlineInputBorder(),
                                labelText: esMiTurno ? 'Escribe tu palabra aquí' : 'Esperando...',
                              ),
                            ),
                            const SizedBox(height: 30),

                            if (esMiTurno)
                              Column(
                                children: [
                                  ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.green,
                                        foregroundColor: Colors.white
                                    ),
                                    onPressed: _viewModel.isLoading
                                        ? null
                                        : () async {
                                      palabraController.clear();
                                      String siguiente = (widget.miId == "jugador_1") ? "jugador_2" : "jugador_1";

                                      // MVVM: La Vista le dice al ViewModel qué quiere hacer
                                      await _viewModel.sendValidWord(roomId: room.id, nextTurnId: siguiente);
                                    },
                                    child: const Text('Enviar Palabra (Acierto)'),
                                  ),
                                  const SizedBox(height: 12),
                                  OutlinedButton(
                                    style: OutlinedButton.styleFrom(
                                        side: const BorderSide(color: Colors.red, width: 2),
                                        foregroundColor: Colors.red
                                    ),
                                    onPressed: _viewModel.isLoading
                                        ? null
                                        : () async {
                                      palabraController.clear();
                                      String siguiente = (widget.miId == "jugador_1") ? "jugador_2" : "jugador_1";
                                      int peligroActual = (widget.miId == "jugador_1") ? room.dangerJ1 : room.dangerJ2;

                                      // MVVM: Reportamos el error directamente a través del ViewModel
                                      await _viewModel.handleTurnError(
                                        roomId: room.id,
                                        currentTurnId: widget.miId,
                                        currentDanger: peligroActual,
                                        nextTurnId: siguiente,
                                      );
                                    },
                                    child: const Text('Cometer Error (+10%)'),
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
                      ),

                      // Capa transparente que bloquea la pantalla si el ViewModel está cargando algo de Firebase
                      if (_viewModel.isLoading)
                        Container(
                          color: Colors.black12,
                          child: const Center(
                            child: CircularProgressIndicator(),
                          ),
                        ),
                    ],
                  );
                }
            );
          },
        ),
      ),
    );
  }
}

class _PlayerScoreCard extends StatelessWidget {
  final String title;
  final int danger;
  final bool isActive;
  final Color color;

  const _PlayerScoreCard({
    required this.title,
    required this.danger,
    required this.isActive,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isActive ? color.withAlpha(38) : Colors.grey.withAlpha(25),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isActive ? color : Colors.transparent, width: 2),
      ),
      child: Column(
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
          const SizedBox(height: 4),
          Text('$danger% muerte', style: TextStyle(color: danger > 0 ? Colors.orange[900] : Colors.grey, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}