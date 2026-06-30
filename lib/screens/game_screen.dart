import 'package:flutter/material.dart';
import '../models/game_room_model.dart';
import '../viewmodels/game_viewmodel.dart';

class GameScreen extends StatefulWidget {
  final String miId;
  final String roomId;

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
  final GameViewModel _viewModel = GameViewModel();

  @override
  void initState() {
    super.initState();
    palabraController = TextEditingController();
    _viewModel.startBackgroundMusic();
  }

  @override
  void dispose() {
    palabraController.dispose();
    _viewModel.stopMusic();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text('Sala: ${widget.roomId}'),
        centerTitle: true,
        // 🔇 BOTÓN DE MUTE EN LA BARRA SUPERIOR
        actions: [
          ListenableBuilder(
            listenable: _viewModel,
            builder: (context, _) {
              return IconButton(
                icon: Icon(
                  _viewModel.isMuted ? Icons.volume_off : Icons.volume_up,
                  color: theme.colorScheme.secondary,
                ),
                onPressed: () => _viewModel.toggleMute(),
              );
            },
          )
        ],
      ),
      body: Center(
        child: StreamBuilder<GameRoom>(
          stream: _viewModel.getRoomStream(widget.roomId),
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return Padding(
                padding: const EdgeInsets.all(20.0),
                child: Text(
                  "Error en la sala:\n${snapshot.error}",
                  style: TextStyle(color: theme.colorScheme.error, fontSize: 18, fontWeight: FontWeight.bold),
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
            final int miPeligroActual = (widget.miId == "jugador_1") ? room.dangerJ1 : room.dangerJ2;

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
                          color: yoPerdi ? theme.colorScheme.error : Colors.green
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
                        Navigator.pop(context);
                      },
                      child: const Text('Volver al Menú'),
                    )
                  ],
                ),
              );
            }

            // ⏱️ Sincronizamos el temporizador de 6 segundos y el castigo automático de MVVM
            if (_viewModel.displayedSequence == "TE") {
              _viewModel.startSyllableRotation(
                initialSequence: room.currentSequence,
                esMiTurno: esMiTurno,
                roomId: room.id,
                miId: widget.miId,
                miPeligroActual: miPeligroActual,
              );
            }

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
                                    activeColor: theme.colorScheme.primary,
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
                                    activeColor: theme.colorScheme.secondary,
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
                                  color: esMiTurno ? theme.colorScheme.primary : Colors.grey
                              ),
                            ),
                            const SizedBox(height: 25),

                            Container(
                              width: 140,
                              height: 140,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: theme.colorScheme.surface,
                                border: Border.all(
                                    color: esMiTurno ? theme.colorScheme.primary : Colors.grey.shade700,
                                    width: 4
                                ),
                                boxShadow: [
                                  if (esMiTurno)
                                    BoxShadow(
                                      color: theme.colorScheme.primary.withAlpha(50),
                                      blurRadius: 15,
                                      spreadRadius: 2,
                                    )
                                ],
                              ),
                              child: Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Text("Palabra con:", style: TextStyle(color: Colors.grey, fontSize: 13)),
                                    const SizedBox(height: 4),
                                    Text(
                                      _viewModel.displayedSequence,
                                      style: TextStyle(
                                          fontSize: 36,
                                          fontWeight: FontWeight.w900,
                                          color: esMiTurno ? theme.colorScheme.secondary : Colors.white,
                                          letterSpacing: 2
                                      ),
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
                                focusedBorder: OutlineInputBorder(
                                  borderSide: BorderSide(color: theme.colorScheme.primary, width: 2),
                                ),
                                labelText: esMiTurno ? 'Escribe tu palabra aquí' : 'Esperando...',
                                labelStyle: TextStyle(color: esMiTurno ? theme.colorScheme.secondary : Colors.grey),
                              ),
                            ),
                            const SizedBox(height: 30),

                            if (esMiTurno)
                              Column(
                                children: [
                                  ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: theme.colorScheme.primary,
                                      foregroundColor: Colors.white,
                                      minimumSize: const Size.fromHeight(50),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                    ),
                                    onPressed: _viewModel.isLoading
                                        ? null
                                        : () async {
                                      palabraController.clear();
                                      String siguiente = (widget.miId == "jugador_1") ? "jugador_2" : "jugador_1";

                                      await _viewModel.sendValidWord(roomId: room.id, nextTurnId: siguiente);
                                    },
                                    child: const Text('Enviar Palabra (Acierto)', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                                  ),
                                  const SizedBox(height: 14),
                                  OutlinedButton(
                                    style: OutlinedButton.styleFrom(
                                      side: BorderSide(color: theme.colorScheme.error, width: 2),
                                      foregroundColor: theme.colorScheme.error,
                                      minimumSize: const Size.fromHeight(50),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                    ),
                                    onPressed: _viewModel.isLoading
                                        ? null
                                        : () async {
                                      palabraController.clear();
                                      String siguiente = (widget.miId == "jugador_1") ? "jugador_2" : "jugador_1";

                                      await _viewModel.handleTurnError(
                                        roomId: room.id,
                                        currentTurnId: widget.miId,
                                        currentDanger: miPeligroActual,
                                        nextTurnId: siguiente,
                                      );
                                    },
                                    child: const Text('Cometer Error (+10%)', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
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

                      if (_viewModel.isLoading)
                        Container(
                          color: Colors.black45,
                          child: Center(
                            child: CircularProgressIndicator(color: theme.colorScheme.primary),
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
  final Color activeColor;

  const _PlayerScoreCard({
    required this.title,
    required this.danger,
    required this.isActive,
    required this.activeColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isActive ? activeColor.withAlpha(30) : theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isActive ? activeColor : Colors.transparent, width: 2),
      ),
      child: Column(
        children: [
          Text(title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: isActive ? Colors.white : Colors.grey)),
          const SizedBox(height: 6),
          Text(
            '$danger% muerte',
            style: TextStyle(
                color: danger > 40 ? theme.colorScheme.error : (danger > 0 ? theme.colorScheme.secondary : Colors.grey),
                fontWeight: FontWeight.bold
            ),
          ),
        ],
      ),
    );
  }
}