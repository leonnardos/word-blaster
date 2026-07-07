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
import 'components/battlefield.dart';
import 'components/bullet.dart';
import 'components/explosion.dart';
import 'components/player_tank.dart';
import 'components/word_enemy.dart';

/// Jogo principal (PRD §5-§9): nave embaixo, palavras descendo, digitou certo
/// = tiro, completou a palavra = explosão + XP + combo.
class WordBlasterGame extends FlameGame {
  static const overlayGameOver = 'gameOver';
  static const overlayPaused = 'paused';
  static const overlayInspect = 'inspect';
  static const _maxEnemies = 5;
  static const _wordsPerLevel = 12;
  static const _startLives = 3;

  final Difficulty difficulty;

  /// Zoom da câmera: 1.0 no desktop; menor no celular ("zoom out"), onde o
  /// teclado embutido rouba metade da tela — o mundo lógico fica maior e o
  /// caminho até o tanque rende mais tempo de digitação.
  final double zoom;

  WordBlasterGame({this.difficulty = Difficulty.beginner, this.zoom = 1.0})
      : levelLabel = ValueNotifier<String>('Nível ${difficulty.startLevel}');

  final _random = Random();

  late PlayerTank _tank;
  late Battlefield _battlefield;
  final List<WordEnemy> _enemies = [];
  WordEnemy? _target;

  /// Tremida leve da tela quando um tiro acerta a palavra.
  static const _shakeDuration = 0.14;
  double _shakeTime = 0;

  /// Fila de tiros: cada letra correta enfileira uma bala, que só sai quando a
  /// torre está apontada para o alvo — mirar primeiro, atirar depois.
  final List<WordEnemy> _shotQueue = [];
  double _shotCooldown = 0;

  /// Canhão duplo: as balas alternam entre o cano esquerdo e o direito.
  bool _leftBarrel = false;

  /// Último alvo atirado: a nave continua mirando nele até a última bala
  /// explodir a palavra; só então volta (devagar) a apontar para cima.
  WordEnemy? _watchTarget;

  /// Últimas palavras que saíram da tela: ficam fora do sorteio por alguns
  /// spawns para um tópico pequeno não virar loop da mesma palavra.
  final List<String> _recentWords = [];

  /// Quantas vezes cada palavra já apareceu NESTA partida: o sorteio divide
  /// o peso por isso, empurrando a vez para quem ainda não apareceu —
  /// garante cobertura do pool em vez de repetir as mesmas favoritas.
  final Map<String, int> _seenThisRun = {};

  // Estado da partida, exposto ao HUD Flutter.
  final score = ValueNotifier<int>(0);
  final streak = ValueNotifier<int>(0);
  final multiplier = ValueNotifier<int>(1);
  final lives = ValueNotifier<int>(_startLives);

  /// Fim de jogo (o HUD/controles somem para o cartão ficar limpo).
  final isOverNotifier = ValueNotifier<bool>(false);

  /// Letra digitada errada, mostrada animada no lugar do combo por ~1s.
  /// O id incremental faz a animação reiniciar mesmo repetindo a letra.
  final wrongLetter = ValueNotifier<(int, String)>((0, ''));
  double _wrongLetterClock = 0;

  // Já nasce com o valor do nível inicial: onLoad roda durante o primeiro
  // build do GameWidget, e notificar um ValueListenableBuilder nessa fase
  // lança "setState() called during build". Com valor idêntico, nada notifica.
  final ValueNotifier<String> levelLabel;

  int _level = 1;
  int _wordsThisLevel = 0;

  /// Ondas: as palavras vêm em levas de 8-10; limpar a leva dá uma pausa de
  /// 2s (respiro) antes do banner "ONDA N" e da próxima.
  int _wave = 0;
  int _waveRemaining = 0;
  double _waveRest = -1; // -1 = não está descansando
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

  /// Nível atual das palavras.
  int get level => _level;

  /// Velocidade automática: sobe 1 a cada 2 níveis e trava no 8 — a mesma
  /// escala do painel manual (travar no 8 É a velocidade máxima do jogo).
  /// Nível 1-2 → 1, 3-4 → 2, 5-6 → 3 ... 15+ → 8.
  static int autoSpeedFor(int level) => min(8, (level + 1) ~/ 2);

  /// Preenchimento da barra de estamina (0..1) para uma sequência de
  /// [words] palavras corretas: 5 palavras = 25%, 15 = 50%, 25 = 75%,
  /// 35 = 100% — cada quarto da barra é um marco de multiplicador.
  static double staminaFor(int words) {
    if (words >= 35) return 1.0;
    if (words >= 25) return 0.75 + (words - 25) / 10 * 0.25;
    if (words >= 15) return 0.50 + (words - 15) / 10 * 0.25;
    if (words >= 5) return 0.25 + (words - 5) / 10 * 0.25;
    return words / 5 * 0.25;
  }

  /// Ritmo do jogo (velocidade de queda e cadência de spawn): automático
  /// (1 a cada 2 níveis, teto 8) ou travado no valor escolhido no painel.
  /// O TAMANHO das palavras continua evoluindo pelo nível — só o relógio
  /// fica sob controle do jogador.
  int get _paceLevel => ProgressService.speedLevel == 0
      ? autoSpeedFor(_level)
      : ProgressService.speedLevel;

  void pause() {
    if (_isGameOver || _isPaused || _inspected != null) return;
    _isPaused = true;
    pauseEngine();
    overlays.add(overlayPaused);
  }

  // ------------------------------------------------------ inspeção de palavra

  /// Palavra sendo "estudada": o jogador tocou nela (cartão aberto).
  WordEnemy? _inspected;

  WordEnemy? get inspectedEnemy => _inspected;

  /// Tocar numa palavra: congela o jogo e abre o cartão de dicionário.
  /// Retorna true se havia uma palavra no ponto tocado.
  bool tryInspectAt(Vector2 point) {
    if (_isGameOver || _isPaused || _inspected != null) return false;
    for (final enemy in _enemies) {
      if (!enemy.isAlive) continue;
      if (enemy.toRect().inflate(8).contains(point.toOffset())) {
        _inspected = enemy;
        pauseEngine();
        overlays.add(overlayInspect);
        TtsService.speak(enemy.word); // pronúncia junto com a leitura
        return true;
      }
    }
    return false;
  }

  /// Próximo toque (em qualquer lugar): fecha o cartão e o jogo continua.
  void endInspect() {
    if (_inspected == null) return;
    _inspected = null;
    overlays.remove(overlayInspect);
    if (!_isPaused && !_isGameOver) resumeEngine();
  }

  /// Liga/desliga a tradução nas palavras que já estão na tela.
  void refreshTranslations() {
    for (final enemy in _enemies) {
      enemy.refreshText();
    }
  }

  void resumeGame() {
    if (!_isPaused) return;
    _isPaused = false;
    resumeEngine();
    overlays.remove(overlayPaused);
  }

  @override
  Color backgroundColor() => const Color(0xFF16110C); // terra escura

  @override
  Future<void> onLoad() async {
    _battlefield = Battlefield();
    add(_battlefield);
    _tank = PlayerTank()..position = _tankHome;
    add(_tank);
    _startLevel(difficulty.startLevel, announce: true);
    _startWave(1);
  }

  void _startWave(int number) {
    _wave = number;
    _waveRemaining = 8 + number % 3; // 8-10 palavras por onda
    _waveRest = -1;
    // A primeira palavra da onda não pode demorar: adianta o relógio.
    _spawnClock = 999;
    if (number > 1) _showBanner('ONDA $number');
  }

  Vector2 get _tankHome => Vector2(size.x / 2, size.y - 106);

  @override
  // ignore: avoid_renaming_method_parameters
  void onGameResize(Vector2 canvasSize) {
    // O tamanho LÓGICO é o canvas dividido pelo zoom: com zoom 0.75 o campo
    // fica 33% maior e é desenhado menor (veja renderTree).
    super.onGameResize(canvasSize / zoom);
    if (isLoaded) {
      _tank.position = _tankHome;
      for (final enemy in _enemies) {
        enemy.bottomLimit = size.y - 160;
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
          fontFamily: 'Orbitron',
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

  /// Impacto do tiro na palavra: só a clareada rápida do cenário.
  /// (A tremida ficou reservada para o estouro da palavra completa.)
  void _onBulletImpact() {
    _battlefield.flash();
  }

  @override
  void renderTree(Canvas canvas) {
    final shaking = _shakeTime > 0;
    final scaled = zoom != 1.0;
    if (!shaking && !scaled) {
      super.renderTree(canvas);
      return;
    }
    canvas.save();
    if (scaled) canvas.scale(zoom);
    if (shaking) {
      final strength = 2.2 * (_shakeTime / _shakeDuration); // sutil
      canvas.translate(
        (_random.nextDouble() * 2 - 1) * strength,
        (_random.nextDouble() * 2 - 1) * strength,
      );
    }
    super.renderTree(canvas);
    canvas.restore();
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (_shakeTime > 0) _shakeTime = max(0, _shakeTime - min(dt, 1 / 20));
    if (_wrongLetterClock > 0) {
      _wrongLetterClock -= min(dt, 1 / 20);
      if (_wrongLetterClock <= 0) {
        wrongLetter.value = (wrongLetter.value.$1, '');
      }
    }
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
        _leftBarrel = !_leftBarrel;
        final muzzle = _tank.muzzleTip(left: _leftBarrel);
        add(buildMuzzleFlash(muzzle, _tank.aimAngle));
        add(Bullet(start: muzzle, target: enemy, onImpact: _onBulletImpact));
        _shotCooldown = 0.07; // rajada: 5 letras = 5 balas em sequência
      }
    } else {
      _tank.aimStraightUp();
    }

    // Ondas: spawna enquanto a leva tem palavras; leva vazia + tela limpa =
    // pausa de 2s de respiro e vem a próxima onda.
    if (_waveRemaining > 0) {
      _spawnClock += dtc;
      // Cadência calibrada para a escala 1-8: no 8, igual à antiga 10.
      final interval = max(1.15, 2.7 - _paceLevel * 0.1625);
      if (_spawnClock >= interval && _enemies.length < _maxEnemies) {
        _spawnClock = 0;
        if (_spawnEnemy()) _waveRemaining--;
      }
    } else if (_enemies.isEmpty) {
      if (_waveRest < 0) _waveRest = 2.0; // acabou de limpar a onda
      _waveRest -= dtc;
      if (_waveRest <= 0) _startWave(_wave + 1);
    }
  }

  /// Spawna um inimigo; false se não conseguiu (sem palavra/sem espaço) —
  /// nesse caso a onda não desconta e tenta no próximo tick.
  bool _spawnEnemy() {
    final word = _pickWord();
    if (word == null) return false;

    final estWidth = max(word.en.length, word.pt.length) * 13.0 + 28;
    final x = _pickSpawnX(estWidth);
    if (x == null) return false; // sem espaço livre agora
    // Escala 1-8 esticada: velocidade 8 = 51 px/s (a antiga nível 10).
    final speed = min(16 + _paceLevel * 4.375, 70.0) *
        difficulty.speedFactor *
        (0.85 + _random.nextDouble() * 0.35);

    final enemy = WordEnemy(
      wordData: word,
      speed: speed,
      position: Vector2(x, -30),
      onDestroyed: _onEnemyDestroyed,
      onReachedBottom: _onEnemyReachedBottom,
      homingTarget: () => _tank.position,
    )..bottomLimit = size.y - 160;
    _enemies.add(enemy);
    add(enemy);
    _seenThisRun[word.en] = (_seenThisRun[word.en] ?? 0) + 1;
    return true;
  }

  /// Peso efetivo no sorteio: o peso pedagógico (erros pesam mais) dividido
  /// pela exposição na partida — cada aparição corta o peso quase pela
  /// metade, então quem nunca apareceu sempre acaba tendo a vez.
  static double pickWeight(double spawnWeight, int timesSeen) =>
      spawnWeight / (1 + 0.8 * timesSeen);

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

    final weights = candidates
        .map((w) => pickWeight(ProgressService.statFor(w.en).spawnWeight,
            _seenThisRun[w.en] ?? 0))
        .toList();
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
    // Cartão de dicionário aberto: qualquer tecla só FECHA o cartão (a
    // letra não conta) — o jogador volta ao jogo sem tirar a mão do teclado.
    if (_inspected != null) {
      endInspect();
      return;
    }
    final char = raw.toLowerCase();

    var target = _target;
    if (target == null || !target.isAlive || target.typed >= target.word.length) {
      target = _acquireTarget(char);
      if (target == null) {
        _registerError(null, char);
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
      _registerError(target, char);
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

  void _registerError(WordEnemy? target, String char) {
    _wrongChars++;
    streak.value = 0;
    multiplier.value = 1;
    SoundService.playError();
    // A letra errada toma o lugar do combo no HUD por um instante.
    wrongLetter.value = (wrongLetter.value.$1 + 1, char);
    _wrongLetterClock = 1.0;
    if (target != null) {
      target.flashError();
      final stat = ProgressService.statFor(target.word);
      final wasMastered = stat.mastery == Mastery.dominada;
      ProgressService.recordMiss(target.word);
      if (wasMastered) {
        // Errou a dominada: regride para "aprendendo" (5 acertos).
        stat.regressFromMastered();
      }
      if (wasMastered || ProgressService.hiddenMode) {
        // Palavra oculta errada SE REVELA na hora — "hammer tem dois m!".
        target.revealWord();
      }
    }
  }

  void _completeWord(WordEnemy enemy) {
    runWords++;
    _wordsThisLevel++;
    streak.value++;
    // Estamina: 5 palavras seguidas = ×2, 15 = ×3, 25 = ×4, 35 = ×5.
    multiplier.value = switch (streak.value) {
      >= 35 => 5,
      >= 25 => 4,
      >= 15 => 3,
      >= 5 => 2,
      _ => 1,
    };

    // XP por dificuldade (PRD §9): curta +5 … frase +30.
    var xp = enemy.word.contains(' ')
        ? 30
        : (5 + (enemy.word.length - 3) * 2).clamp(5, 20);
    // Palavra dominada (digitada sem o andaime da tradução) vale +50%.
    if (ProgressService.statFor(enemy.word).mastery == Mastery.dominada) {
      xp = (xp * 1.5).round();
    }
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
    add(buildFireExplosion(enemy.absoluteCenter));
    _shakeTime = _shakeDuration; // tremida só no estouro da palavra
    enemy.removeFromParent();
    // Pronúncia junto com a explosão: som + grafia + significado no mesmo
    // instante de recompensa — é aqui que o aprendizado gruda.
    TtsService.speak(enemy.word);
  }

  void _onEnemyReachedBottom(WordEnemy enemy) {
    _rememberRecent(enemy.word);
    _enemies.remove(enemy);
    // Maior que a de destruir: chegar no tanque é o impacto mais violento.
    add(buildFireExplosion(enemy.absoluteCenter, scale: 1.35));
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
    isOverNotifier.value = true;
    for (final enemy in List.of(_enemies)) {
      add(buildFireExplosion(enemy.absoluteCenter, scale: 1.2));
      enemy.removeFromParent();
    }
    _enemies.clear();
    _setTarget(null);
    ProgressService.saveRun(score: score.value, xp: runXp, words: runWords);
    overlays.add(overlayGameOver);
  }

  void restart() {
    endInspect();
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
    wrongLetter.value = (wrongLetter.value.$1, '');
    _wrongLetterClock = 0;
    runXp = 0;
    runWords = 0;
    _correctChars = 0;
    _wrongChars = 0;
    _spawnClock = 0;
    _shotQueue.clear();
    _shotCooldown = 0;
    _watchTarget = null;
    _recentWords.clear();
    _seenThisRun.clear();
    _isGameOver = false;
    isOverNotifier.value = false;
    _tank.aimStraightUp();
    _startLevel(difficulty.startLevel, announce: true);
    _startWave(1);
  }
}
