import 'package:flutter_test/flutter_test.dart';
import 'package:word_blaster/game/word_blaster_game.dart';

void main() {
  test('estamina: marcos 5/15/25/35 palavras = 25/50/75/100%', () {
    expect(WordBlasterGame.staminaFor(0), 0);
    expect(WordBlasterGame.staminaFor(5), 0.25);
    expect(WordBlasterGame.staminaFor(10), closeTo(0.375, 0.001));
    expect(WordBlasterGame.staminaFor(15), 0.50);
    expect(WordBlasterGame.staminaFor(25), 0.75);
    expect(WordBlasterGame.staminaFor(35), 1.0);
    expect(WordBlasterGame.staminaFor(99), 1.0, reason: 'satura em 100%');
    for (var i = 1; i <= 40; i++) {
      expect(
        WordBlasterGame.staminaFor(i) >= WordBlasterGame.staminaFor(i - 1),
        isTrue,
        reason: 'a barra nunca regride enquanto acerta ($i)',
      );
    }
  });

  test('velocidade automática: sobe 1 a cada 2 níveis, teto no 8', () {
    expect(WordBlasterGame.autoSpeedFor(1), 1);
    expect(WordBlasterGame.autoSpeedFor(2), 1);
    expect(WordBlasterGame.autoSpeedFor(3), 2);
    expect(WordBlasterGame.autoSpeedFor(4), 2);
    expect(WordBlasterGame.autoSpeedFor(5), 3);
    expect(WordBlasterGame.autoSpeedFor(9), 5);
    expect(WordBlasterGame.autoSpeedFor(14), 7);
    expect(WordBlasterGame.autoSpeedFor(15), 8);
    expect(WordBlasterGame.autoSpeedFor(16), 8);
    expect(WordBlasterGame.autoSpeedFor(50), 8, reason: 'nunca passa do 8');
  });
}
