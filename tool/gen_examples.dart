// Junta tool/examples/*.json (gerados por agentes) no mapa Dart
// lib/data/word_examples.dart, na ordem do banco de palavras.
// Formato novo: 3 frases por palavra (presente, passado, futuro), com a
// palavra-alvo marcada entre *asteriscos* para o destaque azul no cartão.
// Rodar com: dart run tool/gen_examples.dart
import 'dart:convert';
import 'dart:io';

import 'package:word_blaster/data/word_bank.dart';

void main() {
  final dir = Directory('tool/examples');
  if (!dir.existsSync()) {
    stderr.writeln('tool/examples/ não existe — rode a geração antes.');
    exit(1);
  }

  final entries = <String, List<(String, String)>>{};
  var badFormat = 0;
  for (final file in dir
      .listSync()
      .whereType<File>()
      .where((f) => f.path.endsWith('.json'))) {
    final list = jsonDecode(file.readAsStringSync()) as List<dynamic>;
    for (final raw in list) {
      final m = raw as Map<String, dynamic>;
      final en = (m['en'] as String).trim();
      final ex = (m['ex'] as List<dynamic>)
          .map((pair) => (
                ((pair as List<dynamic>)[0] as String).trim(),
                (pair[1] as String).trim(),
              ))
          .toList();
      // Cada frase precisa de exatamente UM par de *asteriscos* (o
      // destaque azul); sem isso o cartão perderia a marcação.
      final valid = ex.length == 3 &&
          ex.every((p) =>
              '*'.allMatches(p.$1).length == 2 &&
              p.$1.indexOf('*') < p.$1.lastIndexOf('*') - 1);
      if (!valid) {
        badFormat++;
        stdout.writeln('FORMATO RUIM: ${file.path} :: $en');
        continue;
      }
      // Duplicatas entre tópicos (ex.: 'clean' em Verbos e Adjetivos):
      // vale a primeira; o cartão mostra um conjunto só.
      entries.putIfAbsent(en, () => ex);
    }
  }

  var missing = 0;
  for (final category in wordBank) {
    for (final w in category.words) {
      if (!entries.containsKey(w.en)) {
        missing++;
        stdout.writeln('FALTA: ${category.name} :: ${w.en}');
      }
    }
  }

  String esc(String s) => s
      .replaceAll(r'\', r'\\')
      .replaceAll(r'$', r'\$')
      .replaceAll("'", r"\'");

  final buf = StringBuffer()
    ..writeln(
        '/// Frases de exemplo por palavra, em 3 tempos (presente, passado,')
    ..writeln(
        '/// futuro): en → [(frase, tradução) ×3]. A palavra-alvo vem marcada')
    ..writeln('/// entre *asteriscos* para o destaque azul no cartão.')
    ..writeln(
        '/// GERADO por tool/gen_examples.dart a partir de tool/examples/*.json —')
    ..writeln(
        '/// não edite à mão; rode `dart run tool/gen_examples.dart` para regenerar.')
    ..writeln('const Map<String, List<(String, String)>> wordExamples = {');
  final written = <String>{};
  for (final category in wordBank) {
    for (final w in category.words) {
      final ex = entries[w.en];
      if (ex == null || !written.add(w.en)) continue;
      buf.writeln("  '${esc(w.en)}': [");
      for (final p in ex) {
        buf.writeln("    ('${esc(p.$1)}', '${esc(p.$2)}'),");
      }
      buf.writeln('  ],');
    }
  }
  buf.writeln('};');
  File('lib/data/word_examples.dart').writeAsStringSync(buf.toString());
  stdout.writeln(
      'OK: ${written.length} palavras com 3 tempos; $missing faltando; '
      '$badFormat com formato ruim.');
  if (missing > 0 || badFormat > 0) exit(1);
}
