import 'dart:math';
import 'dart:ui';

import 'package:flame/components.dart';

import 'battlefield.dart';

/// Tanque do jogador: esteiras completas nas laterais com gomos GIRANDO
/// (na velocidade do chão — o tanque está sempre avançando), blindagem
/// clara no casco e torre central com CANHÃO DUPLO de pontas azuis.
/// O casco fica plantado; só a torre gira.
class PlayerTank extends PositionComponent {
  // Paleta da referência.
  static const _blue = Color(0xFF2FB7F2);
  static const _podDark = Color(0xFF262B31);
  static const _outline = Color(0xFF11141A);
  static const _plate = Color(0xFFC2C9CF);
  static const _plateLight = Color(0xFFD8DDE2);
  static const _plateMid = Color(0xFF9BA3AB);
  static const _seam = Color(0xFF858D94);

  /// Ângulo atual da torre (0 = canhões para cima). O componente em si não
  /// gira; a rotação é aplicada só na torre, dentro do render.
  double aimAngle = 0;

  double _targetAngle = 0;
  double _turnSpeed = 18;

  /// Deslocamento dos gomos da esteira (anima o "andar" do tanque).
  static const _slatSpacing = 6.0;
  double _treadScroll = 0;

  PlayerTank() : super(size: Vector2(56, 62), anchor: Anchor.center);

  Offset get _turretCenter => Offset(size.x / 2, size.y * 0.52);

  /// Ponta do cano (esquerdo ou direito) em coordenadas do mundo — as balas
  /// saem alternando entre os dois canos.
  Vector2 muzzleTip({required bool left}) {
    final local = Vector2(left ? -5.5 : 5.5, -34);
    final c = cos(aimAngle);
    final s = sin(aimAngle);
    final turretOffset = Vector2(0, size.y * 0.02);
    return position +
        turretOffset +
        Vector2(local.x * c - local.y * s, local.x * s + local.y * c);
  }

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
    // Gomos rolam para baixo em sincronia com o chão: tanque avançando.
    _treadScroll = (_treadScroll + Battlefield.scrollSpeed * dt) % _slatSpacing;
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
      ..color = _outline
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6;

    // Sombra no chão.
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(2, 5, w - 4, h - 6),
        const Radius.circular(10),
      ),
      Paint()
        ..color = const Color(0xAA000000)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
    );

    // Base branca central: coluna + travessa ligando os quatro cantos.
    final plate = Paint()..color = _plate;
    final hullColumn = RRect.fromRectAndRadius(
      Rect.fromLTWH(12, 6, w - 24, h - 12),
      const Radius.circular(6),
    );
    final hullBand = RRect.fromRectAndRadius(
      Rect.fromLTWH(3, h / 2 - 6, w - 6, 12),
      const Radius.circular(4),
    );
    canvas.drawRRect(hullBand, plate);
    canvas.drawRRect(hullColumn, plate);
    canvas.drawRRect(hullBand, outline);
    canvas.drawRRect(hullColumn, outline);
    // Placa frontal (glacis) e seams de blindagem.
    final glacis = Path()
      ..moveTo(w / 2 - 10, 8)
      ..lineTo(w / 2 + 10, 8)
      ..lineTo(w / 2 + 6, 2)
      ..lineTo(w / 2 - 6, 2)
      ..close();
    canvas.drawPath(glacis, Paint()..color = _plateMid);
    canvas.drawPath(glacis, outline);
    final seam = Paint()
      ..color = _seam
      ..strokeWidth = 1;
    canvas.drawLine(Offset(w / 2, 10), Offset(w / 2, 20), seam);
    canvas.drawLine(Offset(w / 2, h - 20), Offset(w / 2, h - 8), seam);

    // Esteiras nos QUATRO cantos (como na referência), gomos rolando.
    final slat = Paint()
      ..color = const Color(0xFF3E4650)
      ..strokeWidth = 2.2;
    final rail = Paint()
      ..color = const Color(0xFF171B20)
      ..strokeWidth = 2.4;
    for (final corner in [
      const Offset(0, 2),
      Offset(w - 14, 2),
      Offset(0, h - 29),
      Offset(w - 14, h - 29),
    ]) {
      final pod = RRect.fromRectAndRadius(
        Rect.fromLTWH(corner.dx, corner.dy, 14, 27),
        const Radius.circular(5),
      );
      canvas.drawRRect(pod, Paint()..color = _podDark);
      canvas.save();
      canvas.clipRRect(pod);
      // Gomos descendo em loop — o tanque nunca para de andar.
      for (var y = corner.dy - _slatSpacing + _treadScroll;
          y < corner.dy + 29;
          y += _slatSpacing) {
        canvas.drawLine(
            Offset(corner.dx + 1.5, y), Offset(corner.dx + 12.5, y), slat);
      }
      // Trilho-guia central da esteira.
      canvas.drawLine(
        Offset(corner.dx + 7, corner.dy),
        Offset(corner.dx + 7, corner.dy + 27),
        rail,
      );
      canvas.restore();
      canvas.drawRRect(pod, outline);
    }

    // ------------------------- torre (gira pelo ângulo de mira) ------------
    canvas.save();
    canvas.translate(_turretCenter.dx, _turretCenter.dy);
    canvas.rotate(aimAngle);

    // Canhão duplo.
    for (final dx in const [-5.5, 5.5]) {
      final barrel = RRect.fromRectAndRadius(
        Rect.fromLTWH(dx - 2.2, -32, 4.4, 27),
        const Radius.circular(2),
      );
      canvas.drawRRect(barrel, Paint()..color = _plate);
      canvas.drawRRect(barrel, outline);
      // Anel do segmento.
      canvas.drawRect(
        Rect.fromLTWH(dx - 2.6, -19, 5.2, 4),
        Paint()..color = _seam,
      );
      // Ponta azul brilhante.
      final tip = RRect.fromRectAndRadius(
        Rect.fromLTWH(dx - 2.7, -34.5, 5.4, 6),
        const Radius.circular(2),
      );
      canvas.drawRRect(
        tip,
        Paint()
          ..color = _blue.withValues(alpha: 0.7)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
      );
      canvas.drawRRect(tip, Paint()..color = _blue);
      canvas.drawRRect(tip, outline);
    }

    // Corpo da torre: placa chanfrada.
    final housing = Path()
      ..moveTo(-7, -11)
      ..lineTo(7, -11)
      ..lineTo(12, -6)
      ..lineTo(12, 7)
      ..lineTo(7, 12)
      ..lineTo(-7, 12)
      ..lineTo(-12, 7)
      ..lineTo(-12, -6)
      ..close();
    canvas.drawPath(housing, Paint()..color = _plateLight);
    canvas.drawPath(housing, outline);
    // Detalhe traseiro e seam interno.
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(-5, 8, 10, 6),
        const Radius.circular(2),
      ),
      Paint()..color = _podDark,
    );
    canvas.drawLine(const Offset(-8, -4), const Offset(8, -4), seam);

    // Domo central azul.
    final dome = Rect.fromCenter(
      center: const Offset(0, -1),
      width: 9,
      height: 12,
    );
    canvas.drawOval(
      dome,
      Paint()
        ..color = _blue.withValues(alpha: 0.55)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5),
    );
    canvas.drawOval(dome, Paint()..color = _blue);
    canvas.drawOval(dome, outline);
    canvas.drawCircle(const Offset(-1.4, -3.4), 1.4,
        Paint()..color = const Color(0xCCFFFFFF));

    canvas.restore();
  }
}
