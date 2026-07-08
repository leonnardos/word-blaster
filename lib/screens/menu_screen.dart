import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../data/word_bank.dart';
import '../game/difficulty.dart';
import '../services/ads_service.dart';
import '../services/progress_service.dart';
import '../services/ranking_service.dart';
import '../services/sound_service.dart';
import '../services/tts_service.dart';
import '../version.dart';
import 'game_screen.dart';
import 'menu_background.dart';

class MenuScreen extends StatefulWidget {
  const MenuScreen({super.key});

  @override
  State<MenuScreen> createState() => _MenuScreenState();
}

class _MenuScreenState extends State<MenuScreen> {
  late Difficulty _difficulty;

  @override
  void initState() {
    super.initState();
    _difficulty = Difficulty.values.firstWhere(
      (d) => d.name == ProgressService.difficultyName,
      orElse: () => Difficulty.beginner,
    );
    // O menu é silencioso: a trilha toca só com o jogo rodando
    // (SoundService.setGameplay, acionado pelo JOGAR).
  }

  void _selectDifficulty(Difficulty difficulty) {
    setState(() => _difficulty = difficulty);
    ProgressService.saveDifficulty(difficulty.name);
  }

  Future<void> _play() async {
    // Gesto do usuário: destrava o autoplay do web E liga a trilha,
    // que toca apenas durante o jogo ativo. No iOS também destrava a
    // FALA (WebKit exige a 1ª fala dentro de um toque).
    TtsService.warmUp();
    SoundService.setGameplay(true);
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => GameScreen(difficulty: _difficulty)),
    );
    SoundService.setGameplay(false); // voltou ao menu: silêncio
    // Atualiza recorde/estatísticas ao voltar da partida.
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF070B14),
      // Banner só no MENU: dentro da partida, nunca (atrapalha e derruba
      // retenção — o plano é anúncio recompensado no game over, fase 5).
      bottomNavigationBar: const SafeArea(child: _MenuBanner()),
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Arte de batalha pintada por código (tanque, fogo, fumaça,
          // destroços de palavras) — recriação da referência do usuário.
          const MenuBackground(),
          // A arte do usuário (assets/images/menu_bg.png) cobre a pintura;
          // sem o arquivo, o errorBuilder não mostra nada. FilterQuality.high
          // é essencial: o padrão (low) borra a imagem ao redimensionar.
          Image.asset(
            'assets/images/menu_bg.png',
            fit: BoxFit.cover,
            filterQuality: FilterQuality.high,
            isAntiAlias: true,
            errorBuilder: (_, __, ___) => const SizedBox.shrink(),
          ),
          // Véu escuro para o texto continuar legível sobre a arte.
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xB3070B14),
                  Color(0x99070B14),
                  Color(0xCC070B14),
                ],
              ),
            ),
          ),
          SafeArea(
            child: Center(
              child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(flex: 2),
              const FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  'WORD',
                  maxLines: 1,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 48,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 12,
                    height: 0.9,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: const Text(
                    'BLASTER',
                    maxLines: 1,
                    style: TextStyle(
                      color: Color(0xFF00E5FF),
                      fontSize: 48,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 12,
                      height: 1.1,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                'Digite. Destrua. Aprenda.',
                style: TextStyle(
                  color: Color(0xFF8A93B2),
                  fontSize: 15,
                  letterSpacing: 1.5,
                ),
              ),
              const Spacer(),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _stat('RECORDE', '${ProgressService.bestScore}'),
                      _stat('XP TOTAL', '${ProgressService.totalXp}'),
                      _stat('PALAVRAS',
                          '${ProgressService.totalWordsDestroyed}'),
                    ],
                  ),
                ),
              ),
              const Spacer(),
              const Text(
                'ESCOLHA SEU NÍVEL',
                style: TextStyle(
                  color: Color(0xFF9AA3BC),
                  fontSize: 11,
                  letterSpacing: 3,
                  shadows: [Shadow(color: Color(0xCC000000), blurRadius: 6)],
                ),
              ),
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: Difficulty.values
                      .map((d) => Expanded(child: _difficultyCard(d)))
                      .toList(),
                ),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                alignment: WrapAlignment.center,
                children: [_topicsButton(), _cefrButton(), _top10Button()],
              ),
              const SizedBox(height: 14),
              _volumeRow('MÚSICA', ProgressService.musicVolume, (v) async {
                await ProgressService.saveMusicVolume(v);
                SoundService.syncMusic();
                setState(() {});
              }),
              const SizedBox(height: 6),
              _volumeRow('PRONÚNCIA', ProgressService.voiceVolume, (v) async {
                await ProgressService.saveVoiceVolume(v);
                await TtsService.applyVolume();
                TtsService.speak('hello'); // amostra para calibrar de ouvido
                setState(() {});
              }),
              const Spacer(),
              SizedBox(
                width: 240,
                height: 60,
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF00E5FF),
                    foregroundColor: const Color(0xFF070B14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  onPressed: _play,
                  child: const Text(
                    'JOGAR',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 6,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Digite as palavras para destruir os inimigos\nantes que alcancem sua nave.',
                textAlign: TextAlign.center,
                // Cinza bem claro + sombra: legível sobre a arte de fundo.
                style: TextStyle(
                  color: Color(0xFFD9DEE8),
                  fontSize: 12,
                  shadows: [Shadow(color: Color(0xCC000000), blurRadius: 6)],
                ),
              ),
              const Spacer(flex: 2),
            ],
          ),
        ),
      ),
          Positioned(
            right: 10,
            bottom: 6,
            // Tocar na versão mostra a voz que o TTS escolheu — diagnóstico
            // para celulares que insistem em falar inglês com voz PT-BR.
            child: GestureDetector(
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'voz: ${TtsService.voiceInfo.value}',
                      style: const TextStyle(fontSize: 12),
                    ),
                    duration: const Duration(seconds: 6),
                  ),
                );
              },
              child: const Text(
                kBuildVersion,
                style: TextStyle(color: Color(0x805A6284), fontSize: 9),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _topicsButton() {
    final count = ProgressService.selectedTopics.length;
    final label = count == 0 ? 'TÓPICOS: TODOS' : 'TÓPICOS: $count';
    return OutlinedButton.icon(
      style: OutlinedButton.styleFrom(
        // Fundo escuro sólido: sem ele o botão sumia na arte do menu.
        backgroundColor: const Color(0xE0141A2E),
        foregroundColor: const Color(0xFFAAB4CE),
        side: const BorderSide(color: Color(0xFF3A4568)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
      ),
      icon: const Icon(Icons.category_outlined, size: 16),
      label: Text(label,
          style: const TextStyle(fontSize: 12, letterSpacing: 1.5)),
      onPressed: _openTopicsSheet,
    );
  }

  /// Escada CEFR acumulativa: escolher B1 treina A1+A2+B1.
  Widget _cefrButton() {
    final max = ProgressService.maxCefr;
    final label = max == 'C2' ? 'NÍVEL: TODOS' : 'NÍVEL: ATÉ $max';
    return OutlinedButton.icon(
      style: OutlinedButton.styleFrom(
        backgroundColor: const Color(0xE0141A2E),
        foregroundColor: const Color(0xFFAAB4CE),
        side: const BorderSide(color: Color(0xFF3A4568)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
      ),
      icon: const Icon(Icons.school_outlined, size: 16),
      label: Text(label,
          style: const TextStyle(fontSize: 12, letterSpacing: 1.5)),
      onPressed: _openCefrSheet,
    );
  }

  Future<void> _openCefrSheet() async {
    const descriptions = {
      'A1': 'começando do zero',
      'A2': 'básico do dia-a-dia',
      'B1': 'intermediário',
      'B2': 'intermediário-alto',
      'C1': 'avançado',
      'C2': 'proficiente',
    };
    // Nível só é selecionável com conteúdo de verdade (30+ palavras dele);
    // os demais ficam "EM BREVE" e DESTRAVAM SOZINHOS quando as palavras
    // entrarem no Supabase — sem novo deploy.
    final counts = <String, int>{};
    for (final level in runtimeCefr.values) {
      counts[level] = (counts[level] ?? 0) + 1;
    }
    bool available(String level) =>
        level == 'A1' || (counts[level] ?? 0) >= 30;

    Future<void> pick(String value) async {
      await ProgressService.saveMaxCefr(value);
      if (mounted) Navigator.of(context).pop();
      setState(() {});
    }

    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: const Color(0xFF10162A),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'TREINAR PALAVRAS ATÉ O NÍVEL',
              style: TextStyle(
                color: Color(0xFF9AA3BC),
                fontSize: 12,
                letterSpacing: 2,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'os níveis acumulam: B1 inclui A1 e A2',
              style: TextStyle(color: Color(0xFF5A6284), fontSize: 11),
            ),
            const SizedBox(height: 12),
            // TODOS (padrão): sem filtro — internamente maxCefr = C2.
            ListTile(
              dense: true,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              tileColor: ProgressService.maxCefr == 'C2'
                  ? const Color(0xFF0E2A33)
                  : null,
              leading: Icon(
                Icons.all_inclusive,
                size: 20,
                color: ProgressService.maxCefr == 'C2'
                    ? const Color(0xFF00E5FF)
                    : const Color(0xFFAAB4CE),
              ),
              title: const Text(
                'TODOS — vocabulário inteiro',
                style: TextStyle(color: Color(0xFF8A93B2), fontSize: 13),
              ),
              trailing: ProgressService.maxCefr == 'C2'
                  ? const Icon(Icons.check,
                      color: Color(0xFF00E5FF), size: 18)
                  : null,
              onTap: () => pick('C2'),
            ),
            for (final level in cefrOrder.where((l) => l != 'C2'))
              ListTile(
                dense: true,
                enabled: available(level),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                tileColor: level == ProgressService.maxCefr
                    ? const Color(0xFF0E2A33)
                    : null,
                leading: Text(
                  level,
                  style: TextStyle(
                    color: !available(level)
                        ? const Color(0xFF3A4258)
                        : level == ProgressService.maxCefr
                            ? const Color(0xFF00E5FF)
                            : const Color(0xFFAAB4CE),
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                title: Text(
                  descriptions[level]!,
                  style: TextStyle(
                    color: available(level)
                        ? const Color(0xFF8A93B2)
                        : const Color(0xFF3A4258),
                    fontSize: 13,
                  ),
                ),
                trailing: !available(level)
                    ? Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          border:
                              Border.all(color: const Color(0xFF3A4258)),
                        ),
                        child: const Text(
                          'EM BREVE',
                          style: TextStyle(
                            color: Color(0xFF5A6284),
                            fontSize: 9,
                            letterSpacing: 1.5,
                          ),
                        ),
                      )
                    : level == ProgressService.maxCefr
                        ? const Icon(Icons.check,
                            color: Color(0xFF00E5FF), size: 18)
                        : null,
                onTap: available(level) ? () => pick(level) : null,
              ),
          ],
        ),
      ),
    );
  }

  Widget _top10Button() {
    return OutlinedButton.icon(
      style: OutlinedButton.styleFrom(
        backgroundColor: const Color(0xE0141A2E),
        foregroundColor: const Color(0xFFFFC93C),
        side: const BorderSide(color: Color(0xFF5C4A16)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
      ),
      icon: const Icon(Icons.emoji_events_outlined, size: 16),
      label: const Text('TOP 10',
          style: TextStyle(fontSize: 12, letterSpacing: 1.5)),
      onPressed: _openTop10Sheet,
    );
  }

  /// Placar arcade online: top 10 geral, sem cadastro.
  Future<void> _openTop10Sheet() async {
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: const Color(0xFF10162A),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 28),
        child: FutureBuilder<List<RankEntry>?>(
          future: RankingService.fetchTop10(),
          builder: (context, snap) {
            final Widget body;
            if (!snap.hasData && snap.connectionState != ConnectionState.done) {
              body = const Padding(
                padding: EdgeInsets.symmetric(vertical: 30),
                child: Center(
                  child: CircularProgressIndicator(color: Color(0xFFFFC93C)),
                ),
              );
            } else if (snap.data == null) {
              body = const Padding(
                padding: EdgeInsets.symmetric(vertical: 30),
                child: Text(
                  'Ranking indisponível — verifique a internet.',
                  style: TextStyle(color: Color(0xFF8A93B2), fontSize: 13),
                ),
              );
            } else if (snap.data!.isEmpty) {
              body = const Padding(
                padding: EdgeInsets.symmetric(vertical: 30),
                child: Text(
                  'Ninguém no placar ainda — seja o primeiro!',
                  style: TextStyle(color: Color(0xFF8A93B2), fontSize: 13),
                ),
              );
            } else {
              final top = snap.data!;
              body = Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (var i = 0; i < top.length; i++)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        children: [
                          SizedBox(
                            width: 34,
                            child: Text(
                              '${i + 1}º',
                              style: TextStyle(
                                color: i == 0
                                    ? const Color(0xFFFFC93C)
                                    : const Color(0xFF8A93B2),
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          Expanded(
                            child: Text(
                              top[i].nickname,
                              style: const TextStyle(
                                color: Color(0xFFE8ECF0),
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          Text(
                            'nv ${top[i].level}',
                            style: const TextStyle(
                                color: Color(0xFF5A6284), fontSize: 12),
                          ),
                          const SizedBox(width: 14),
                          Text(
                            '${top[i].score}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              );
            }
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  '🏆 TOP 10',
                  style: TextStyle(
                    color: Color(0xFFFFC93C),
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 3,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'partidas em velocidade automática',
                  style: TextStyle(color: Color(0xFF5A6284), fontSize: 11),
                ),
                const SizedBox(height: 10),
                body,
              ],
            );
          },
        ),
      ),
    );
  }

  Future<void> _openTopicsSheet() async {
    // Cópia local: só persiste ao fechar a folha.
    final selection = Set<String>.of(ProgressService.selectedTopics);
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: const Color(0xFF10162A),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      isScrollControlled: true,
      builder: (context) => StatefulBuilder(
        builder: (context, setSheetState) => SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Flexible(
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          'O QUE VOCÊ QUER TREINAR?',
                          maxLines: 1,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 2,
                          ),
                        ),
                      ),
                    ),
                    TextButton(
                      onPressed: selection.isEmpty
                          ? null
                          : () => setSheetState(selection.clear),
                      child: const Text(
                        'TODOS',
                        style: TextStyle(
                            color: Color(0xFF00E5FF), letterSpacing: 1),
                      ),
                    ),
                  ],
                ),
                const Text(
                  'Nenhum marcado = todos os tópicos entram no jogo.',
                  style: TextStyle(color: Color(0xFF5A6284), fontSize: 12),
                ),
                const SizedBox(height: 14),
                Flexible(
                  child: SingleChildScrollView(
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: runtimeBank.map((category) {
                        final selected = selection.contains(category.name);
                        return FilterChip(
                          label: Text(
                              '${category.name} · ${category.words.length}'),
                          selected: selected,
                          onSelected: (_) => setSheetState(() {
                            selected
                                ? selection.remove(category.name)
                                : selection.add(category.name);
                          }),
                          labelStyle: TextStyle(
                            color: selected
                                ? const Color(0xFF00E5FF)
                                : const Color(0xFF8A93B2),
                            fontSize: 13,
                          ),
                          backgroundColor: const Color(0xFF141A2E),
                          selectedColor: const Color(0xFF0E2A33),
                          checkmarkColor: const Color(0xFF00E5FF),
                          side: BorderSide(
                            color: selected
                                ? const Color(0xFF00E5FF)
                                : const Color(0xFF2A3350),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF00E5FF),
                      foregroundColor: const Color(0xFF070B14),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text(
                      'PRONTO',
                      style: TextStyle(
                          fontWeight: FontWeight.bold, letterSpacing: 2),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    await ProgressService.saveTopics(selection);
    setState(() {});
  }

  /// Linha de volume estilo mixer: LABEL  −  40%  +
  Widget _volumeRow(String label, int value, void Function(int) onChanged) {
    return FittedBox(
      fit: BoxFit.scaleDown,
      child: Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        SizedBox(
          width: 112, // cabe "PRONÚNCIA" com letterSpacing 2
          child: Text(
            label,
            maxLines: 1,
            textAlign: TextAlign.right,
            style: const TextStyle(
              color: Color(0xFF9AA3BC),
              fontSize: 11,
              letterSpacing: 2,
              shadows: [Shadow(color: Color(0xCC000000), blurRadius: 6)],
            ),
          ),
        ),
        const SizedBox(width: 10),
        _stepButton('−', () => onChanged(value - 10)),
        SizedBox(
          width: 56,
          child: Text(
            '$value%',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: value == 0 ? const Color(0xFF5A6284) : Colors.white,
              fontSize: 15,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        _stepButton('+', () => onChanged(value + 10)),
        const SizedBox(width: 122), // equilibra o label à esquerda
      ],
      ),
    );
  }

  Widget _stepButton(String symbol, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 28,
        height: 28,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: const Color(0xFF10162A),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFF2A3350)),
        ),
        child: Text(
          symbol,
          style: const TextStyle(
            color: Color(0xFF00E5FF),
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _difficultyCard(Difficulty difficulty) {
    final selected = difficulty == _difficulty;
    return GestureDetector(
      onTap: () => _selectDifficulty(difficulty),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        margin: const EdgeInsets.symmetric(horizontal: 5),
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 6),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFF0E2A33) : const Color(0xFF10162A),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color:
                selected ? const Color(0xFF00E5FF) : const Color(0xFF2A3350),
            width: selected ? 2 : 1,
          ),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: const Color(0xFF00E5FF).withValues(alpha: 0.25),
                    blurRadius: 16,
                  ),
                ]
              : const [],
        ),
        child: Column(
          children: [
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                difficulty.label,
                maxLines: 1,
                style: TextStyle(
                  color: selected ? const Color(0xFF00E5FF) : Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              difficulty.description,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Color(0xFF8A93B2),
                fontSize: 10,
                height: 1.3,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _stat(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18),
      child: Column(
        children: [
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              color: Color(0xFF9AA3BC),
              fontSize: 11,
              letterSpacing: 2,
              shadows: [Shadow(color: Color(0xCC000000), blurRadius: 6)],
            ),
          ),
        ],
      ),
    );
  }
}

/// Banner AdMob no rodapé do menu. Só existe no celular; em web/desktop (ou
/// se o anúncio não carregar) ocupa zero espaço.
class _MenuBanner extends StatefulWidget {
  const _MenuBanner();

  @override
  State<_MenuBanner> createState() => _MenuBannerState();
}

class _MenuBannerState extends State<_MenuBanner> {
  BannerAd? _banner;
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    if (!AdsService.isReady) return;
    _banner = BannerAd(
      size: AdSize.banner,
      adUnitId: AdsService.bannerUnitId,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (_) {
          if (mounted) setState(() => _loaded = true);
        },
        onAdFailedToLoad: (ad, _) {
          ad.dispose();
          _banner = null;
        },
      ),
    )..load();
  }

  @override
  void dispose() {
    _banner?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final banner = _banner;
    if (!_loaded || banner == null) return const SizedBox.shrink();
    return SizedBox(
      width: banner.size.width.toDouble(),
      height: banner.size.height.toDouble(),
      child: AdWidget(ad: banner),
    );
  }
}
