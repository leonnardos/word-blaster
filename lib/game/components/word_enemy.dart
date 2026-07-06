import 'package:flame/components.dart';
import 'package:flutter/painting.dart';

import '../../data/word_bank.dart';
import '../../services/progress_service.dart';

/// Inimigo-palavra que desce em direção à nave.
///
/// Mostra a palavra em inglês (alvo de digitação) e a tradução em PT-BR
/// menor logo abaixo — assim o jogador aprende o significado enquanto atira.
/// A parte já digitada acende em ciano; o restante fica branco.
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
  double _errorFlash = 0;
  double _hitFlash = 0;

  late TextPainter _enPainter;
  late TextPainter _ptPainter;
  bool _showPt = true;
  double _bottomLimit = double.infinity;

  WordEnemy({
    required this.wordData,
    required this.speed,
    required Vector2 position,
    required this.onDestroyed,
    required this.onReachedBottom,
    this.homingTarget,
  }) : super(position: position, anchor: Anchor.center) {
    _rebuildText();
  }

  String get word => wordData.en;

  int get typed => _typed;

  bool get isAlive => !_dead;

  /// Chamado pelo jogo a cada letra correta: acende a letra imediatamente.
  void advanceTyped() {
    if (_typed < word.length) {
      _typed++;
      _rebuildText();
    }
  }

  /// Reconstrói o texto quando o jogador liga/desliga a tradução.
  void refreshText() => _rebuildText();

  set bottomLimit(double value) => _bottomLimit = value;

  void _rebuildText() {
    const baseStyle = TextStyle(
      fontSize: 20,
      fontWeight: FontWeight.w600,
      letterSpacing: 1.2,
    );
    // Maestria (PLANO §1.4): dominada perde a tradução e ganha uma ★.
    final mastery = ProgressService.statFor(word).mastery;
    _enPainter = TextPainter(
      text: TextSpan(
        children: [
          TextSpan(
            text: word.substring(0, _typed),
            style: baseStyle.copyWith(color: const Color(0xFF00E5FF)),
          ),
          TextSpan(
            text: word.substring(_typed),
            style: baseStyle.copyWith(color: const Color(0xFFF5F7FA)),
          ),
          if (mastery == Mastery.dominada)
            TextSpan(
              text: ' ★',
              style: baseStyle.copyWith(
                  color: const Color(0xFFFFC93C), fontSize: 14),
            ),
        ],
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    // Andaime da tradução: visível (nova) → esmaecida (aprendendo) → some
    // (dominada, ou toggle manual desligado). A caixinha colapsa e centraliza
    // — e ainda dá para espiar segurando (cartão de dicionário).
    _showPt =
        ProgressService.showTranslation && mastery != Mastery.dominada;
    _ptPainter = TextPainter(
      text: TextSpan(
        text: _showPt ? wordData.pt : '',
        style: TextStyle(
          fontSize: 12,
          fontStyle: FontStyle.italic,
          color: mastery == Mastery.aprendendo
              ? const Color(0x668A93B2) // esmaecida: quase lá!
              : const Color(0xFF8A93B2),
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    final textWidth =
        _enPainter.width > _ptPainter.width ? _enPainter.width : _ptPainter.width;
    size = Vector2(textWidth + 28, _contentHeight + 14);
  }

  /// Altura real do conteúdo: só a palavra, ou palavra + tradução.
  double get _contentHeight =>
      _enPainter.height + (_showPt ? _ptPainter.height + 2 : 0);

  /// Chamado pelo projétil ao atingir o inimigo. O destaque das letras já
  /// aconteceu na digitação; aqui fica só o flash e a destruição final.
  void onBulletHit() {
    if (_dead) return;
    _hitFlash = 0.12;
    if (_revealed < word.length) _revealed++;
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
    final rect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, size.x, size.y),
      const Radius.circular(10),
    );

    var bgColor = const Color(0xFF141A2E).withValues(alpha: 0.92);
    if (_errorFlash > 0) bgColor = const Color(0xFF7A1B2E);
    if (_hitFlash > 0) bgColor = const Color(0xFF1E3A50);
    canvas.drawRRect(rect, Paint()..color = bgColor);

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
      canvas.drawRRect(rect, glow);
    }
    canvas.drawRRect(rect, border);

    // Conteúdo centralizado verticalmente (com ou sem tradução).
    final top = (size.y - _contentHeight) / 2;
    final enX = (size.x - _enPainter.width) / 2;
    _enPainter.paint(canvas, Offset(enX, top));
    if (_showPt) {
      final ptX = (size.x - _ptPainter.width) / 2;
      _ptPainter.paint(canvas, Offset(ptX, top + _enPainter.height + 2));
    }
  }
}
