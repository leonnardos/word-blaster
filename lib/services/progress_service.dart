import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../data/word_bank.dart';
import '../game/screen_size.dart';

/// Maestria de uma palavra: o andaime da tradução desaparece conforme o
/// jogador domina (PLANO §1.4).
enum Mastery {
  nova, // 0-2 acertos líquidos: tradução visível
  aprendendo, // 3-5: tradução esmaecida
  dominada; // 6+: sem tradução e +50% de XP
}

/// Estatísticas de uma palavra, usadas na repetição espaçada simplificada
/// (PRD §8): palavras erradas ganham peso e reaparecem mais.
class WordStat {
  int hits;
  int misses;

  WordStat({this.hits = 0, this.misses = 0});

  /// Peso de sorteio: erros aumentam, acertos reduzem aos poucos.
  /// Faixa APERTADA (0.5–3.0, razão máx. 6×): a antiga (0.2–8.0 = 40×)
  /// fazia meia dúzia de palavras erradas monopolizar o jogo enquanto
  /// as dominadas quase nunca apareciam (queixa do usuário).
  double get spawnWeight =>
      (1.0 + misses * 1.0 - hits * 0.1).clamp(0.5, 3.0);

  /// Acertos líquidos: errar a palavra faz a maestria regredir.
  int get masteryScore => hits - misses < 0 ? 0 : hits - misses;

  Mastery get mastery => masteryScore >= 6
      ? Mastery.dominada
      : masteryScore >= 3
          ? Mastery.aprendendo
          : Mastery.nova;

  /// Errou uma palavra OCULTA (dominada): ela volta para "aprendendo" com
  /// exatamente 5 acertos líquidos — o próximo acerto a esconde de novo.
  /// Ajusta hits (não misses) para não inflar o peso de spawn para sempre.
  void regressFromMastered() {
    if (masteryScore > 5) hits = misses + 5;
  }

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
  static const _kMusicVolume = 'music_volume';
  static const _kVoiceVolume = 'voice_volume';
  static const _kMusicOn = 'music_on';
  static const _kShowTranslation = 'show_translation';
  static const _kHiddenMode = 'hidden_mode';
  static const _kNickname = 'nickname';
  static const _kMaxCefr = 'max_cefr';
  static const _kTotalCorrect = 'total_correct_chars';
  static const _kTotalWrong = 'total_wrong_chars';
  static const _kLastPlayDay = 'last_play_day';
  static const _kStreakDays = 'streak_days';

  static late SharedPreferences _prefs;
  static final Map<String, WordStat> _wordStats = {};

  static int bestScore = 0;
  static int totalXp = 0;
  static int totalWordsDestroyed = 0;

  /// Precisão VITALÍCIA (todas as partidas): letras certas e erradas.
  static int totalCorrectChars = 0;
  static int totalWrongChars = 0;

  /// Sequência de DIAS jogados (streak): aversão à perda em ação.
  static String? lastPlayDay;
  static int streakDays = 0;

  /// Precisão vitalícia 0..1 (1 = nunca errou / nunca jogou).
  static double get lifetimeAccuracy =>
      (totalCorrectChars + totalWrongChars) == 0
          ? 1
          : totalCorrectChars / (totalCorrectChars + totalWrongChars);

  /// Quantas palavras o jogador já DOMINOU (maestria 6+ acertos líquidos).
  static int get masteredCount =>
      _wordStats.values.where((s) => s.mastery == Mastery.dominada).length;

  /// Escada de marcos da barra de vocabulário: sempre há um objetivo
  /// alcançável à vista (50 → 100 → 250 → 500 → banco inteiro).
  static const vocabGoals = [50, 100, 250, 500, 1001];

  static int nextVocabGoal(int mastered) {
    for (final goal in vocabGoals) {
      if (mastered < goal) return goal;
    }
    return vocabGoals.last;
  }

  /// Streak do dia: mesma data mantém, dia seguinte soma, lacuna zera.
  /// Pura (testável); [today] no formato yyyy-mm-dd de [dayKey].
  static int nextStreak({
    required String? lastDay,
    required int current,
    required DateTime now,
  }) {
    final today = dayKey(now);
    if (lastDay == today) return current == 0 ? 1 : current;
    final yesterday = dayKey(now.subtract(const Duration(days: 1)));
    return lastDay == yesterday ? current + 1 : 1;
  }

  static String dayKey(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-'
      '${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';

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

  /// Volumes em porcentagem (0-100), ajustáveis no menu.
  static int musicVolume = 40;
  static int voiceVolume = 100;

  /// Trilha sonora ligada/desligada (botão próprio no jogo, independente
  /// do mudo geral e do volume).
  static bool musicOn = true;

  /// Tradução PT-BR embaixo das palavras. Desligar = modo recall ativo
  /// (dá para espiar segurando a palavra — cartão de dicionário).
  static bool showTranslation = true;

  /// Modo estudo: TODAS as palavras vêm ocultas (asteriscos) com a tradução
  /// como dica — treino de recall puro. O bônus ×1.5 continua só para
  /// palavras genuinamente dominadas (6+ acertos).
  static bool hiddenMode = false;

  /// Apelido do jogador no ranking arcade (pré-preenche o próximo envio).
  static String nickname = '';

  /// Escada CEFR acumulativa: treinar palavras ATÉ este nível
  /// ('A1'..'C2'; 'C2' = vocabulário inteiro, o padrão).
  static String maxCefr = 'C2';

  static Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    bestScore = _prefs.getInt(_kBestScore) ?? 0;
    totalXp = _prefs.getInt(_kTotalXp) ?? 0;
    totalWordsDestroyed = _prefs.getInt(_kTotalWords) ?? 0;
    totalCorrectChars = _prefs.getInt(_kTotalCorrect) ?? 0;
    totalWrongChars = _prefs.getInt(_kTotalWrong) ?? 0;
    lastPlayDay = _prefs.getString(_kLastPlayDay);
    streakDays = _prefs.getInt(_kStreakDays) ?? 0;
    // Sequência quebrada desde a última visita? Zera já na abertura,
    // para o menu não exibir uma sequência que não existe mais.
    if (lastPlayDay != null && streakDays > 0) {
      final now = DateTime.now();
      if (lastPlayDay != dayKey(now) &&
          lastPlayDay != dayKey(now.subtract(const Duration(days: 1)))) {
        streakDays = 0;
      }
    }
    difficultyName = _prefs.getString(_kDifficulty) ?? 'beginner';
    // Descarta nomes de tópicos que não existem mais (renomeados em alguma
    // atualização) — um nome fantasma deixaria o sorteio sem palavras.
    final validTopics = runtimeBank.map((c) => c.name).toSet();
    selectedTopics = (_prefs.getStringList(_kTopics) ?? const [])
        .where(validTopics.contains)
        .toSet();

    speedLevel = (_prefs.getInt(_kSpeedLevel) ?? 0).clamp(0, 8);
    soundOn = _prefs.getBool(_kSoundOn) ?? true;
    musicVolume = (_prefs.getInt(_kMusicVolume) ?? 40).clamp(0, 100);
    voiceVolume = (_prefs.getInt(_kVoiceVolume) ?? 100).clamp(0, 100);
    musicOn = _prefs.getBool(_kMusicOn) ?? true;
    showTranslation = _prefs.getBool(_kShowTranslation) ?? true;
    hiddenMode = _prefs.getBool(_kHiddenMode) ?? false;
    nickname = _prefs.getString(_kNickname) ?? '';
    final cefr = _prefs.getString(_kMaxCefr) ?? 'C2';
    maxCefr = cefrOrder.contains(cefr) ? cefr : 'C2';

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

  static Future<void> saveNickname(String nick) async {
    nickname = nick;
    await _prefs.setString(_kNickname, nick);
  }

  static Future<void> saveMaxCefr(String cefr) async {
    maxCefr = cefr;
    await _prefs.setString(_kMaxCefr, cefr);
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

  static Future<void> saveMusicVolume(int volume) async {
    musicVolume = volume.clamp(0, 100);
    await _prefs.setInt(_kMusicVolume, musicVolume);
  }

  static Future<void> saveVoiceVolume(int volume) async {
    voiceVolume = volume.clamp(0, 100);
    await _prefs.setInt(_kVoiceVolume, voiceVolume);
  }

  static Future<void> saveMusicOn(bool on) async {
    musicOn = on;
    await _prefs.setBool(_kMusicOn, on);
  }

  static Future<void> saveShowTranslation(bool show) async {
    showTranslation = show;
    await _prefs.setBool(_kShowTranslation, show);
  }

  static Future<void> saveHiddenMode(bool on) async {
    hiddenMode = on;
    await _prefs.setBool(_kHiddenMode, on);
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

  static Future<void> saveRun({
    required int score,
    required int xp,
    required int words,
    int correct = 0,
    int wrong = 0,
  }) async {
    totalXp += xp;
    totalWordsDestroyed += words;
    totalCorrectChars += correct;
    totalWrongChars += wrong;
    if (score > bestScore) bestScore = score;

    final now = DateTime.now();
    streakDays =
        nextStreak(lastDay: lastPlayDay, current: streakDays, now: now);
    lastPlayDay = dayKey(now);

    await _prefs.setInt(_kBestScore, bestScore);
    await _prefs.setInt(_kTotalXp, totalXp);
    await _prefs.setInt(_kTotalWords, totalWordsDestroyed);
    await _prefs.setInt(_kTotalCorrect, totalCorrectChars);
    await _prefs.setInt(_kTotalWrong, totalWrongChars);
    await _prefs.setString(_kLastPlayDay, lastPlayDay!);
    await _prefs.setInt(_kStreakDays, streakDays);
    await _prefs.setString(
      _kWordStats,
      jsonEncode(_wordStats.map((k, v) => MapEntry(k, v.toJson()))),
    );
  }
}
