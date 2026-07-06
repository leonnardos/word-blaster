import 'dart:math';
import 'dart:ui';

import 'package:flame/components.dart';

class _Prop {
  double x;
  double y;
  final int kind; // 0 = pedra, 1 = capim, 2 = cratera, 3 = mancha de terra
  final double scale;
  final int seed;

  _Prop(this.x, this.y, this.kind, this.scale, this.seed);
}

/// Campo de batalha visto de cima, rolando para baixo — a sensação é o
/// tanque avançando por uma estrada de terra aberta (sem muros: campo
/// livre, com margens de pedras e capim). Tudo em tons escuros e apagados
/// de propósito: o foco visual são sempre as palavras.
class Battlefield extends Component {
  /// Rolagem lenta = tanque pesado avançando. Público: as esteiras do tanque
  /// giram nesta mesma velocidade para o movimento ser coerente.
  static const scrollSpeed = 26.0;
  static const _tile = 48.0;

  // Paleta apagada (terra à noite).
  static const _ground = Color(0xFF16110C);
  static const _groundAlt = Color(0xFF1C160E);
  static const _road = Color(0xFF221A10);
  static const _rock = Color(0xFF2B231A);
  static const _rockEdge = Color(0xFF3A2F21);
  static const _grass = Color(0xFF223420);

  final _random = Random();
  final List<_Prop> _props = [];
  double _scroll = 0;
  double _flash = 0;
  Vector2 _size = Vector2.zero();

  /// Clareada rápida do cenário quando um tiro acerta a palavra.
  void flash() => _flash = 1;

  double get _roadLeft => _size.x * 0.22;
  double get _roadRight => _size.x * 0.78;

  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);
    _size = size.clone();
    if (_props.isEmpty) {
      for (var i = 0; i < 26; i++) {
        _props.add(_randomProp(y: _random.nextDouble() * size.y));
      }
    }
  }

  _Prop _randomProp({double? y}) {
    // Margens são mais povoadas que a estrada, que fica limpa para leitura.
    final roll = _random.nextDouble();
    final int kind;
    if (roll < 0.40) {
      kind = 0; // pedra
    } else if (roll < 0.75) {
      kind = 1; // capim
    } else if (roll < 0.88) {
      kind = 2; // cratera
    } else {
      kind = 3; // mancha de terra
    }

    double x;
    if (kind == 3 || _random.nextDouble() < 0.2) {
      x = _random.nextDouble() * _size.x; // manchas podem cair na estrada
    } else {
      final band = _size.x * 0.20;
      x = _random.nextBool()
          ? _random.nextDouble() * band
          : _size.x - _random.nextDouble() * band;
    }

    return _Prop(
      x,
      y ?? -40,
      kind,
      0.7 + _random.nextDouble() * 0.9,
      _random.nextInt(1 << 30),
    );
  }

  @override
  void update(double dt) {
    _scroll = (_scroll + scrollSpeed * dt) % (_tile * 2);
    if (_flash > 0) _flash = max(0, _flash - dt * 7);
    for (var i = 0; i < _props.length; i++) {
      final prop = _props[i];
      prop.y += scrollSpeed * dt;
      if (prop.y > _size.y + 60) {
        _props[i] = _randomProp();
      }
    }
  }

  @override
  void render(Canvas canvas) {
    // Chão base.
    canvas.drawRect(Offset.zero & Size(_size.x, _size.y), Paint()..color = _ground);

    // Xadrez sutil de terra (rolando junto — é o chão passando).
    final alt = Paint()..color = _groundAlt.withValues(alpha: 0.55);
    final cols = (_size.x / _tile).ceil() + 1;
    final rows = (_size.y / _tile).ceil() + 3;
    for (var r = -2; r < rows; r++) {
      final sy = r * _tile + _scroll;
      for (var c = 0; c < cols; c++) {
        if ((r + c).isEven) continue;
        canvas.drawRect(Rect.fromLTWH(c * _tile, sy, _tile, _tile), alt);
      }
    }

    // Estrada central: banda levemente mais clara com bordas difusas.
    final roadPaint = Paint()
      ..color = _road.withValues(alpha: 0.75)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 18);
    canvas.drawRect(
      Rect.fromLTRB(_roadLeft, -20, _roadRight, _size.y + 20),
      roadPaint,
    );

    // Rastro das esteiras SÓ atrás do tanque: a terra fica marcada por onde
    // ele já passou, e as marcas escorrem para fora da tela por baixo.
    final trackPaint =
        Paint()..color = const Color(0xFF0D0A06).withValues(alpha: 0.8);
    const dashH = 14.0;
    const gap = 10.0;
    const period = dashH + gap; // 24 divide 96 (2 tiles): loop perfeito
    // Mesma conta do jogo para a posição do tanque (size.y - 106), começando
    // logo atrás dele; ±21.5 = centro das esteiras no componente de 56px.
    final trailTop = _size.y - 106 + 22;
    for (final dx in [-21.5, 21.5]) {
      final x = _size.x / 2 + dx;
      for (var y = trailTop + (_scroll % period); y < _size.y + period; y += period) {
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromCenter(center: Offset(x, y), width: 9, height: dashH),
            const Radius.circular(2),
          ),
          trackPaint,
        );
      }
    }

    // Adereços das margens.
    for (final prop in _props) {
      switch (prop.kind) {
        case 0:
          _drawRock(canvas, prop);
        case 1:
          _drawGrass(canvas, prop);
        case 2:
          _drawCrater(canvas, prop);
        default:
          _drawDirtPatch(canvas, prop);
      }
    }

    // Vinheta: escurece as bordas e concentra o olhar no centro.
    final vignette = Paint()
      ..shader = Gradient.radial(
        Offset(_size.x / 2, _size.y * 0.55),
        _size.y * 0.75,
        [const Color(0x00000000), const Color(0x66000000)],
        [0.62, 1.0],
      );
    canvas.drawRect(Offset.zero & Size(_size.x, _size.y), vignette);

    // Clareada quente e rápida quando um tiro acerta.
    if (_flash > 0) {
      canvas.drawRect(
        Offset.zero & Size(_size.x, _size.y),
        Paint()
          ..color = const Color(0xFFFFDFAE).withValues(alpha: 0.10 * _flash),
      );
    }
  }

  void _drawRock(Canvas canvas, _Prop prop) {
    final rnd = Random(prop.seed);
    final r = 5.0 + rnd.nextDouble() * 9 * prop.scale;
    final path = Path();
    const points = 6;
    for (var i = 0; i < points; i++) {
      final a = 2 * pi * i / points;
      final rr = r * (0.75 + rnd.nextDouble() * 0.5);
      final p = Offset(prop.x + cos(a) * rr, prop.y + sin(a) * rr * 0.8);
      i == 0 ? path.moveTo(p.dx, p.dy) : path.lineTo(p.dx, p.dy);
    }
    path.close();
    canvas.drawPath(path, Paint()..color = _rock);
    canvas.drawPath(
      path,
      Paint()
        ..color = _rockEdge
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1,
    );
  }

  void _drawGrass(Canvas canvas, _Prop prop) {
    final rnd = Random(prop.seed);
    final paint = Paint()
      ..color = _grass.withValues(alpha: 0.8)
      ..strokeWidth = 1.6
      ..strokeCap = StrokeCap.round;
    final blades = 3 + rnd.nextInt(3);
    for (var i = 0; i < blades; i++) {
      final a = -pi / 2 + (rnd.nextDouble() - 0.5) * 1.2;
      final len = (5 + rnd.nextDouble() * 6) * prop.scale;
      canvas.drawLine(
        Offset(prop.x + (i - blades / 2) * 2.2, prop.y),
        Offset(prop.x + (i - blades / 2) * 2.2 + cos(a) * len,
            prop.y + sin(a) * len),
        paint,
      );
    }
  }

  void _drawCrater(Canvas canvas, _Prop prop) {
    final r = 9.0 * prop.scale;
    final center = Offset(prop.x, prop.y);
    canvas.drawCircle(
        center, r, Paint()..color = const Color(0xFF0E0B07).withValues(alpha: 0.9));
    canvas.drawCircle(
      center,
      r,
      Paint()
        ..color = _rockEdge.withValues(alpha: 0.7)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.4,
    );
  }

  void _drawDirtPatch(Canvas canvas, _Prop prop) {
    canvas.drawCircle(
      Offset(prop.x, prop.y),
      36 * prop.scale,
      Paint()
        ..color = _groundAlt.withValues(alpha: 0.35)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 22),
    );
  }
}
