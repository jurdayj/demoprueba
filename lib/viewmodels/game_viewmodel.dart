import 'dart:async';
import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import '../models/game_room_model.dart';
import '../repositories/game_repository.dart';

class GameViewModel extends ChangeNotifier {
  // 🛠️ Corregido aquí para que compile perfecto:
  final GameRepository _repository = GameRepository();
  final AudioPlayer _audioPlayer = AudioPlayer();

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  // 🎵 PLAYLIST DE MVC2 Y MUTE
  final List<String> _playlist = [
    'audio/mvc2_carnival.mp3',
    'audio/mvc2_factory.mp3',
    'audio/mvc2_swamp.mp3',
  ];
  int _currentSongIndex = 0;
  bool _isMuted = false;
  bool get isMuted => _isMuted;

  // 🔤 ROTACIÓN DE SÍLABAS (6 SEGUNDOS)
  Timer? _rotationTimer;
  String _displayedSequence = "TE";
  String get displayedSequence => _displayedSequence;

  final List<String> _syllablesPool = ["TE", "MA", "CO", "PA", "FI", "RE", "LU", "CA", "BO"];
  int _syllableIndex = 0;

  // Inicia la rotación cada 6 segundos con castigo automático si se agota el tiempo
  void startSyllableRotation({
    required String initialSequence,
    required bool esMiTurno,
    required String roomId,
    required String miId,
    required int miPeligroActual,
  }) {
    _rotationTimer?.cancel();
    _displayedSequence = initialSequence;

    _rotationTimer = Timer.periodic(const Duration(milliseconds: 6000), (timer) async {
      if (esMiTurno && !_isLoading) {
        String siguiente = (miId == "jugador_1") ? "jugador_2" : "jugador_1";

        await handleTurnError(
          roomId: roomId,
          currentTurnId: miId,
          currentDanger: miPeligroActual,
          nextTurnId: siguiente,
        );
      }

      _syllableIndex = (_syllableIndex + 1) % _syllablesPool.length;
      _displayedSequence = _syllablesPool[_syllableIndex];
      notifyListeners();
    });
  }

  void stopSyllableRotation() {
    _rotationTimer?.cancel();
  }

  // CONTROLES DE AUDIO
  Future<void> startBackgroundMusic() async {
    try {
      await _audioPlayer.setReleaseMode(ReleaseMode.release);
      _audioPlayer.onPlayerComplete.listen((event) {
        _playNextSong();
      });
      await _audioPlayer.play(AssetSource(_playlist[_currentSongIndex]));
      if (_isMuted) await _audioPlayer.setVolume(0);
    } catch (e) {
      debugPrint("Error al reproducir audio: $e");
    }
  }

  Future<void> _playNextSong() async {
    try {
      _currentSongIndex = (_currentSongIndex + 1) % _playlist.length;
      await _audioPlayer.play(AssetSource(_playlist[_currentSongIndex]));
      await _audioPlayer.setVolume(_isMuted ? 0 : 1);
    } catch (e) {
      debugPrint("Error al cambiar de canción: $e");
    }
  }

  void toggleMute() {
    _isMuted = !_isMuted;
    _audioPlayer.setVolume(_isMuted ? 0 : 1);
    notifyListeners();
  }

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
      // Silencioso
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
      // Silencioso
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
    _rotationTimer?.cancel();
    _audioPlayer.dispose();
    super.dispose();
  }
}