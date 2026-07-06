/// Nível escolhido pelo jogador na tela inicial.
///
/// A dificuldade define em que nível interno o jogo começa (que controla o
/// tamanho das palavras sorteadas e a entrada de frases) e um multiplicador
/// de velocidade dos inimigos.
enum Difficulty {
  beginner(
    label: 'INICIANTE',
    description: 'Palavras curtas\ne mais tempo',
    startLevel: 1,
    speedFactor: 1.0,
  ),
  intermediate(
    label: 'INTERMEDIÁRIO',
    description: 'Palavras médias\ne longas',
    startLevel: 5,
    speedFactor: 1.15,
  ),
  fluent(
    label: 'FLUENTE',
    description: 'Frases inteiras\ne alta velocidade',
    startLevel: 9,
    speedFactor: 1.3,
  );

  const Difficulty({
    required this.label,
    required this.description,
    required this.startLevel,
    required this.speedFactor,
  });

  final String label;
  final String description;
  final int startLevel;
  final double speedFactor;
}
