import 'dart:math';

import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, TargetPlatform;
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../data/word_bank.dart';
import '../game/difficulty.dart';
import '../services/ads_service.dart';
import '../services/install_service.dart';
import '../services/progress_service.dart';
import '../services/ranking_service.dart';
import '../services/sound_service.dart';
import '../services/tts_service.dart';
import '../services/web_links.dart';
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
  bool _missionHover = false;

  @override
  void initState() {
    super.initState();
    _difficulty = Difficulty.values.firstWhere(
      (d) => d.name == ProgressService.difficultyName,
      orElse: () => Difficulty.beginner,
    );
    // O menu é silencioso: a trilha toca só com o jogo rodando
    // (SoundService.setGameplay, acionado pelo JOGAR).

    // O beforeinstallprompt (Android) pode chegar DEPOIS do primeiro
    // build — reconfere para o card de instalação aparecer.
    if (InstallService.supported) {
      Future.delayed(const Duration(seconds: 3), () {
        if (mounted) setState(() {});
      });
      Future.delayed(const Duration(seconds: 8), () {
        if (mounted) setState(() {});
      });
    }
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
          // A arte do usuário (campo de batalha devastado) cobre a pintura;
          // sem o arquivo, o errorBuilder não mostra nada. FilterQuality.high
          // é essencial: o padrão (low) borra a imagem ao redimensionar.
          Image.asset(
            'assets/images/menu_bg2.jpg',
            fit: BoxFit.cover,
            filterQuality: FilterQuality.high,
            isAntiAlias: true,
            errorBuilder: (_, __, ___) => const SizedBox.shrink(),
          ),
          // Véu escuro FORTE (~75%): a arte vira clima, o foco é o menu.
          // (O logo agora é uma FAIXA própria no fluxo, acima do véu.)
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xB3070B14),
                  Color(0xBF070B14),
                  Color(0xD9070B14),
                ],
              ),
            ),
          ),
          // Fagulhas e fumaça sutis flutuando por cima do véu.
          const MenuParticles(),
          SafeArea(
            child: LayoutBuilder(
              builder: (context, box) {
                // SEM rolagem quando cabe: a coluna é esticada à altura da
                // tela e o spaceEvenly reparte a sobra IGUALMENTE entre os
                // blocos (pedido do usuário). Em janelas muito baixas o
                // scroll continua como rede de segurança.
                return SingleChildScrollView(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(minHeight: box.maxHeight),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 660),
                        child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              // FAIXA do logo (recorte da arte com fade na base): flui na
              // coluna como widget normal — o slogan NUNCA sobrepõe, em
              // qualquer tela/zoom (bug visto em celulares reais).
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 480),
                    child: Image.asset(
                      'assets/images/logo_banner.png',
                      fit: BoxFit.fitWidth,
                      semanticLabel: 'Word Blaster',
                      filterQuality: FilterQuality.high,
                      isAntiAlias: true,
                      errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                    ),
                  ),
                  // Slogan do mockup: vendedor, não descritivo.
                  const Text(
                    'Aprenda inglês jogando.',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.5,
                      shadows: [
                        Shadow(color: Color(0xCC000000), blurRadius: 6)
                      ],
                    ),
                  ),
                  const SizedBox(height: 2),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20),
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        'Digite mais rápido e memorize naturalmente.',
                        maxLines: 1,
                        style: TextStyle(
                          color: Color(0xFF00B8CC),
                          fontSize: 11.5,
                          letterSpacing: 1,
                          shadows: [
                            Shadow(color: Color(0xCC000000), blurRadius: 6)
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              _vocabBar(),
              _skillsGrid(),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    '★  ESCOLHA SUA PATENTE  ★',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      letterSpacing: 3,
                      shadows: [
                        Shadow(color: Color(0xCC000000), blurRadius: 6)
                      ],
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
                ],
              ),
              // O botão-herói no estilo da referência do usuário: placa de
              // OURO com moldura bronze escura e rebites nas pontas.
              // Hover (desktop): cresce e brilha mais.
              MouseRegion(
                cursor: SystemMouseCursors.click,
                onEnter: (_) => setState(() => _missionHover = true),
                onExit: (_) => setState(() => _missionHover = false),
                child: GestureDetector(
                onTap: _play,
                child: AnimatedScale(
                  scale: _missionHover ? 1.05 : 1.0,
                  duration: const Duration(milliseconds: 140),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 140),
                  width: 312,
                  height: 62,
                  decoration: BoxDecoration(
                    color: const Color(0xFF241708),
                    borderRadius: BorderRadius.circular(9),
                    border: Border.all(color: const Color(0xFF0F0A04)),
                    // Sem o halo dourado (pedido do usuário) — o relevo
                    // fica por conta da moldura; o hover cresce e clareia.
                  ),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 5, vertical: 5),
                  child: Row(
                    children: [
                      _rivets(),
                      const SizedBox(width: 5),
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Color(0xFFFFE082),
                                Color(0xFFFFC93C),
                                Color(0xFFD9971C),
                              ],
                              stops: [0.0, 0.45, 1.0],
                            ),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                                color: const Color(0xFF6B4A12), width: 1.2),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.play_arrow_rounded,
                                  color: Color(0xFF15100A), size: 30),
                              const SizedBox(width: 6),
                              Flexible(
                                child: FittedBox(
                                  fit: BoxFit.scaleDown,
                                  child: Text(
                                    'INICIAR MISSÃO',
                                    maxLines: 1,
                                    style: TextStyle(
                                      color: const Color(0xFF15100A),
                                      fontSize: 18,
                                      fontWeight: FontWeight.w900,
                                      letterSpacing: 2,
                                      shadows: [
                                        Shadow(
                                          color: const Color(0xFFFFE9A8)
                                              .withValues(alpha: 0.6),
                                          offset: const Offset(0, 1),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 5),
                      _rivets(),
                    ],
                  ),
                ),
                ),
                ),
              ),
            ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
      ),
          // Troféu do TOP 10: fixo no topo esquerdo, na linha do logo.
          Positioned(
            left: 10,
            top: 10,
            child: SafeArea(child: _trophyFab()),
          ),
          // INSTALAR: fixo no topo direito (só navegador de celular,
          // some quando o app já está instalado).
          Positioned(
            right: 10,
            top: 10,
            child: SafeArea(child: _installFab() ?? const SizedBox.shrink()),
          ),
          // Links das páginas do site (AdSense pede privacidade acessível).
          if (WebLinks.available)
            Positioned(
              left: 10,
              bottom: 6,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  GestureDetector(
                    onTap: () => WebLinks.open('como-jogar.html'),
                    child: const Text(
                      'como jogar',
                      style:
                          TextStyle(color: Color(0x805A6284), fontSize: 9),
                    ),
                  ),
                  const Text(
                    '  ·  ',
                    style: TextStyle(color: Color(0x805A6284), fontSize: 9),
                  ),
                  GestureDetector(
                    onTap: () => WebLinks.open('privacidade.html'),
                    child: const Text(
                      'privacidade',
                      style:
                          TextStyle(color: Color(0x805A6284), fontSize: 9),
                    ),
                  ),
                ],
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

  /// Popup da PATENTE (nova lógica dos ajustes, pedido do usuário):
  /// tocar num card de patente seleciona E abre esta folha com nível
  /// das palavras, tópicos e volumes. Fecha no X ou tocando fora.
  Future<void> _openRankSheet(Difficulty difficulty) async {
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: const Color(0xFF10162A),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setSheet) => Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Título com a cor da patente + botão X (mais bonito que só
              // o toque-fora, que continua funcionando).
              Row(
                children: [
                  const SizedBox(width: 40),
                  Expanded(
                    child: Text(
                      difficulty.label,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: difficulty.accent,
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 3,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close,
                        color: Color(0xFF8A93B2), size: 22),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              ListTile(
                dense: true,
                leading: const Icon(Icons.category_outlined,
                    color: Color(0xFFAAB4CE), size: 20),
                title: const Text('Tópicos',
                    style:
                        TextStyle(color: Color(0xFFE8ECF0), fontSize: 14)),
                trailing: Text(
                  ProgressService.selectedTopics.isEmpty
                      ? 'todos  ›'
                      : '${ProgressService.selectedTopics.length}  ›',
                  style: const TextStyle(
                      color: Color(0xFF8A93B2), fontSize: 13),
                ),
                onTap: () {
                  Navigator.of(context).pop();
                  _openTopicsSheet();
                },
              ),
              ListTile(
                dense: true,
                leading: const Icon(Icons.school_outlined,
                    color: Color(0xFFAAB4CE), size: 20),
                title: const Text('Nível das palavras',
                    style:
                        TextStyle(color: Color(0xFFE8ECF0), fontSize: 14)),
                trailing: Text(
                  ProgressService.maxCefr == 'C2'
                      ? 'todos  ›'
                      : 'até ${ProgressService.maxCefr}  ›',
                  style: const TextStyle(
                      color: Color(0xFF8A93B2), fontSize: 13),
                ),
                onTap: () {
                  Navigator.of(context).pop();
                  _openCefrSheet();
                },
              ),
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: Divider(color: Color(0xFF2A3350), height: 1),
              ),
              _volumeRow('MÚSICA', ProgressService.musicVolume, (v) async {
                await ProgressService.saveMusicVolume(v);
                SoundService.syncMusic();
                setSheet(() {});
              }),
              const SizedBox(height: 6),
              _volumeRow('PRONÚNCIA', ProgressService.voiceVolume,
                  (v) async {
                await ProgressService.saveVoiceVolume(v);
                await TtsService.applyVolume();
                TtsService.speak('hello'); // amostra para calibrar de ouvido
                setSheet(() {});
              }),
            ],
          ),
        ),
      ),
    );
  }

  /// "INSTALAR" fixo no canto superior direito: sempre à vista enquanto
  /// o app não está instalado — instalou, some sozinho. null = sem botão.
  Widget? _installFab() {
    if (!InstallService.supported || InstallService.isStandalone) {
      return null;
    }
    final isIos = defaultTargetPlatform == TargetPlatform.iOS;
    final isAndroid = defaultTargetPlatform == TargetPlatform.android;
    if (!isIos && !isAndroid) return null;
    // Android sem beforeinstallprompt = já instalado (ou o Chrome ainda
    // não liberou): sem sinal confiável, o botão não aparece — os
    // rechecks de 3s/8s do initState pegam o prompt que chega depois.
    if (isAndroid && !InstallService.hasPrompt) return null;

    return GestureDetector(
      onTap: () {
        if (isIos) {
          _openIosInstallSheet();
        } else {
          InstallService.promptInstall();
          // O prompt nativo consumiu o evento: reavalia o botão (se o
          // jogador instalar, o modo standalone o esconde nas próximas).
          setState(() {});
        }
      },
      child: Container(
        height: 42,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: const Color(0xE0141A2E),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFF14505C)),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.install_mobile, color: Color(0xFF00E5FF), size: 17),
            SizedBox(width: 7),
            Text(
              'INSTALAR',
              style: TextStyle(
                color: Color(0xFF00E5FF),
                fontSize: 11.5,
                letterSpacing: 1.5,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// iPhone não tem prompt de instalação (WebKit): o botão abre o passo
  /// a passo de "Adicionar à Tela de Início".
  Future<void> _openIosInstallSheet() async {
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: const Color(0xFF10162A),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 22, 24, 30),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Center(
              child: Text(
                '📲 INSTALAR NO IPHONE',
                style: TextStyle(
                  color: Color(0xFF00E5FF),
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2,
                ),
              ),
            ),
            const SizedBox(height: 16),
            for (final (i, step) in const [
              'Toque no botão Compartilhar do navegador (quadrado com seta para cima).',
              'Role a lista e toque em "Adicionar à Tela de Início".',
              'Confirme — o ícone do jogo aparece na tela inicial e abre em tela cheia, funcionando até offline.',
            ].indexed) ...[
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${i + 1}.',
                      style: const TextStyle(
                        color: Color(0xFF00E5FF),
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        step,
                        style: const TextStyle(
                            color: Color(0xFFC9D2E0), fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 6),
            Center(
              child: TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text(
                  'FECHAR',
                  style:
                      TextStyle(color: Color(0xFF8A93B2), letterSpacing: 2),
                ),
              ),
            ),
          ],
        ),
      ),
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

  /// Troféu fixo no canto superior esquerdo: abre o TOP 10.
  Widget _trophyFab() {
    return GestureDetector(
      onTap: _openTop10Sheet,
      child: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: const Color(0xE0141A2E),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFF5C4A16)),
        ),
        child: const Icon(Icons.emoji_events,
            color: Color(0xFFFFC93C), size: 22),
      ),
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

  /// Barra de progresso do vocabulário — gamificação central do mockup:
  /// blocos segmentados, sempre com um marco alcançável à vista.
  Widget _vocabBar() {
    final mastered = ProgressService.masteredCount;
    final goal = ProgressService.nextVocabGoal(mastered);
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 26),
      padding: const EdgeInsets.fromLTRB(18, 12, 18, 12),
      decoration: BoxDecoration(
        color: const Color(0xD910162A),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF2A3350)),
      ),
      child: Column(
        children: [
          const Text(
            'VOCABULÁRIO',
            style: TextStyle(
              color: Color(0xFF00E5FF),
              fontSize: 11,
              letterSpacing: 3,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 12,
            width: double.infinity,
            child: CustomPaint(
              painter: _SegmentBarPainter(
                  fill: (mastered / goal).clamp(0.0, 1.0)),
            ),
          ),
          const SizedBox(height: 8),
          Text.rich(
            TextSpan(
              children: [
                TextSpan(
                  text: '$mastered',
                  style: const TextStyle(
                    color: Color(0xFF00E5FF),
                    fontWeight: FontWeight.bold,
                  ),
                ),
                TextSpan(text: ' / $goal palavras dominadas'),
              ],
            ),
            style: const TextStyle(color: Color(0xFF9AA3BC), fontSize: 11.5),
          ),
          // Estatísticas no MESMO card (pedido do usuário: economiza um
          // card inteiro de espaço).
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 9),
            child: Divider(color: Color(0xFF2A3350), height: 1),
          ),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Row(
              children: [
                _stat('MAIOR PONTUAÇÃO', '${ProgressService.bestScore}'),
                _statDivider(),
                _stat('DOMINADAS', '${ProgressService.masteredCount}'),
                _statDivider(),
                _stat('PRECISÃO',
                    '${(ProgressService.lifetimeAccuracy * 100).round()}%'),
                _statDivider(),
                _stat(
                    'SEQUÊNCIA',
                    ProgressService.streakDays > 0
                        ? '${ProgressService.streakDays} dias'
                        : '—'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// BENEFÍCIOS: só ícone + título (descrições saíram — no celular
  /// esticavam demais, feedback do usuário). Cabem os 4 numa linha.
  Widget _skillsGrid() {
    const skills = [
      (Icons.keyboard, 'DIGITAÇÃO'),
      (Icons.headphones, 'ESCUTA'),
      (Icons.translate, 'TRADUÇÃO'),
      (Icons.psychology, 'MEMÓRIA'),
    ];
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text(
          '★  BENEFÍCIOS  ★',
          style: TextStyle(
            color: Colors.white,
            fontSize: 11,
            letterSpacing: 3,
            shadows: [Shadow(color: Color(0xCC000000), blurRadius: 6)],
          ),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 7,
          runSpacing: 7,
          alignment: WrapAlignment.center,
          children: [
            for (final (icon, title) in skills)
              Container(
                width: 80,
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: const Color(0xD910162A),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFF14505C)),
                ),
                child: Column(
                  children: [
                    Icon(icon, color: const Color(0xFF00E5FF), size: 24),
                    const SizedBox(height: 6),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        title,
                        maxLines: 1,
                        style: const TextStyle(
                          color: Color(0xFF00E5FF),
                          fontSize: 9.5,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ],
    );
  }

  Widget _statDivider() => Container(
        width: 1,
        height: 34,
        color: const Color(0xFF2A3350),
      );

  /// Coluna de rebites da moldura do botão dourado.
  Widget _rivets() => Column(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          for (var i = 0; i < 3; i++)
            Container(
              width: 4,
              height: 4,
              decoration: const BoxDecoration(
                color: Color(0xFF8A6A2F),
                shape: BoxShape.circle,
              ),
            ),
        ],
      );

  Widget _difficultyCard(Difficulty difficulty) {
    final selected = difficulty == _difficulty;
    final accent = difficulty.accent;
    return GestureDetector(
      // Seleciona a patente E abre o popup de ajustes dela (nível das
      // palavras, tópicos e volumes) — nova lógica pedida pelo usuário.
      onTap: () {
        _selectDifficulty(difficulty);
        _openRankSheet(difficulty);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        margin: const EdgeInsets.symmetric(horizontal: 5),
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 6),
        decoration: BoxDecoration(
          color: selected
              ? Color.lerp(const Color(0xFF10162A), accent, 0.16)
              : const Color(0xFF10162A),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? accent : const Color(0xFF2A3350),
            width: selected ? 2 : 1,
          ),
          boxShadow: selected
              ? [BoxShadow(color: accent.withValues(alpha: 0.30), blurRadius: 16)]
              : const [],
        ),
        child: Column(
          children: [
            // Insígnia da patente, desenhada por código.
            SizedBox(
              width: 38,
              height: 26,
              child: CustomPaint(
                painter: _InsigniaPainter(difficulty, selected: selected),
              ),
            ),
            const SizedBox(height: 6),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                difficulty.label,
                maxLines: 1,
                style: TextStyle(
                  color: selected ? accent : Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
            ),
            const SizedBox(height: 7),
            for (final perk in difficulty.perks)
              Padding(
                padding: const EdgeInsets.only(bottom: 3),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    perk,
                    maxLines: 1,
                    style: const TextStyle(
                      color: Color(0xFF9AA3BC),
                      fontSize: 9.5,
                    ),
                  ),
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

/// Barra de progresso segmentada em blocos (estilo mockup): preenchidos em
/// ciano com brilho, vazios em cinza escuro.
class _SegmentBarPainter extends CustomPainter {
  final double fill;

  const _SegmentBarPainter({required this.fill});

  @override
  void paint(Canvas canvas, Size size) {
    const gap = 3.0;
    const count = 20;
    final blockW = (size.width - gap * (count - 1)) / count;
    final filled = (fill * count).round();
    for (var i = 0; i < count; i++) {
      final rect = RRect.fromRectAndRadius(
        Rect.fromLTWH(i * (blockW + gap), 0, blockW, size.height),
        const Radius.circular(2.5),
      );
      if (i < filled) {
        canvas.drawRRect(
          rect,
          Paint()
            ..color = const Color(0x5500E5FF)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3),
        );
        canvas.drawRRect(rect, Paint()..color = const Color(0xFF00CFE8));
      } else {
        canvas.drawRRect(rect, Paint()..color = const Color(0xFF23293E));
      }
    }
  }

  @override
  bool shouldRepaint(covariant _SegmentBarPainter old) => old.fill != fill;
}

/// Insígnias das patentes, desenhadas por código no estilo do jogo:
/// RECRUTA = capacete · SOLDADO = divisas (chevrons) · COMANDANTE =
/// estrela com asas.
class _InsigniaPainter extends CustomPainter {
  final Difficulty difficulty;
  final bool selected;

  const _InsigniaPainter(this.difficulty, {required this.selected});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final color = selected
        ? difficulty.accent
        : Color.lerp(difficulty.accent, const Color(0xFF8A93B2), 0.35)!;
    final paint = Paint()..color = color;
    final stroke = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.4
      ..strokeCap = StrokeCap.round;

    switch (difficulty) {
      case Difficulty.beginner:
        // Capacete: domo + aba.
        final dome = Path()
          ..moveTo(w * 0.18, h * 0.62)
          ..quadraticBezierTo(w * 0.5, h * -0.25, w * 0.82, h * 0.62)
          ..close();
        canvas.drawPath(dome, paint);
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(w * 0.08, h * 0.60, w * 0.84, h * 0.16),
            const Radius.circular(2),
          ),
          paint,
        );
      case Difficulty.intermediate:
        // Três divisas (chevrons) empilhadas.
        for (var i = 0; i < 3; i++) {
          final top = h * (0.12 + i * 0.30);
          final chevron = Path()
            ..moveTo(w * 0.22, top + h * 0.16)
            ..lineTo(w * 0.5, top)
            ..lineTo(w * 0.78, top + h * 0.16);
          canvas.drawPath(chevron, stroke);
        }
      case Difficulty.fluent:
        // Estrela central com asas.
        canvas.drawLine(
            Offset(w * 0.02, h * 0.5), Offset(w * 0.30, h * 0.5), stroke);
        canvas.drawLine(
            Offset(w * 0.70, h * 0.5), Offset(w * 0.98, h * 0.5), stroke);
        canvas.drawLine(
            Offset(w * 0.06, h * 0.72), Offset(w * 0.26, h * 0.66), stroke);
        canvas.drawLine(
            Offset(w * 0.74, h * 0.66), Offset(w * 0.94, h * 0.72), stroke);
        final star = Path();
        final c = Offset(w * 0.5, h * 0.5);
        final r = h * 0.48;
        for (var i = 0; i < 5; i++) {
          final aOut = -pi / 2 + i * 2 * pi / 5;
          final aIn = aOut + pi / 5;
          final pOut = Offset(c.dx + cos(aOut) * r, c.dy + sin(aOut) * r);
          final pIn = Offset(
              c.dx + cos(aIn) * r * 0.45, c.dy + sin(aIn) * r * 0.45);
          i == 0 ? star.moveTo(pOut.dx, pOut.dy) : star.lineTo(pOut.dx, pOut.dy);
          star.lineTo(pIn.dx, pIn.dy);
        }
        star.close();
        canvas.drawPath(star, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _InsigniaPainter old) =>
      old.difficulty != difficulty || old.selected != selected;
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
