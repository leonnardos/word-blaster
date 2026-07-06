# Plano de Implantação — Word Blaster
### Jogo arcade estilo ZType focado em ensinar inglês para brasileiros

> Complementa o [PRD.md](PRD.md). Aqui está a análise das referências e o
> roteiro de execução fase a fase, priorizado por impacto na diversão e na
> retenção.

---

## 1. Análise das referências

### 1.1 ZType (zty.pe) — o que o torna gostoso de jogar

| Mecânica | Por que funciona | Status no nosso jogo |
|---|---|---|
| **Mira travada**: a 1ª letra digitada trava no inimigo mais próximo; você não troca de alvo até terminar a palavra | Elimina ambiguidade e cria foco total; zero decisão além de digitar | ✅ implementado |
| **Um tiro por letra** com projétil teleguiado | Cada tecla dá feedback físico imediato — a digitação "vira" a arma | ✅ implementado |
| **Nunca há duas palavras com a mesma inicial na tela** | Garante que a mira travada nunca frustra | ✅ implementado |
| **Ondas (waves)** com pausa breve e contador | Ritmo de respiração: tensão → alívio → tensão maior | 🔜 Fase 1 |
| **Inimigos especiais**: atiradores (o projétil também é palavra), divisores (quebram em palavras menores), boss de palavra longa | Variedade sem mudar a mecânica base | 🔜 Fase 3 |
| **EMP (bomba)** carregada por digitação perfeita | Recompensa precisão com poder, não só pontos | 🔜 Fase 3 |
| **Estética**: vetores neon, partículas, screen shake, som por tecla | "Game feel" — o jogo parece responder ao seu dedo | ⚠️ parcial (partículas ✅; som e shake 🔜 Fase 1) |
| **Stats de fim de partida**: WPM, precisão | Auto-superação vira motivo de replay | ✅ implementado |

### 1.2 Duolingo — o que o torna viciante e eficaz

| Mecânica | Princípio psicológico | Status |
|---|---|---|
| **Streak (ofensiva) diária** + streak freeze | Aversão à perda — o motor nº 1 de retenção deles | 🔜 Fase 2 |
| **Sessões de 1–3 min** | Cabe em qualquer brecha do dia; sem custo de começar | ✅ partidas curtas por design |
| **Repetição espaçada** (palavras fracas voltam) | Curva do esquecimento de Ebbinghaus | ✅ versão simples; FSFR completo na Fase 2 |
| **Nova palavra chega com tradução, depois é testada sem ela** | Andaime (scaffolding): apoio que desaparece com a maestria | ⚠️ tradução sempre visível hoje; fade por maestria na Fase 1 |
| **Metas diárias + notificação** | Gatilho externo de hábito | 🔜 Fase 2 |
| **Ligas semanais** | Competição com prazos curtos renova a motivação toda segunda | 🔜 Fase 4 |
| **Celebração exagerada de acertos** | Recompensa variável, dopamina | ⚠️ explosões ✅; sons/celebrações 🔜 Fase 1 |
| **Teste de nivelamento** | Adulto iniciante não quer começar do "the cat" se já sabe | 🔜 Fase 3 |

### 1.3 Síntese para o público BR iniciante

1. **Tradução PT-BR visível na palavra** (✅ feito): iniciante não pode depender
   de inferência; ele precisa saber O QUE está digitando, senão é só um jogo de
   digitação.
2. **Áudio da palavra ao destruir**: associa som → grafia → significado em um
   único momento de recompensa. É o maior ganho pedagógico pendente.
3. **Maestria por palavra**: `nova → aprendendo → dominada`. Palavra dominada
   perde a tradução (recall ativo) e vale mais XP. É onde jogo e pedagogia se
   fundem.
4. **Interface 100% em PT-BR** (✅ feito).

---

## 2. Estado atual (MVP jogável — concluído)

- Flutter + Flame, offline-first, Android/iOS/Web/Windows
- Modo Digitação completo: nave, palavras descendo com tradução PT-BR menor,
  mira travada, tiro por letra, explosões, 3 vidas
- 10 níveis/categorias (Animais → Conversação), ~190 palavras com tradução
- XP por dificuldade, combo ×2/×3/×5, pontuação
- Repetição ponderada por erro/acerto (persistida)
- Anti-sobreposição de palavras no spawn
- Recorde, XP total e estatísticas locais; tela de fim de jogo com
  "revise estas palavras"

---

## 3. Fases de implantação

### Fase 1 — Game feel + aprendizado de verdade (1–2 semanas)
*Objetivo: transformar "funciona" em "gostoso de jogar e ensina".*

| # | Tarefa | Detalhe |
|---|---|---|
| 1.1 | **Áudio TTS** | `flutter_tts` (offline, grátis): fala a palavra ao destruí-la; botão 🔊 na tela de fim para reouvir as erradas |
| 1.2 | **Sons de arcade** | `flame_audio`: laser por tecla, explosão, erro, level-up, game over. Sem som o jogo parece morto |
| 1.3 | **Screen shake + hit-stop** | Tremor de 100ms ao destruir; congela 30ms no último tiro — o "soco" do ZType |
| 1.4 | **Sistema de maestria** | Por palavra: 0–2 acertos = *nova* (tradução visível), 3–5 = *aprendendo* (tradução esmaece), 6+ = *dominada* (sem tradução, +50% XP). Persistir no ProgressService |
| 1.5 | **Ondas** | 8–10 palavras por onda, pausa de 2s com "ONDA 3", velocidade sobe por onda dentro do nível |
| 1.6 | **Tutorial de 30s** | Primeira partida guiada: 1 palavra lenta, seta apontando o teclado, texto "digite C-A-T" |
| 1.7 | **Teste em Android real** | Validar teclado (IME, autocorreção, latência) — maior risco técnico do projeto |

### Fase 2 — Motor de hábito (1–2 semanas)
*Objetivo: o jogador volta amanhã.*

| # | Tarefa | Detalhe |
|---|---|---|
| 2.1 | **Streak diário** | Contador na home, congelamento ganho a cada 7 dias, aviso ao abrir |
| 2.2 | **Missões diárias** | 3 por dia ("destrua 30 palavras", "faça um combo ×3", "domine 2 palavras") com recompensa em moedas |
| 2.3 | **Calendário estilo GitHub** | Tela de perfil com mapa de calor dos dias jogados |
| 2.4 | **Conquistas** | 100/500/1.000 palavras, streaks, precisão 100%, categoria completa |
| 2.5 | **Notificação local** | `flutter_local_notifications`: lembrete no horário em que o jogador costuma jogar |
| 2.6 | **Repetição espaçada real** | Intervalos crescentes por palavra (1d, 3d, 7d, 21d) — fila de revisão do dia entra como 30% do spawn |

### Fase 3 — Profundidade de jogo e conteúdo (2–3 semanas)

| # | Tarefa | Detalhe |
|---|---|---|
| 3.1 | **Boss por nível** | Frase inteira ("Where are you from?"), barra de vida por palavra, recompensa grande |
| 3.2 | **Modo Tradução reversa** | Mostra "vaca" → digita "cow" (recall ativo, muito mais difícil) |
| 3.3 | **Modo Áudio** | Só fala a palavra (TTS da Fase 1), sem texto — listening puro |
| 3.4 | **Inimigos especiais** | Divisor (palavra composta quebra em duas), veloz (palavra curta rápida), tanque (palavra longa lenta) |
| 3.5 | **EMP / poder** | Carregado por 20 letras perfeitas; limpa a tela — botão grande pro polegar |
| 3.6 | **Teste de nivelamento** | 10 palavras na primeira abertura decidem em que nível começar |
| 3.7 | **+300 palavras** | Expandir banco para ~500 com frequência CEFR A1–A2 |

### Fase 4 — Competição e social (2 semanas, requer backend)

| # | Tarefa | Detalhe |
|---|---|---|
| 4.1 | **Supabase** | Auth anônima + tabela de scores; sync do progresso local |
| 4.2 | **Ranking** | Global, semanal e por estado (geolocalização aproximada opcional) |
| 4.3 | **Ligas** | Bronze → Lendário, 30 jogadores por grupo, reset semanal |
| 4.4 | **Compartilhar** | Card de resultado para stories/WhatsApp ("Aprendi 47 palavras hoje 🚀") |

#### 4.x Desenho do ranking sem cadastro (pesquisa 2026-07-05)

- **Guest-first**: `signInAnonymously()` do Supabase (GA; ativar no dashboard,
  vem desligado) no primeiro launch + **apelido arcade gerado** (adjetivo+animal,
  estilo Kahoot — sem nome real, sem filtro de palavrão para manter, sem LGPD
  de dado pessoal de menor). Jogador entra no ranking sem ver tela de login.
- **Upgrade opcional**: botão "salvar progresso" com Google/Apple via
  `linkIdentity()` — MESMO user id, nada se perde (manual linking é beta,
  habilitar). Oferecer só depois do jogador engajado (3+ dias).
- **Ligas semanais de 30 pessoas** (padrão Duolingo, +25-40% engajamento):
  coorte pequena torna o top-5 alcançável; promoção/rebaixamento Bronze→Lendário.
- **Anti-cheat**: nunca confiar no score do cliente — Edge Function valida
  plausibilidade (score máximo por duração de partida, WPM humanamente possível,
  timestamps); guardar 1 linha por usuário por temporada (melhor score), não
  histórico bruto.
- **Capacidade (plano Free)**: 500 MB Postgres / 50k MAUs / 500k edge calls —
  vocabulário de dezenas de milhares de palavras ≈ 10-25 MB (trivial);
  leaderboard 1-linha-por-usuário ≈ 5-10 MB. Aguenta até ~50k usuários ativos;
  depois Pro US$ 25/mês (100k MAUs, 8 GB). Atenção: Free pausa após 1 semana
  sem atividade.

#### 4.y Escala do vocabulário para milhares de palavras

- **Fontes abertas**: NGSL 2.809 lemas (CC BY-SA), CEFR-J ~7.800 palavras com
  nível A1-B2 (CC BY-SA), traduções EN→PT do Wiktionary/kaikki.org (CC BY-SA),
  197 mil frases EN-PT do Tatoeba (CC BY). **NÃO usar**: Oxford 3000/5000
  (copyright OUP) e MUSE (CC BY-NC, proíbe uso comercial).
- **Pipeline LLM em lote**: traduzir + classificar tema/nível + frase de exemplo
  de ~10.000 palavras via Batch API ≈ US$ 3-15 (custo trivial); validação
  cruzada automática contra Wiktionary + revisão humana por amostragem.
- **Arquitetura**: palavras saem do Dart hardcoded para tabela `words` no
  Supabase; app baixa pacotes por tema/nível e cacheia local (offline-first
  mantido); tópicos viram "pacotes" escolhíveis — e no futuro, tópico
  personalizado gerado sob demanda por LLM.

### Fase 5 — Monetização e expansão (contínuo)

| # | Tarefa | Detalhe |
|---|---|---|
| 5.1 | AdMob recompensado | Continuar partida (1 vida), dobrar XP da partida |
| 5.2 | Premium (IAP) | Sem anúncios + pacotes (Business, Travel, TOEFL) |
| 5.3 | Personalização | Naves, trails, temas compráveis com moedas ganhas jogando |
| 5.4 | Eventos sazonais | Categorias temáticas (Halloween: ghost, pumpkin…) |
| 5.5 | Novos idiomas | Espanhol primeiro (mesmo banco estrutural) |

---

## 3.1 Pesquisa Anki → backlog SRS (2026-07-05)

Pesquisa multi-agente sobre o Anki (SM-2/FSRS), abandono de usuários e mercado
BR. Conclusão: o Word Blaster já é um "SRS de sessão" (peso de spawn por
erro/acerto); falta virar um "SRS de calendário" (intervalos em dias), que é de
onde vem a maior parte da retenção de memória. Recomendações ranqueadas:

| # | Recomendação | Esforço |
|---|---|---|
| 1 | **SRS de calendário leve**: `lastReviewedAt`, `dueAt`, `intervalDays`, estado new/learning/review no WordStat; intervalos 1d/3d/7d/21d; fila "vence hoje" = ~30% do spawn | médio |
| 2 | **Máx. 1 erro por palavra por encontro** (hoje cada tecla errada conta um miss — typo polui o sistema adaptativo) | baixo |
| 3 | **Palavra dominada descansa**: peso zero enquanto `dueAt` no futuro (em vez do piso 0.2) | baixo |
| 4 | **Dosagem de novas por dia** (10-15) com destaque visual "NEW" | médio |
| 5 | **Hard/Good/Easy via gameplay**: tempo-até-destruir e hesitação modulam o próximo intervalo | médio |
| 6 | **Anistia de backlog**: reagendar vencidas ao voltar de ausência, nunca empilhar nem cobrar | baixo |
| 7 | **Persistir hit/miss na hora** (não só no fim da partida — celular interrompe sempre) | baixo |
| 8 | **Decaimento de erros antigos** + corrigir `hardestWords` para refletir o estado atual | baixo |

Princípios de atratividade (o que o Anki NÃO faz e nós preservamos): sessão
curta com fim garantido, feedback imediato (explosão+TTS), zero setup de
conteúdo, diversão como motor de retorno (nunca culpa/cobrança), monetização
transparente, produção escrita ativa como diferencial pedagógico.

## 4. Riscos técnicos e mitigações

| Risco | Impacto | Mitigação |
|---|---|---|
| **Teclado mobile** (autocorreção, IME, latência, teclado cobrindo 40% da tela) | Alto — é o coração do jogo | Testar em Android real na Fase 1 (tarefa 1.7); campo já usa `visiblePassword` sem sugestões; layout já se adapta ao resize |
| TTS com pronúncia ruim offline | Médio | `flutter_tts` usa a voz do sistema; fallback: áudios gravados dos 500 core words (~5 MB) |
| Performance com muitas partículas em celular fraco | Médio | Cap de partículas por explosão; perfil de qualidade "leve" automático |
| Notificação de build phase do Flame ↔ Flutter (`setState during build`) | Baixo | Já resolvido: notifiers nascem com valor inicial correto; futuras notificações só fora do build |

## 5. Métricas de sucesso (medir desde a Fase 2)

- **D1/D7 retention** (meta inicial: 35% / 15%)
- Sessões por dia e duração média (meta: 3 × 2min)
- Palavras dominadas por semana por usuário
- % de partidas terminadas vs abandonadas

## 6. Ordem de execução recomendada

```
Fase 1 (game feel + maestria)  ←  MAIOR RETORNO POR ESFORÇO
   └→ testar com 5-10 pessoas reais (amigos, família)
Fase 2 (hábito)  →  soft launch fechado (Play Store internal testing)
Fase 3 (conteúdo) →  lançamento aberto Android
Fase 4 (social)  →  quando houver ~1k usuários ativos
Fase 5 (monetização) →  quando D7 > 10%
```
