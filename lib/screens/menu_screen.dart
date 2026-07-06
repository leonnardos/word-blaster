import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../data/word_bank.dart';
import '../game/difficulty.dart';
import '../services/ads_service.dart';
import '../services/progress_service.dart';
import 'game_screen.dart';

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
  }

  void _selectDifficulty(Difficulty difficulty) {
    setState(() => _difficulty = difficulty);
    ProgressService.saveDifficulty(difficulty.name);
  }

  Future<void> _play() async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => GameScreen(difficulty: _difficulty)),
    );
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
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(flex: 2),
              const Text(
                'WORD',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 48,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 12,
                  height: 0.9,
                ),
              ),
              const Text(
                'BLASTER',
                style: TextStyle(
                  color: Color(0xFF00E5FF),
                  fontSize: 48,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 12,
                  height: 1.1,
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
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _stat('RECORDE', '${ProgressService.bestScore}'),
                  _stat('XP TOTAL', '${ProgressService.totalXp}'),
                  _stat('PALAVRAS', '${ProgressService.totalWordsDestroyed}'),
                ],
              ),
              const Spacer(),
              const Text(
                'ESCOLHA SEU NÍVEL',
                style: TextStyle(
                  color: Color(0xFF5A6284),
                  fontSize: 11,
                  letterSpacing: 3,
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
              _topicsButton(),
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
                style: TextStyle(color: Color(0xFF5A6284), fontSize: 12),
              ),
              const Spacer(flex: 2),
            ],
          ),
        ),
      ),
    );
  }

  Widget _topicsButton() {
    final count = ProgressService.selectedTopics.length;
    final label = count == 0 ? 'TÓPICOS: TODOS' : 'TÓPICOS: $count';
    return OutlinedButton.icon(
      style: OutlinedButton.styleFrom(
        foregroundColor: const Color(0xFF8A93B2),
        side: const BorderSide(color: Color(0xFF2A3350)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
      ),
      icon: const Icon(Icons.category_outlined, size: 16),
      label: Text(label,
          style: const TextStyle(fontSize: 12, letterSpacing: 1.5)),
      onPressed: _openTopicsSheet,
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
                      children: wordBank.map((category) {
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
              color: Color(0xFF5A6284),
              fontSize: 11,
              letterSpacing: 2,
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
