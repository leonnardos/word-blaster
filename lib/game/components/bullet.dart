import 'dart:math';
import 'dart:ui';

import 'package:flame/components.dart';

import 'word_enemy.dart';

/// Projétil de canhão: cápsula escura de ponta prateada com rastro de fogo,
/// sempre apontando na direção do voo. Um tiro por letra digitada.
class Bullet extends PositionComponent {
  // Rápida o bastante para ser ágil, lenta o bastante para a rajada de
  // "uma bala por letra" ser visível na tela.
  static const _speed = 750.0;
  final WordEnemy target;

  /// Chamado quando o projétil acerta a palavra (tremida/clareada da tela).
  final void Function()? onImpact;

  double _angle = 0;

  Bullet({required Vector2 start, required this.target, this.onImpact})
      : super(position: start, size: Vector2(20, 40), anchor: Anchor.center);

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
    _angle = atan2(delta.x, -delta.y);
    final step = _speed * dt;
    if (distance <= step) {
      target.onBulletHit();
      onImpact?.call();
      removeFromParent();
    } else {
      position += delta..scale(step / distance);
    }
  }

  @override
  void render(Canvas canvas) {
    canvas.save();
    canvas.translate(size.x / 2, size.y / 2);
    canvas.rotate(_angle);

    // Rastro de fogo atrás do projétil.
    canvas.drawCircle(
      const Offset(0, 24),
      6,
      Paint()
        ..color = const Color(0xFFC33B12).withValues(alpha: 0.35)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 7),
    );
    canvas.drawCircle(
      const Offset(0, 16),
      8,
      Paint()
        ..color = const Color(0xFFFF7A1A).withValues(alpha: 0.6)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5),
    );
    canvas.drawCircle(
      const Offset(0, 10),
      5.6,
      Paint()
        ..color = const Color(0xFFFFC93C).withValues(alpha: 0.85)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3),
    );

    // Corpo do projétil: cápsula escura.
    final body = RRect.fromRectAndRadius(
      const Rect.fromLTWH(-5, -18, 10, 28),
      const Radius.circular(5),
    );
    canvas.drawRRect(body, Paint()..color = const Color(0xFF2A2F35));
    canvas.drawRRect(
      body,
      Paint()
        ..color = const Color(0xFF11141A)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.4,
    );
    // Ponta prateada.
    canvas.drawRRect(
      RRect.fromRectAndCorners(
        const Rect.fromLTWH(-5, -18, 10, 11),
        topLeft: const Radius.circular(5),
        topRight: const Radius.circular(5),
      ),
      Paint()..color = const Color(0xFFD8DDE2),
    );

    canvas.restore();
  }
}
