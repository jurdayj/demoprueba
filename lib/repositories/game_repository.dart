import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/game_room_model.dart';

class GameRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Stream<GameRoom> watchRoom(String roomId) {
    return _firestore
        .collection('partidas')
        .doc(roomId)
        .snapshots()
        .map((snapshot) {
      if (!snapshot.exists || snapshot.data() == null) {
        throw Exception("La sala no existe");
      }
      return GameRoom.fromFirestore(snapshot.data()!, snapshot.id);
    });
  }

  Future<void> changeTurn({required String roomId, required String nextTurnId}) async {
    await _firestore.collection('partidas').doc(roomId).update({
      'turno_de': nextTurnId,
    });
  }

  Future<void> processTurnError({
    required String roomId,
    required String currentTurnId,
    required int currentDanger,
    required String nextTurnId,
  }) async {
    final int newDanger = currentDanger + 10;
    final int diceRoll = Random().nextInt(100);
    final bool isInstantDeath = diceRoll < newDanger;

    final String dangerField = currentTurnId == 'jugador_1' ? 'peligro_j1' : 'peligro_j2';

    if (isInstantDeath) {
      await _firestore.collection('partidas').doc(roomId).update({
        dangerField: newDanger,
        'estado': 'finalizado',
        'perdedor': currentTurnId,
      });
    } else {
      await _firestore.collection('partidas').doc(roomId).update({
        dangerField: newDanger,
        'turno_de': nextTurnId,
      });
    }
  }

  Future<void> resetRoom(String roomId) async {
    await _firestore.collection('partidas').doc(roomId).set({
      'turno_de': 'jugador_1',
      'peligro_j1': 0,
      'peligro_j2': 0,
      'secuencia': 'TE',
      'estado': 'activa',
      'perdedor': ''
    });
  }
}