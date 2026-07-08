import 'dart:ui';

import 'package:flame/components.dart';

import 'battlefield.dart';

class _TreadMark {
  final Vector2 pos;
  double age = 0;

  _TreadMark(this.pos);
}

/// Marcas de esteira/pneu deixadas pelos VEÍCULOS INIMIGOS na estrada —
/// a prova visual de que estão andando. Ficam no chão (rolam junto com o
/// cenário) e somem em ~1,5s: só um rastro curto de "pegadas", nunca
/// crescendo sem parar (pedido do usuário).
class EnemyTrails extends Component {
  static const _life = 1.5;
  final List<_TreadMark> _marks = [];

  void drop(Vector2 worldPos) {
    _marks.add(_TreadMark(worldPos.clone()));
    // Trava de segurança: nunca acumula além do razoável.
    if (_marks.length > 220) _marks.removeRange(0, _marks.length - 220);
  }

  void clear() => _marks.clear();

  @override
  void update(double dt) {
    for (var i = _marks.length - 1; i >= 0; i--) {
      final mark = _marks[i];
      mark.age += dt;
      // A marca fica no CHÃO: rola para baixo junto com o cenário.
      mark.pos.y += Battlefield.scrollSpeed * dt;
      if (mark.age >= _life) _marks.removeAt(i);
    }
  }

  @override
  void render(Canvas canvas) {
    for (final mark in _marks) {
      final alpha = (1 - mark.age / _life) * 0.55;
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(
              center: Offset(mark.pos.x, mark.pos.y), width: 6, height: 9),
          const Radius.circular(2),
        ),
        Paint()..color = const Color(0xFF0D0A06).withValues(alpha: alpha),
      );
    }
  }
}
