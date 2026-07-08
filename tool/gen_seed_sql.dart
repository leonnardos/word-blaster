// Gera o SQL de semeadura da tabela public.words no Supabase a partir do
// banco embutido: word_bank (palavras/tópicos) + tool/examples/*.json
// (frases nos 3 tempos) + tool/cefr/*.json (níveis). Upsert idempotente
// (ON CONFLICT en): rodar de novo só atualiza.
// Rodar com: dart run tool/gen_seed_sql.dart  →  tool/seed/words_NNN.sql
import 'dart:convert';
import 'dart:io';

import 'package:word_blaster/data/word_bank.dart';

const _chunkSize = 100;

void main() {
  // Exemplos canônicos por palavra (mesma fonte do gen_examples).
  final examples = <String, List<List<String>>>{};
  for (final file in Directory('tool/examples')
      .listSync()
      .whereType<File>()
      .where((f) => f.path.endsWith('.json'))) {
    for (final raw in jsonDecode(file.readAsStringSync()) as List<dynamic>) {
      final m = raw as Map<String, dynamic>;
      examples.putIfAbsent(
        (m['en'] as String).trim(),
        () => [
          for (final pair in m['ex'] as List<dynamic>)
            [(pair as List)[0] as String, pair[1] as String],
        ],
      );
    }
  }

  final cefr = <String, String>{};
  for (final file in Directory('tool/cefr')
      .listSync()
      .whereType<File>()
      .where((f) => f.path.endsWith('.json'))) {
    (jsonDecode(file.readAsStringSync()) as Map<String, dynamic>)
        .forEach((en, level) => cefr.putIfAbsent(en.trim(), () => '$level'));
  }

  String q(String s) => "'${s.replaceAll("'", "''")}'";

  final rows = <String>[];
  final seen = <String>{};
  for (final category in wordBank) {
    for (final w in category.words) {
      if (!seen.add(w.en)) continue; // duplicata entre tópicos: primeira vale
      final ex = examples[w.en];
      final exJson = ex == null ? 'null' : "${q(jsonEncode(ex))}::jsonb";
      rows.add('(${q(w.en)}, ${q(w.pt)}, ${q(category.name)}, '
          '${category.level}, ${q(cefr[w.en] ?? 'A1')}, $exJson)');
    }
  }

  final outDir = Directory('tool/seed')..createSync(recursive: true);
  for (final old in outDir.listSync().whereType<File>()) {
    old.deleteSync();
  }
  var fileIndex = 0;
  for (var i = 0; i < rows.length; i += _chunkSize) {
    final chunk = rows.sublist(
        i, i + _chunkSize > rows.length ? rows.length : i + _chunkSize);
    final sql = StringBuffer()
      ..writeln('insert into public.words '
          '(en, pt, topic, topic_level, cefr, examples) values')
      ..writeln(chunk.join(',\n'))
      ..writeln('on conflict (en) do update set')
      ..writeln('  pt = excluded.pt, topic = excluded.topic,')
      ..writeln('  topic_level = excluded.topic_level,')
      ..writeln('  cefr = excluded.cefr, examples = excluded.examples;');
    fileIndex++;
    File('tool/seed/words_${fileIndex.toString().padLeft(3, '0')}.sql')
        .writeAsStringSync(sql.toString());
  }
  stdout.writeln('OK: ${rows.length} palavras em $fileIndex arquivos SQL.');
}
