import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import '../models/game_room_model.dart';
import '../repositories/game_repository.dart';

class GameViewModel extends ChangeNotifier {
  final GameRepository _repository = GameRepository();
  final AudioPlayer _audioPlayer = AudioPlayer();

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  // 🎵 TU PLAYLIST REAL DE MARVEL VS CAPCOM 2
  final List<String> _playlist = [
    'audio/mvc2_carnival.mp3',
    'audio/mvc2_factory.mp3',
    'audio/mvc2_swamp.mp3',
  ];

  int _currentSongIndex = 0;

  // 🕹️ INICIAR LA MÚSICA EN CADENA AUTOMÁTICA
  Future<void> startBackgroundMusic() async {
    try {
      // Configuramos para que libere la canción al terminar y permita saltar a la otra
      await _audioPlayer.setReleaseMode(ReleaseMode.release);

      // Creamos el "oído" que escucha cuando termina un tema para poner el siguiente
      _audioPlayer.onPlayerComplete.listen((event) {
        _playNextSong();
      });

      // Arrancamos con el primer temazo de la lista
      await _audioPlayer.play(AssetSource(_playlist[_currentSongIndex]));
    } catch (e) {
      debugPrint("Error al reproducir audio: $e");
    }
  }

  // 🔄 FUNCIÓN INTERNA PARA PASAR AL SIGUIENTE TEMA
  Future<void> _playNextSong() async {
    try {
      // Avanza en la lista, si llega al final vuelve a empezar desde 0
      _currentSongIndex = (_currentSongIndex + 1) % _playlist.length;
      await _audioPlayer.play(AssetSource(_playlist[_currentSongIndex]));
    } catch (e) {
      debugPrint("Error al cambiar de canción: $e");
    }
  }

  // 🔇 APAGAR TODO AL SALIR DE LA PARTIDA
  Future<void> stopMusic() async {
    try {
      await _audioPlayer.stop();
    } catch (e) {
      debugPrint("Error al detener audio: $e");
    }
  }

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

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }
}