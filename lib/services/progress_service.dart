import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../data/word_bank.dart';
import '../game/screen_size.dart';

/// Estatísticas de uma palavra, usadas na repetição espaçada simplificada
/// (PRD §8): palavras erradas ganham peso e reaparecem mais.
class WordStat {
  int hits;
  int misses;

  WordStat({this.hits = 0, this.misses = 0});

  /// Peso de sorteio: erros aumentam bastante, acertos reduzem aos poucos.
  double get spawnWeight =>
      (1.0 + misses * 2.0 - hits * 0.15).clamp(0.2, 8.0);

  Map<String, dynamic> toJson() => {'h': hits, 'm': misses};

  factory WordStat.fromJson(Map<String, dynamic> json) =>
      WordStat(hits: (json['h'] ?? 0) as int, misses: (json['m'] ?? 0) as int);
}

/// Persistência local (offline-first). Backend entra na fase 2.
class ProgressService {
  static const _kBestScore = 'best_score';
  static const _kTotalXp = 'total_xp';
  static const _kTotalWords = 'total_words';
  static const _kWordStats = 'word_stats';
  static const _kDifficulty = 'difficulty';
  static const _kTopics = 'topics';
  static const _kScreenSize = 'screen_size';
  static const _kSpeedLevel = 'speed_level';
  static const _kSoundOn = 'sound_on';

  static late SharedPreferences _prefs;
  static final Map<String, WordStat> _wordStats = {};

  static int bestScore = 0;
  static int totalXp = 0;
  static int totalWordsDestroyed = 0;

  /// Nome do [Difficulty] escolhido na tela inicial (persistido entre sessões).
  static String difficultyName = 'beginner';

  /// Tópicos escolhidos para treinar (nomes de [WordCategory]).
  /// Vazio = todos os tópicos.
  static Set<String> selectedTopics = {};

  /// Velocidade escolhida no jogo: 0 = automática (acelera a cada nível),
  /// 1-8 = ritmo travado nesse nível, para iniciante não ser atropelado.
  static int speedLevel = 0;

  /// Som geral (efeitos + pronúncia). Desligável pelo botão no jogo.
  static bool soundOn = true;

  static Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    bestScore = _prefs.getInt(_kBestScore) ?? 0;
    totalXp = _prefs.getInt(_kTotalXp) ?? 0;
    totalWordsDestroyed = _prefs.getInt(_kTotalWords) ?? 0;
    difficultyName = _prefs.getString(_kDifficulty) ?? 'beginner';
    // Descarta nomes de tópicos que não existem mais (renomeados em alguma
    // atualização) — um nome fantasma deixaria o sorteio sem palavras.
    final validTopics = wordBank.map((c) => c.name).toSet();
    selectedTopics = (_prefs.getStringList(_kTopics) ?? const [])
        .where(validTopics.contains)
        .toSet();

    speedLevel = (_prefs.getInt(_kSpeedLevel) ?? 0).clamp(0, 8);
    soundOn = _prefs.getBool(_kSoundOn) ?? true;

    // 'full' persistido de versões antigas cai no padrão (medium).
    final sizeName = _prefs.getString(_kScreenSize) ?? ScreenSize.medium.name;
    screenSizeNotifier.value = ScreenSize.values.firstWhere(
      (s) => s.name == sizeName,
      orElse: () => ScreenSize.medium,
    );

    final raw = _prefs.getString(_kWordStats);
    if (raw != null) {
      final decoded = jsonDecode(raw) as Map<String, dynamic>;
      decoded.forEach((word, stat) {
        _wordStats[word] = WordStat.fromJson(stat as Map<String, dynamic>);
      });
    }
  }

  static WordStat statFor(String word) =>
      _wordStats.putIfAbsent(word, () => WordStat());

  static Future<void> saveDifficulty(String name) async {
    difficultyName = name;
    await _prefs.setString(_kDifficulty, name);
  }

  static Future<void> saveTopics(Set<String> topics) async {
    selectedTopics = topics;
    await _prefs.setStringList(_kTopics, topics.toList()..sort());
  }

  static Future<void> saveScreenSize(ScreenSize size) async {
    screenSizeNotifier.value = size;
    await _prefs.setString(_kScreenSize, size.name);
  }

  static Future<void> saveSpeedLevel(int level) async {
    speedLevel = level.clamp(0, 8);
    await _prefs.setInt(_kSpeedLevel, speedLevel);
  }

  static Future<void> saveSoundOn(bool on) async {
    soundOn = on;
    await _prefs.setBool(_kSoundOn, on);
  }

  static void recordHit(String word) => statFor(word).hits++;

  static void recordMiss(String word) => statFor(word).misses++;

  /// Palavras com mais erros, para a tela de fim de jogo ("revise estas").
  static List<String> hardestWords({int limit = 3}) {
    final entries = _wordStats.entries
        .where((e) => e.value.misses > 0)
        .toList()
      ..sort((a, b) => b.value.misses.compareTo(a.value.misses));
    return entries.take(limit).map((e) => e.key).toList();
  }

  static Future<void> saveRun({required int score, required int xp, required int words}) async {
    totalXp += xp;
    totalWordsDestroyed += words;
    if (score > bestScore) bestScore = score;

    await _prefs.setInt(_kBestScore, bestScore);
    await _prefs.setInt(_kTotalXp, totalXp);
    await _prefs.setInt(_kTotalWords, totalWordsDestroyed);
    await _prefs.setString(
      _kWordStats,
      jsonEncode(_wordStats.map((k, v) => MapEntry(k, v.toJson()))),
    );
  }
}
