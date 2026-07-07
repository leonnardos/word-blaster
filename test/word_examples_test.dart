import 'package:flutter_test/flutter_test.dart';
import 'package:word_blaster/data/word_bank.dart';
import 'package:word_blaster/data/word_examples.dart';

void main() {
  test('toda palavra do banco tem 3 exemplos (presente/passado/futuro)', () {
    final missing = <String>[];
    for (final category in wordBank) {
      for (final w in category.words) {
        final ex = wordExamples[w.en];
        if (ex == null || ex.length != 3) missing.add(w.en);
      }
    }
    expect(missing, isEmpty,
        reason: 'palavras sem 3 exemplos: ${missing.take(20).join(', ')}');
  });

  test('cada frase marca a palavra-alvo com UM par de asteriscos', () {
    final bad = <String>[];
    wordExamples.forEach((en, examples) {
      for (final (sentence, pt) in examples) {
        final stars = '*'.allMatches(sentence).length;
        if (stars != 2 || pt.trim().isEmpty) bad.add('$en :: $sentence');
      }
    });
    expect(bad, isEmpty,
        reason: 'frases mal marcadas: ${bad.take(10).join(' | ')}');
  });
}
