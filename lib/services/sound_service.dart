import 'package:audioplayers/audioplayers.dart';

import 'progress_service.dart';

/// Efeitos sonoros do jogo (gerados por tool/gen_sounds.dart).
///
/// Só o estouro de PERDER VIDA tem som; destruir palavra é silencioso de
/// propósito, para não atropelar a pronúncia do TTS. Como todo áudio aqui,
/// falha em silêncio — o jogo nunca trava por causa de som.
class SoundService {
  static final AudioPlayer _boom = AudioPlayer();
  static final AudioPlayer _error = AudioPlayer();
  static bool _ready = false;

  static Future<void> init() async {
    try {
      await _boom.setReleaseMode(ReleaseMode.stop);
      await _boom.setSource(AssetSource('audio/explosion.wav'));
      await _boom.setVolume(0.85);
      await _error.setReleaseMode(ReleaseMode.stop);
      await _error.setSource(AssetSource('audio/error.wav'));
      await _error.setVolume(0.5); // discreto: toca a cada tecla errada
      _ready = true;
    } catch (_) {
      _ready = false;
    }
  }

  /// Estouro de quando uma palavra alcança o tanque e custa uma vida.
  static void playLifeLost() {
    if (!_ready || !ProgressService.soundOn) return;
    try {
      _boom.stop();
      _boom.resume();
    } catch (_) {}
  }

  /// Buzz curto de tecla errada.
  static void playError() {
    if (!_ready || !ProgressService.soundOn) return;
    try {
      _error.stop();
      _error.resume();
    } catch (_) {}
  }
}
