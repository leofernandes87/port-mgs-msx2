# Metal Gear MSX2 → Godot — Plano de implementação

## Objetivo

Transformar o estado atual do projeto em um port jogável e fiel da edição
inglesa RC750 do Metal Gear MSX2, evoluindo de forma incremental até permitir
um playthrough completo do início ao ending.

Este documento define:

- ordem de implementação;
- dependências entre tarefas;
- milestones de playthrough;
- escopo de cada issue.

Este documento NÃO é fonte de verdade sobre o comportamento original.

A fonte canônica das mecânicas continua sendo:

`docs/index/mechanics.json`

Para detalhes de uma feature:

```bash
python3 -m tools.context.lookup mech <ID>
```

A desmontagem inglesa RC750 citada pela feature é a autoridade final sobre o
comportamento original.

---

# Regras de desenvolvimento

1. Implementar uma issue por vez.
2. Não expandir o escopo da issue sem necessidade.
3. Consultar todas as `mechanics` associadas antes de modificar gameplay.
4. Verificar o assembly citado antes de assumir comportamento.
5. Não considerar testes existentes como prova automática de fidelidade.
6. Ao concluir uma implementação:
   - atualizar somente as entradas afetadas, identificadas pelos IDs listados na issue, em `docs/index/mechanics.json`;
   - atualizar `implemented_scope`;
   - atualizar `missing_scope`;
   - atualizar `status` somente quando justificado;
   - executar `build_index`;
   - executar `validate.py`.
7. Não editar `coverage.md` manualmente.
8. Preservar alterações locais de `godot/project.godot`.
9. Não fazer commit ou push sem autorização.
10. `IMPLEMENTED` significa que todo o recorte original daquela feature está
    coberto, não apenas que a issue atual funciona.

---

## Resolução dos IDs e preparação dos milestones

Os IDs explícitos deste plano foram recuperados da conversa e, quando disponíveis,
conferidos no catálogo anexado. Esse anexo cobre apenas parte dos IDs citados no
plano; a versão atual de `docs/index/mechanics.json` no repositório deve ser
consultada antes da execução. Este arquivo não certifica o estado atual do port.

Antes de iniciar cada milestone:

1. Confirmar cada ID listado nas suas issues com
   `python3 -m tools.context.lookup mech <ID>`.
2. Todos os IDs deste plano foram verificados e resolvidos diretamente contra o
   catálogo canônico normalizado `docs/index/mechanics.json`.
3. Se houver divergência futura na desmontagem, registrar a lacuna e marcar a issue
   afetada como `[!]`; não inventar IDs nem assumir equivalência apenas pelo título.
4. Conferir as dependências e o estado atual antes de implementar. Os marcadores
   iniciais deste plano são de planejamento, não uma auditoria de conclusão.

Os milestones seguem a ordem apresentada. As dependências explícitas das issues
foram preservadas; a ausência de uma lista não prova independência. Para as issues
sem critérios específicos, o aceite exige que o comportamento indicado no título
e no objetivo funcione na rota original, dentro do recorte confirmado pelo lookup,
com evidência e cumprimento da Definition of Done. Detalhar os cenários de aceite
antes de implementar, sem ampliar o escopo.

# Estados das issues

- `[ ]` A FAZER
- `[>]` EM ANDAMENTO
- `[x]` CONCLUÍDA
- `[!]` BLOQUEADA

---

# MILESTONE 1 — Runtime canônico básico

Objetivo:

Snake deve se mover, colidir e atravessar salas usando regras determinísticas
compatíveis com o original.

## CORE-001 — Loop principal e tick determinístico

Status: `[ ]`

Mechanics (IDs):

- `game-loop`
- `player-runtime-control`

Objetivo:

Estabelecer uma única base temporal determinística para o gameplay antes de
continuar implementando sistemas dependentes de ticks.

Implementar somente o necessário para que os sistemas possam avançar por tick
de forma controlada.

Importante:

A frequência real da edição europeia deve ser verificada contra a ROM/openMSX.
Não assumir 60 Hz apenas porque o Godot atualmente utiliza essa configuração.

Aceite:

- gameplay possui tick determinístico;
- ordem principal de atualização é conhecida;
- comportamento não depende de `delta` onde a ROM trabalha em ticks;
- testes existentes continuam passando;
- mechanics atualizadas.

Dependências:

Nenhuma.

---

## CORE-002 — Movimento cardinal fiel

Status: `[ ]`

Mechanics (IDs):

- `player-movement`
- `player-runtime-control`

Objetivo:

Reproduzir o movimento cardinal do Snake com a lógica discreta original.

Aceite:

- velocidade por tick equivalente;
- parada imediata;
- prioridade entre ControlsTrigger e ControlsHold;
- DirectionMask/DirectionMaskOld equivalentes;
- nenhuma regressão de colisão.

Dependências:

- CORE-001

---

## CORE-003 — Facing e animação de caminhada

Status: `[ ]`

Mechanics (IDs):

- `player-facing-animation`

Objetivo:

Migrar a animação de caminhada para a temporização baseada em tick e fechar as
diferenças ainda registradas no catálogo.

Aceite:

- ciclo de passos original;
- cadência original;
- direção correta;
- comportamento armado/desarmado conforme ROM.

Dependências:

- CORE-001
- CORE-002

---

## CORE-004 — Colisão canônica do jogador

Status: `[ ]`

Mechanics (IDs):

- `player-world-collision`

Objetivo:

Finalizar a colisão por tiles sem barreiras artificiais que interfiram nas
transições do mundo.

Aceite:

- BoxColliderDat equivalente;
- pontos de amostragem equivalentes;
- bordas de tela não são tratadas como paredes artificiais;
- regra especial documentada da sala 78 permanece corretamente delimitada.

Dependências:

- CORE-002

---

## CORE-005 — Transições de borda

Status: `[ ]`

Mechanics (IDs):

- `player-room-transition`
- `world-entry-coordinates`
- `world-cardinal-connections`

Objetivo:

Tornar saída e entrada entre telas determinísticas.

Aceite:

- thresholds originais;
- EntryRoomXY original;
- coordenada transversal preservada;
- direção preservada corretamente;
- sem heurísticas desnecessárias de entrada.

Dependências:

- CORE-004

---

## CORE-006 — Entrada e saída por portas

Status: `[ ]`

Mechanics (IDs):

- `doors`
- `world-entry-coordinates`

Objetivo:

Substituir posicionamentos aproximados por PlayerInDoorDat e regras originais
de entrada por portas.

Aceite:

- offset correto por tipo de porta;
- facing correto;
- nenhuma heurística baseada em números mágicos quando a ROM possui tabela.

Dependências:

- CORE-005

---

# MILESTONE 2 — Mundo canônico

Objetivo:

Um Room ID deve significar a mesma sala na ROM, dados extraídos e Godot.

## WORLD-001 — Remover aliases incorretos 211/212

Status: `[ ]`

Mechanics (IDs):

- `world-room-identity-mapping`
- `capture-prison`
- `progression-grey-fox-rescue`
- `progression-equipment-recovery`
- `world-water-channel-topology`

Objetivo:

Restaurar:

- prisão = sala 165;
- Grey Fox / equipment route = sala 164 conforme dados canônicos;
- 211/212 = salas reais do canal.

Aceite:

- captura usa IDs canônicos;
- aliases locais deixam de mascarar 211/212;
- testes da prisão atualizados;
- snapshots reais 211/212 acessíveis;
- nenhuma porta reescrita artificialmente para sustentar os aliases antigos.

Dependências:

- CORE-006

---

## WORLD-002 — Grafo cardinal completo

Status: `[ ]`

Mechanics (IDs):

- `world-cardinal-connections`
- `world-room-identity-mapping`

Objetivo:

Permitir que RoomManager siga o grafo canônico sem bloqueios artificiais.

Aceite:

- tabela da ROM é fonte da conexão;
- 211/212 deixam de ser bloqueadas;
- conexões canônicas verificadas por testes.

Dependências:

- WORLD-001

---

## WORLD-003 — Elevadores necessários ao fluxo

Status: `[ ]`

Mechanics (IDs):

- `world-elevator-topology`
- `elevators`
- `player-room-transition`

Objetivo:

Validar a integração real dos eixos de elevador conforme forem necessários
para o playthrough.

Aceite:

- destino correto;
- andar correto;
- entrada correta;
- shafts multi-tela funcionais quando alcançados.

Dependências:

- CORE-005
- WORLD-002

---

# MILESTONE 3 — Estado persistente da campanha

Objetivo:

Sair de uma sala, derrotar um boss, coletar um item ou morrer não pode destruir
a progressão lógica da campanha.

## STATE-001 — GameProgressBuffer e checkpoints

Status: `[ ]`

Mechanics (IDs):

- `progression-flags-buffer`

Objetivo:

Implementar a fonte persistente de estado necessária para o restante da
campanha.

Aceite:

- checkpoints canônicos;
- flags relevantes persistem;
- portas persistem;
- bosses persistem;
- inventário persiste;
- reféns persistem;
- restauração é determinística.

Dependências:

- WORLD-002

---

## STATE-002 — Persistência de pickups

Status: `[ ]`

Mechanics (IDs):

- `pickup-persistence`
- `consumable-lifecycle`

Objetivo:

Reproduzir coleta, desaparecimento e reposição conforme o tipo de pickup.

Dependências:

- STATE-001

---

## STATE-003 — Rank e reféns

Status: `[ ]`

Mechanics (IDs):

- `rank-prisoners`
- `progression-rank-stars`
- `progression-hostage-penalty-downgrade`
- `rank-capacities`

Objetivo:

Finalizar a cadeia de rank usando o valor canônico e consequências persistentes.

Dependências:

- STATE-001

---

## STATE-004 — Morte canônica

Status: `[ ]`

Mechanics (IDs):

- `player-death`

Objetivo:

Implementar a sequência física completa antes de Game Over.

Dependências:

- CORE-001

---

## STATE-005 — Game Over e Continue

Status: `[ ]`

Mechanics (IDs):

- `progression-game-over-continue`
- `progression-flags-buffer`
- `player-death`

Objetivo:

Permitir morte → Game Over → Continue → checkpoint sem atalhos de debug.

Dependências:

- STATE-001
- STATE-004

---

# MILESTONE 4 — Infraestrutura compartilhada

Objetivo:

Evitar implementar cada evento com banners, flags e hacks próprios.

## SYS-001 — Motor unificado de TextBox

Status: `[ ]`

Mechanics (IDs):

- `text-window`
- `text-box-geometry-types`
- `text-skip-control-modes`
- `text-appearance-animation`

Objetivo:

Criar o motor compartilhado usado por diálogos e eventos.

Dependências:

- CORE-001

---

## SYS-002 — Eventos disparados pelo fechamento de texto

Status: `[ ]`

Mechanics (IDs):

- `text-event-triggers`
- `text-window`

Objetivo:

Permitir que eventos dependentes da conclusão real do texto funcionem sem
callbacks locais ad-hoc.

Dependências:

- SYS-001
- STATE-001

---

## SYS-003 — Cartões e seleção de equipamento

Status: `[ ]`

Mechanics (IDs):

- `access-cards`
- `equipment-inventory`
- `doors`

Objetivo:

Separar posse de item de item realmente selecionado quando o original exigir.

Dependências:

- STATE-002
- CORE-006

---

# MILESTONE 5 — Edifício 1 completo

Objetivo:

Jogar do início até a saída do Edifício 1 sem teleport, room selector ou cheats.

## B1-001 — Intro e entrada real no gameplay

Status: `[ ]`

Mechanics (IDs):

- `intro-title`
- `intro-mission-briefing`
- `player-runtime-control`

Dependências:

- CORE-001
- SYS-001

---

## B1-002 — Shot Gunner e consequência persistente

Status: `[ ]`

Mechanics (IDs):

- `shot-gunner`
- `progression-boss-shotgunner`

Dependências:

- STATE-001
- SYS-001

---

## B1-003 — Captura e prisão canônica

Status: `[ ]`

Mechanics (IDs):

- `capture-prison`
- `capture-guards`
- `world-room-identity-mapping`

Dependências:

- WORLD-001
- SYS-001
- STATE-001

---

## B1-004 — Grey Fox e fuga da prisão

Status: `[ ]`

Mechanics (IDs):

- `grey-fox`
- `progression-grey-fox-rescue`
- `capture-prison`

Dependências:

- B1-003
- STATE-001

---

## B1-005 — Recuperação dos equipamentos

Status: `[ ]`

Mechanics (IDs):

- `equipment-bag`
- `progression-equipment-recovery`

Dependências:

- B1-004
- STATE-001

---

## B1-006 — Machine Gun Kid

Status: `[ ]`

Mechanics (IDs):

- `machine-gun-kid`
- `progression-boss-machinegunkid`

Dependências:

- STATE-001
- SYS-001

---

## B1-007 — Hind-D

Status: `[ ]`

Mechanics (IDs):

- `hind-d`
- `progression-boss-hind-d`
- `remote-missile`

Dependências:

- STATE-001

---

## B1-008 — Paraquedas: aquisição e seleção

Status: `[ ]`

Mechanics (IDs):

- `parachute`

Dependências:

- STATE-002

---

## B1-009 — Física de queda e paraquedas

Status: `[ ]`

Mechanics (IDs):

- `player-freefall-parachute`
- `hazard-roof-freefall`

Dependências:

- B1-008
- CORE-001

---

## B1-010 — Sala 204 e aterrissagem

Status: `[ ]`

Mechanics (IDs):

- `world-parachute-courtyard-204`
- `progression-roof-parachute-jump`

Dependências:

- B1-009
- WORLD-002

Milestone concluído quando:

O jogo pode ser iniciado normalmente e o jogador consegue sair do Edifício 1
pela rota original sem ferramentas de debug.

---

# MILESTONE 6 — Deserto e entrada no Edifício 2

## D1-001 — Compass

Status: `[ ]`

Mechanics (IDs):

- `compass`
- `progression-desert-crossing-compass`
- `hazard-desert-loop`
- `world-desert-navigation`

Dependências:

- STATE-002

---

## D1-002 — Campo minado

Status: `[ ]`

Mechanics (IDs):

- `hazard-minefield`
- `enemy-mines`
- `mine-detector`

Dependências:

- CORE-004

---

## D1-003 — Tank

Status: `[ ]`

Mechanics (IDs):

- `tank`
- `progression-boss-tank`

Dependências:

- STATE-001

---

## D1-004 — Entrada no Edifício 2

Status: `[ ]`

Mechanics (IDs):

- `progression-building-transitions`
- `progression-building2-entrance-door`

Dependências:

- D1-001
- D1-002
- D1-003

---

## D1-005 — Caminhões móveis

Status: `[ ]`

Mechanics (IDs):

- `progression-moving-lorries-transport`
- `world-lorry-navigation`

Dependências:

- CORE-001
- WORLD-002
- SYS-001

---

# MILESTONE 7 — Edifício 2

## B2-001 — Antenna

Status: `[ ]`

Mechanics (IDs):

- `antenna`
- `radio-cond-antenna`
- `progression-antenna-requirement`

---

## B2-002 — Bulldozer

Status: `[ ]`

Mechanics (IDs):

- `bulldozer`
- `progression-boss-bulldozer`

---

## B2-003 — Hazards principais

Status: `[ ]`

Mechanics (IDs):

- `gas`
- `electrified-floor`
- `hazard-dark-rooms`
- `hazard-roof-wind`
- `player-roof-airflow`
- `gas-mask`
- `bomb-blast-suit`

---

## B2-004 — Fire Trooper

Status: `[ ]`

Mechanics (IDs):

- `fire-trooper`
- `progression-boss-firetrooper`

---

## B2-005 — Ellen

Status: `[ ]`

Mechanics (IDs):

- `ellen`
- `progression-ellen-rescue`

---

## B2-006 — Madnar e fórmula

Status: `[ ]`

Mechanics (IDs):

- `madnar`
- `progression-madnar-rescue-formula`

Dependências:

- B2-005

---

## B2-007 — Fake Madnar

Status: `[ ]`

Mechanics (IDs):

- `fake-madnar`
- `fake-madnar-trap-dialogue`
- `progression-fake-madnar-trap`
- `hazard-pitfall-trap`

---

## B2-008 — Oxygen Tank e deep water

Status: `[ ]`

Mechanics (IDs):

- `oxygen-tank`
- `player-water-movement`
- `player-deep-water`
- `hazard-water-environment`
- `progression-water-channel-oxygen`

---

## B2-009 — Canal subterrâneo

Status: `[ ]`

Mechanics (IDs):

- `world-water-channel-topology`
- `world-room-identity-mapping`

Dependências:

- WORLD-001
- B2-008

Milestone concluído quando:

O jogador consegue chegar ao Edifício 3 pela rota original.

---

# MILESTONE 8 — Edifício 3 e final

## B3-001 — Rocket Launcher

Status: `[ ]`

Mechanics (IDs):

- `rocket-launcher`
- `progression-jennifer-rocket-launcher`

---

## B3-002 — Arnolds e Card 7

Status: `[ ]`

Mechanics (IDs):

- `arnold`
- `progression-boss-arnolds-card7`
- `access-cards`

Dependências:

- B3-001

---

## B3-003 — Traição de Big Boss

Status: `[ ]`

Mechanics (IDs):

- `progression-bigboss-betrayal-switchoff`
- `radio-cond-bigboss-switch-off`

---

## B3-004 — Metal Gear

Status: `[ ]`

Mechanics (IDs):

- `metal-gear-boss`
- `progression-metalgear-destruction`

---

## B3-005 — Autodestruição

Status: `[ ]`

Mechanics (IDs):

- `progression-metalgear-destruction`

Dependências:

- B3-004

---

## B3-006 — Big Boss final

Status: `[ ]`

Mechanics (IDs):

- `big-boss`
- `progression-boss-bigboss-final`

---

## B3-007 — Escadas de fuga

Status: `[ ]`

Mechanics (IDs):

- `player-escape-ladders`
- `world-escape-ladder-topology`

Dependências:

- B3-005
- B3-006

---

## B3-008 — Ending

Status: `[ ]`

Mechanics (IDs):

- `progression-escape-ending`
- `ending-broadcast-dialogue`

Dependências:

- B3-007

Milestone concluído quando:

Existe um playthrough completo do início ao ending sem comandos de debug,
teleportes ou seleção manual de salas.

---

# MILESTONE 9 — Fechamento de fidelidade

Somente depois do primeiro playthrough completo:

- auditoria `scenes-flow`;
- auditoria `menus-ui`;
- áudio/música;
- varredura de todas as features `PARTIAL`;
- varredura de todas as features `PROVISIONAL`;
- resolução de `UNMAPPED`;
- comparação dinâmica com openMSX;
- fechamento final 1:1.

---

# Definition of Done de uma issue

Uma issue só pode ser marcada `[x]` quando:

- o recorte descrito pela issue funciona;
- assembly usado como referência foi verificado;
- testes específicos foram criados ou atualizados;
- suítes existentes continuam passando;
- as entradas afetadas em `docs/index/mechanics.json` foram atualizadas pelos IDs exatos da issue;
- não restam notas de ID a resolver na issue;
- `python3 -m tools.context.build_index` passou;
- `python3 -m tools.context.build_index --check` passou;
- `python3 tools/validate.py` passou;
- nenhuma alteração fora do escopo foi introduzida;
- nenhuma alteração local não relacionada foi sobrescrita.

A conclusão de uma issue NÃO implica automaticamente que todas as features
referenciadas nela devem virar `IMPLEMENTED`.

---

# Prompt mínimo reutilizável

Substitua `<ISSUE-ID>` pelo identificador da issue, por exemplo `CORE-001`,
`WORLD-001` ou `B1-006`. Salve este plano em `docs/IMPLEMENTATION_PLAN.md`
no repositório do port.

```text
Implemente a issue <ISSUE-ID> de docs/IMPLEMENTATION_PLAN.md.
Siga seu escopo, dependências, critérios de aceite, regras e Definition of Done.
Antes de começar o milestone, resolva as notas de IDs pendentes no catálogo e
confirme cada ID com: python3 -m tools.context.lookup mech <ID>.
Use o assembly RC750 citado como autoridade e siga a skill
implement-faithful-mechanic do projeto; se indisponível, informe a ausência.
Não amplie o escopo; registre separadamente outras divergências encontradas.
Atualize os IDs afetados em docs/index/mechanics.json sem promover status indevidamente.
Execute testes relevantes, python3 -m tools.context.build_index,
python3 -m tools.context.build_index --check e python3 tools/validate.py.
Preserve alterações locais de godot/project.godot e demais alterações não relacionadas.
Informe implementação, evidências, testes, divergências e status final da issue.
Não faça commit nem push.
```

