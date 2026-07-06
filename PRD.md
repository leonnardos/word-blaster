# PRD — Word Blaster (nome provisório)

> Jogo arcade de digitação que ensina idiomas sem o usuário perceber.
> Inspiração: **ZType**, adaptado para celular e focado em aprendizado.

## 1. Visão

O jogador não sente que está estudando — ele sente que está jogando. O aprendizado
acontece como consequência da mecânica. Quanto mais joga, mais aprende; quanto mais
aprende, mais quer jogar (ciclo de retenção).

Não é um app de inglês. Não é um jogo de digitação. É um **jogo arcade que ensina
idiomas**.

## 2. Objetivo

Ensinar inglês (futuramente outros idiomas) por repetição ativa: escrita, leitura,
vocabulário, pronúncia e memorização — tudo jogando.

## 3. Público

- Idade: 12 a 45 anos
- Perfis: quem quer aprender inglês, estudantes, concurseiros, profissionais,
  jogadores casuais

## 4. Plataforma e stack

| Item | Escolha |
|---|---|
| Plataformas | Android, iOS (Web depois) |
| Engine | Flutter + Flame |
| Backend | **Fase 2** — MVP é offline-first (armazenamento local) |
| Sessão ideal | Partidas de 1 a 3 minutos (fila, ônibus, intervalo) |

## 5. Conceito central

- O jogador controla uma **nave** na base da tela.
- **Inimigos descem lentamente**; cada inimigo é uma **palavra**.
- Para destruir, o jogador **digita a palavra corretamente**.
- Quanto mais rápido digita, maior a pontuação.

Cada palavra possui: texto, imagem (opcional), áudio, categoria, nível, frequência
e dificuldade.

## 6. Modos de jogo

| # | Modo | Mostra | Jogador digita | MVP |
|---|---|---|---|---|
| 1 | Digitação | `APPLE` | `apple` | ✅ |
| 2 | Tradução | `Maçã` | `apple` | fase 2 |
| 3 | Áudio | 🔊 "apple" (sem texto) | `apple` | fase 2 |
| 4 | Imagem | 🍎 | `apple` | fase 2 |
| 5 | Frases | `Bom dia` | `good morning` | fase 2 |
| 6 | Escuta avançada | 🔊 "I would like a coffee." | frase exata | fase 3 |

## 7. Progressão (níveis por categoria)

1. Animais → 2. Frutas → 3. Comidas → 4. Casa → 5. Cidade → 6. Viagem →
7. Verbos → 8. Adjetivos → 9. Negócios → 10. Conversação

**Curva de dificuldade:** palavras pequenas → médias → longas → frases → conversas.

## 8. Inteligência do aprendizado (repetição espaçada)

Inspirado no Anki/FSRS:

- Palavra **errada** → reaparece com mais frequência.
- Palavra **acertada várias vezes** → aparece raramente.
- (Futuro) IA identifica dificuldades por categoria e reforça (erra verbos → mais verbos).

## 9. Pontuação e engajamento

- **XP por palavra:** fácil +5 … difícil +20 (por tamanho/dificuldade).
- **Combo:** 10 acertos → x2, 20 → x3, 50 → x5. Errar zera o combo.
- **Boss por fase:** só morre digitando uma frase inteira (ex.: `Where are you from?`).
- **Missões diárias:** aprenda 10 palavras, complete 3 fases, acerte 100 palavras,
  faça 5 combos, complete sem errar.
- **Sequência (streak):** 1, 3, 7, 30, 100, 365 dias.
- **Conquistas:** 100/1.000 palavras, 30 dias de sequência, 100% de precisão etc.
- **Calendário de progresso** estilo GitHub.

## 10. Competição (fase 2 — requer backend)

- Ranking: global, país, estado, cidade, amigos.
- Ligas: Bronze → Prata → Ouro → Platina → Diamante → Mestre → Lendário.
- Social: desafiar amigos, compartilhar pontuação, ranking semanal.

## 11. Estatísticas

Palavras aprendidas, precisão, velocidade (WPM), tempo estudado, dias consecutivos,
categorias completas.

## 12. Personalização (desbloqueável)

Temas, naves, explosões, fundos, sons, trails.

## 13. Monetização

- **Vídeo recompensado:** moedas, continuar partida, dobrar XP.
- **Premium:** remover anúncios, categorias premium (TOEFL, IELTS, Business,
  Travel, Medical English).

## 14. Eventos e futuro

- Eventos sazonais: Halloween, Natal, Black Friday, Páscoa.
- Novos idiomas: espanhol, francês, italiano, alemão, japonês, coreano, português.
- IA futura: gerar frases novas, desafios personalizados, identificar nível do
  aluno, adaptar dificuldade.
- Metas personalizadas: "inglês para viajar / negócios / jogos / programação".
- Modo offline com lições baixadas.
- Longo prazo: plataforma de aprendizado gamificada (matemática, geografia,
  programação, concursos) com a mesma mecânica.

## 15. Design

Minimalista, poucas cores, muito efeito de explosão, muito feedback visual,
animações rápidas, nada poluído.

## 16. Roadmap resumido

| Fase | Entrega |
|---|---|
| **MVP (atual)** | Modo Digitação jogável, 10 categorias, combo, XP, repetição de erros, recorde local, offline |
| Fase 2 | Modos Tradução/Áudio/Imagem, boss, missões diárias, streak, backend (auth + ranking), TTS |
| Fase 3 | Ligas, social, eventos, monetização, personalização, novos idiomas, IA adaptativa |
