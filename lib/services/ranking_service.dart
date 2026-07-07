import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../version.dart';
import 'progress_service.dart';

/// Uma linha do placar online.
class RankEntry {
  final String nickname;
  final int score;
  final int level;

  const RankEntry(
      {required this.nickname, required this.score, required this.level});
}

/// Ranking arcade online: top 10 sem cadastro (Supabase REST).
///
/// Versão simples para brincar com amigos — a fase R2 do PLANO §3.3 traz o
/// anti-cheat de verdade (Edge Functions). Toda falha aqui é silenciosa:
/// o jogo é offline-first e NUNCA depende da rede; sem internet o ranking
/// apenas não aparece.
class RankingService {
  static const _url =
      'https://obocpanjjtdvqclstyqg.supabase.co/rest/v1/scores';

  /// Chave PUBLISHABLE do Supabase: feita para ficar no cliente — com o
  /// RLS ela só consegue ler o placar e inserir scores (nunca alterar
  /// nem apagar).
  static const _key = 'sb_publishable_6YnjXwA8oSUQdB2LPF9UKg_1FxCIsDZ';

  static const _headers = {
    'apikey': _key,
    'Authorization': 'Bearer $_key',
    'Content-Type': 'application/json',
  };

  static const _timeout = Duration(seconds: 6);

  /// Top 10 geral (maiores pontuações). `null` = rede indisponível.
  static Future<List<RankEntry>?> fetchTop10() async {
    try {
      final res = await http
          .get(
            Uri.parse(
                '$_url?select=nickname,score,level&order=score.desc&limit=10'),
            headers: _headers,
          )
          .timeout(_timeout);
      if (res.statusCode != 200) return null;
      final list = jsonDecode(res.body) as List<dynamic>;
      return [
        for (final raw in list)
          RankEntry(
            nickname: (raw['nickname'] ?? '?').toString(),
            score: ((raw['score'] ?? 0) as num).toInt(),
            level: ((raw['level'] ?? 1) as num).toInt(),
          ),
      ];
    } catch (_) {
      return null;
    }
  }

  /// O [score] entraria no top 10 atual?
  static bool qualifies(int score, List<RankEntry> top) =>
      score > 0 && (top.length < 10 || score > top.last.score);

  /// Envia o score. true = gravado.
  static Future<bool> submit({
    required String nickname,
    required int score,
    required int level,
    required int words,
  }) async {
    try {
      final res = await http
          .post(
            Uri.parse(_url),
            headers: {..._headers, 'Prefer': 'return=minimal'},
            body: jsonEncode({
              'nickname': nickname,
              'score': score,
              'level': level.clamp(1, 50),
              'words': words,
              'difficulty': ProgressService.difficultyName,
              'platform': kIsWeb ? 'web' : defaultTargetPlatform.name,
              'client_version': kBuildVersion,
            }),
          )
          .timeout(_timeout);
      return res.statusCode == 201;
    } catch (_) {
      return false;
    }
  }

  /// Normaliza para o formato de fliperama: A-Za-z0-9_ com até 12 letras.
  static String normalizeNick(String raw) {
    final cleaned = raw
        .trim()
        .replaceAll(' ', '_')
        .replaceAll(RegExp(r'[^A-Za-z0-9_]'), '');
    return cleaned.length > 12 ? cleaned.substring(0, 12) : cleaned;
  }

  static bool validNick(String nick) =>
      RegExp(r'^[A-Za-z0-9_]{2,12}$').hasMatch(nick);
}
