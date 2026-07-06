import 'package:flutter_tts/flutter_tts.dart';

import 'progress_service.dart';

/// Pronúncia das palavras em inglês (TTS nativo do sistema).
///
/// Android/iOS usam a voz do aparelho (offline); web usa a SpeechSynthesis do
/// navegador; Windows usa a voz do sistema. Se o dispositivo não tiver voz em
/// inglês, as chamadas falham em silêncio — o jogo nunca trava por causa do som.
class TtsService {
  static final FlutterTts _tts = FlutterTts();
  static bool _ready = false;
  static bool _voiceChosen = false;

  /// Fila de pronúncia: destruir duas palavras em sequência rápida não pode
  /// engolir a segunda — cada uma espera a anterior terminar.
  static final List<String> _queue = [];
  static bool _speaking = false;

  static Future<void> init() async {
    try {
      // speak() só retorna quando a fala termina — é o que permite a fila.
      await _tts.awaitSpeakCompletion(true);
      await _applySettings();
      _ready = true;
      // As vozes carregam de forma assíncrona (principalmente no navegador);
      // reaplica algumas vezes até conseguir uma voz boa de inglês.
      Future.delayed(const Duration(seconds: 1), _applySettings);
      Future.delayed(const Duration(seconds: 3), _applySettings);
      Future.delayed(const Duration(seconds: 8), _applySettings);
    } catch (_) {
      _ready = false;
    }
  }

  static Future<void> _applySettings() async {
    try {
      await _tts.setLanguage('en-US');
      await _tts.setSpeechRate(0.5); // levemente devagar: é para aprender
      await _tts.setVolume(ProgressService.voiceVolume / 100);
      await _tts.setPitch(1.0);
      if (!_voiceChosen) await _pickNaturalFemaleVoice();
    } catch (_) {}
  }

  /// Reaplica o volume da fala após o ajuste no menu.
  static Future<void> applyVolume() async {
    try {
      await _tts.setVolume(ProgressService.voiceVolume / 100);
    } catch (_) {}
  }

  /// Escolhe a voz de inglês mais natural disponível, preferindo femininas.
  /// Cada plataforma tem nomes diferentes, então usa um ranking por pontos.
  static Future<void> _pickNaturalFemaleVoice() async {
    try {
      final raw = await _tts.getVoices;
      if (raw is! List) return;

      Map<String, String>? best;
      var bestScore = -1;
      for (final item in raw) {
        final voice = Map<Object?, Object?>.from(item as Map);
        final name = (voice['name'] ?? '').toString();
        final locale = (voice['locale'] ?? '').toString();
        final n = name.toLowerCase();
        final l = locale.toLowerCase().replaceAll('_', '-');

        final isEnglish = l.startsWith('en-us') ||
            l == 'en' ||
            n.contains('us english') ||
            n.contains('english (united states)');
        if (!isEnglish) continue;

        var score = 1;
        // Vozes femininas naturais conhecidas, por plataforma:
        if (n.contains('google us english')) score += 100; // Chrome desktop
        if (n.contains('samantha')) score += 90; // iOS / macOS
        if (n.contains('aria')) score += 85; // Windows (natural)
        if (n.contains('jenny')) score += 84; // Windows (natural)
        if (n.contains('zira')) score += 80; // Windows (clássica)
        if (n.contains('ava')) score += 78; // iOS premium
        if (n.contains('allison')) score += 76; // iOS
        if (n.contains('female')) score += 60; // Android marca "#female"
        if (n.contains('sfg') || n.contains('tpf')) score += 40; // Google TTS femininas
        if (n.contains('natural') || n.contains('neural')) score += 25;
        if (n.contains('local')) score += 5; // offline é melhor no celular

        if (score > bestScore) {
          bestScore = score;
          best = {'name': name, 'locale': locale};
        }
      }

      if (best != null) {
        await _tts.setVoice(best);
        // Achou uma voz boa (não só "qualquer inglês")? Para de procurar.
        if (bestScore > 1) _voiceChosen = true;
      }
    } catch (_) {}
  }

  /// Enfileira a palavra: fala assim que a anterior terminar, sem pular
  /// nenhuma. A fila é curta (3) para o áudio não atrasar demais do jogo
  /// numa sequência muito rápida — nesse caso a mais antiga cai fora.
  static void speak(String text) {
    if (!_ready || !ProgressService.soundOn) return;
    if (_queue.length >= 3) _queue.removeAt(0);
    _queue.add(text);
    _drain();
  }

  static Future<void> _drain() async {
    if (_speaking) return;
    _speaking = true;
    try {
      while (_queue.isNotEmpty && ProgressService.soundOn) {
        final word = _queue.removeAt(0);
        final Future<dynamic> done = _tts.speak(word);
        // Se a plataforma nunca sinalizar o fim, a fila não pode travar.
        await done.timeout(const Duration(seconds: 6), onTimeout: () {
          _tts.stop();
          return null;
        });
      }
    } catch (_) {
      _queue.clear();
    } finally {
      _speaking = false;
    }
  }
}
