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
  static final AudioPlayer _music = AudioPlayer();
  static bool _ready = false;
  static bool _musicLoaded = false;

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
    try {
      await _music.setReleaseMode(ReleaseMode.loop);
      // Trilha sintetizada (tool/gen_sounds.dart) — discreta de propósito;
      // trilhas externas testadas ficavam altas demais e atrapalhavam.
      await _music.setSource(AssetSource('audio/war_theme.wav'));
      _musicLoaded = true;
    } catch (_) {
      _musicLoaded = false;
    }
  }

  /// A trilha toca SÓ com o jogo rodando de verdade (pedido do usuário):
  /// menu, pause, cartão de dicionário e game over ficam em silêncio.
  static bool _inGameplay = false;

  /// Liga/desliga o "portão" de gameplay e aplica na hora.
  static void setGameplay(bool active) {
    _inGameplay = active;
    playMusic();
  }

  /// Toca (ou retoma) a trilha de guerra respeitando o portão de gameplay,
  /// volume e mudo. No navegador o autoplay é bloqueado até o primeiro
  /// gesto — o toque em JOGAR já conta como gesto, então destrava.
  static Future<void> playMusic() async {
    if (!_musicLoaded) return;
    try {
      if (!_inGameplay ||
          !ProgressService.soundOn ||
          !ProgressService.musicOn ||
          ProgressService.musicVolume == 0) {
        await _music.pause();
        return;
      }
      await _music.setVolume(ProgressService.musicVolume / 100 * 0.9);
      await _music.resume();
    } catch (_) {}
  }

  /// Reaplica o estado da música após mudar volume ou o botão de mudo.
  static void syncMusic() => playMusic();

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
