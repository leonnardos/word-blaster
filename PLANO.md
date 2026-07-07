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
| **Ondas (waves)** com pausa breve e contador | Ritmo de respiração: tensão → alívio → tensão maior | ✅ implementado (8-10 palavras/onda, 2s de respiro, banner "ONDA N") |
| **Inimigos especiais**: atiradores (o projétil também é palavra), divisores (quebram em palavras menores), boss de palavra longa | Variedade sem mudar a mecânica base | 🔜 Fase 3 |
| **EMP (bomba)** carregada por digitação perfeita | Recompensa precisão com poder, não só pontos | 🔜 Fase 3 |
| **Estética**: vetores neon, partículas, screen shake, som por tecla | "Game feel" — o jogo parece responder ao seu dedo | ✅ (explosões de fogo, shake no estouro, sons de erro/vida, muzzle flash, música) |
| **Stats de fim de partida**: WPM, precisão | Auto-superação vira motivo de replay | ✅ implementado |

### 1.2 Duolingo — o que o torna viciante e eficaz

| Mecânica | Princípio psicológico | Status |
|---|---|---|
| **Streak (ofensiva) diária** + streak freeze | Aversão à perda — o motor nº 1 de retenção deles | 🔜 Fase 2 |
| **Sessões de 1–3 min** | Cabe em qualquer brecha do dia; sem custo de começar | ✅ partidas curtas por design |
| **Repetição espaçada** (palavras fracas voltam) | Curva do esquecimento de Ebbinghaus | ✅ versão simples; FSFR completo na Fase 2 |
| **Nova palavra chega com tradução, depois é testada sem ela** | Andaime (scaffolding): apoio que desaparece com a maestria | ✅ completo: nova = tradução visível → aprendendo = esmaecida → dominada = RECALL INVERTIDO (inglês oculto, tradução como dica) + modo estudo 👁 + cartão de dicionário por toque |
| **Metas diárias + notificação** | Gatilho externo de hábito | 🔜 Fase 2 |
| **Ligas semanais** | Competição com prazos curtos renova a motivação toda segunda | 🔜 Fase 4 |
| **Celebração exagerada de acertos** | Recompensa variável, dopamina | ✅ explosões de fogo + pronúncia + barra de estamina com marcos ×2..×5 |
| **Teste de nivelamento** | Adulto iniciante não quer começar do "the cat" se já sabe | ❌ descartado (decisão do dono, 2026-07-07): o seletor manual resolve — "deixa a pessoa escolher como quer brincar" |

### 1.3 Síntese para o público BR iniciante

1. **Tradução PT-BR visível na palavra** (✅ feito): iniciante não pode depender
   de inferência; ele precisa saber O QUE está digitando, senão é só um jogo de
   digitação.
2. **Áudio da palavra ao destruir** (✅ feito: TTS com fila e voz feminina):
   associa som → grafia → significado em um único momento de recompensa.
3. **Maestria por palavra**: `nova → aprendendo → dominada`. Palavra dominada
   perde a tradução (recall ativo) e vale mais XP. É onde jogo e pedagogia se
   fundem.
4. **Interface 100% em PT-BR** (✅ feito).

---

## 2. Estado atual (atualizado em 2026-07-08, v0.10.2 — jogo completo, no ar)

**Publicado**: web em wordblaster.vercel.app (deploy automático por push no
GitHub leonnardos/word-blaster; selo de versão no menu — incrementar a cada
deploy) + APK Android compilando + **PWA instalável** (Android "Instalar app"
/ iPhone "Adicionar à Tela de Início"; ícones do tanque; funciona offline
após a 1ª visita via service worker).

- **Conteúdo**: 1003 palavras em 23 tópicos com tradução PT-BR + **3.003
  frases de exemplo em 3 tempos** (presente/passado/futuro, EN+PT, geradas
  por 23 agentes com revisão); sorteio JUSTO: peso pedagógico limitado
  (0.5–3.0, erros pesam mais sem monopolizar) + cobertura por exposição
  (cada aparição na partida derruba o peso — o pool inteiro circula);
  maestria por palavra (nova → aprendendo esmaecida → dominada = recall
  invertido com ★) + modo estudo 👁; ondas de 8-10 palavras com respiro
- **Combate**: veículo blindado com rodas animadas e canhão duplo giratório,
  mísseis com rastro de fogo, muzzle flash, explosões de fogo, tremida no
  estouro, clareada no impacto, palavras convergem para o tanque
- **Aprendizado**: TTS com fila (qualquer voz en; corrigido locale en_US
  com underscore do Chrome Android — tocar no selo de versão mostra a voz
  escolhida), **cartão de dicionário por TOQUE**: palavra em azul, tradução,
  3 frases nos 3 tempos com ▶ de pronúncia cada e tradução escondida atrás
  do olhinho (pensa antes de espiar); fecha tocando fora ou digitando;
  botão de ocultar tradução; letra errada em vermelho animada no centro
- **Progressão**: 3 dificuldades (Iniciante/Intermediário/Fluente), estamina
  com marcos ×2..×5 (5/15/25/35 palavras), +1 vida por nível, velocidade
  automática ou travada (1-8, indicador azul=auto/vermelho=travada),
  "revise estas palavras" com 🔊 no fim de jogo
- **Plataformas**: teclado embutido no celular (minúsculas como as palavras,
  células cheias + feedback), zoom out mobile (+33% de campo), moldura
  média/mobile no desktop com laterais reservadas para anúncios, pause
  (botão/ESC), botões de música, mudo e volumes (música/pronúncia);
  fallback de CPU + aviso para navegador sem WebGL (ex.: Comet)
- **Estética**: Orbitron nos títulos + Exo 2 legível nas palavras/teclado;
  HUD discreto no canto (placar/combo translúcidos, centro livre); campo de
  batalha procedural rolando; menu com arte de guerra; trilha sintetizada
  com corpo nos médios (audível em alto-falante de celular) que toca SÓ
  durante o jogo ativo (menu/pause/cartão/game over em silêncio)
- **Monetização preparada**: AdMob com IDs de teste (banner só no menu) +
  slots AdSense no index.html (ativar após aprovação)
- **Qualidade**: 22 testes automatizados (inclui validação dos 3.003
  exemplos); analyze limpo

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
| 3.6 | ~~Teste de nivelamento~~ | ❌ descartado — seletor manual de dificuldade é a escolha do produto |
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

#### 4.z Escada CEFR — decisões do dono (2026-07-08, ainda NÃO construir)

Referência de tamanhos citada pelo dono (não é contrato): A1 800 · A2 1.200 ·
B1 1.500 · B2 2.000 · C1 2.500. Decisões já tomadas:

1. **Fase 1 = A1+A2**: etiquetar as 1.003 palavras atuais com nível CEFR e
   completar até ~2.000 (A1+A2), COM as 3 frases de exemplo de cada uma.
   B1-C1 ficam para depois de validar o sistema.
2. **UI = seletor acumulativo "até X"**: botões A1…C1 no menu; escolher B1
   treina A1+A2+B1 (vocabulário acumula). Convive com os tópicos e com a
   dificuldade atual (Iniciante/Intermediário/Fluente segue controlando
   ritmo/tamanho; CEFR controla QUAIS palavras existem no pool).
3. **Modelo de dados**: `Word(en, pt, {cefr})` — etiqueta opcional; as
   1.003 atuais são reaproveitadas (maestria dos jogadores preservada).

Alertas anotados: cada palavra nova exige tradução + 3 frases (presente/
passado/futuro) → A1+A2 ≈ +1.000 palavras/+3.000 frases; exemplos hoje
pesam ~1 MB no download web — a partir de B1 considerar carregar exemplos
sob demanda (ou pacotes por nível, ver §4.y). Fontes de lista por nível:
CEFR-J (CC BY-SA) como referência de classificação.

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

## 3.3 Plano de implementação — Ranking Arcade Top 10 (2026-07-07)

Ideia do produto (dono): top 10 estilo fliperama, sem cadastro — só quem entra
no top 10 digita um apelido. Elegibilidade: velocidade em AUTO (travar = casual).
Plano refinado por crítica de 2 agentes (fairness de jogo + técnica/Supabase).

**Descoberta crítica da revisão**: o jogo tem TETO de dificuldade (velocidade
satura no nível ~16 em 70px/s, spawn tem piso de 1.15s, máx. 5 inimigos, e
vidas são +1/nível = estoque infinito para bons jogadores). Sem fechar isso,
qualquer ranking vira concurso de resistência (~1M pontos/hora infinitos), não
de habilidade — o primeiro no-lifer crava um recorde imbatível. R1 é
pré-requisito do ranking.

### Fase R0 — Ajustes de velocidade (sem backend, ~1h)
| # | Tarefa |
|---|---|
| R0.1 | ✅ feito (variante melhor): botão mostra SEMPRE o número da velocidade — AZUL = automática, VERMELHO = travada |
| R0.2 | ✅ feito: em auto o número acompanha o nível (autoSpeedFor, teto 8) |
| R0.3 | 🔜 Trocar velocidade vale NA HORA para as palavras já na tela (hoje `WordEnemy.speed` é final: só as próximas mudam; retunar os inimigos ativos preservando a variância aleatória de cada um) |

### Fase R1 — Fechar o jogo para competição (~1 dia)
| # | Tarefa |
|---|---|
| R1.1 | **Cronômetro de partida** (tempo ATIVO: exclui pausa, inspeção e background) — dependência de todo o resto; hoje não existe |
| R1.2 | **Fechar o teto**: velocidade continua subindo após o nível 16 (cap progressivo), spawn continua acelerando, `_maxEnemies` cresce com o nível → toda run termina por skill em ~15-25 min |
| R1.3 | **Vidas sem estoque infinito**: +1 vida a cada 3 níveis OU cap de 5 corações |
| R1.4 | Em run valendo ranking: inspeção de palavra com orçamento (ex.: 3 usos) e pausa limitada — hoje pausar/inspecionar é "bullet time" grátis que ainda por cima infla a duração (facilitando passar na validação!) |

### Fase R2 — Backend Supabase free (~1-2 dias)
| # | Tarefa |
|---|---|
| R2.1 | Tabela `scores` (nickname, score, difficulty, level, words, active_s, client_version, platform, created_at) + CHECK constraints + índice (difficulty, score DESC). **RLS ON com ZERO policy de escrita para anon** (escrita só por Edge Function com service_role — sem isso, INSERT direto via REST ignora toda a validação). Leitura por view `top10` (só nickname/score/level) |
| R2.2 | Edge Functions: `start_session` (token + timestamp do servidor no início da run) e `submit_score` (1 submit por token; valida com as FÓRMULAS EXATAS do jogo: score ≤ words×1500, words ≤ active_s/1.15, words ≥ (level−start)×12, duração real = now−session.start) |
| R2.3 | **Sem invariante de "30 linhas"**: insere toda submissão válida, top 10 = SELECT…LIMIT 10 (zero corrida entre jogadores simultâneos); pg_cron limpa runs fora do top com +30 dias |
| R2.4 | Keepalive (cron ping a cada 3 dias — free tier pausa em 1 semana) + cliente degrada graciosamente ("ranking indisponível", jogo nunca depende da rede) |
| R2.5 | Apelido: charset [A-Za-z0-9_] 3-12 forçado no servidor (mata leetspeak/homóglifos de graça), filtro de palavrões na forma normalizada, hint "não use seu nome real" (LGPD), sem unicidade (convenção de fliperama) |

### Fase R3 — UX do ranking (~1 dia)
| # | Tarefa |
|---|---|
| R3.1 | Game over elegível → submete e o **SERVIDOR responde a posição** (nada de decidir contra cache): top 10 → campo de apelido (pré-preenchido do local) → board com destaque; fora → **"você ficaria em 87º esta semana"** + recorde pessoal |
| R3.2 | Menu: botão TOP 10 com abas por dificuldade + aba **SEMANAL** (reseta segunda — a chance recorrente do jogador mediano; all-time é a vitrine) |
| R3.3 | Partida com velocidade travada/tópico filtrado: selo discreto "casual — não vale ranking" |
| R3.4 | Página curta de privacidade no menu; run offline não ranqueia (sem fila — incompatível com token de sessão) |

### Decisões em aberto (dono do produto)
1. **3 boards por dificuldade** (recomendado; a crítica alertou: Iniciante teria os MAIORES scores — mitigar destacando Fluente como board principal na UI) vs board único com multiplicador ×1/×1.25/×1.5.
2. Web (teclado físico) e celular (touch) no MESMO board? v1: sim, registrando `platform` desde o dia 1 para poder separar depois.
3. Anti-cheat é MITIGAÇÃO, não garantia (código aberto no navegador): projetar para limpeza (remoção manual, são só 30 linhas visíveis) e opcionalmente Cloudflare Turnstile no submit (atrito zero: o jogador já parou para digitar o apelido).

## 4. Riscos técnicos e mitigações

| Risco | Impacto | Mitigação |
|---|---|---|
| **Teclado mobile** (autocorreção, IME, latência, teclado cobrindo 40% da tela) | Alto — é o coração do jogo | ✅ RESOLVIDO: teclado QWERTY próprio embutido no jogo (o do sistema esmagava o layout); células inteiras clicáveis, minúsculas, feedback ciano; zoom out compensa a área perdida |
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
