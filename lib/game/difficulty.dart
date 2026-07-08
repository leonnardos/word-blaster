import 'dart:ui';

/// Nível escolhido pelo jogador na tela inicial — apresentado como
/// PATENTE militar (tema do jogo; redesign do menu a pedido do usuário).
///
/// A dificuldade define em que nível interno o jogo começa (que controla o
/// tamanho das palavras sorteadas e a entrada de frases) e um multiplicador
/// de velocidade dos inimigos.
///
/// ATENÇÃO: os NOMES dos valores (beginner/intermediate/fluent) são
/// persistidos nas preferências E são CHECK constraint na tabela `scores`
/// do Supabase — nunca renomear; só os rótulos visuais.
enum Difficulty {
  beginner(
    label: 'RECRUTA',
    perks: ['Palavras simples', 'Muito tempo', 'Ideal para começar'],
    accent: Color(0xFF4CAF6E),
    startLevel: 1,
    speedFactor: 1.0,
  ),
  intermediate(
    label: 'SOLDADO',
    perks: ['Vocabulário intermediário', 'Velocidade média', 'Mais desafio'],
    accent: Color(0xFFD9B23A),
    startLevel: 5,
    speedFactor: 1.15,
  ),
  fluent(
    label: 'COMANDANTE',
    perks: ['Frases completas', 'Alta velocidade', 'Listening avançado'],
    accent: Color(0xFFE0554A),
    startLevel: 9,
    speedFactor: 1.3,
  );

  const Difficulty({
    required this.label,
    required this.perks,
    required this.accent,
    required this.startLevel,
    required this.speedFactor,
  });

  final String label;

  /// As 3 linhas do card da patente (o que esperar deste modo).
  final List<String> perks;

  /// Cor da patente (borda/título/insígnia do card).
  final Color accent;

  final int startLevel;
  final double speedFactor;
}
