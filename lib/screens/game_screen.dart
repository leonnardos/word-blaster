import 'dart:math';

import 'package:flame/game.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../data/word_bank.dart';
import '../data/word_examples.dart';
import '../game/difficulty.dart';
import '../game/screen_size.dart';
import '../game/word_blaster_game.dart';
import '../services/progress_service.dart';
import '../services/sound_service.dart';
import '../services/tts_service.dart';

/// Celular (nativo ou navegador) usa o teclado próprio do jogo — o teclado
/// do sistema esmaga o layout e rola a página.
bool get _isMobileDevice =>
    defaultTargetPlatform == TargetPlatform.android ||
    defaultTargetPlatform == TargetPlatform.iOS;

/// Tela de jogo com duas rotas de digitação:
///  1. Campo de texto invisível — abre o teclado virtual no celular.
///  2. Listener global de teclado físico — desktop/web digitam mesmo que o
///     campo perca o foco (GameWidget e TextField disputam foco).
class GameScreen extends StatefulWidget {
  final Difficulty difficulty;

  const GameScreen({super.key, this.difficulty = Difficulty.beginner});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  static final _typable = RegExp(r"^[a-zA-Z' ]$");

  late final WordBlasterGame _game;
  final _controller = TextEditingController();
  final _focusNode = FocusNode();
  bool _speedMenuOpen = false;

  @override
  void initState() {
    super.initState();
    _game = WordBlasterGame(
      difficulty: widget.difficulty,
      // Zoom out no celular: o teclado embutido rouba metade da tela, então
      // o campo lógico fica maior para dar mais tempo de digitação.
      zoom: _isMobileDevice ? 0.75 : 1.0,
    );
    HardwareKeyboard.instance.addHandler(_onHardwareKey);
    // O GameWidget também pede autofocus e costuma vencer a disputa; sem este
    // pedido pós-frame o campo nunca foca e a digitação morre na 1ª partida.
    // No celular NÃO focamos: o teclado é o do jogo, não o do sistema.
    if (!_isMobileDevice) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _focusNode.requestFocus();
      });
    }
  }

  @override
  void dispose() {
    HardwareKeyboard.instance.removeHandler(_onHardwareKey);
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  /// Teclado físico: só age quando o TextField NÃO tem foco (senão o caractere
  /// chegaria duplicado via onChanged).
  bool _onHardwareKey(KeyEvent event) {
    if (event is KeyDownEvent &&
        event.logicalKey == LogicalKeyboardKey.escape &&
        !_game.isGameOver) {
      _game.isPaused ? _resumeFromPause() : _game.pause();
      return true;
    }
    if (_focusNode.hasFocus) return false;
    if (event is! KeyDownEvent) return false;
    final char = event.character;
    if (char == null || !_typable.hasMatch(char)) return false;
    _game.onTyped(char);
    return true;
  }

  void _onChanged(String value) {
    if (value.isEmpty) return;
    for (final char in value.split('')) {
      if (_typable.hasMatch(char)) _game.onTyped(char);
    }
    _controller.clear();
  }

  void _restart() {
    _game.restart();
    // Sem isso o teclado fecha após o game over e o jogador não digita mais.
    if (!_isMobileDevice) _focusNode.requestFocus();
  }

  void _resumeFromPause() {
    _game.resumeGame();
    if (!_isMobileDevice) _focusNode.requestFocus();
  }

  /// Coluna lateral de controles rápidos: velocidade (todas as plataformas)
  /// e tamanho da tela (só web/desktop) — tudo sem sair da partida.
  Widget _sideStrip() {
    return Positioned(
      right: 6,
      top: 0,
      bottom: 0,
      child: Center(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_speedMenuOpen) ...[
              _speedPanel(),
              const SizedBox(width: 6),
            ],
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _musicButton(),
                const SizedBox(height: 6),
                _soundButton(),
                const SizedBox(height: 6),
                _speedButton(),
                const SizedBox(height: 6),
                _translationButton(),
                if (isScreenSizeSelectorAvailable) ...[
                  const SizedBox(height: 16),
                  ValueListenableBuilder<ScreenSize>(
                    valueListenable: screenSizeNotifier,
                    builder: (_, current, __) => Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        for (final size in ScreenSize.values) ...[
                          _sizeIconButton(size, selected: size == current),
                          const SizedBox(height: 6),
                        ],
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _musicButton() {
    final on = ProgressService.musicOn;
    return Tooltip(
      message: on ? 'Parar a música' : 'Tocar a música',
      child: GestureDetector(
        onTap: () {
          ProgressService.saveMusicOn(!on);
          SoundService.syncMusic();
          setState(() {});
          _focusNode.requestFocus();
        },
        child: Container(
          width: 30,
          height: 30,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: const Color(0xB010162A),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: on ? const Color(0xFF2A3350) : const Color(0xFFFF2E88),
            ),
          ),
          child: Icon(
            on ? Icons.music_note : Icons.music_off,
            size: 16,
            color: on ? const Color(0xFF8A93B2) : const Color(0xFFFF2E88),
          ),
        ),
      ),
    );
  }

  Widget _translationButton() {
    final on = ProgressService.showTranslation;
    return Tooltip(
      message: on
          ? 'Ocultar tradução (modo desafio)'
          : 'Mostrar tradução',
      child: GestureDetector(
        onTap: () {
          ProgressService.saveShowTranslation(!on);
          _game.refreshTranslations();
          setState(() {});
          if (!_isMobileDevice) _focusNode.requestFocus();
        },
        child: Container(
          width: 30,
          height: 30,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: const Color(0xB010162A),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: on ? const Color(0xFF2A3350) : const Color(0xFFFFB020),
            ),
          ),
          child: Icon(
            Icons.translate,
            size: 16,
            color: on ? const Color(0xFF8A93B2) : const Color(0xFFFFB020),
          ),
        ),
      ),
    );
  }

  Widget _soundButton() {
    final on = ProgressService.soundOn;
    return Tooltip(
      message: on ? 'Silenciar (efeitos e voz)' : 'Ativar som',
      child: GestureDetector(
        onTap: () {
          ProgressService.saveSoundOn(!on);
          SoundService.syncMusic(); // mudo pausa/retoma a trilha também
          setState(() {});
          _focusNode.requestFocus();
        },
        child: Container(
          width: 30,
          height: 30,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: const Color(0xB010162A),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: on ? const Color(0xFF2A3350) : const Color(0xFFFF2E88),
            ),
          ),
          child: Icon(
            on ? Icons.volume_up : Icons.volume_off,
            size: 16,
            color: on ? const Color(0xFF8A93B2) : const Color(0xFFFF2E88),
          ),
        ),
      ),
    );
  }

  /// Mostra SEMPRE a velocidade atual: azul = automática (acompanha o
  /// nível, sobe sozinha), vermelho = travada pelo jogador.
  Widget _speedButton() {
    return ValueListenableBuilder<String>(
      // levelLabel muda exatamente quando o nível muda — atualiza o número.
      valueListenable: _game.levelLabel,
      builder: (_, __, ___) {
        final locked = ProgressService.speedLevel != 0;
        final shown = locked
            ? ProgressService.speedLevel
            : min(_game.level, WordBlasterGame.speedCapLevel);
        final color =
            locked ? const Color(0xFFFF4444) : const Color(0xFF00E5FF);
        return Tooltip(
          message: locked
              ? 'Velocidade TRAVADA em $shown — toque e escolha A para voltar'
              : 'Velocidade automática: $shown (sobe com o nível)',
          child: GestureDetector(
            onTap: () => setState(() => _speedMenuOpen = !_speedMenuOpen),
            child: Container(
              width: 30,
              height: 30,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: const Color(0xB010162A),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: color),
              ),
              child: Text(
                '$shown',
                style: TextStyle(
                  color: color,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  /// A = automática (acelera com o nível); 1-8 = ritmo travado.
  Widget _speedPanel() {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: const Color(0xE010162A),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFF2A3350)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'VELOCIDADE',
            style: TextStyle(
              color: Color(0xFF5A6284),
              fontSize: 9,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 6),
          for (final row in const [
            [0, 1, 2],
            [3, 4, 5],
            [6, 7, 8],
          ])
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (final value in row)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 2),
                      child: _speedOption(value),
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _speedOption(int value) {
    final selected = ProgressService.speedLevel == value;
    // Travar (1-8) é vermelho; automático (A) é azul.
    final accent =
        value == 0 ? const Color(0xFF00E5FF) : const Color(0xFFFF4444);
    return Tooltip(
      message: value == 0
          ? 'Automática (acelera com o nível)'
          : 'Travar na velocidade $value',
      child: GestureDetector(
        onTap: () {
          ProgressService.saveSpeedLevel(value);
          setState(() => _speedMenuOpen = false);
          if (!_isMobileDevice) _focusNode.requestFocus();
        },
        child: Container(
          width: 28,
          height: 28,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected
                ? (value == 0
                    ? const Color(0xFF0E2A33)
                    : const Color(0xFF331416))
                : const Color(0xFF141A2E),
            borderRadius: BorderRadius.circular(7),
            border: Border.all(
              color: selected ? accent : const Color(0xFF2A3350),
            ),
          ),
          child: Text(
            value == 0 ? 'A' : '$value',
            style: TextStyle(
              color: selected ? accent : const Color(0xFF8A93B2),
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }

  Widget _sizeIconButton(ScreenSize size, {required bool selected}) {
    final icon = switch (size) {
      ScreenSize.medium => Icons.tablet_android,
      ScreenSize.mobile => Icons.smartphone,
    };
    return Tooltip(
      message: size.label,
      child: GestureDetector(
        onTap: () {
          ProgressService.saveScreenSize(size);
          _focusNode.requestFocus(); // digitação não pode morrer após o clique
        },
        child: Container(
          width: 30,
          height: 30,
          decoration: BoxDecoration(
            color: const Color(0xB010162A),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color:
                  selected ? const Color(0xFF00E5FF) : const Color(0xFF2A3350),
            ),
          ),
          child: Icon(
            icon,
            size: 15,
            color:
                selected ? const Color(0xFF00E5FF) : const Color(0xFF8A93B2),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final gameArea = Listener(
      // Segurar numa palavra abre o cartão de dicionário (jogo congela);
      // soltar em qualquer lugar fecha e o jogo continua.
      behavior: HitTestBehavior.translucent,
      // Divide pelo zoom: o toque chega em pixels de tela, o jogo pensa em
      // coordenadas lógicas (maiores no celular).
      onPointerDown: (event) => _game.tryInspectAt(
        Vector2(event.localPosition.dx, event.localPosition.dy) / _game.zoom,
      ),
      onPointerUp: (_) => _game.endInspect(),
      onPointerCancel: (_) => _game.endInspect(),
      child: GestureDetector(
        // Toque em qualquer lugar reabre o teclado (desktop/web).
        onTap: _isMobileDevice ? null : () => _focusNode.requestFocus(),
        child: Stack(
          children: [
            GameWidget(
              game: _game,
              overlayBuilderMap: {
                WordBlasterGame.overlayGameOver: (context, WordBlasterGame game) =>
                    _GameOverOverlay(game: game, onRestart: _restart),
                WordBlasterGame.overlayPaused: (context, WordBlasterGame game) =>
                    _PauseOverlay(onResume: _resumeFromPause),
                WordBlasterGame.overlayInspect: (context, WordBlasterGame game) =>
                    _InspectOverlay(game: game),
              },
            ),
            _Hud(game: _game),
            _sideStrip(),
            Positioned(
              left: 16,
              right: 16,
              bottom: 8,
              child: _StaminaBar(game: _game),
            ),
            // Campo invisível: captura a digitação no desktop/web. No celular
            // não existe — o teclado do jogo alimenta onTyped diretamente.
            if (!_isMobileDevice)
              Positioned(
                left: 0,
                bottom: 0,
                width: 1,
                height: 1,
                child: Opacity(
                  opacity: 0,
                  child: TextField(
                    controller: _controller,
                    focusNode: _focusNode,
                    autofocus: true,
                    autocorrect: false,
                    enableSuggestions: false,
                    keyboardType: TextInputType.visiblePassword,
                    textCapitalization: TextCapitalization.none,
                    onChanged: _onChanged,
                  ),
                ),
              ),
          ],
        ),
      ),
    );

    return Scaffold(
      backgroundColor: const Color(0xFF070B14),
      resizeToAvoidBottomInset: false,
      body: _isMobileDevice
          ? Column(
              children: [
                Expanded(child: gameArea),
                _MobileKeyboard(onKey: _game.onTyped),
              ],
            )
          : gameArea,
    );
  }
}

/// Teclado embutido para celular (estilo ZType): o teclado do sistema
/// esmaga o layout, então o jogo tem o seu próprio.
class _MobileKeyboard extends StatelessWidget {
  final void Function(String) onKey;

  const _MobileKeyboard({required this.onKey});

  static const _rows = ['qwertyuiop', 'asdfghjkl', 'zxcvbnm'];

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF0A0F1C),
      padding: EdgeInsets.only(
        top: 3,
        left: 2,
        right: 2,
        bottom: 3 + MediaQuery.of(context).padding.bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final row in _rows)
            Row(
              children: [
                if (row.length < 10) Spacer(flex: 10 - row.length),
                for (final letter in row.split(''))
                  Expanded(
                      flex: 2, child: _KeyCap(char: letter, onKey: onKey)),
                if (row.length < 10) Spacer(flex: 10 - row.length),
              ],
            ),
          Row(
            children: [
              const Spacer(flex: 2),
              Expanded(
                flex: 6,
                child: _KeyCap(char: ' ', label: 'ESPAÇO', onKey: onKey),
              ),
              const Spacer(flex: 2),
            ],
          ),
        ],
      ),
    );
  }
}

/// Tecla individual: a célula INTEIRA é área de toque (o vão entre teclas é
/// só visual, dentro da célula) e acende em ciano no instante do toque.
class _KeyCap extends StatefulWidget {
  final String char;
  final String? label;
  final void Function(String) onKey;

  const _KeyCap({required this.char, this.label, required this.onKey});

  @override
  State<_KeyCap> createState() => _KeyCapState();
}

class _KeyCapState extends State<_KeyCap> {
  bool _pressed = false;

  void _release() {
    // Segura o "aceso" por um instante para o olho registrar o toque
    // mesmo num tap rápido.
    Future.delayed(const Duration(milliseconds: 90), () {
      if (mounted) setState(() => _pressed = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      // opaque: captura o toque na célula toda, incluindo os vãos.
      behavior: HitTestBehavior.opaque,
      onPointerDown: (_) {
        HapticFeedback.lightImpact();
        setState(() => _pressed = true);
        widget.onKey(widget.char); // dispara no toque: reflexo conta
      },
      onPointerUp: (_) => _release(),
      onPointerCancel: (_) => _release(),
      child: Padding(
        padding: const EdgeInsets.all(2.5),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 60),
          height: 50,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color:
                _pressed ? const Color(0xFF0E3A46) : const Color(0xFF141A2E),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color:
                  _pressed ? const Color(0xFF00E5FF) : const Color(0xFF2A3350),
              width: _pressed ? 1.8 : 1,
            ),
            boxShadow: _pressed
                ? const [BoxShadow(color: Color(0x8000E5FF), blurRadius: 10)]
                : const [],
          ),
          child: Text(
            widget.label ?? widget.char.toUpperCase(),
            style: TextStyle(
              color: _pressed
                  ? const Color(0xFF00E5FF)
                  : const Color(0xFFD5E2F0),
              fontSize: widget.label == null ? 19 : 12,
              fontWeight: FontWeight.w600,
              letterSpacing: widget.label == null ? 0 : 2,
            ),
          ),
        ),
      ),
    );
  }
}

Widget _cardChip(String text, Color fg, Color bg) {
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
    decoration: BoxDecoration(
      color: bg,
      borderRadius: BorderRadius.circular(8),
      border: Border.all(color: fg),
    ),
    child: Text(text, style: TextStyle(color: fg, fontSize: 11)),
  );
}

/// Cartão de dicionário (segure a palavra para ler; solte para continuar):
/// palavra, pronúncia, tradução, tópico, maestria e frase de exemplo.
class _InspectOverlay extends StatelessWidget {
  final WordBlasterGame game;

  const _InspectOverlay({required this.game});

  @override
  Widget build(BuildContext context) {
    final enemy = game.inspectedEnemy;
    if (enemy == null) return const SizedBox.shrink();
    final word = enemy.wordData;
    final example = wordExamples[word.en];
    final topic = topicOfWord(word.en);

    return IgnorePointer(
      // O cartão não captura toques: o soltar precisa chegar ao Listener.
      child: Container(
        color: const Color(0xD9070B14),
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(horizontal: 28),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 420),
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            color: const Color(0xFF10162A),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xFF00E5FF), width: 1.5),
            boxShadow: const [
              BoxShadow(color: Color(0x5500E5FF), blurRadius: 24),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      word.en,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 30,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const Icon(Icons.volume_up,
                      color: Color(0xFF00E5FF), size: 22),
                ],
              ),
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Wrap(
                  spacing: 6,
                  children: [
                    if (topic != null)
                      _cardChip(topic, const Color(0xFF00E5FF),
                          const Color(0xFF0E2A33)),
                    switch (ProgressService.statFor(word.en).mastery) {
                      Mastery.dominada => _cardChip('★ DOMINADA',
                          const Color(0xFFFFC93C), const Color(0xFF33290E)),
                      Mastery.aprendendo => _cardChip('APRENDENDO',
                          const Color(0xFF7CE87C), const Color(0xFF12331A)),
                      Mastery.nova => _cardChip('NOVA',
                          const Color(0xFF8A93B2), const Color(0xFF141A2E)),
                    },
                  ],
                ),
              ),
              const SizedBox(height: 10),
              Text(
                word.pt,
                style: const TextStyle(
                  color: Color(0xFF00E5FF),
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (example != null) ...[
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 10),
                  child: Divider(color: Color(0xFF2A3350), height: 1),
                ),
                Text(
                  example.$1,
                  style: const TextStyle(
                    color: Color(0xFFE8ECF0),
                    fontSize: 16,
                    fontStyle: FontStyle.italic,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  example.$2,
                  style: const TextStyle(
                      color: Color(0xFF8A93B2), fontSize: 14),
                ),
              ],
              const SizedBox(height: 14),
              const Center(
                child: Text(
                  'SOLTE PARA CONTINUAR',
                  style: TextStyle(
                    color: Color(0xFF5A6284),
                    fontSize: 10,
                    letterSpacing: 2,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Barra de estamina no rodapé: enche a cada palavra correta e zera no erro.
/// Cada quarto é um marco de multiplicador (5/15/25/35 palavras → ×2..×5).
class _StaminaBar extends StatelessWidget {
  final WordBlasterGame game;

  const _StaminaBar({required this.game});

  static Color _tierColor(int multiplier) => switch (multiplier) {
        5 => const Color(0xFFFF2E88),
        4 => const Color(0xFFFFB020),
        3 => const Color(0xFF7CE87C),
        2 => const Color(0xFF00E5FF),
        _ => const Color(0xFF3A7A8C),
      };

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<int>(
      valueListenable: game.streak,
      builder: (_, streak, __) {
        final pct = WordBlasterGame.staminaFor(streak);
        return ValueListenableBuilder<int>(
          valueListenable: game.multiplier,
          builder: (_, mult, __) {
            final color = _tierColor(mult);
            return Row(
              children: [
                Expanded(
                  child: LayoutBuilder(
                    builder: (_, constraints) => Container(
                      height: 10,
                      clipBehavior: Clip.antiAlias,
                      decoration: BoxDecoration(
                        color: const Color(0x9910162A),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: const Color(0xFF2A3350)),
                      ),
                      child: Stack(
                        children: [
                          Align(
                            alignment: Alignment.centerLeft,
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 260),
                              curve: Curves.easeOut,
                              width: constraints.maxWidth * pct,
                              decoration: BoxDecoration(
                                color: color,
                                borderRadius: BorderRadius.circular(6),
                                boxShadow: mult > 1
                                    ? [
                                        BoxShadow(
                                          color:
                                              color.withValues(alpha: 0.6),
                                          blurRadius: 8,
                                        ),
                                      ]
                                    : const [],
                              ),
                            ),
                          ),
                          // Marcos de 25/50/75%.
                          for (final tick in const [0.25, 0.5, 0.75])
                            Positioned(
                              left: constraints.maxWidth * tick - 1,
                              top: 0,
                              bottom: 0,
                              child: Container(
                                width: 2,
                                color: const Color(0x80070B14),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                SizedBox(
                  width: 32,
                  child: Text(
                    mult > 1 ? '×$mult' : '',
                    style: TextStyle(
                      color: color,
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }
}

/// Letra errada explodindo no lugar do combo: pop elástico, tremidinha
/// e brilho vermelho, sumindo ao final (~1s, casado com o relógio do jogo).
class _WrongLetterPop extends StatelessWidget {
  final String letter;

  const _WrongLetterPop({super.key, required this.letter});

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 950),
      builder: (_, t, __) {
        final pop = Curves.elasticOut.transform((t / 0.4).clamp(0.0, 1.0));
        final scale = 2.2 - 1.2 * pop;
        final opacity =
            t < 0.72 ? 1.0 : (1 - (t - 0.72) / 0.28).clamp(0.0, 1.0);
        final shake = sin(t * pi * 9) * 3 * (1 - t);
        return Transform.translate(
          offset: Offset(shake, 0),
          child: Transform.scale(
            scale: scale,
            child: Opacity(
              opacity: opacity,
              child: Text(
                letter,
                style: const TextStyle(
                  color: Color(0xFFFF5252),
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1,
                  shadows: [
                    Shadow(color: Color(0xAAFF2E2E), blurRadius: 14),
                    Shadow(color: Color(0x66FF6B4A), blurRadius: 26),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _Hud extends StatelessWidget {
  final WordBlasterGame game;

  const _Hud({required this.game});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        // Stack em vez de Row: o placar e o combo ficam no CENTRO exato da
        // tela, independentemente da largura dos corações e do nível.
        child: SizedBox(
          height: 72,
          child: Stack(
            children: [
              Align(
                alignment: Alignment.topLeft,
                child: ValueListenableBuilder<int>(
                  valueListenable: game.lives,
                  builder: (_, lives, __) {
                    // Vidas crescem a cada nível; acima de 6 vira "♥ ×N" para
                    // não engolir o HUD em telas estreitas.
                    if (lives > 6) {
                      return Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.favorite,
                              color: Color(0xFFFF2E88), size: 20),
                          const SizedBox(width: 4),
                          Text(
                            '×$lives',
                            style: const TextStyle(
                              color: Color(0xFFFF2E88),
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      );
                    }
                    return Row(
                      mainAxisSize: MainAxisSize.min,
                      children: List.generate(
                        lives,
                        (_) => const Icon(
                          Icons.favorite,
                          color: Color(0xFFFF2E88),
                          size: 20,
                        ),
                      ),
                    );
                  },
                ),
              ),
              Align(
                alignment: Alignment.topRight,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ValueListenableBuilder<String>(
                      valueListenable: game.levelLabel,
                      builder: (_, label, __) => Text(
                        label,
                        style: const TextStyle(
                          color: Color(0xFF8A93B2),
                          fontSize: 12,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    GestureDetector(
                      onTap: game.pause,
                      child: Container(
                        width: 30,
                        height: 30,
                        decoration: BoxDecoration(
                          color: const Color(0xB010162A),
                          borderRadius: BorderRadius.circular(8),
                          border:
                              Border.all(color: const Color(0xFF2A3350)),
                        ),
                        child: const Icon(
                          Icons.pause,
                          size: 16,
                          color: Color(0xFF8A93B2),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Align(
                alignment: Alignment.topCenter,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ValueListenableBuilder<int>(
                      valueListenable: game.score,
                      builder: (_, score, __) => Text(
                        '$score',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.5,
                        ),
                      ),
                    ),
                    // Linha do combo — que explode na letra errada (animada)
                    // quando o jogador erra e o combo se apaga.
                    SizedBox(
                      height: 28,
                      child: ValueListenableBuilder<(int, String)>(
                        valueListenable: game.wrongLetter,
                        builder: (_, wrong, __) {
                          final (id, char) = wrong;
                          final Widget child;
                          if (char.isNotEmpty) {
                            child = _WrongLetterPop(
                              key: ValueKey('wrong-$id'),
                              letter: char == ' ' ? '␣' : char.toUpperCase(),
                            );
                          } else {
                            child = ValueListenableBuilder<int>(
                              key: const ValueKey('combo'),
                              valueListenable: game.streak,
                              builder: (_, streak, __) {
                                if (streak < 2) return const SizedBox.shrink();
                                return ValueListenableBuilder<int>(
                                  valueListenable: game.multiplier,
                                  builder: (_, mult, __) => Text(
                                    mult > 1
                                        ? 'COMBO $streak  ×$mult'
                                        : 'COMBO $streak',
                                    style: const TextStyle(
                                      color: Color(0xFF00E5FF),
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 2,
                                    ),
                                  ),
                                );
                              },
                            );
                          }
                          // O combo "estoura" (encolhe/some) dando lugar à letra.
                          return AnimatedSwitcher(
                            duration: const Duration(milliseconds: 160),
                            switchInCurve: Curves.easeOut,
                            switchOutCurve: Curves.easeIn,
                            transitionBuilder: (widget, animation) =>
                                ScaleTransition(
                              scale: animation,
                              child: FadeTransition(
                                  opacity: animation, child: widget),
                            ),
                            child: child,
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PauseOverlay extends StatelessWidget {
  final VoidCallback onResume;

  const _PauseOverlay({required this.onResume});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xCC070B14),
      alignment: Alignment.center,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'PAUSADO',
            style: TextStyle(
              color: Color(0xFF00E5FF),
              fontSize: 26,
              fontWeight: FontWeight.bold,
              letterSpacing: 6,
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: 220,
            child: FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF00E5FF),
                foregroundColor: const Color(0xFF070B14),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              onPressed: onResume,
              child: const Text(
                'CONTINUAR',
                style:
                    TextStyle(fontWeight: FontWeight.bold, letterSpacing: 2),
              ),
            ),
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text(
              'MENU',
              style: TextStyle(color: Color(0xFF8A93B2), letterSpacing: 2),
            ),
          ),
        ],
      ),
    );
  }
}

class _GameOverOverlay extends StatelessWidget {
  final WordBlasterGame game;
  final VoidCallback onRestart;

  const _GameOverOverlay({required this.game, required this.onRestart});

  @override
  Widget build(BuildContext context) {
    final review = ProgressService.hardestWords();
    return Container(
      color: const Color(0xCC070B14),
      alignment: Alignment.center,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 32),
        padding: const EdgeInsets.all(28),
        decoration: BoxDecoration(
          color: const Color(0xFF10162A),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFF2A3350)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'FIM DE JOGO',
              style: TextStyle(
                color: Color(0xFFFF2E88),
                fontSize: 24,
                fontWeight: FontWeight.bold,
                letterSpacing: 4,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              '${game.score.value}',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 44,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              'Recorde: ${ProgressService.bestScore}',
              style: const TextStyle(color: Color(0xFF8A93B2), fontSize: 14),
            ),
            const SizedBox(height: 16),
            _statRow('Palavras destruídas', '${game.runWords}'),
            _statRow('XP ganho', '+${game.runXp}'),
            _statRow('Precisão', '${(game.accuracy * 100).toStringAsFixed(0)}%'),
            if (review.isNotEmpty) ...[
              const SizedBox(height: 16),
              const Text(
                'REVISE ESTAS PALAVRAS',
                style: TextStyle(
                  color: Color(0xFF8A93B2),
                  fontSize: 11,
                  letterSpacing: 2,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: review
                    .map((w) => ActionChip(
                          avatar: const Icon(Icons.volume_up,
                              size: 16, color: Color(0xFF00E5FF)),
                          label: Text(w),
                          labelStyle: const TextStyle(
                              color: Color(0xFF00E5FF), fontSize: 13),
                          backgroundColor: const Color(0xFF141A2E),
                          side: const BorderSide(color: Color(0xFF2A3350)),
                          onPressed: () => TtsService.speak(w),
                        ))
                    .toList(),
              ),
            ],
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF00E5FF),
                  foregroundColor: const Color(0xFF070B14),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                onPressed: onRestart,
                child: const Text(
                  'JOGAR DE NOVO',
                  style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 2),
                ),
              ),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text(
                'MENU',
                style: TextStyle(color: Color(0xFF8A93B2), letterSpacing: 2),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _statRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: const TextStyle(color: Color(0xFF8A93B2), fontSize: 14)),
          Text(value,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
