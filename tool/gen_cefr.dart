// Junta tool/cefr/*.json (classificação por agentes) no mapa Dart
// lib/data/word_cefr.dart, validando cobertura total do banco.
// Rodar com: dart run tool/gen_cefr.dart
import 'dart:convert';
import 'dart:io';

import 'package:word_blaster/data/word_bank.dart';

const _levels = {'A1', 'A2', 'B1', 'B2', 'C1', 'C2'};

void main() {
  final dir = Directory('tool/cefr');
  if (!dir.existsSync()) {
    stderr.writeln('tool/cefr/ não existe — rode a classificação antes.');
    exit(1);
  }

  final entries = <String, String>{};
  var invalid = 0;
  for (final file in dir
      .listSync()
      .whereType<File>()
      .where((f) => f.path.endsWith('.json'))) {
    final map = jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
    map.forEach((en, level) {
      if (!_levels.contains(level)) {
        invalid++;
        stdout.writeln('NÍVEL INVÁLIDO: ${file.path} :: $en → $level');
        return;
      }
      // Duplicata entre tópicos: fica o nível MAIS BAIXO (jogo de iniciante).
      final existing = entries[en];
      final rank = 'A1A2B1B2C1C2'.indexOf(level as String);
      if (existing == null || 'A1A2B1B2C1C2'.indexOf(existing) > rank) {
        entries[en.trim()] = level;
      }
    });
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
    ..writeln("/// Nível CEFR por palavra: en → 'A1'..'C2'.")
    ..writeln(
        '/// GERADO por tool/gen_cefr.dart a partir de tool/cefr/*.json —')
    ..writeln(
        '/// não edite à mão; rode `dart run tool/gen_cefr.dart` para regenerar.')
    ..writeln('const Map<String, String> wordCefr = {');
  final written = <String>{};
  for (final category in wordBank) {
    for (final w in category.words) {
      final level = entries[w.en];
      if (level == null || !written.add(w.en)) continue;
      buf.writeln("  '${esc(w.en)}': '$level',");
    }
  }
  buf.writeln('};');
  File('lib/data/word_cefr.dart').writeAsStringSync(buf.toString());

  final counts = <String, int>{};
  for (final w in written) {
    counts[entries[w]!] = (counts[entries[w]!] ?? 0) + 1;
  }
  stdout.writeln('OK: ${written.length} palavras classificadas '
      '(${counts.entries.map((e) => '${e.key}:${e.value}').join(' ')}); '
      '$missing faltando; $invalid inválidas.');
  if (missing > 0 || invalid > 0) exit(1);
}
