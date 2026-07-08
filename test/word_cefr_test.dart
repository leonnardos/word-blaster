import 'package:flutter_test/flutter_test.dart';
import 'package:word_blaster/data/word_bank.dart';
import 'package:word_blaster/data/word_cefr.dart';

void main() {
  test('toda palavra do banco tem nível CEFR válido', () {
    const levels = {'A1', 'A2', 'B1', 'B2', 'C1', 'C2'};
    final missing = <String>[];
    for (final category in wordBank) {
      for (final w in category.words) {
        final level = wordCefr[w.en];
        if (level == null || !levels.contains(level)) missing.add(w.en);
      }
    }
    expect(missing, isEmpty,
        reason: 'sem nível CEFR: ${missing.take(20).join(', ')}');
  });

  test('a maioria do banco atual é A1/A2 (jogo de iniciante)', () {
    var basic = 0;
    for (final level in wordCefr.values) {
      if (level == 'A1' || level == 'A2') basic++;
    }
    expect(basic / wordCefr.length, greaterThan(0.5),
        reason: 'classificação suspeita: menos da metade A1/A2');
  });
}
