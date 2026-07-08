import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../data/word_bank.dart';

/// Fonte do vocabulário em tempo de execução, em 3 camadas (offline-first):
///
///   1. EMBUTIDO no app (word_bank/word_examples/word_cefr) — a semente:
///      funciona offline desde a primeira abertura, para sempre;
///   2. CACHE local da última sincronização (SharedPreferences);
///   3. SUPABASE (tabela `words`, só leitura) — sincroniza em segundo
///      plano por `updated_at`; palavras novas chegam SEM novo deploy.
///
/// Toda falha de rede é silenciosa: o jogo nunca espera nem depende dela.
class WordRepository {
  static const _cacheKey = 'words_cache_v1';
  static const _syncKey = 'words_last_sync_v1';

  static const _base =
      'https://obocpanjjtdvqclstyqg.supabase.co/rest/v1/words';
  static const _key = 'sb_publishable_6YnjXwA8oSUQdB2LPF9UKg_1FxCIsDZ';
  static const _headers = {
    'apikey': _key,
    'Authorization': 'Bearer $_key',
  };
  static const _select = 'en,pt,topic,topic_level,cefr,examples,updated_at';
  static const _pageSize = 1000;

  static late SharedPreferences _prefs;

  /// Linhas sincronizadas, por palavra (a chave é o `en`).
  static final Map<String, Map<String, dynamic>> _rows = {};

  /// Carrega o cache (rápido, local) e dispara a sincronização em segundo
  /// plano. Chamar ANTES de ProgressService.init (que valida os tópicos
  /// escolhidos contra o banco ativo).
  static Future<void> init() async {
    try {
      _prefs = await SharedPreferences.getInstance();
      final raw = _prefs.getString(_cacheKey);
      if (raw != null) {
        for (final row in jsonDecode(raw) as List<dynamic>) {
          final m = row as Map<String, dynamic>;
          _rows[m['en'] as String] = m;
        }
        _apply();
      }
    } catch (_) {}
    refresh(); // sem await: rede nunca atrasa a abertura do jogo
  }

  /// Busca no Supabase o que mudou desde a última sincronização e aplica.
  static Future<void> refresh() async {
    try {
      final since = _prefs.getString(_syncKey);
      // Primeira vez (sem cache): busca tudo; depois só o delta.
      final filter = (since == null || _rows.isEmpty)
          ? ''
          : '&updated_at=gt.$since';
      final fresh = <Map<String, dynamic>>[];
      for (var offset = 0;; offset += _pageSize) {
        final uri = Uri.parse(
            '$_base?select=$_select&order=id&limit=$_pageSize&offset=$offset$filter');
        final res =
            await http.get(uri, headers: _headers).timeout(const Duration(seconds: 10));
        if (res.statusCode != 200) return;
        final page = jsonDecode(res.body) as List<dynamic>;
        fresh.addAll(page.cast<Map<String, dynamic>>());
        if (page.length < _pageSize) break;
      }
      if (fresh.isEmpty) return;

      var latest = since ?? '';
      for (final row in fresh) {
        _rows[row['en'] as String] = row;
        final u = (row['updated_at'] ?? '') as String;
        if (u.compareTo(latest) > 0) latest = u;
      }
      await _prefs.setString(_cacheKey, jsonEncode(_rows.values.toList()));
      if (latest.isNotEmpty) await _prefs.setString(_syncKey, latest);
      _apply();
    } catch (_) {}
  }

  /// Reconstrói o banco ativo (runtimeBank/runtimeExamples/runtimeCefr)
  /// a partir das linhas sincronizadas.
  static void _apply() {
    if (_rows.isEmpty) return;
    try {
      final byTopic = <String, List<Word>>{};
      final topicLevel = <String, int>{};
      final examples = <String, List<(String, String)>>{};
      final cefr = <String, String>{};

      for (final m in _rows.values) {
        final en = m['en'] as String;
        final topic = (m['topic'] ?? '?') as String;
        byTopic.putIfAbsent(topic, () => []).add(Word(en, (m['pt'] ?? '') as String));
        topicLevel[topic] = ((m['topic_level'] ?? 1) as num).toInt();
        cefr[en] = (m['cefr'] ?? 'A1') as String;
        final ex = m['examples'];
        if (ex is List && ex.length == 3) {
          examples[en] = [
            for (final pair in ex)
              (
                ((pair as List)[0] ?? '').toString(),
                (pair[1] ?? '').toString(),
              ),
          ];
        }
      }

      final bank = byTopic.entries
          .map((e) => WordCategory(topicLevel[e.key] ?? 1, e.key, e.value))
          .toList()
        ..sort((a, b) => a.level.compareTo(b.level));

      runtimeBank = bank;
      runtimeExamples = examples;
      runtimeCefr = cefr;
    } catch (_) {
      // Cache corrompido não pode derrubar o jogo: fica no embutido.
    }
  }
}
