import 'dart:math';
import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flame/particles.dart';

final _random = Random();

const _sparkColors = [
  Color(0xFFFFE082), // amarelo claro
  Color(0xFFFFA726), // laranja
  Color(0xFFFF6D00), // laranja fogo
];

/// Chama curta na boca do cano no instante do disparo, apontando na direção
/// do tiro (estilo muzzle flash de tanque).
ParticleSystemComponent buildMuzzleFlash(Vector2 position, double angle) {
  return ParticleSystemComponent(
    position: position,
    particle: ComputedParticle(
      lifespan: 0.09,
      renderer: (canvas, particle) {
        final t = particle.progress;
        final fade = 1 - t;
        canvas.save();
        canvas.rotate(angle);
        final len = 13 + 9 * t;
        final flame = Path()
          ..moveTo(-3.6 * fade, 1)
          ..quadraticBezierTo(-2.2, -len * 0.55, 0, -len)
          ..quadraticBezierTo(2.2, -len * 0.55, 3.6 * fade, 1)
          ..close();
        canvas.drawPath(
          flame,
          Paint()
            ..color = const Color(0xFFFF8A2A).withValues(alpha: 0.85 * fade)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3),
        );
        canvas.drawCircle(
          const Offset(0, -3),
          3.6 * fade,
          Paint()
            ..color = const Color(0xFFFFF1B8).withValues(alpha: 0.9 * fade)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2),
        );
        canvas.restore();
      },
    ),
  );
}

/// Explosão de FOGO: clarão, bola de fogo (vermelho → laranja → amarelo),
/// anel de choque, faíscas com gravidade e fumaça subindo. Usada tanto ao
/// destruir a palavra quanto quando ela alcança o tanque ([scale] maior).
/// Sem som ao destruir palavra — a pronúncia do TTS fica em primeiro plano.
ParticleSystemComponent buildFireExplosion(Vector2 position,
    {double scale = 1.0}) {
  return ParticleSystemComponent(
    position: position,
    particle: ComposedParticle(
      lifespan: 1.0,
      // Sem isto o Flame sobrescreve o lifespan de TODAS as camadas para
      // 1.0s e a coreografia (clarão 0.12s, fogo 0.5s, anel 0.4s...) morre.
      applyLifespanToChildren: false,
      children: [
        // Clarão inicial amarelo-branco.
        ComputedParticle(
          lifespan: 0.12,
          renderer: (canvas, particle) {
            final fade = 1 - particle.progress;
            canvas.drawCircle(
              Offset.zero,
              (22 * fade + 8) * scale,
              Paint()
                ..color =
                    const Color(0xFFFFF6CC).withValues(alpha: 0.95 * fade)
                ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12),
            );
          },
        ),
        // Bola de fogo em camadas: vermelho fora, laranja, núcleo amarelo.
        ComputedParticle(
          lifespan: 0.5,
          renderer: (canvas, particle) {
            final t = particle.progress;
            final ease = 1 - (1 - t) * (1 - t);
            final fade = 1 - t;
            final r = (12 + 30 * ease) * scale;
            canvas.drawCircle(
              Offset.zero,
              r,
              Paint()
                ..color =
                    const Color(0xFFC33B12).withValues(alpha: 0.55 * fade)
                ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10),
            );
            canvas.drawCircle(
              Offset.zero,
              r * 0.72,
              Paint()
                ..color =
                    const Color(0xFFFF7A1A).withValues(alpha: 0.85 * fade)
                ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
            );
            canvas.drawCircle(
              Offset.zero,
              r * 0.45 * (1 - t * 0.5),
              Paint()
                ..color =
                    const Color(0xFFFFC93C).withValues(alpha: 0.95 * fade)
                ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
            );
          },
        ),
        // Anel de choque alaranjado.
        ComputedParticle(
          lifespan: 0.4,
          renderer: (canvas, particle) {
            final t = particle.progress;
            final ease = 1 - (1 - t) * (1 - t);
            canvas.drawCircle(
              Offset.zero,
              (10 + 52 * ease) * scale,
              Paint()
                ..style = PaintingStyle.stroke
                ..strokeWidth = 3 * (1 - t) + 0.5
                ..color = const Color(0xFFFF9840).withValues(alpha: 0.7 * (1 - t))
                ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3),
            );
          },
        ),
        // Faíscas incandescentes voando (com gravidade puxando para baixo).
        Particle.generate(
          count: (26 * scale).round(),
          lifespan: 0.7,
          generator: (i) {
            final angle = _random.nextDouble() * 2 * pi;
            final speed = (90 + _random.nextDouble() * 240) * scale;
            final direction = Vector2(cos(angle), sin(angle));
            return AcceleratedParticle(
              speed: direction * speed,
              acceleration: direction * -speed * 0.5 + Vector2(0, 160),
              child: CircleParticle(
                radius: 1.2 + _random.nextDouble() * 2.2,
                paint: Paint()
                  ..color = _sparkColors[i % _sparkColors.length]
                  ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1.5),
              ),
            );
          },
        ),
        // Fumaça escura subindo e se dissipando.
        Particle.generate(
          count: 6,
          lifespan: 1.0,
          generator: (i) {
            final angle = -pi / 2 + (_random.nextDouble() - 0.5) * 1.4;
            final drift = (18 + _random.nextDouble() * 30) * scale;
            return MovingParticle(
              to: Vector2(cos(angle), sin(angle)) * drift,
              child: ComputedParticle(
                renderer: (canvas, particle) {
                  final t = particle.progress;
                  canvas.drawCircle(
                    Offset.zero,
                    (6 + 15 * t) * scale,
                    Paint()
                      ..color = const Color(0xFF3A3532)
                          .withValues(alpha: 0.45 * (1 - t))
                      ..maskFilter =
                          const MaskFilter.blur(BlurStyle.normal, 8),
                  );
                },
              ),
            );
          },
        ),
      ],
    ),
  );
}
