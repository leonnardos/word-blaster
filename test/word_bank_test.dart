import 'package:flutter_test/flutter_test.dart';
import 'package:word_blaster/data/word_bank.dart';
import 'package:word_blaster/services/progress_service.dart';

void main() {
  test('banco tem 1000+ palavras em tópicos sequenciais', () {
    expect(wordBank.length, greaterThanOrEqualTo(20));
    var total = 0;
    for (var i = 0; i < wordBank.length; i++) {
      expect(wordBank[i].level, i + 1);
      expect(wordBank[i].words, isNotEmpty);
      total += wordBank[i].words.length;
    }
    expect(total, greaterThanOrEqualTo(1000));
  });

  test('palavras são minúsculas e sem duplicatas dentro da categoria', () {
    for (final category in wordBank) {
      final seen = <String>{};
      for (final word in category.words) {
        expect(word.en, word.en.toLowerCase(),
            reason: '"${word.en}" deve ser minúscula');
        expect(seen.add(word.en), isTrue,
            reason: '"${word.en}" duplicada em ${category.name}');
      }
    }
  });

  test('peso de repetição sobe com erros e desce com acertos', () {
    final stat = WordStat();
    final base = stat.spawnWeight;
    stat.misses = 2;
    expect(stat.spawnWeight, greaterThan(base));
    stat.misses = 0;
    stat.hits = 10;
    expect(stat.spawnWeight, lessThan(base));
  });

  test('maestria: nova (0-2), aprendendo (3-5), dominada (6+), erros regridem',
      () {
    expect(WordStat(hits: 0).mastery, Mastery.nova);
    expect(WordStat(hits: 2).mastery, Mastery.nova);
    expect(WordStat(hits: 3).mastery, Mastery.aprendendo);
    expect(WordStat(hits: 5).mastery, Mastery.aprendendo);
    expect(WordStat(hits: 6).mastery, Mastery.dominada);
    expect(WordStat(hits: 40).mastery, Mastery.dominada);
    // Errar derruba a maestria: 7 acertos - 3 erros = 4 (aprendendo).
    expect(WordStat(hits: 7, misses: 3).mastery, Mastery.aprendendo);
    expect(WordStat(hits: 2, misses: 9).masteryScore, 0);
  });

  group('candidateWords', () {
    test('nível 1 sem tópicos: só palavras curtas, sem frases', () {
      final pool = candidateWords(level: 1);
      expect(pool, isNotEmpty);
      for (final w in pool) {
        expect(w.en.contains(' '), isFalse);
        expect(w.en.length, lessThanOrEqualTo(5));
      }
    });

    test('respeita os tópicos escolhidos', () {
      final animais =
          wordBank.firstWhere((c) => c.name == 'Animais').words.toSet();
      final pool = candidateWords(level: 3, topics: {'Animais'});
      expect(pool, isNotEmpty);
      for (final w in pool) {
        expect(animais.contains(w), isTrue,
            reason: '"${w.en}" não é do tópico Animais');
      }
    });

    test('só Conversação no nível 1 relaxa o filtro em vez de zerar', () {
      final pool = candidateWords(level: 1, topics: {'Conversação'});
      expect(pool, isNotEmpty,
          reason: 'tópico escolhido nunca pode deixar o jogo sem palavras');
      final conversacao =
          wordBank.firstWhere((c) => c.name == 'Conversação').words.toSet();
      expect(pool.every(conversacao.contains), isTrue);
      // O relaxamento libera as frases que o nível 1 normalmente bloqueia.
      expect(pool.any((w) => w.en.contains(' ')), isTrue);
    });

    test('exclui palavras ativas e iniciais em uso', () {
      final pool = candidateWords(
        level: 5,
        excludeWords: {'cat'},
        excludeInitials: {'d'},
      );
      expect(pool.any((w) => w.en == 'cat'), isFalse);
      expect(pool.any((w) => w.en.startsWith('d')), isFalse);
    });

    test('tópico inexistente devolve pool vazio (sem crash)', () {
      expect(candidateWords(level: 1, topics: {'NãoExiste'}), isEmpty);
    });

    test('pool pequeno relaxa o filtro: nunca menos de 8 candidatos', () {
      // Só Conversação no nível 5: sem o relaxamento, 'welcome' seria o único
      // candidato e monopolizaria o spawn (achado da revisão).
      for (final category in wordBank) {
        for (var level = 1; level <= 12; level++) {
          final pool = candidateWords(level: level, topics: {category.name});
          expect(pool.length, greaterThanOrEqualTo(8),
              reason: 'tópico ${category.name} no nível $level: pool degenerado '
                  'com ${pool.length} candidato(s)');
        }
      }
    });
  });
}
