// Junta tool/examples/*.json (gerados por agentes) no mapa Dart
// lib/data/word_examples.dart, na ordem do banco de palavras.
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

  final entries = <String, (String, String)>{};
  for (final file in dir
      .listSync()
      .whereType<File>()
      .where((f) => f.path.endsWith('.json'))) {
    final list = jsonDecode(file.readAsStringSync()) as List<dynamic>;
    for (final raw in list) {
      final m = raw as Map<String, dynamic>;
      final en = (m['en'] as String).trim();
      // Duplicatas entre tópicos (ex.: 'clean' em Verbos e Adjetivos):
      // vale a primeira; o cartão mostra um exemplo só.
      entries.putIfAbsent(
          en, () => (m['example'] as String, m['examplePt'] as String));
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
        '/// Frase de exemplo por palavra: en → (exemplo em inglês, tradução PT-BR).')
    ..writeln(
        '/// GERADO por tool/gen_examples.dart a partir de tool/examples/*.json —')
    ..writeln(
        '/// não edite à mão; rode `dart run tool/gen_examples.dart` para regenerar.')
    ..writeln('const Map<String, (String, String)> wordExamples = {');
  final written = <String>{};
  for (final category in wordBank) {
    for (final w in category.words) {
      final e = entries[w.en];
      if (e == null || !written.add(w.en)) continue;
      buf.writeln("  '${esc(w.en)}': ('${esc(e.$1)}', '${esc(e.$2)}'),");
    }
  }
  buf.writeln('};');
  File('lib/data/word_examples.dart').writeAsStringSync(buf.toString());
  stdout.writeln('OK: ${written.length} exemplos gerados; $missing faltando.');
}
