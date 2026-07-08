/// Veículos inimigos desenhados por código (mesma técnica do PlayerTank),
/// vistos de cima e DESCENDO (frente para baixo, em direção ao jogador).
/// Paleta ferrugem + vermelho: o oposto hostil do branco/azul do jogador.
///
/// kind: 0 = jipe (palavras curtas), 1 = blindado (médias), 2 = tanque
/// (longas/frases). O dano 0..1 vai chamuscando o casco conforme as
/// letras são acertadas — o veículo "sente" os tiros até explodir.
library;

import 'dart:math';
import 'dart:ui';

// Paleta inimiga compartilhada.
const _outline = Color(0xFF15100C);
const _hull = Color(0xFF4A3126);
const _hullLight = Color(0xFF5F4232);
const _hullDark = Color(0xFF33231B);
const _track = Color(0xFF1E1A15);
const _trackEdge = Color(0xFF3B342C);
const _red = Color(0xFFC0392B);
const _redDark = Color(0xFF7E241B);
const _metal = Color(0xFF6B4A38);

/// Tamanho do sprite de cada tipo (largura, altura).
Size enemyVehicleSize(int kind) => switch (kind) {
      0 => const Size(36, 44),
      1 => const Size(44, 52),
      _ => const Size(54, 60),
    };

/// Desenha o veículo com o canto superior esquerdo em (0,0).
/// [phase] anima rodas/esteiras (avança com o movimento do veículo).
void drawEnemyVehicle(Canvas canvas, int kind,
    {required int seed, double damage = 0, double phase = 0}) {
  final s = enemyVehicleSize(kind);
  final w = s.width;
  final h = s.height;

  // Sombra no chão.
  canvas.drawRRect(
    RRect.fromRectAndRadius(
      Rect.fromLTWH(2, 4, w - 4, h - 5),
      const Radius.circular(10),
    ),
    Paint()
      ..color = const Color(0x99000000)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5),
  );

  switch (kind) {
    case 0:
      _drawJeep(canvas, w, h, phase);
    case 1:
      _drawApc(canvas, w, h, phase);
    default:
      _drawTank(canvas, w, h, phase);
  }

  _drawDamage(canvas, w, h, seed: seed, damage: damage);
}

/// Gomos animados dentro de um pneu/esteira: linhas que correm para TRÁS
/// (para cima) enquanto o veículo desce — rodas girando de verdade.
void _drawRolling(Canvas canvas, RRect tire, double phase, double spacing) {
  canvas.save();
  canvas.clipRRect(tire);
  final groove = Paint()
    ..color = const Color(0xFF0F0C09)
    ..strokeWidth = 1.4;
  final rect = tire.outerRect;
  final off = spacing - (phase % spacing);
  for (var y = rect.top - spacing + off; y < rect.bottom + 1; y += spacing) {
    canvas.drawLine(
        Offset(rect.left + 1, y), Offset(rect.right - 1, y), groove);
  }
  canvas.restore();
}

Paint get _outlinePaint => Paint()
  ..color = _outline
  ..style = PaintingStyle.stroke
  ..strokeWidth = 1.4;

/// Jipe de assalto: capô na frente (embaixo), para-brisa inclinado e
/// caçamba com carga atrás (em cima). Quatro pneus salientes.
void _drawJeep(Canvas canvas, double w, double h, double phase) {
  // Pneus (salientes nas laterais), girando — SEM borda clara: pneu de
  // carro é borracha escura (feedback do usuário).
  final tire = Paint()..color = _track;
  for (final ty in [h * 0.18, h * 0.68]) {
    for (final tx in [1.0, w - 8]) {
      final r = RRect.fromRectAndRadius(
        Rect.fromLTWH(tx, ty, 7, h * 0.18),
        const Radius.circular(3),
      );
      canvas.drawRRect(r, tire);
      _drawRolling(canvas, r, phase, 4.5);
    }
  }

  // Corpo.
  final body = RRect.fromRectAndRadius(
    Rect.fromLTWH(5, 2, w - 10, h - 6),
    const Radius.circular(6),
  );
  canvas.drawRRect(body, Paint()..color = _hull);
  canvas.drawRRect(body, _outlinePaint);

  // Capô (frente = embaixo) mais claro.
  canvas.drawRRect(
    RRect.fromRectAndRadius(
      Rect.fromLTWH(7, h * 0.62, w - 14, h * 0.30),
      const Radius.circular(5),
    ),
    Paint()..color = _hullLight,
  );
  // Para-brisa inclinado (vidro escuro com brilho vermelho fraco).
  canvas.drawRRect(
    RRect.fromRectAndRadius(
      Rect.fromLTWH(8, h * 0.50, w - 16, h * 0.12),
      const Radius.circular(3),
    ),
    Paint()..color = const Color(0xFF20140F),
  );
  // Caçamba traseira com carga.
  canvas.drawRRect(
    RRect.fromRectAndRadius(
      Rect.fromLTWH(8, 5, w - 16, h * 0.36),
      const Radius.circular(4),
    ),
    Paint()..color = _hullDark,
  );
  canvas.drawRRect(
    RRect.fromRectAndRadius(
      Rect.fromLTWH(w / 2 - 6, 9, 12, 10),
      const Radius.circular(2),
    ),
    Paint()..color = _metal,
  );
  // Listra vermelha no capô.
  canvas.drawRect(
    Rect.fromLTWH(w / 2 - 2, h * 0.64, 4, h * 0.24),
    Paint()..color = _red,
  );
}

/// Blindado (APC): casco anguloso com nariz em bico na frente (embaixo),
/// quatro rodas grandes e torreta pequena com metralhadora.
void _drawApc(Canvas canvas, double w, double h, double phase) {
  // Rodas girando — sem borda clara (pneu é borracha escura).
  final tire = Paint()..color = _track;
  for (final ty in [h * 0.14, h * 0.42, h * 0.68]) {
    for (final tx in [0.5, w - 8.5]) {
      final r = RRect.fromRectAndRadius(
        Rect.fromLTWH(tx, ty, 8, h * 0.17),
        const Radius.circular(4),
      );
      canvas.drawRRect(r, tire);
      _drawRolling(canvas, r, phase, 5.0);
    }
  }

  // Casco com bico frontal (embaixo).
  final hull = Path()
    ..moveTo(6, 4)
    ..lineTo(w - 6, 4)
    ..lineTo(w - 5, h * 0.72)
    ..lineTo(w / 2, h - 2)
    ..lineTo(5, h * 0.72)
    ..close();
  canvas.drawPath(hull, Paint()..color = _hull);
  canvas.drawPath(hull, _outlinePaint);

  // Placa central mais clara.
  final plate = Path()
    ..moveTo(10, 8)
    ..lineTo(w - 10, 8)
    ..lineTo(w - 9, h * 0.66)
    ..lineTo(w / 2, h * 0.84)
    ..lineTo(9, h * 0.66)
    ..close();
  canvas.drawPath(plate, Paint()..color = _hullLight);

  // Torreta pequena com metralhadora apontando para baixo.
  canvas.drawCircle(
      Offset(w / 2, h * 0.34), 7.5, Paint()..color = _hullDark);
  canvas.drawCircle(Offset(w / 2, h * 0.34), 7.5, _outlinePaint);
  canvas.drawRect(
    Rect.fromLTWH(w / 2 - 1.5, h * 0.34, 3, h * 0.26),
    Paint()..color = _metal,
  );
  // Insígnia vermelha.
  canvas.drawCircle(Offset(w / 2, h * 0.16), 3.4, Paint()..color = _red);
}

/// Tanque pesado: esteiras largas, casco robusto, torreta grande com
/// canhão comprido apontando para baixo (para o jogador!) e estrela.
void _drawTank(Canvas canvas, double w, double h, double phase) {
  // Esteiras girando.
  for (final tx in [0.0, w - 11]) {
    final r = RRect.fromRectAndRadius(
      Rect.fromLTWH(tx, 2, 11, h - 4),
      const Radius.circular(5),
    );
    canvas.drawRRect(r, Paint()..color = _track);
    _drawRolling(canvas, r, phase, 6.0);
    canvas.drawRRect(r, Paint()..color = _trackEdge..style = PaintingStyle.stroke..strokeWidth = 1);
  }

  // Casco.
  final hull = RRect.fromRectAndRadius(
    Rect.fromLTWH(9, 3, w - 18, h - 6),
    const Radius.circular(6),
  );
  canvas.drawRRect(hull, Paint()..color = _hull);
  canvas.drawRRect(hull, _outlinePaint);
  // Placa frontal (embaixo) inclinada mais clara.
  canvas.drawRRect(
    RRect.fromRectAndRadius(
      Rect.fromLTWH(11, h * 0.72, w - 22, h * 0.20),
      const Radius.circular(4),
    ),
    Paint()..color = _hullLight,
  );

  // Canhão comprido apontando para BAIXO, saindo da torreta.
  canvas.drawRRect(
    RRect.fromRectAndRadius(
      Rect.fromLTWH(w / 2 - 2.5, h * 0.42, 5, h * 0.52),
      const Radius.circular(2),
    ),
    Paint()..color = _metal,
  );
  // Boca do cano.
  canvas.drawRRect(
    RRect.fromRectAndRadius(
      Rect.fromLTWH(w / 2 - 3.5, h * 0.88, 7, 6),
      const Radius.circular(2),
    ),
    Paint()..color = _redDark,
  );

  // Torreta grande.
  final turret = Offset(w / 2, h * 0.38);
  canvas.drawCircle(turret, 11, Paint()..color = _hullDark);
  canvas.drawCircle(turret, 11, _outlinePaint);
  canvas.drawCircle(turret, 7, Paint()..color = _hullLight);
  // Estrela vermelha.
  _drawStar(canvas, turret, 4.6, Paint()..color = _red);
}

void _drawStar(Canvas canvas, Offset c, double r, Paint paint) {
  final path = Path();
  for (var i = 0; i < 5; i++) {
    final aOut = -pi / 2 + i * 2 * pi / 5;
    final aIn = aOut + pi / 5;
    final pOut = Offset(c.dx + cos(aOut) * r, c.dy + sin(aOut) * r);
    final pIn = Offset(c.dx + cos(aIn) * r * 0.45, c.dy + sin(aIn) * r * 0.45);
    i == 0 ? path.moveTo(pOut.dx, pOut.dy) : path.lineTo(pOut.dx, pOut.dy);
    path.lineTo(pIn.dx, pIn.dy);
  }
  path.close();
  canvas.drawPath(path, paint);
}

/// Chamuscados que aparecem conforme o dano: o jogador VÊ o veículo
/// apanhando a cada letra acertada.
void _drawDamage(Canvas canvas, double w, double h,
    {required int seed, required double damage}) {
  if (damage <= 0) return;
  final rnd = Random(seed);
  final marks = (damage * 5).ceil().clamp(0, 5);
  for (var i = 0; i < marks; i++) {
    final x = 8 + rnd.nextDouble() * (w - 16);
    final y = 6 + rnd.nextDouble() * (h - 12);
    final r = 3.0 + rnd.nextDouble() * 3.5;
    canvas.drawCircle(
      Offset(x, y),
      r,
      Paint()
        ..color = const Color(0xCC120D08)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1.5),
    );
    // Brasa no centro dos chamuscados mais novos.
    if (i >= marks - 2 && damage < 1) {
      canvas.drawCircle(
        Offset(x, y),
        r * 0.35,
        Paint()..color = const Color(0xFFE25822).withValues(alpha: 0.55),
      );
    }
  }
}
