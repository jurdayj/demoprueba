enum RoomStatus { active, finished }

class GameRoom {
  final String id;
  final String currentTurn;
  final int dangerJ1;
  final int dangerJ2;
  final String currentSequence;
  final RoomStatus status;
  final String loserId;

  GameRoom({
    required this.id,
    required this.currentTurn,
    required this.dangerJ1,
    required this.dangerJ2,
    required this.currentSequence,
    required this.status,
    required this.loserId,
  });

  factory GameRoom.fromFirestore(Map<String, dynamic> data, String documentId) {
    return GameRoom(
      id: documentId,
      currentTurn: data['turno_de'] ?? 'jugador_1',
      dangerJ1: data['peligro_j1'] ?? 0,
      dangerJ2: data['peligro_j2'] ?? 0,
      currentSequence: data['secuencia'] ?? 'TE',
      status: data['estado'] == 'finalizado' ? RoomStatus.finished : RoomStatus.active,
      loserId: data['perdedor'] ?? '',
    );
  }

  bool isMyTurn(String myId) => currentTurn == myId;
}