import 'dart:math';
import 'dart:ui';

import 'package:flame/components.dart';

class _Prop {
  double x;
  double y;
  // 0 pedra, 1 capim, 2 cratera, 3 mancha, 4 sacos de areia, 5 caixote,
  // 6 árvore queimada, 7 esteira destroçada
  final int kind;
  final double scale;
  final int seed;

  _Prop(this.x, this.y, this.kind, this.scale, this.seed);
}

/// Campo de batalha visto de cima, rolando para baixo — a sensação é o
/// tanque avançando. Tudo em tons escuros e apagados de propósito: o foco
/// visual são sempre as palavras.
///
/// CENÁRIOS (trocam a cada 5 ondas, com transição suave):
///   0 = CAMPO ABERTO: estrada estreita, margens de pedras e capim;
///   1 = ESTRADA DE GUERRA: pista larga (~90% da tela), acostamentos com
///       sacos de areia, caixotes, árvores queimadas e destroços — a
///       recriação em código da arte de referência do usuário.
class Battlefield extends Component {
  /// Rolagem lenta = tanque pesado avançando. Público: as esteiras do tanque
  /// giram nesta mesma velocidade para o movimento ser coerente.
  static const scrollSpeed = 26.0;
  static const _tile = 48.0;

  // Paleta apagada (terra à noite).
  static const _ground = Color(0xFF16110C);
  static const _groundAlt = Color(0xFF1C160E);
  static const _roadCampo = Color(0xFF221A10);
  static const _roadEstrada = Color(0xFF281E11);
  static const _rock = Color(0xFF2B231A);
  static const _rockEdge = Color(0xFF3A2F21);
  static const _grass = Color(0xFF223420);
  static const _sandbag = Color(0xFF4A3D28);
  static const _sandbagEdge = Color(0xFF5F4F33);
  static const _crate = Color(0xFF3B2C1C);
  static const _crateEdge = Color(0xFF54402A);
  static const _burnt = Color(0xFF1B1512);

  final _random = Random();
  final List<_Prop> _props = [];
  double _scroll = 0;
  double _flash = 0;
  Vector2 _size = Vector2.zero();

  int _scene = 0;

  /// 0 = campo, 1 = estrada; anda suavemente entre os dois na troca.
  double _mix = 0;

  /// Clareada rápida do cenário quando um tiro acerta a palavra.
  void flash() => _flash = 1;

  /// Troca o cenário (0 campo, 1 estrada) com transição suave; os adereços
  /// são re-sorteados no layout novo.
  void setScene(int scene) {
    if (scene == _scene) return;
    _scene = scene;
    for (var i = 0; i < _props.length; i++) {
      _props[i] = _randomProp(y: _random.nextDouble() * _size.y);
    }
  }

  double get _roadLeft => _size.x * _lerp(0.22, 0.05, _mix);
  double get _roadRight => _size.x * _lerp(0.78, 0.95, _mix);

  static double _lerp(double a, double b, double t) => a + (b - a) * t;

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
    final roll = _random.nextDouble();
    final int kind;
    if (_scene == 0) {
      if (roll < 0.40) {
        kind = 0; // pedra
      } else if (roll < 0.75) {
        kind = 1; // capim
      } else if (roll < 0.88) {
        kind = 2; // cratera
      } else {
        kind = 3; // mancha de terra
      }
    } else {
      if (roll < 0.30) {
        kind = 4; // sacos de areia
      } else if (roll < 0.52) {
        kind = 5; // caixote
      } else if (roll < 0.70) {
        kind = 6; // árvore queimada
      } else if (roll < 0.80) {
        kind = 7; // esteira destroçada
      } else if (roll < 0.90) {
        kind = 2; // cratera (pode cair na pista)
      } else {
        kind = 3; // mancha
      }
    }

    double x;
    final onRoadOk = kind == 3 || (kind == 2 && _scene == 1);
    if (onRoadOk || _random.nextDouble() < 0.15) {
      x = _random.nextDouble() * _size.x; // manchas/crateras pela pista
    } else {
      // Acostamento: estreito na estrada, largo no campo.
      final band = _size.x * (_scene == 0 ? 0.20 : 0.07);
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
    // Transição de cenário: ~1,6s de morph.
    final target = _scene.toDouble();
    if (_mix != target) {
      final step = dt / 1.6;
      _mix = target > _mix
          ? min(target, _mix + step)
          : max(target, _mix - step);
    }
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

    // Estrada central: banda mais clara com bordas difusas — no cenário
    // ESTRADA ela abre para ~90% da tela.
    final roadColor = Color.lerp(_roadCampo, _roadEstrada, _mix)!;
    final roadPaint = Paint()
      ..color = roadColor.withValues(alpha: _lerp(0.75, 0.9, _mix))
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 18);
    canvas.drawRect(
      Rect.fromLTRB(_roadLeft, -20, _roadRight, _size.y + 20),
      roadPaint,
    );

    // Sulcos de rodas na pista larga (aparecem junto com a estrada):
    // duas faixas de tráfego marcadas pelos comboios que já passaram.
    if (_mix > 0.05) {
      final rut = Paint()
        ..color = const Color(0xFF0F0B07).withValues(alpha: 0.45 * _mix)
        ..strokeWidth = 5
        ..strokeCap = StrokeCap.round;
      const dashH = 26.0;
      const gap = 22.0;
      const period = dashH + gap; // 48 = tile: loop perfeito
      for (final fx in [0.26, 0.36, 0.64, 0.74]) {
        final x = _size.x * fx;
        for (var y = -period + (_scroll % period);
            y < _size.y + period;
            y += period) {
          canvas.drawLine(Offset(x, y), Offset(x, y + dashH), rut);
        }
      }
    }

    // Rastro das esteiras SÓ atrás do tanque: a terra fica marcada por onde
    // ele já passou, e as marcas escorrem para fora da tela por baixo.
    final trackPaint =
        Paint()..color = const Color(0xFF0D0A06).withValues(alpha: 0.8);
    const dashH = 14.0;
    const gap = 10.0;
    const period = dashH + gap; // 24 divide 96 (2 tiles): loop perfeito
    // Mesma conta do jogo para a posição do tanque (size.y - 106), começando
    // logo atrás dele; ±20 = centro das rodas no componente de 60px.
    final trailTop = _size.y - 106 + 24;
    for (final dx in [-20.0, 20.0]) {
      final x = _size.x / 2 + dx;
      for (var y = trailTop + (_scroll % period); y < _size.y + period; y += period) {
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromCenter(center: Offset(x, y), width: 11, height: dashH),
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
        case 4:
          _drawSandbags(canvas, prop);
        case 5:
          _drawCrate(canvas, prop);
        case 6:
          _drawBurntTree(canvas, prop);
        case 7:
          _drawTrackDebris(canvas, prop);
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

  /// Pilha de sacos de areia (2-3 sacos deitados, empilhados).
  void _drawSandbags(Canvas canvas, _Prop prop) {
    final rnd = Random(prop.seed);
    final s = prop.scale;
    final rows = 2 + rnd.nextInt(2);
    for (var r = 0; r < rows; r++) {
      final y = prop.y - r * 6.5 * s;
      final shift = (r.isOdd ? 4.0 : 0.0) * s;
      for (var i = 0; i < 2; i++) {
        final rect = RRect.fromRectAndRadius(
          Rect.fromCenter(
            center: Offset(prop.x + shift + (i - 0.5) * 13 * s, y),
            width: 13 * s,
            height: 7 * s,
          ),
          Radius.circular(3.5 * s),
        );
        canvas.drawRRect(rect, Paint()..color = _sandbag);
        canvas.drawRRect(
          rect,
          Paint()
            ..color = _sandbagEdge
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1,
        );
      }
    }
  }

  /// Caixote de suprimentos com tábuas em X.
  void _drawCrate(Canvas canvas, _Prop prop) {
    final s = 14 * prop.scale;
    final rect = Rect.fromCenter(
        center: Offset(prop.x, prop.y), width: s, height: s);
    canvas.drawRect(rect, Paint()..color = _crate);
    final edge = Paint()
      ..color = _crateEdge
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4;
    canvas.drawRect(rect, edge);
    canvas.drawLine(rect.topLeft, rect.bottomRight, edge);
    canvas.drawLine(rect.topRight, rect.bottomLeft, edge);
  }

  /// Árvore queimada: tronco torto com 2-3 galhos secos.
  void _drawBurntTree(Canvas canvas, _Prop prop) {
    final rnd = Random(prop.seed);
    final s = prop.scale;
    final paint = Paint()
      ..color = _burnt
      ..strokeWidth = 3 * s
      ..strokeCap = StrokeCap.round;
    final top = Offset(
        prop.x + (rnd.nextDouble() - 0.5) * 8 * s, prop.y - 20 * s);
    canvas.drawLine(Offset(prop.x, prop.y), top, paint);
    final branches = 2 + rnd.nextInt(2);
    for (var i = 0; i < branches; i++) {
      final t = 0.35 + rnd.nextDouble() * 0.5;
      final from = Offset.lerp(Offset(prop.x, prop.y), top, t)!;
      final a = -pi / 2 + (rnd.nextBool() ? 1 : -1) * (0.6 + rnd.nextDouble());
      canvas.drawLine(
        from,
        from + Offset(cos(a) * 9 * s, sin(a) * 9 * s),
        paint..strokeWidth = 1.8 * s,
      );
    }
  }

  /// Esteira de tanque destroçada, jogada na margem (como na referência).
  void _drawTrackDebris(Canvas canvas, _Prop prop) {
    final rnd = Random(prop.seed);
    final s = prop.scale;
    final paint = Paint()
      ..color = const Color(0xFF14100C)
      ..strokeWidth = 5 * s
      ..strokeCap = StrokeCap.round;
    final path = Path()..moveTo(prop.x - 12 * s, prop.y);
    for (var i = 1; i <= 3; i++) {
      path.quadraticBezierTo(
        prop.x - 12 * s + i * 8 * s - 4 * s,
        prop.y + (i.isOdd ? -5 : 5) * s * rnd.nextDouble(),
        prop.x - 12 * s + i * 8 * s,
        prop.y,
      );
    }
    canvas.drawPath(
        path,
        paint
          ..style = PaintingStyle.stroke);
    // Elos da esteira.
    for (var i = 0; i < 4; i++) {
      canvas.drawCircle(
        Offset(prop.x - 10 * s + i * 7 * s, prop.y),
        1.6 * s,
        Paint()..color = _rockEdge,
      );
    }
  }
}
