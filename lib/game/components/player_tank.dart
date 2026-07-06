import 'dart:math';
import 'dart:ui';

import 'package:flame/components.dart';

/// Tanque de guerra do jogador: casco fixo com esteiras, e uma torre com
/// canhão que gira em direção ao alvo atual. Só a torre gira — é o que dá
/// a cara de tanque (o casco fica plantado no chão).
class PlayerTank extends PositionComponent {
  static const color = Color(0xFF00E5FF);

  /// Ângulo atual da torre (0 = canhão para cima). O componente em si não
  /// gira; a rotação é aplicada só na torre, dentro do render.
  double aimAngle = 0;

  double _targetAngle = 0;
  double _turnSpeed = 18;

  PlayerTank() : super(size: Vector2(46, 50), anchor: Anchor.center);

  /// Gira a torre rápido para apontar ao ponto dado (coordenadas do jogo).
  void aimAt(Vector2 point) {
    final delta = point - position;
    _targetAngle = atan2(delta.x, -delta.y);
    _turnSpeed = 18; // ataque: giro ágil
  }

  /// Volta a apontar para cima devagar — o retorno lento é o que dá
  /// naturalidade depois de estourar a palavra.
  void aimStraightUp() {
    _targetAngle = 0;
    _turnSpeed = 4;
  }

  /// Quão longe (em radianos) a torre está de apontar para o ponto.
  /// Usado para só atirar quando ela realmente mirou o alvo.
  double aimError(Vector2 point) {
    final delta = point - position;
    var diff = atan2(delta.x, -delta.y) - aimAngle;
    while (diff > pi) {
      diff -= 2 * pi;
    }
    while (diff < -pi) {
      diff += 2 * pi;
    }
    return diff.abs();
  }

  @override
  void update(double dt) {
    super.update(dt);
    var diff = _targetAngle - aimAngle;
    while (diff > pi) {
      diff -= 2 * pi;
    }
    while (diff < -pi) {
      diff += 2 * pi;
    }
    aimAngle += diff * (_turnSpeed * dt).clamp(0.0, 1.0);
  }

  @override
  void render(Canvas canvas) {
    final w = size.x;
    final h = size.y;

    final glow = Paint()
      ..color = color.withValues(alpha: 0.45)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 9);
    final fill = Paint()..color = const Color(0xFF0A2530);
    final stroke = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6;

    // Esteiras (laterais) com gomos.
    final leftTrack = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, h * 0.14, w * 0.2, h * 0.78),
      const Radius.circular(5),
    );
    final rightTrack = RRect.fromRectAndRadius(
      Rect.fromLTWH(w * 0.8, h * 0.14, w * 0.2, h * 0.78),
      const Radius.circular(5),
    );
    canvas.drawRRect(leftTrack, glow);
    canvas.drawRRect(rightTrack, glow);
    canvas.drawRRect(leftTrack, fill);
    canvas.drawRRect(rightTrack, fill);
    canvas.drawRRect(leftTrack, stroke);
    canvas.drawRRect(rightTrack, stroke);
    final tread = Paint()
      ..color = color.withValues(alpha: 0.5)
      ..strokeWidth = 1;
    for (var i = 1; i < 5; i++) {
      final y = h * 0.14 + (h * 0.78) * i / 5;
      canvas.drawLine(Offset(1, y), Offset(w * 0.2 - 1, y), tread);
      canvas.drawLine(Offset(w * 0.8 + 1, y), Offset(w - 1, y), tread);
    }

    // Casco central.
    final hull = RRect.fromRectAndRadius(
      Rect.fromLTWH(w * 0.18, h * 0.22, w * 0.64, h * 0.62),
      const Radius.circular(6),
    );
    canvas.drawRRect(hull, fill);
    canvas.drawRRect(hull, stroke);

    // Torre + canhão, girados pelo ângulo de mira.
    final center = Offset(w / 2, h * 0.54);
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(aimAngle);

    final barrel = RRect.fromRectAndRadius(
      Rect.fromLTWH(-2.4, -h * 0.62, 4.8, h * 0.62),
      const Radius.circular(2),
    );
    canvas.drawRRect(barrel, glow);
    canvas.drawRRect(barrel, Paint()..color = const Color(0xFF10334A));
    canvas.drawRRect(barrel, stroke);
    // Boca do canhão.
    canvas.drawRect(
      Rect.fromLTWH(-3.4, -h * 0.62, 6.8, 4),
      Paint()..color = color,
    );

    canvas.drawCircle(Offset.zero, w * 0.19, glow);
    canvas.drawCircle(Offset.zero, w * 0.19, fill);
    canvas.drawCircle(Offset.zero, w * 0.19, stroke);
    canvas.drawCircle(
        Offset.zero, w * 0.07, Paint()..color = color.withValues(alpha: 0.9));

    canvas.restore();
  }
}
