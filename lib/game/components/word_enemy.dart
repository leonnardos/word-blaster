import 'package:flame/components.dart';
import 'package:flutter/painting.dart';

import '../../data/word_bank.dart';
import '../../services/progress_service.dart';
import 'enemy_vehicle.dart';

/// Inimigo-palavra que desce em direção à nave — um VEÍCULO inimigo
/// (jipe/blindado/tanque, conforme o tamanho da palavra) com a placa da
/// palavra logo abaixo. Cada tiro certeiro chamusca o casco até explodir.
///
/// A placa mostra a palavra em inglês (alvo de digitação) e a tradução
/// PT-BR menor — a parte já digitada acende em ciano.
class WordEnemy extends PositionComponent {
  final Word wordData;
  final double speed;
  final void Function(WordEnemy) onDestroyed;
  final void Function(WordEnemy) onReachedBottom;

  /// Posição do tanque: no começo a palavra cai reto, e quanto mais perto
  /// do fim, mais ela converge para o tanque (estilo ZType).
  final Vector2 Function()? homingTarget;

  /// Letras já digitadas: mira lógica E destaque visual — a letra acende no
  /// instante da tecla (estilo ZType), sem esperar a bala chegar, para o
  /// jogador ver na hora qual letra falta.
  int _typed = 0;

  /// Balas que já chegaram (controlam a destruição, não o destaque).
  int _revealed = 0;

  bool isTargeted = false;
  bool _dead = false;
  bool _revealedByError = false;
  bool _hidden = false;
  double _errorFlash = 0;
  double _hitFlash = 0;

  late TextPainter _enPainter;
  late TextPainter _ptPainter;
  bool _showPt = true;
  double _bottomLimit = double.infinity;
  double _plateWidth = 0;
  double _plateHeight = 0;

  /// 0 = jipe (palavra curta), 1 = blindado (média), 2 = tanque (longa
  /// ou frase) — determinístico por palavra.
  late final int vehicleKind;

  WordEnemy({
    required this.wordData,
    required this.speed,
    required Vector2 position,
    required this.onDestroyed,
    required this.onReachedBottom,
    this.homingTarget,
  }) : super(position: position, anchor: Anchor.center) {
    final en = wordData.en;
    vehicleKind = (en.contains(' ') || en.length >= 8)
        ? 2
        : en.length >= 5
            ? 1
            : 0;
    _rebuildText();
  }

  String get word => wordData.en;

  int get typed => _typed;

  bool get isAlive => !_dead;

  /// A palavra está mascarada (***) agora? Usado quando ela estoura no
  /// tanque: oculta que morre sem ser digitada é revelada na tela.
  bool get isHiddenNow => _hidden;

  /// Chamado pelo jogo a cada letra correta: acende a letra imediatamente.
  /// ESPAÇOS são neutros (pedido do usuário): o avanço pula por cima deles
  /// sozinho — "good morning" se digita "goodmorning" (ou com espaço, que
  /// a tecla é ignorada pelo jogo; ver onTyped).
  void advanceTyped() {
    if (_typed < word.length) {
      _typed++;
      while (_typed < word.length && word[_typed] == ' ') {
        _typed++;
      }
      _rebuildText();
    }
  }

  /// Reconstrói o texto quando o jogador liga/desliga a tradução.
  void refreshText() => _rebuildText();

  /// Errou uma palavra oculta: ela se revela — "ah, hammer tem dois m!".
  void revealWord() {
    _revealedByError = true;
    _rebuildText();
  }

  set bottomLimit(double value) => _bottomLimit = value;

  void _rebuildText() {
    // Exo 2 (não Orbitron): a palavra que desce precisa ser LEGÍVEL —
    // feedback do usuário jogando no celular.
    const baseStyle = TextStyle(
      fontFamily: 'Exo2',
      fontSize: 20,
      fontWeight: FontWeight.w600,
      letterSpacing: 1.2,
    );
    // Maestria (PLANO §1.4): dominada vira RECALL INVERTIDO — a palavra em
    // inglês vem OCULTA (asteriscos + ★) e a tradução é a dica; as letras
    // se revelam conforme o jogador acerta (aprende a grafia, ex.: 2 "m"
    // em hammer).
    final mastery = ProgressService.statFor(word).mastery;
    // Oculta: dominada de verdade OU modo estudo ligado — a menos que um
    // erro já tenha revelado esta palavra.
    final hidden = !_revealedByError &&
        (mastery == Mastery.dominada || ProgressService.hiddenMode);
    _hidden = hidden;
    final rest = word.substring(_typed);
    _enPainter = TextPainter(
      text: TextSpan(
        children: [
          TextSpan(
            text: word.substring(0, _typed),
            style: baseStyle.copyWith(color: const Color(0xFF00E5FF)),
          ),
          TextSpan(
            // Oculta: mascara o que falta (espaços continuam visíveis para
            // frases mostrarem os limites das palavras).
            text: hidden ? rest.replaceAll(RegExp(r'[^ ]'), '*') : rest,
            style: baseStyle.copyWith(color: const Color(0xFFF5F7FA)),
          ),
          // A ★ marca maestria DE VERDADE (6+ acertos), não o modo estudo.
          if (hidden && mastery == Mastery.dominada)
            TextSpan(
              text: ' ★',
              style: baseStyle.copyWith(
                  color: const Color(0xFFFFC93C), fontSize: 14),
            ),
        ],
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    // Andaime da tradução: visível (nova) → esmaecida (aprendendo).
    // Na OCULTA a tradução é a dica principal — aparece SEMPRE (até com o
    // toggle 文A desligado) e um pouco mais viva.
    _showPt = hidden || ProgressService.showTranslation;
    _ptPainter = TextPainter(
      text: TextSpan(
        text: _showPt ? wordData.pt : '',
        style: TextStyle(
          fontFamily: 'Exo2',
          fontSize: hidden ? 13 : 12,
          fontStyle: FontStyle.italic,
          color: hidden
              ? const Color(0xFFB9C2D8) // dica do recall: em destaque
              : mastery == Mastery.aprendendo
                  ? const Color(0x668A93B2) // esmaecida: quase lá!
                  : const Color(0xFF8A93B2),
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    final textWidth =
        _enPainter.width > _ptPainter.width ? _enPainter.width : _ptPainter.width;
    _plateWidth = textWidth + 24;
    _plateHeight = _contentHeight + 12;
    final veh = enemyVehicleSize(vehicleKind);
    size = Vector2(
      _plateWidth > veh.width ? _plateWidth : veh.width,
      veh.height + 3 + _plateHeight,
    );
  }

  /// Altura real do conteúdo: só a palavra, ou palavra + tradução.
  double get _contentHeight =>
      _enPainter.height + (_showPt ? _ptPainter.height + 2 : 0);

  /// Chamado pelo projétil ao atingir o inimigo. O destaque das letras já
  /// aconteceu na digitação; aqui fica só o flash e a destruição final.
  void onBulletHit() {
    if (_dead) return;
    _hitFlash = 0.12;
    if (_revealed < word.length) {
      _revealed++;
      // Balas são uma por LETRA: os espaços (neutros) contam de carona,
      // senão a frase nunca somaria o total e não explodiria.
      while (_revealed < word.length && word[_revealed] == ' ') {
        _revealed++;
      }
    }
    if (_revealed >= word.length) {
      _dead = true;
      onDestroyed(this);
    }
  }

  void flashError() => _errorFlash = 0.25;

  @override
  void update(double dt) {
    super.update(dt);
    if (_dead) return;

    final home = homingTarget?.call();
    if (home != null && _bottomLimit.isFinite && _bottomLimit > 0) {
      // Mistura: cai reto no topo e converge para o tanque perto do fim.
      final progress = (position.y / _bottomLimit).clamp(0.0, 1.0);
      final pull = progress * 0.85;
      final toTank = home - position;
      if (toTank.length2 > 1) toTank.normalize();
      final dir = Vector2(0, 1) * (1 - pull) + toTank * pull;
      if (dir.length2 > 0.001) dir.normalize();
      position += dir * (speed * dt);
    } else {
      position.y += speed * dt;
    }

    if (_errorFlash > 0) _errorFlash -= dt;
    if (_hitFlash > 0) _hitFlash -= dt;
    if (position.y >= _bottomLimit) {
      _dead = true;
      onReachedBottom(this);
    }
  }

  @override
  void render(Canvas canvas) {
    final veh = enemyVehicleSize(vehicleKind);
    final vehX = (size.x - veh.width) / 2;

    // Mira travada: anel ciano sob o veículo (o alvo é ELE).
    if (isTargeted) {
      canvas.drawCircle(
        Offset(size.x / 2, veh.height * 0.5),
        veh.width * 0.62,
        Paint()
          ..color = const Color(0xFF00E5FF).withValues(alpha: 0.35)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
      );
    }

    // O veículo descendo, chamuscando conforme apanha dos tiros.
    canvas.save();
    canvas.translate(vehX, 0);
    drawEnemyVehicle(
      canvas,
      vehicleKind,
      seed: word.hashCode,
      damage: word.isEmpty ? 0 : _revealed / word.length,
    );
    canvas.restore();
    // Erro tinge o veículo de vermelho por um instante.
    if (_errorFlash > 0) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(vehX, 0, veh.width, veh.height),
          const Radius.circular(10),
        ),
        Paint()..color = const Color(0xFFFF2E2E).withValues(alpha: 0.25),
      );
    }

    // Placa da palavra, logo abaixo do veículo.
    final plateRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(
        (size.x - _plateWidth) / 2,
        veh.height + 3,
        _plateWidth,
        _plateHeight,
      ),
      const Radius.circular(9),
    );

    var bgColor = const Color(0xFF141A2E).withValues(alpha: 0.92);
    if (_errorFlash > 0) bgColor = const Color(0xFF7A1B2E);
    if (_hitFlash > 0) bgColor = const Color(0xFF1E3A50);
    canvas.drawRRect(plateRect, Paint()..color = bgColor);

    final borderColor = isTargeted
        ? const Color(0xFF00E5FF)
        : const Color(0xFF2A3350);
    final border = Paint()
      ..color = borderColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = isTargeted ? 2 : 1;
    if (isTargeted) {
      final glow = Paint()
        ..color = const Color(0xFF00E5FF).withValues(alpha: 0.4)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 5
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5);
      canvas.drawRRect(plateRect, glow);
    }
    canvas.drawRRect(plateRect, border);

    // Conteúdo centralizado na placa (com ou sem tradução).
    final top = veh.height + 3 + (_plateHeight - _contentHeight) / 2;
    final enX = (size.x - _enPainter.width) / 2;
    _enPainter.paint(canvas, Offset(enX, top));
    if (_showPt) {
      final ptX = (size.x - _ptPainter.width) / 2;
      _ptPainter.paint(canvas, Offset(ptX, top + _enPainter.height + 2));
    }
  }
}
