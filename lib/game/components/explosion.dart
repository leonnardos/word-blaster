import 'dart:math';
import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flame/particles.dart';

final _random = Random();

/// Explosão neon (PRD §15: muito efeito, muito feedback): flash central,
/// anel de choque expandindo e chuva de fagulhas. Sem som ao destruir
/// palavra — a pronúncia do TTS fica em primeiro plano.
ParticleSystemComponent buildExplosion(Vector2 position,
    {Color color = const Color(0xFF00E5FF)}) {
  return ParticleSystemComponent(
    position: position,
    particle: ComposedParticle(
      lifespan: 0.65,
      children: [
        // Flash central: clarão branco que some rápido.
        ComputedParticle(
          lifespan: 0.14,
          renderer: (canvas, particle) {
            final fade = 1 - particle.progress;
            canvas.drawCircle(
              Offset.zero,
              20 * fade + 6,
              Paint()
                ..color = const Color(0xFFFFFFFF).withValues(alpha: 0.9 * fade)
                ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10),
            );
          },
        ),
        // Anel de choque: círculo que expande e esmaece.
        ComputedParticle(
          lifespan: 0.5,
          renderer: (canvas, particle) {
            final t = particle.progress;
            final ease = 1 - (1 - t) * (1 - t); // acelera no início
            canvas.drawCircle(
              Offset.zero,
              10 + 58 * ease,
              Paint()
                ..style = PaintingStyle.stroke
                ..strokeWidth = 3.5 * (1 - t) + 0.5
                ..color = color.withValues(alpha: 0.85 * (1 - t))
                ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3),
            );
          },
        ),
        // Fagulhas voando em todas as direções.
        Particle.generate(
          count: 34,
          lifespan: 0.65,
          generator: (i) {
            final angle = _random.nextDouble() * 2 * pi;
            final speed = 60 + _random.nextDouble() * 260;
            final direction = Vector2(cos(angle), sin(angle));
            return AcceleratedParticle(
              speed: direction * speed,
              acceleration: direction * -speed * 0.8,
              child: CircleParticle(
                radius: 1.5 + _random.nextDouble() * 2.8,
                paint: Paint()
                  ..color = (i % 3 == 0 ? const Color(0xFFFFFFFF) : color)
                  ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2),
              ),
            );
          },
        ),
      ],
    ),
  );
}
