import 'package:flutter/material.dart';
import '../models/game_room_model.dart';
import '../repositories/game_repository.dart';

class GameViewModel extends ChangeNotifier {
  final GameRepository _repository = GameRepository();

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  Stream<GameRoom> getRoomStream(String roomId) {
    return _repository.watchRoom(roomId);
  }

  Future<void> sendValidWord({required String roomId, required String nextTurnId}) async {
    _setLoading(true);
    try {
      await _repository.changeTurn(roomId: roomId, nextTurnId: nextTurnId);
    } catch (e) {
      // Manejo silencioso de errores
    } finally {
      _setLoading(false);
    }
  }

  Future<void> handleTurnError({
    required String roomId,
    required String currentTurnId,
    required int currentDanger,
    required String nextTurnId,
  }) async {
    _setLoading(true);
    try {
      await _repository.processTurnError(
        roomId: roomId,
        currentTurnId: currentTurnId,
        currentDanger: currentDanger,
        nextTurnId: nextTurnId,
      );
    } catch (e) {
      // Manejo silencioso de errores
    } finally {
      _setLoading(false);
    }
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
}