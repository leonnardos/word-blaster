import 'dart:math';

import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flame/game.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';

import '../data/word_bank.dart';
import '../services/progress_service.dart';
import '../services/sound_service.dart';
import '../services/tts_service.dart';
import 'difficulty.dart';
import 'components/bullet.dart';
import 'components/explosion.dart';
import 'components/player_tank.dart';
import 'components/starfield.dart';
import 'components/word_enemy.dart';

/// Jogo principal (PRD §5-§9): nave embaixo, palavras descendo, digitou certo
/// = tiro, completou a palavra = explosão + XP + combo.
class WordBlasterGame extends FlameGame {
  static const overlayGameOver = 'gameOver';
  static const overlayPaused = 'paused';
  static const _maxEnemies = 5;
  static const _wordsPerLevel = 12;
  static const _startLives = 3;

  final Difficulty difficulty;

  WordBlasterGame({this.difficulty = Difficulty.beginner})
      : levelLabel = ValueNotifier<String>('Nível ${difficulty.startLevel}');

  final _random = Random();

  late PlayerTank _tank;
  final List<WordEnemy> _enemies = [];
  WordEnemy? _target;

  /// Fila de tiros: cada letra correta enfileira uma bala, que só sai quando a
  /// nave está apontada para o alvo — mirar primeiro, atirar depois.
  final List<WordEnemy> _shotQueue = [];
  double _shotCooldown = 0;

  /// Último alvo atirado: a nave continua mirando nele até a última bala
  /// explodir a palavra; só então volta (devagar) a apontar para cima.
  WordEnemy? _watchTarget;

  /// Últimas palavras que saíram da tela: ficam fora do sorteio por alguns
  /// spawns para um tópico pequeno não virar loop da mesma palavra.
  final List<String> _recentWords = [];

  // Estado da partida, exposto ao HUD Flutter.
  final score = ValueNotifier<int>(0);
  final streak = ValueNotifier<int>(0);
  final multiplier = ValueNotifier<int>(1);
  final lives = ValueNotifier<int>(_startLives);

  // Já nasce com o valor do nível inicial: onLoad roda durante o primeiro
  // build do GameWidget, e notificar um ValueListenableBuilder nessa fase
  // lança "setState() called during build". Com valor idêntico, nada notifica.
  final ValueNotifier<String> levelLabel;

  int _level = 1;
  int _wordsThisLevel = 0;
  int runXp = 0;
  int runWords = 0;
  int _correctChars = 0;
  int _wrongChars = 0;
  bool _isGameOver = false;
  bool _isPaused = false;
  double _spawnClock = 0;

  double get accuracy => (_correctChars + _wrongChars) == 0
      ? 1
      : _correctChars / (_correctChars + _wrongChars);

  bool get isGameOver => _isGameOver;

  bool get isPaused => _isPaused;

  /// Ritmo do jogo (velocidade de queda e cadência de spawn): segue o nível
  /// quando a velocidade está em automático, ou trava no valor escolhido no
  /// painel lateral. O TAMANHO das palavras continua evoluindo pelo nível —
  /// só o relógio fica sob controle do jogador.
  int get _paceLevel =>
      ProgressService.speedLevel == 0 ? _level : ProgressService.speedLevel;

  void pause() {
    if (_isGameOver || _isPaused) return;
    _isPaused = true;
    pauseEngine();
    overlays.add(overlayPaused);
  }

  void resumeGame() {
    if (!_isPaused) return;
    _isPaused = false;
    resumeEngine();
    overlays.remove(overlayPaused);
  }

  @override
  Color backgroundColor() => const Color(0xFF070B14);

  @override
  Future<void> onLoad() async {
    add(Starfield());
    _tank = PlayerTank()..position = _tankHome;
    add(_tank);
    _startLevel(difficulty.startLevel, announce: true);
  }

  Vector2 get _tankHome => Vector2(size.x / 2, size.y - 56);

  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);
    if (isLoaded) {
      _tank.position = _tankHome;
      for (final enemy in _enemies) {
        enemy.bottomLimit = size.y - 110;
        // Encolher a moldura no meio da partida (seletor de tamanho de tela)
        // não pode deixar palavra presa fora da área visível.
        final half = enemy.size.x / 2;
        enemy.position.x = enemy.position.x
            .clamp(half + 4, max(half + 4, size.x - half - 4))
            .toDouble();
      }
    }
  }

  // ------------------------------------------------------------------ níveis

  void _startLevel(int level, {bool announce = false}) {
    _level = level;
    _wordsThisLevel = 0;
    levelLabel.value = 'Nível $_level';
    if (announce) _showBanner(levelLabel.value);
  }

  void _showBanner(String text) {
    final banner = TextComponent(
      text: text,
      anchor: Anchor.center,
      position: Vector2(size.x / 2, size.y * 0.35),
      textRenderer: TextPaint(
        style: const TextStyle(
          color: Color(0xFF00E5FF),
          fontSize: 26,
          fontWeight: FontWeight.bold,
          letterSpacing: 2,
        ),
      ),
    );
    banner.addAll([
      MoveByEffect(Vector2(0, -24), EffectController(duration: 1.4)),
      RemoveEffect(delay: 1.4),
    ]);
    add(banner);
  }

  // ------------------------------------------------------------------ spawns

  @override
  void updateTree(double dt) {
    // Aba/app em segundo plano acumula dt gigante; sem o clamp, ao voltar os
    // inimigos teleportam para o fundo e o jogador perde vidas injustamente.
    super.updateTree(min(dt, 1 / 20));
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (_isGameOver) return;
    final dtc = min(dt, 1 / 20);

    _shotQueue.removeWhere((e) => !e.isMounted);
    if (_watchTarget != null && !_watchTarget!.isMounted) _watchTarget = null;
    _shotCooldown -= dtc;

    // Prioridade da mira: tiros pendentes → palavra em digitação → palavra
    // ainda explodindo (balas no ar). Sem nada disso, retorno lento para cima.
    final aimTarget = _shotQueue.isNotEmpty
        ? _shotQueue.first
        : (_target != null && _target!.isMounted && _target!.isAlive)
            ? _target
            : _watchTarget;
    if (aimTarget != null) {
      _tank.aimAt(aimTarget.absoluteCenter);
      // Só solta a bala quando a torre está de fato apontada para a palavra.
      if (_shotQueue.isNotEmpty &&
          _shotCooldown <= 0 &&
          _tank.aimError(aimTarget.absoluteCenter) < 0.12) {
        final enemy = _shotQueue.removeAt(0);
        _watchTarget = enemy;
        final muzzle = Vector2(sin(_tank.aimAngle), -cos(_tank.aimAngle))
          ..scale(30);
        add(Bullet(start: _tank.position + muzzle, target: enemy));
        _shotCooldown = 0.07; // rajada: 5 letras = 5 balas em sequência
      }
    } else {
      _tank.aimStraightUp();
    }

    _spawnClock += dtc;
    final interval = max(1.15, 2.7 - _paceLevel * 0.13);
    if (_spawnClock >= interval && _enemies.length < _maxEnemies) {
      _spawnClock = 0;
      _spawnEnemy();
    }
  }

  void _spawnEnemy() {
    final word = _pickWord();
    if (word == null) return;

    final estWidth = max(word.en.length, word.pt.length) * 13.0 + 28;
    final x = _pickSpawnX(estWidth);
    if (x == null) return; // sem espaço livre agora; tenta no próximo tick
    final speed = min(16 + _paceLevel * 3.5, 70.0) *
        difficulty.speedFactor *
        (0.85 + _random.nextDouble() * 0.35);

    final enemy = WordEnemy(
      wordData: word,
      speed: speed,
      position: Vector2(x, -30),
      onDestroyed: _onEnemyDestroyed,
      onReachedBottom: _onEnemyReachedBottom,
      homingTarget: () => _tank.position,
    )..bottomLimit = size.y - 110;
    _enemies.add(enemy);
    add(enemy);
  }

  /// Escolhe um X que não sobreponha inimigos ainda perto do topo, para as
  /// palavras nunca aparecerem grudadas umas nas outras.
  double? _pickSpawnX(double width) {
    final nearTop = _enemies.where((e) => e.isAlive && e.position.y < 140);
    for (var attempt = 0; attempt < 8; attempt++) {
      final x = width / 2 +
          8 +
          _random.nextDouble() * max(1, size.x - width - 16);
      final collides = nearTop.any(
          (e) => (e.position.x - x).abs() < (e.size.x + width) / 2 + 14);
      if (!collides) return x;
    }
    return null;
  }

  /// Sorteio ALEATÓRIO entre os tópicos escolhidos pelo jogador (todos, se
  /// nada foi escolhido). O nível controla a dificuldade: palavras curtas no
  /// início, longas depois, frases nos níveis altos. Erros pesam mais no
  /// sorteio, acertos pesam menos (PRD §8).
  Word? _pickWord() {
    final active = _enemies.where((e) => e.isAlive).map((e) => e.word).toSet();
    final activeInitials = active.map((w) => w[0]).toSet();

    var candidates = candidateWords(
      level: _level,
      topics: ProgressService.selectedTopics,
      excludeWords: {...active, ..._recentWords},
      excludeInitials: activeInitials,
    );
    if (candidates.isEmpty) {
      // Pool pequeno demais para o cooldown de repetição: solta o cooldown.
      candidates = candidateWords(
        level: _level,
        topics: ProgressService.selectedTopics,
        excludeWords: active,
        excludeInitials: activeInitials,
      );
    }
    if (candidates.isEmpty) return null;

    final weights =
        candidates.map((w) => ProgressService.statFor(w.en).spawnWeight).toList();
    var roll = _random.nextDouble() * weights.reduce((a, b) => a + b);
    for (var i = 0; i < candidates.length; i++) {
      roll -= weights[i];
      if (roll <= 0) return candidates[i];
    }
    return candidates.last;
  }

  // ---------------------------------------------------------------- digitação

  /// Recebe cada caractere digitado (teclado do sistema ou físico).
  void onTyped(String raw) {
    if (_isGameOver || _isPaused || raw.isEmpty) return;
    final char = raw.toLowerCase();

    var target = _target;
    if (target == null || !target.isAlive || target.typed >= target.word.length) {
      target = _acquireTarget(char);
      if (target == null) {
        _registerError(null);
        return;
      }
      _setTarget(target);
    }

    if (target.word[target.typed] == char) {
      target.advanceTyped(); // letra acende na hora, sem esperar a bala
      _correctChars++;
      // Uma bala por letra: entra na fila e sai quando a nave mirar o alvo.
      _shotQueue.add(target);
      if (target.typed >= target.word.length) {
        _completeWord(target);
      }
    } else {
      _registerError(target);
    }
  }

  /// Mira no inimigo mais próximo da nave cuja palavra começa com a letra.
  WordEnemy? _acquireTarget(String char) {
    WordEnemy? best;
    for (final enemy in _enemies) {
      if (!enemy.isAlive || enemy.typed > 0) continue;
      if (enemy.word[0] != char) continue;
      if (best == null || enemy.position.y > best.position.y) best = enemy;
    }
    return best;
  }

  void _setTarget(WordEnemy? enemy) {
    _target?.isTargeted = false;
    _target = enemy;
    if (enemy != null) enemy.isTargeted = true;
  }

  void _registerError(WordEnemy? target) {
    _wrongChars++;
    streak.value = 0;
    multiplier.value = 1;
    SoundService.playError();
    if (target != null) {
      target.flashError();
      ProgressService.recordMiss(target.word);
    }
  }

  void _completeWord(WordEnemy enemy) {
    runWords++;
    _wordsThisLevel++;
    streak.value++;
    multiplier.value = switch (streak.value) {
      >= 50 => 5,
      >= 20 => 3,
      >= 10 => 2,
      _ => 1,
    };

    // XP por dificuldade (PRD §9): curta +5 … frase +30.
    final xp = enemy.word.contains(' ')
        ? 30
        : (5 + (enemy.word.length - 3) * 2).clamp(5, 20);
    runXp += xp;
    score.value += xp * multiplier.value * 10;

    ProgressService.recordHit(enemy.word);
    _setTarget(null);

    if (_wordsThisLevel >= _wordsPerLevel && _level < 50) {
      _startLevel(_level + 1);
      // Recompensa de subir de nível: +1 coração.
      lives.value++;
      _showBanner('Nível $_level  ·  +1 vida');
    }
  }

  // ------------------------------------------------------------------ eventos

  void _rememberRecent(String word) {
    _recentWords.add(word);
    if (_recentWords.length > 4) _recentWords.removeAt(0);
  }

  void _onEnemyDestroyed(WordEnemy enemy) {
    _rememberRecent(enemy.word);
    _enemies.remove(enemy);
    add(buildExplosion(enemy.absoluteCenter));
    enemy.removeFromParent();
    // Pronúncia junto com a explosão: som + grafia + significado no mesmo
    // instante de recompensa — é aqui que o aprendizado gruda.
    TtsService.speak(enemy.word);
  }

  void _onEnemyReachedBottom(WordEnemy enemy) {
    _rememberRecent(enemy.word);
    _enemies.remove(enemy);
    add(buildExplosion(enemy.absoluteCenter, color: const Color(0xFFFF2E88)));
    enemy.removeFromParent();
    SoundService.playLifeLost();
    ProgressService.recordMiss(enemy.word);
    if (_target == enemy) _setTarget(null);

    streak.value = 0;
    multiplier.value = 1;
    lives.value--;
    if (lives.value <= 0) _endGame();
  }

  void _endGame() {
    _isGameOver = true;
    for (final enemy in List.of(_enemies)) {
      add(buildExplosion(enemy.absoluteCenter, color: const Color(0xFFFF2E88)));
      enemy.removeFromParent();
    }
    _enemies.clear();
    _setTarget(null);
    ProgressService.saveRun(score: score.value, xp: runXp, words: runWords);
    overlays.add(overlayGameOver);
  }

  void restart() {
    if (_isPaused) resumeGame();
    overlays.remove(overlayGameOver);
    for (final enemy in List.of(_enemies)) {
      enemy.removeFromParent();
    }
    _enemies.clear();
    _setTarget(null);

    score.value = 0;
    streak.value = 0;
    multiplier.value = 1;
    lives.value = _startLives;
    runXp = 0;
    runWords = 0;
    _correctChars = 0;
    _wrongChars = 0;
    _spawnClock = 0;
    _shotQueue.clear();
    _shotCooldown = 0;
    _watchTarget = null;
    _recentWords.clear();
    _isGameOver = false;
    _tank.aimStraightUp();
    _startLevel(difficulty.startLevel, announce: true);
  }
}
