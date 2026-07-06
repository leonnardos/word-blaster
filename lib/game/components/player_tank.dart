import 'dart:math';
import 'dart:ui';

import 'package:flame/components.dart';

import 'battlefield.dart';

/// Veículo do jogador, seguindo a arte de referência: quatro RODAS grandes
/// de pneu com gomos (girando — ele está sempre avançando), casco branco
/// blindado com placa octogonal central e DOMO azul brilhante, e canhão
/// duplo de pontas azuis que emerge por baixo da placa central.
/// O casco fica plantado; só o conjunto dos canhões gira para mirar.
class PlayerTank extends PositionComponent {
  // Paleta da referência.
  static const _blue = Color(0xFF2FB7F2);
  static const _blueLight = Color(0xFF8FD9FF);
  static const _tire = Color(0xFF23272D);
  static const _tireGroove = Color(0xFF10131A);
  static const _tireEdge = Color(0xFF3A424B);
  static const _outlineColor = Color(0xFF15181D);
  static const _plate = Color(0xFFD9DDE2);
  static const _plateBright = Color(0xFFEDF0F3);
  static const _plateMid = Color(0xFF9BA3AB);
  static const _seam = Color(0xFF9AA1A8);
  static const _dark = Color(0xFF2A2F35);
  static const _barrel = Color(0xFFC7CDD3);

  /// Ângulo atual dos canhões (0 = para cima). O componente não gira.
  double aimAngle = 0;

  double _targetAngle = 0;
  double _turnSpeed = 18;

  /// Deslocamento dos gomos dos pneus (anima o "andar").
  static const _grooveSpacing = 5.5;
  double _treadScroll = 0;

  PlayerTank() : super(size: Vector2(60, 64), anchor: Anchor.center);

  /// Ponta do cano (esquerdo ou direito) em coordenadas do mundo — as balas
  /// saem alternando entre os dois canos.
  Vector2 muzzleTip({required bool left}) {
    final local = Vector2(left ? -4.5 : 4.5, -37);
    final c = cos(aimAngle);
    final s = sin(aimAngle);
    return position +
        Vector2(local.x * c - local.y * s, local.x * s + local.y * c);
  }

  /// Gira os canhões rápido para apontar ao ponto dado.
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

  /// Quão longe (em radianos) os canhões estão de apontar para o ponto.
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
    // Pneus rolam em sincronia com o chão: veículo avançando.
    _treadScroll =
        (_treadScroll + Battlefield.scrollSpeed * dt) % _grooveSpacing;
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
    final outline = Paint()
      ..color = _outlineColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6;

    // Sombra no chão.
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(2, 5, w - 4, h - 6),
        const Radius.circular(12),
      ),
      Paint()
        ..color = const Color(0xAA000000)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
    );

    // ------------------------- casco branco em cruz ------------------------
    final plateH = RRect.fromRectAndRadius(
      Rect.fromLTWH(4, 19, w - 8, h - 38),
      const Radius.circular(7),
    );
    final plateV = RRect.fromRectAndRadius(
      Rect.fromLTWH(15, 3, w - 30, h - 6),
      const Radius.circular(7),
    );
    canvas.drawRRect(plateH, Paint()..color = _plate);
    canvas.drawRRect(plateV, Paint()..color = _plate);
    canvas.drawRRect(plateH, outline);
    canvas.drawRRect(plateV, outline);

    // Para-choque frontal e traseiro.
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(w / 2 - 8, 0, 16, 5),
        const Radius.circular(2),
      ),
      Paint()..color = _plateMid,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(w / 2 - 7, h - 5, 14, 5),
        const Radius.circular(2),
      ),
      Paint()..color = _plateMid,
    );

    // Rebites e seams de blindagem.
    final rivet = Paint()..color = _seam;
    for (final p in [
      Offset(19, 9),
      Offset(w - 19, 9),
      Offset(19, h - 9),
      Offset(w - 19, h - 9),
      Offset(9, 24),
      Offset(w - 9, 24),
      Offset(9, h - 24),
      Offset(w - 9, h - 24),
    ]) {
      canvas.drawCircle(p, 1.1, rivet);
    }
    final seamLine = Paint()
      ..color = _seam
      ..strokeWidth = 1;
    canvas.drawLine(Offset(w / 2 - 6, 12), Offset(w / 2 + 6, 12), seamLine);
    canvas.drawLine(
        Offset(w / 2, h - 16), Offset(w / 2, h - 8), seamLine);
    // Logo (chevron duplo) na traseira.
    final chevron = Paint()
      ..color = _seam
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4;
    for (final dy in [0.0, 4.0]) {
      final y = h - 15 + dy;
      canvas.drawPath(
        Path()
          ..moveTo(w / 2 - 4, y)
          ..lineTo(w / 2, y + 3)
          ..lineTo(w / 2 + 4, y),
        chevron,
      );
    }

    // ------------------------- rodas com pneus girando ---------------------
    for (final corner in [
      const Offset(0, 1),
      Offset(w - 20, 1),
      Offset(0, h - 27),
      Offset(w - 20, h - 27),
    ]) {
      final wheel = RRect.fromRectAndRadius(
        Rect.fromLTWH(corner.dx, corner.dy, 20, 26),
        const Radius.circular(9),
      );
      canvas.drawRRect(wheel, Paint()..color = _tire);
      canvas.save();
      canvas.clipRRect(wheel);
      // Gomos do pneu descendo em loop.
      final groove = Paint()
        ..color = _tireGroove
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round;
      final knob = Paint()
        ..color = _tireEdge
        ..strokeWidth = 1.2;
      for (var y = corner.dy - _grooveSpacing + _treadScroll;
          y < corner.dy + 28;
          y += _grooveSpacing) {
        canvas.drawLine(
            Offset(corner.dx + 2, y), Offset(corner.dx + 18, y), groove);
        canvas.drawLine(Offset(corner.dx + 2, y + 2.6),
            Offset(corner.dx + 18, y + 2.6), knob);
      }
      // Sulco circunferencial central do pneu.
      canvas.drawRect(
        Rect.fromLTWH(corner.dx + 9, corner.dy, 2, 26),
        Paint()..color = _tireGroove,
      );
      canvas.restore();
      canvas.drawRRect(wheel, outline);
    }

    // --------------- canhão duplo (gira; passa por baixo da placa) ---------
    canvas.save();
    canvas.translate(w / 2, h / 2);
    canvas.rotate(aimAngle);

    for (final dx in const [-4.5, 4.5]) {
      // Bloco de montagem escuro (fica escondido sob a placa central).
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(dx - 3, -16, 6, 9),
          const Radius.circular(2),
        ),
        Paint()..color = _dark,
      );
      // Cano prateado segmentado.
      final barrel = RRect.fromRectAndRadius(
        Rect.fromLTWH(dx - 2.2, -34, 4.4, 20),
        const Radius.circular(2),
      );
      canvas.drawRRect(barrel, Paint()..color = _barrel);
      canvas.drawRRect(barrel, outline);
      for (final y in const [-28.0, -22.0]) {
        canvas.drawRect(
          Rect.fromLTWH(dx - 2.2, y, 4.4, 2.2),
          Paint()..color = _seam,
        );
      }
      // Ponta azul incandescente.
      final tip = RRect.fromRectAndRadius(
        Rect.fromLTWH(dx - 2.8, -38.5, 5.6, 5.5),
        const Radius.circular(2.4),
      );
      canvas.drawRRect(
        tip,
        Paint()
          ..color = _blue.withValues(alpha: 0.7)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5),
      );
      canvas.drawRRect(tip, Paint()..color = _blue);
      canvas.drawCircle(Offset(dx, -36), 1.1,
          Paint()..color = const Color(0xE6FFFFFF));
    }
    // Halo suave nas bocas dos canos.
    canvas.drawCircle(
      const Offset(0, -38),
      7,
      Paint()
        ..color = _blue.withValues(alpha: 0.22)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
    );

    canvas.restore();

    // -------------- placa octogonal central + domo azul (por cima) ---------
    final cx = w / 2;
    final cy = h / 2;
    final octagon = Path()
      ..moveTo(cx - 7, cy - 13)
      ..lineTo(cx + 7, cy - 13)
      ..lineTo(cx + 13, cy - 7)
      ..lineTo(cx + 13, cy + 7)
      ..lineTo(cx + 7, cy + 13)
      ..lineTo(cx - 7, cy + 13)
      ..lineTo(cx - 13, cy + 7)
      ..lineTo(cx - 13, cy - 7)
      ..close();
    canvas.drawPath(octagon, Paint()..color = _plateBright);
    canvas.drawPath(octagon, outline);
    // Seam interno da placa.
    canvas.drawPath(
      Path()
        ..moveTo(cx - 5.5, cy - 10)
        ..lineTo(cx + 5.5, cy - 10)
        ..lineTo(cx + 10, cy - 5.5)
        ..lineTo(cx + 10, cy + 5.5)
        ..lineTo(cx + 5.5, cy + 10)
        ..lineTo(cx - 5.5, cy + 10)
        ..lineTo(cx - 10, cy + 5.5)
        ..lineTo(cx - 10, cy - 5.5)
        ..close(),
      Paint()
        ..color = _seam
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1,
    );

    // Domo azul: aro escuro + vidro com brilho.
    canvas.drawCircle(Offset(cx, cy), 9, Paint()..color = _dark);
    canvas.drawCircle(Offset(cx, cy), 9, outline);
    final glass = Rect.fromCenter(
        center: Offset(cx, cy), width: 12, height: 14.5);
    canvas.drawOval(
      glass,
      Paint()
        ..color = _blue.withValues(alpha: 0.55)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
    );
    canvas.drawOval(glass, Paint()..color = _blue);
    canvas.drawOval(
      Rect.fromCenter(
          center: Offset(cx - 1.2, cy - 2.2), width: 6.5, height: 8),
      Paint()..color = _blueLight,
    );
    canvas.drawCircle(Offset(cx - 2.2, cy - 4), 1.3,
        Paint()..color = const Color(0xF2FFFFFF));
  }
}
