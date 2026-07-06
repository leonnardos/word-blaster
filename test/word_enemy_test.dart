import 'package:flame/components.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:word_blaster/data/word_bank.dart';
import 'package:word_blaster/game/components/word_enemy.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  WordEnemy build({required Vector2 position, Vector2? tank}) {
    return WordEnemy(
      wordData: const Word('cat', 'gato'),
      speed: 60,
      position: position,
      onDestroyed: (_) {},
      onReachedBottom: (_) {},
      homingTarget: tank == null ? null : () => tank,
    )..bottomLimit = 500;
  }

  group('convergência para o tanque', () {
    test('no topo cai praticamente reto', () {
      final enemy = build(
        position: Vector2(300, 30),
        tank: Vector2(150, 500),
      );
      final xBefore = enemy.position.x;
      final yBefore = enemy.position.y;
      enemy.update(0.1);
      expect(enemy.position.y, greaterThan(yBefore), reason: 'desce');
      expect((enemy.position.x - xBefore).abs(), lessThan(1.0),
          reason: 'no topo quase não puxa para o lado');
    });

    test('perto do fim converge forte para o tanque', () {
      final enemy = build(
        position: Vector2(300, 420),
        tank: Vector2(150, 500),
      );
      final xBefore = enemy.position.x;
      enemy.update(0.1);
      expect(enemy.position.x, lessThan(xBefore),
          reason: 'perto do fim a palavra anda em direção ao tanque (x=150)');
      // E continua convergindo a cada tique.
      for (var i = 0; i < 10; i++) {
        enemy.update(0.05);
      }
      expect((enemy.position.x - 150).abs(), lessThan(xBefore - 150),
          reason: 'distância horizontal até o tanque só diminui');
    });

    test('sem homingTarget continua caindo reto (compatibilidade)', () {
      final enemy = build(position: Vector2(300, 420));
      final xBefore = enemy.position.x;
      enemy.update(0.1);
      expect(enemy.position.x, xBefore);
      expect(enemy.position.y, greaterThan(420));
    });
  });

  test('letra acende na tecla (advanceTyped), sem depender da bala', () {
    final enemy = build(position: Vector2(100, 100));
    expect(enemy.typed, 0);
    enemy.advanceTyped();
    enemy.advanceTyped();
    expect(enemy.typed, 2);
    // A destruição continua vindo das balas (onBulletHit), não da digitação.
    expect(enemy.isAlive, isTrue);
  });
}
