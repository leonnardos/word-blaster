import 'dart:math';

import 'package:flutter/material.dart';

/// Fundo do menu: releitura procedural da arte de referência do usuário —
/// tanque em silhueta com faróis azuis acesos, explosões de fogo ao fundo,
/// fumaça, fagulhas e "destroços de palavras" voando pelos ares.
/// Pintado uma única vez e cacheado pelo RepaintBoundary.
class MenuBackground extends StatelessWidget {
  const MenuBackground({super.key});

  @override
  Widget build(BuildContext context) {
    return const RepaintBoundary(
      child: CustomPaint(
        painter: _BattleScenePainter(),
        size: Size.infinite,
      ),
    );
  }
}

/// Partículas sutis flutuando sobre o menu: fagulhas âmbar subindo com
/// leve deriva e fiapos de fumaça — vida no cenário sem roubar o foco
/// (direção do mockup do usuário). Uma única camada animada e barata;
/// a arte de fundo continua estática/cacheada.
class MenuParticles extends StatefulWidget {
  const MenuParticles({super.key});

  @override
  State<MenuParticles> createState() => _MenuParticlesState();
}

class _MenuParticlesState extends State<MenuParticles>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 14),
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: CustomPaint(
        painter: _ParticlesPainter(_controller),
        size: Size.infinite,
      ),
    );
  }
}

class _ParticlesPainter extends CustomPainter {
  final Animation<double> anim;

  _ParticlesPainter(this.anim) : super(repaint: anim);

  // Partículas fixas por seed: cada uma tem posição-base, velocidade de
  // subida, deriva lateral e fase própria — o loop de 14s fecha sem pulo.
  static final List<_Particle> _particles = () {
    final rnd = Random(11);
    return [
      // 30 partículas (o usuário pediu mais fogos subindo).
      for (var i = 0; i < 30; i++)
        _Particle(
          x: rnd.nextDouble(),
          y: rnd.nextDouble(),
          laps: 1 + rnd.nextInt(2), // voltas por ciclo (velocidades variadas)
          drift: 0.008 + rnd.nextDouble() * 0.02,
          phase: rnd.nextDouble() * 2 * pi,
          size: 1.0 + rnd.nextDouble() * 1.9,
          smoke: i % 8 == 7, // fumaça continua rara: o pedido foi FOGO
        ),
    ];
  }();

  @override
  void paint(Canvas canvas, Size size) {
    final t = anim.value;
    for (final p in _particles) {
      // Sobe em loop; a fração some no topo e renasce embaixo.
      final fy = (p.y - t * p.laps) % 1.0;
      final fx = p.x + sin(t * 2 * pi * p.laps + p.phase) * p.drift;
      final pos = Offset(fx * size.width, fy * size.height);
      // Nasce e morre suave (alpha em rampa nas pontas do trajeto).
      final edge = (fy < 0.15 ? fy / 0.15 : (fy > 0.85 ? (1 - fy) / 0.15 : 1.0));
      if (p.smoke) {
        canvas.drawCircle(
          pos,
          16 + p.size * 6,
          Paint()
            ..color = const Color(0xFF2C2016).withValues(alpha: 0.16 * edge)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 18),
        );
      } else {
        canvas.drawCircle(
          pos,
          p.size,
          Paint()
            ..color = (p.size > 2.0
                    ? const Color(0xFFFFB74D)
                    : const Color(0xFFFF8A3C))
                .withValues(alpha: 0.42 * edge),
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant _ParticlesPainter old) => false;
}

class _Particle {
  final double x, y, drift, phase, size;
  final int laps;
  final bool smoke;

  const _Particle({
    required this.x,
    required this.y,
    required this.laps,
    required this.drift,
    required this.phase,
    required this.size,
    required this.smoke,
  });
}

class _BattleScenePainter extends CustomPainter {
  const _BattleScenePainter();

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final rnd = Random(7);

    // ------------------------------------------------------------- céu
    canvas.drawRect(
      Offset.zero & size,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF090C14), Color(0xFF16100C), Color(0xFF200E08)],
          stops: [0.0, 0.55, 1.0],
        ).createShader(Offset.zero & size),
    );

    // ----------------------------------------------------------- fumaça
    const smokeColors = [Color(0xFF1B1511), Color(0xFF241A12), Color(0xFF2C2016)];
    for (var i = 0; i < 16; i++) {
      final cx = rnd.nextDouble() * w;
      final cy = h * (0.02 + rnd.nextDouble() * 0.45);
      final r = w * (0.09 + rnd.nextDouble() * 0.15);
      canvas.drawCircle(
        Offset(cx, cy),
        r,
        Paint()
          ..color = smokeColors[i % 3].withValues(alpha: 0.55)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 45),
      );
    }

    // ------------------------------------------------------ bolas de fogo
    _fireball(canvas, Offset(w * 0.80, h * 0.10), w * 0.17);
    _fireball(canvas, Offset(w * 0.22, h * 0.15), w * 0.12);
    _fireball(canvas, Offset(w * 0.62, h * 0.28), w * 0.075);

    // ---------------------------------------------------------- fagulhas
    for (var i = 0; i < 60; i++) {
      final nearRight = rnd.nextBool();
      final cx = nearRight
          ? w * (0.55 + rnd.nextDouble() * 0.45)
          : w * (0.05 + rnd.nextDouble() * 0.45);
      final cy = h * (0.03 + rnd.nextDouble() * 0.42);
      final paint = Paint()
        ..color = (i % 3 == 0
                ? const Color(0xFFFFE082)
                : i % 3 == 1
                    ? const Color(0xFFFF9840)
                    : const Color(0xFFFF6D00))
            .withValues(alpha: 0.5 + rnd.nextDouble() * 0.5)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1.5);
      if (i % 4 == 0) {
        // risco de fagulha voando
        final ang = rnd.nextDouble() * pi;
        final len = 6 + rnd.nextDouble() * 14;
        canvas.drawLine(Offset(cx, cy),
            Offset(cx + cos(ang) * len, cy + sin(ang) * len), paint..strokeWidth = 1.6);
      } else {
        canvas.drawCircle(Offset(cx, cy), 1 + rnd.nextDouble() * 2, paint);
      }
    }

    // ------------------------------------------ destroços de palavras
    _wordChip(canvas, w, '-clock-', Offset(w * 0.17, h * 0.19), -0.30);
    _wordChip(canvas, w, '-race-', Offset(w * 0.31, h * 0.28), 0.22);
    _wordChip(canvas, w, 'HARD', Offset(w * 0.12, h * 0.34), -0.12);
    _wordChip(canvas, w, 'c-L', Offset(w * 0.07, h * 0.26), 0.38);
    _wordChip(canvas, w, '-word-', Offset(w * 0.86, h * 0.30), -0.45);

    // -------------------------------------------------------------- chão
    final ground = Path()..moveTo(0, h * 0.86);
    var gx = 0.0;
    while (gx < w) {
      final gy = h * (0.84 + rnd.nextDouble() * 0.04);
      ground.lineTo(gx, gy);
      gx += w * (0.06 + rnd.nextDouble() * 0.08);
    }
    ground
      ..lineTo(w, h * 0.85)
      ..lineTo(w, h)
      ..lineTo(0, h)
      ..close();
    canvas.drawPath(ground, Paint()..color = const Color(0xFF0B0906));
    // Brasas no entulho.
    for (var i = 0; i < 14; i++) {
      canvas.drawCircle(
        Offset(rnd.nextDouble() * w, h * (0.87 + rnd.nextDouble() * 0.11)),
        1 + rnd.nextDouble() * 1.8,
        Paint()
          ..color = const Color(0xFFFF6D00)
              .withValues(alpha: 0.25 + rnd.nextDouble() * 0.4)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2),
      );
    }

    // ------------------------------------------------------------ tanque
    _tankSilhouette(canvas, size);

    // ------------------------------------------------------------ vinheta
    canvas.drawRect(
      Offset.zero & size,
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(0, -0.1),
          radius: 1.2,
          colors: const [Color(0x00000000), Color(0x8A000000)],
          stops: const [0.55, 1.0],
        ).createShader(Offset.zero & size),
    );
  }

  void _fireball(Canvas canvas, Offset center, double radius) {
    canvas.drawCircle(
      center,
      radius * 1.5,
      Paint()
        ..color = const Color(0xFF8A2508).withValues(alpha: 0.55)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 40),
    );
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..color = const Color(0xFFD84A12).withValues(alpha: 0.8)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 24),
    );
    canvas.drawCircle(
      center.translate(0, -radius * 0.15),
      radius * 0.62,
      Paint()
        ..color = const Color(0xFFFF8A1F).withValues(alpha: 0.9)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 14),
    );
    canvas.drawCircle(
      center.translate(radius * 0.1, -radius * 0.25),
      radius * 0.3,
      Paint()
        ..color = const Color(0xFFFFDD8A)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
    );
  }

  void _wordChip(
      Canvas canvas, double w, String text, Offset center, double angle) {
    final painter = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          fontFamily: 'Orbitron',
          color: const Color(0xFFE8ECF0),
          fontSize: w * 0.030,
          fontWeight: FontWeight.w700,
          letterSpacing: 1,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(angle);
    final rect = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: Offset.zero,
        width: painter.width + w * 0.024,
        height: painter.height + w * 0.014,
      ),
      const Radius.circular(6),
    );
    canvas.drawRRect(rect, Paint()..color = const Color(0xE6141A22));
    // Rebordo aquecido pelo fogo.
    canvas.drawRRect(
      rect,
      Paint()
        ..color = const Color(0x99FF8A3C)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2,
    );
    painter.paint(
        canvas, Offset(-painter.width / 2, -painter.height / 2));
    canvas.restore();
  }

  void _tankSilhouette(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final cx = w * 0.5;
    final cy = h * 0.72;
    final tw = w * 0.52; // largura total do tanque

    Offset p(double fx, double fy) => Offset(cx + tw * fx, cy + tw * fy);

    // Sombra no chão.
    canvas.drawOval(
      Rect.fromCenter(
          center: p(0, 0.24), width: tw * 1.05, height: tw * 0.16),
      Paint()
        ..color = const Color(0xCC000000)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 14),
    );

    final body = Paint()..color = const Color(0xFF14181E);
    final bodyLight = Paint()..color = const Color(0xFF1B2129);

    // Esteiras (vista frontal: blocos nas laterais).
    for (final side in [-1, 1]) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(
              center: p(side * 0.40, 0.13),
              width: tw * 0.22,
              height: tw * 0.22),
          Radius.circular(tw * 0.05),
        ),
        body,
      );
    }

    // Casco frontal (trapézio largo).
    final hull = Path()
      ..moveTo(p(-0.34, -0.06).dx, p(-0.34, -0.06).dy)
      ..lineTo(p(0.34, -0.06).dx, p(0.34, -0.06).dy)
      ..lineTo(p(0.40, 0.20).dx, p(0.40, 0.20).dy)
      ..lineTo(p(-0.40, 0.20).dx, p(-0.40, 0.20).dy)
      ..close();
    canvas.drawPath(hull, bodyLight);

    // Glacis superior.
    final glacis = Path()
      ..moveTo(p(-0.26, -0.13).dx, p(-0.26, -0.13).dy)
      ..lineTo(p(0.26, -0.13).dx, p(0.26, -0.13).dy)
      ..lineTo(p(0.34, -0.06).dx, p(0.34, -0.06).dy)
      ..lineTo(p(-0.34, -0.06).dx, p(-0.34, -0.06).dy)
      ..close();
    canvas.drawPath(glacis, body);

    // Torre + domo.
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
            center: p(0.01, -0.19), width: tw * 0.30, height: tw * 0.14),
        Radius.circular(tw * 0.04),
      ),
      bodyLight,
    );
    canvas.drawOval(
      Rect.fromCenter(
          center: p(0.01, -0.26), width: tw * 0.16, height: tw * 0.08),
      body,
    );

    // Canhão apontando para o alto, na diagonal (como na arte).
    canvas.save();
    canvas.translate(p(-0.04, -0.20).dx, p(-0.04, -0.20).dy);
    canvas.rotate(-0.62);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(-tw * 0.018, -tw * 0.52, tw * 0.036, tw * 0.52),
        Radius.circular(tw * 0.012),
      ),
      body,
    );
    // Freio de boca.
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(-tw * 0.028, -tw * 0.55, tw * 0.056, tw * 0.06),
        Radius.circular(tw * 0.012),
      ),
      bodyLight,
    );
    canvas.restore();

    // Antena.
    canvas.drawLine(
      p(0.16, -0.24),
      p(0.22, -0.46),
      Paint()
        ..color = const Color(0xFF1B2129)
        ..strokeWidth = 1.4,
    );

    // Luz de contorno do fogo (rim light) nas bordas superiores.
    final rim = Paint()
      ..color = const Color(0xFFFF8A3C).withValues(alpha: 0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);
    canvas.drawLine(p(-0.26, -0.13), p(0.26, -0.13), rim);
    canvas.drawLine(p(-0.15, -0.255), p(0.16, -0.255), rim);

    // FARÓIS AZUIS — a assinatura da arte.
    for (final side in [-1, 1]) {
      final light = p(side * 0.22, 0.015);
      canvas.drawCircle(
        light,
        tw * 0.055,
        Paint()
          ..color = const Color(0x662FB7F2)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 16),
      );
      canvas.drawCircle(
        light,
        tw * 0.022,
        Paint()
          ..color = const Color(0xFF9FDFFF)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3),
      );
      canvas.drawCircle(
          light, tw * 0.009, Paint()..color = const Color(0xFFFFFFFF));
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
