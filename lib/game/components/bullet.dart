import 'dart:ui';

import 'package:flame/components.dart';

import 'word_enemy.dart';

/// Projétil teleguiado: um tiro por letra digitada corretamente.
class Bullet extends PositionComponent {
  // Rápida o bastante para ser ágil, lenta o bastante para a rajada de
  // "uma bala por letra" ser visível na tela.
  static const _speed = 750.0;
  final WordEnemy target;

  Bullet({required Vector2 start, required this.target})
      : super(position: start, size: Vector2.all(6), anchor: Anchor.center);

  @override
  void update(double dt) {
    super.update(dt);
    if (!target.isMounted) {
      removeFromParent();
      return;
    }
    final goal = target.absoluteCenter;
    final delta = goal - position;
    final distance = delta.length;
    final step = _speed * dt;
    if (distance <= step) {
      target.onBulletHit();
      removeFromParent();
    } else {
      position += delta..scale(step / distance);
    }
  }

  @override
  void render(Canvas canvas) {
    final glow = Paint()
      ..color = const Color(0xFF00E5FF).withValues(alpha: 0.7)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
    canvas.drawCircle(const Offset(3, 3), 5, glow);
    canvas.drawCircle(const Offset(3, 3), 2.5, Paint()..color = const Color(0xFFFFFFFF));
  }
}
