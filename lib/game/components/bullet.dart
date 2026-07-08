import 'dart:math';
import 'dart:ui';

import 'package:flame/components.dart';

import 'word_enemy.dart';

/// Míssil: corpo fino branco, bico pontudo e aletas vermelhas, com rastro
/// de fogo — sempre apontando na direção do voo. Um por letra digitada.
class Bullet extends PositionComponent {
  // Rápida o bastante para ser ágil, lenta o bastante para a rajada de
  // "uma bala por letra" ser visível na tela.
  static const _speed = 750.0;
  final WordEnemy target;

  /// Chamado quando o projétil acerta a palavra (tremida/clareada da tela).
  final void Function()? onImpact;

  double _angle = 0;

  Bullet({required Vector2 start, required this.target, this.onImpact})
      : super(position: start, size: Vector2(14, 36), anchor: Anchor.center);

  @override
  void update(double dt) {
    super.update(dt);
    if (!target.isMounted) {
      removeFromParent();
      return;
    }
    final goal = target.vehicleCenter; // mira no VEÍCULO, não na placa
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

    const red = Color(0xFFD8402C);
    final outline = Paint()
      ..color = const Color(0xFF11141A)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;

    // Rastro de fogo atrás do míssil.
    canvas.drawCircle(
      const Offset(0, 22),
      5,
      Paint()
        ..color = const Color(0xFFC33B12).withValues(alpha: 0.35)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
    );
    canvas.drawCircle(
      const Offset(0, 16),
      6.5,
      Paint()
        ..color = const Color(0xFFFF7A1A).withValues(alpha: 0.6)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5),
    );
    canvas.drawCircle(
      const Offset(0, 11),
      4.5,
      Paint()
        ..color = const Color(0xFFFFC93C).withValues(alpha: 0.85)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3),
    );

    // Aletas traseiras vermelhas.
    final fins = Path()
      ..moveTo(-2.4, 6)
      ..lineTo(-6.2, 12)
      ..lineTo(-2.4, 12)
      ..lineTo(-2.4, 6)
      ..moveTo(2.4, 6)
      ..lineTo(6.2, 12)
      ..lineTo(2.4, 12)
      ..lineTo(2.4, 6);
    canvas.drawPath(fins, Paint()..color = red);
    canvas.drawPath(fins, outline);

    // Corpo fino branco-prata.
    final body = RRect.fromRectAndRadius(
      const Rect.fromLTWH(-2.6, -12, 5.2, 24),
      const Radius.circular(2.4),
    );
    canvas.drawRRect(body, Paint()..color = const Color(0xFFE6EAEE));
    canvas.drawRRect(body, outline);
    // Faixa vermelha no meio do corpo.
    canvas.drawRect(
      const Rect.fromLTWH(-2.6, 0, 5.2, 3.2),
      Paint()..color = red,
    );

    // Bico pontudo vermelho.
    final nose = Path()
      ..moveTo(-2.6, -12)
      ..quadraticBezierTo(-1.4, -17, 0, -19.5)
      ..quadraticBezierTo(1.4, -17, 2.6, -12)
      ..close();
    canvas.drawPath(nose, Paint()..color = red);
    canvas.drawPath(nose, outline);

    canvas.restore();
  }
}
