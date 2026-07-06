import 'dart:math';
import 'dart:ui';

import 'package:flame/components.dart';

class _Star {
  double x;
  double y;
  final double radius;
  final double speed;
  final double alpha;

  _Star(this.x, this.y, this.radius, this.speed, this.alpha);
}

class _NebulaCloud {
  final double fx; // posição relativa (0-1) para sobreviver a resize
  final double fy;
  final double radius;
  final Color color;

  _NebulaCloud(this.fx, this.fy, this.radius, this.color);
}

/// Fundo do campo de batalha: nebulosa (nuvens coloridas difusas, estilo
/// ZType) com estrelas rolando para baixo.
class Starfield extends Component {
  final _random = Random();
  final List<_Star> _stars = [];
  final List<_NebulaCloud> _clouds = [];
  Vector2 _size = Vector2.zero();

  static const _palette = [
    Color(0xFF231447), // roxo profundo
    Color(0xFF102A4A), // azul
    Color(0xFF0C3A45), // teal
    Color(0xFF3A1240), // magenta escuro
    Color(0xFF141A3E), // índigo
  ];

  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);
    _size = size.clone();
    if (_stars.isEmpty) {
      for (var i = 0; i < 60; i++) {
        _stars.add(_randomStar(y: _random.nextDouble() * size.y));
      }
    }
    if (_clouds.isEmpty) {
      for (var i = 0; i < 12; i++) {
        _clouds.add(_NebulaCloud(
          _random.nextDouble(),
          _random.nextDouble(),
          70 + _random.nextDouble() * 190,
          _palette[i % _palette.length],
        ));
      }
    }
  }

  _Star _randomStar({double? y}) {
    final depth = _random.nextDouble(); // 0 = longe, 1 = perto
    return _Star(
      _random.nextDouble() * _size.x,
      y ?? -2,
      0.6 + depth * 1.6,
      12 + depth * 45,
      0.25 + depth * 0.55,
    );
  }

  @override
  void update(double dt) {
    for (var i = 0; i < _stars.length; i++) {
      final star = _stars[i];
      star.y += star.speed * dt;
      if (star.y > _size.y + 2) {
        _stars[i] = _randomStar();
      }
    }
  }

  @override
  void render(Canvas canvas) {
    // Nuvens de nebulosa (bem difusas, atrás de tudo).
    for (final cloud in _clouds) {
      final paint = Paint()
        ..color = cloud.color.withValues(alpha: 0.30)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 60);
      canvas.drawCircle(
        Offset(cloud.fx * _size.x, cloud.fy * _size.y),
        cloud.radius,
        paint,
      );
    }

    final paint = Paint();
    for (final star in _stars) {
      paint.color = const Color(0xFFFFFFFF).withValues(alpha: star.alpha);
      canvas.drawCircle(Offset(star.x, star.y), star.radius, paint);
    }
  }
}
