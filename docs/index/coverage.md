# Cobertura progressiva — atores e bosses

Gerado por `python3 -m tools.context.build_index` a partir de [mechanics.json](mechanics.json). Não editar esta visualização.

**Relatório para leitura humana; não é contexto padrão de agentes.** Agentes não devem ler este arquivo integralmente: use `python3 -m tools.context.lookup domain actors-bosses`, `lookup status STATUS` ou `lookup unmapped`; detalhes somente com `lookup mech ID`.

Contagem por feature/família declarada, não por rotina ou percentual do jogo. Cadeias sem `domain` estão fora da auditoria e não entram nos totais. IDs podem reaparecer em comportamentos transversais; não somar IDs como features.

## Atores e bosses — edição inglesa RC750

Auditoria: 2026-10-04; HEAD de partida: `0c268ca121e4a00b404f8e08cada95323bb00b18`; referência inglesa: `30d1b940bede10fdabbaf9767ad4f0ad8dd33291`.

Famílias de comportamento do despacho de atores, NPCs, bosses, perigos/geradores implementados como atores, projéteis associados e mecanismos transversais de percepção/resgate. Não audita inventário, mapas, armas do jogador, rádio ou áudio como domínios independentes.

Inventário original primeiro: enums, SetupActor e RunEnemyLogic via índices/lookup. Depois cruzamento estático do dispatcher _spawn_room_enemies, geradores/reféns/painéis/cutscene e sistemas correspondentes, export_room_data/extract.py, índice de testes, documentação e títulos/faixas do histórico. NOT_STARTED exige também exclusão no fluxo de criação e ausência de consumidor específico; um nome encontrado em texto de rádio não comprova boss implementado. Suíte verde valida regressão, não comprova automaticamente fidelidade 1:1.

- ID 0 é slot vazio, fora do recorte 1–65. O despacho de atualização inclui ID 65; a tabela de inicialização termina em 64. A documentação histórica de 57 tipos não é inventário completo.
- Cada família é uma entrada; projéteis exclusivos de boss ficam na mesma entrada. Features transversais não possuem actor_ids para evitar fingir novos tipos. Não é porcentagem de conclusão.
- Inventário baseado somente na desmontagem inglesa, sem reextração da ROM. Dados existentes são referências locais, não evidência de comportamento implementado; a validação final verifica a ROM por perfil/hash.
- Arte procedural, textos resumidos, aproximações e testes que apenas repetem constantes locais impedem promover automaticamente famílias completas a IMPLEMENTED.
- Histórico preservado: afirmações antigas de fidelidade ou conclusão são confrontadas com código atual. Nenhuma ausência descoberta é chamada de bug sem demonstrar divergência em comportamento existente.
- Validação desta entrega: python3 tools/validate.py fora do sandbox, exit 0, 37 etapas PASS, 134 testes Python; importação, suítes e boot no Godot 4.7.2 aprovados. Os testes de índice usam fixtures sintéticas. Nenhuma comparação dinâmica nova com openMSX foi executada nesta auditoria estática.

| Status | Features |
| --- | ---: |
| `IMPLEMENTED` | 0 |
| `PARTIAL` | 20 |
| `PROVISIONAL` | 12 |
| `NOT_STARTED` | 17 |
| `DEFERRED` | 0 |
| `UNMAPPED` | 2 |
| `INVESTIGATING` | 0 |
| Total | 51 |

### Entradas

| Feature | IDs | Status |
| --- | --- | --- |
| [guards](#guards) — Guardas de patrulha lenta, média e rápida | 4, 5, 30 | `PARTIAL` |
| [dogs](#dogs) — Cães de guarda comuns | 25 | `PARTIAL` |
| [elevator-guards](#elevator-guards) — Sentinelas e revezamento do elevador | 14, 40 | `PARTIAL` |
| [rank-prisoners](#rank-prisoners) — Reféns comuns, resgate, patente e morte | 49 | `PARTIAL` |
| [shot-gunner](#shot-gunner) — Shot Gunner e projétil expansivo | 33, 43 | `PARTIAL` |
| [actor-runtime](#actor-runtime) — Ciclo, criação, dano e remoção de atores | transversal | `PARTIAL` |
| [guard-senses](#guard-senses) — Percepção de atores e obstrução por tiles | transversal | `PARTIAL` |
| [guard-alert](#guard-alert) — Guardas em alerta e vermelho | 10, 11 | `PARTIAL` |
| [guard-sleep](#guard-sleep) — Sono e despertar de guardas | transversal | `PARTIAL` |
| [guard-entry-hiding](#guard-entry-hiding) — Ocultação de guardas conforme entrada na sala | transversal | `PARTIAL` |
| [guard-lorry](#guard-lorry) — Guardas que saem e entram em caminhões | 19 | `PARTIAL` |
| [shooter-guards](#shooter-guards) — Atiradores que andam, disparam e se escondem | 13 | `PROVISIONAL` |
| [switch-guards](#switch-guards) — Guarda que corre para o interruptor | 24 | `PROVISIONAL` |
| [lorry-shooters](#lorry-shooters) — Atiradores nos caminhões do deserto | 28 | `PROVISIONAL` |
| [scorpions](#scorpions) — Escorpiões | 31 | `PROVISIONAL` |
| [desert-security](#desert-security) — Segurança do acesso ao edifício 2 | 46 | `PROVISIONAL` |
| [sentinels](#sentinels) — Sentinelas com lista de direções | 48 | `PROVISIONAL` |
| [silencer-guards](#silencer-guards) — Guardas da sala do silenciador | 57 | `PARTIAL` |
| [basement-dogs](#basement-dogs) — Cães do subsolo | 27 | `PROVISIONAL` |
| [dog-spawner](#dog-spawner) — Gerador de cães entre salas | 29 | `NOT_STARTED` |
| [jetpack-guards](#jetpack-guards) — Soldados com jetpack e decolagem | 20, 21, 22 | `PROVISIONAL` |
| [bridges](#bridges) — Pontes e controlador de trechos | 1, 2 | `NOT_STARTED` |
| [enemy-mines](#enemy-mines) — Minas do cenário | 7 | `NOT_STARTED` |
| [rolling-barrels](#rolling-barrels) — Barris rolantes | 15 | `NOT_STARTED` |
| [pitfalls](#pitfalls) — Alçapões de ator | 16 | `NOT_STARTED` |
| [shell-barrage](#shell-barrage) — Bombardeio e gerador de projéteis aéreos | 12, 39 | `NOT_STARTED` |
| [actor-camera](#actor-camera) — Câmera de vigilância comum | 6 | `PARTIAL` |
| [laser-cameras](#laser-cameras) — Câmeras armadas e seus lasers | 53, 54 | `NOT_STARTED` |
| [actor-lasers](#actor-lasers) — Controlador de feixes móveis | 35 | `PARTIAL` |
| [actor-gas](#actor-gas) — Nuvens de gás | 8 | `PARTIAL` |
| [actor-power-switch](#actor-power-switch) — Painel de força e pulsação da paleta | 44 | `PARTIAL` |
| [capture-guards](#capture-guards) — Guardas da sequência de captura | 45 | `PARTIAL` |
| [guard-projectiles](#guard-projectiles) — Projéteis comuns e variantes horizontal/vertical/mirada | 47, 58, 59, 61 | `PARTIAL` |
| [tank](#tank) — Tanque e seus disparos | 9, 23, 62 | `NOT_STARTED` |
| [bulldozer](#bulldozer) — Bulldozer | 18 | `NOT_STARTED` |
| [arnold](#arnold) — Arnold | 26 | `NOT_STARTED` |
| [big-boss](#big-boss) — Big Boss em combate | 32 | `NOT_STARTED` |
| [machine-gun-kid](#machine-gun-kid) — Machine Gun Kid e rajadas | 34, 60 | `NOT_STARTED` |
| [fire-trooper](#fire-trooper) — Fire Trooper e chamas | 36, 37 | `NOT_STARTED` |
| [hind-d](#hind-d) — Hind D | 38 | `NOT_STARTED` |
| [coward-duck](#coward-duck) — Coward Duck e bumerangues | 41, 63 | `NOT_STARTED` |
| [metal-gear-boss](#metal-gear-boss) — Metal Gear, sequência de bombas e destruição | 17 | `NOT_STARTED` |
| [ellen](#ellen) — Ellen como refém | 50 | `PARTIAL` |
| [ellen-help](#ellen-help) — Pedido de ajuda periódico de Ellen | 3 | `NOT_STARTED` |
| [grey-fox](#grey-fox) — Grey Fox: resgate e diálogo inglês | 51 | `PARTIAL` |
| [madnar](#madnar) — Dr. Pettrovich Madnar | 52 | `PROVISIONAL` |
| [fake-madnar](#fake-madnar) — Fake Madnar e armadilha | 55 | `PROVISIONAL` |
| [jennifer-brother](#jennifer-brother) — Reféns de Coward Duck e irmão de Jennifer | transversal | `PROVISIONAL` |
| [prisoner6](#prisoner6) — Slot de prisioneiro ID 56 | 56 | `UNMAPPED` |
| [sleep-sign](#sleep-sign) — Ator de indicação de sono | 64 | `PROVISIONAL` |
| [big-explosion-actor](#big-explosion-actor) — Explosão grande de ator | 65 | `UNMAPPED` |

### UNMAPPED

- **prisoner6**: Não é seguro afirmar feature não iniciada: despacho é inerte e o uso real do slot não foi demonstrado.
- **big-explosion-actor**: Explosões existentes impedem concluir ausência só por nome/ID; correspondência entre este ator e os efeitos atuais não estabelecida.

<a id="guards"></a>
### Guardas de patrulha lenta, média e rápida

`guards` · **PARTIAL**

**Original:** Patrulha por caminhos, curvas, espera, animação e transição para alerta.

**Classificação:** Máquina de patrulha existe e tem testes, mas o próprio spawn inclui aproximações.

**Assembly:** logic/actors/guard.asm:29-56 GuardLogic; Banks0123.asm:6852-6923 InitGuardPath

**Extractors:** tools/extractors/extract.py; tools/extractors/export_room_data.py; tools/extractors/extract_enemy_sprites.py

**Dados canônicos locais:** rooms/

**Godot relacionado:** godot/scripts/systems/enemy.gd

**Integração inspecionada:** godot/scripts/scenes/sandbox_gameplay.gd::_spawn_room_enemies

**Testes existentes:** godot-enemy-patrol; godot-room-007-patrol; godot-floor3-review; tests/test_enemy_sprite_extractor.py

**Documentação:** docs/reverse_engineering/stage-7-enemy-patrols.md; docs/reverse_engineering/enemies.md

**Histórico consultado:** docs/progress/2026-09.md::2026-09-20 — Etapa 12b concluída: Spawn de Inimigos, Itens e Portas Canônicas da ROM

**Implementado:** Waypoints extraídos, patrulha/colisão, animação, dano e sprites privados.

**Faltante / não comprovado:** Escolha inicial de rota/posição usa aleatoriedade e fallback ±32 px no sandbox; fidelidade integral de tempos/velocidades não estabelecida.

**Notas de evidência:** _spawn_room_enemies aplica reverse aleatório e pode substituir o spawn pelo primeiro waypoint. Não corrigido.


<a id="dogs"></a>
### Cães de guarda comuns

`dogs` · **PARTIAL**

**Original:** Sono, escuta, corrida, latido, contato e animação canina.

**Classificação:** Há máquina própria, mas aproximações explícitas impedem classificação 1:1.

**Assembly:** logic/actors/dog.asm:29-81 DogLogic; logic/actors/dog.asm:193-201 DogSpeeds

**Extractors:** tools/extractors/extract.py; tools/extractors/export_room_data.py; tools/extractors/extract_enemy_sprites.py

**Dados canônicos locais:** rooms/

**Godot relacionado:** godot/scripts/systems/enemy.gd

**Integração inspecionada:** godot/scripts/scenes/sandbox_gameplay.gd::_spawn_room_enemies

**Testes existentes:** godot-dogs; tests/test_enemy_sprite_extractor.py

**Documentação:** docs/reverse_engineering/enemies.md; docs/reverse_engineering/stage-12b-actors-and-items-evidence.md

**Histórico consultado:** docs/progress/2026-09.md::[Implementação Canônica] - Cães de Guarda Canônicos (ID_DOG = 25) e Sprite Canino na Sala 006

**Implementado:** Estados de cão, dano, sprites e testes próprios.

**Faltante / não comprovado:** Despertar radial a 48 px adicionado no Godot; tempos/velocidades e transições precisam de paridade completa; som de latido ausente.

**Notas de evidência:** Teste valida o despertar radial da implementação; isso não o transforma em regra original.


<a id="elevator-guards"></a>
### Sentinelas e revezamento do elevador

`elevator-guards` · **PARTIAL**

**Original:** Postos, olhar, fala de revezamento, chegada/saída dos guardas e gerador.

**Classificação:** Revezamento implementado; fidelidade audiovisual e temporal completa permanece aberta.

**Assembly:** logic/actors/guardelevator.asm:68-112 GuardElevator; logic/actors/elevatorguardspawner.asm:8-43 InitSpawnGuardElev

**Extractors:** tools/extractors/extract.py; tools/extractors/export_room_data.py

**Dados canônicos locais:** rooms/

**Godot relacionado:** godot/scripts/systems/enemy.gd

**Integração inspecionada:** godot/scripts/scenes/sandbox_gameplay.gd::_process_elevator_spawner; godot/scripts/scenes/sandbox_gameplay.gd::_spawn_relieve_guard

**Testes existentes:** godot-elevator-guards

**Documentação:** docs/reverse_engineering/enemies.md; docs/reverse_engineering/stage-12b-actors-and-items-evidence.md

**Histórico consultado:** docs/progress/2026-09.md::[Correção Canônica] - Sentinelas do Elevador na Sala 003 e Rotina "Chow time!!" (GuardElevator & ElevatorGuardSpawner)

**Implementado:** Estados próprios, gerador integrado e teste de revezamento.

**Faltante / não comprovado:** Fala fora da janela canônica e temporização de todo o ciclo sem comparação dinâmica.

**Notas de evidência:** Gerador ID 40 está em código da cena, não precisa de classe com o nome original.


<a id="rank-prisoners"></a>
### Reféns comuns, resgate, patente e morte

`rank-prisoners` · **PARTIAL**

**Original:** Contato diferido, libertação, texto por sala, flags de resgate, promoção e penalidade.

**Classificação:** Mecânica portável e testada em parte; divergência numérica já registrada no STATUS.

**Assembly:** logic/actors/prisoner.asm:55-96 PrisonerLogic; logic/actors/prisoner.asm:244-277 RescuedLogic3; Banks0123.asm:9634-9641 IncRescued

**Extractors:** tools/extractors/extract.py; tools/extractors/export_room_data.py; tools/extractors/extract_prisoner_sprites.py

**Dados canônicos locais:** rooms/

**Godot relacionado:** godot/scripts/systems/prisoner.gd; godot/scripts/systems/rank_system.gd

**Integração inspecionada:** godot/scripts/scenes/sandbox_gameplay.gd::_spawn_room_prisoners; godot/scripts/scenes/sandbox_gameplay.gd::_on_prisoner_rescued

**Testes existentes:** godot-rank-and-prisoners; tests/test_prisoner_sprite_extractor.py

**Documentação:** docs/reverse_engineering/enemies.md; docs/reverse_engineering/stage-12b-actors-and-items-evidence.md

**Histórico consultado:** docs/progress/2026-09.md::2026-09-21 — Etapa 19: Sistema de Prisioneiros, Reféns e Patente Militar (Ranks ★1 a ★4)

**Implementado:** Ator com estados/atraso, sprites, resgate, contador e morte; suíte dedicada.

**Faltante / não comprovado:** Promoção usa quatro resgates contra cp 5; textos comuns resumidos, condições específicas e persistência por indivíduo não completas.

**Notas de evidência:** Uma suíte que exige quatro resgates não comprova o limiar original de cinco.


<a id="shot-gunner"></a>
### Shot Gunner e projétil expansivo

`shot-gunner` · **PARTIAL**

**Original:** Apresentação modal, rolagem, vulnerabilidade/tiros, expansão do projétil, dano e persistência.

**Classificação:** Único boss com sistema dedicado; completude do combate não equivale à completude da apresentação original.

**Assembly:** logic/actors/shotgunner.asm:40-70 ShotGunnerLogic; logic/actors/shotgunner.asm:80-148 ShotGunnerRoll; logic/actors/shotgunner.asm:188-235 ShotGunnerShot

**Extractors:** tools/extractors/extract.py; tools/extractors/export_room_data.py; tools/extractors/extract_shoot_gunner_sprites.py

**Dados canônicos locais:** rooms/

**Godot relacionado:** godot/scripts/systems/shot_gunner.gd; godot/scripts/systems/shot_gunner_bullet.gd

**Integração inspecionada:** godot/scripts/scenes/sandbox_gameplay.gd::_on_boss_intro_dialog; godot/scripts/scenes/sandbox_gameplay.gd::_on_boss_defeated

**Testes existentes:** godot-boss-shoot-gunner; tests/test_shoot_gunner_sprite_extractor.py

**Documentação:** docs/reverse_engineering/stage-18-shoot-gunner.md

**Histórico consultado:** docs/progress/2026-09.md::2026-09-20 — Etapa 18 concluída: Boss Fight Canônica — Shoot Gunner (Sala 57); docs/progress/2026-09.md::2026-09-30 — Sprites Originais do Boss Shoot Gunner e Projéteis de Escopeta MSX2

**Implementado:** Chefe específico, sprites extraídos, estados/colisão/HP/projétil e persistência na cena.

**Faltante / não comprovado:** Discurso usa Label e não SetTextUnskippable canônico; SFX/música ausentes, temporização integral não validada contra execução original.

**Notas de evidência:** Histórico relata ajustes de cadência como melhorias; sua equivalência ao assembly não deve ser presumida.


<a id="actor-runtime"></a>
### Ciclo, criação, dano e remoção de atores

`actor-runtime` · **PARTIAL**

**Original:** Lista de 16 atores, inicialização por ID, vida/contato/soco, despacho, movimento e remoção por tipo.

**Classificação:** Infraestrutura funcional para um subconjunto; metadados de todos os atores não equivalem ao porte do runtime.

**Assembly:** Banks0123.asm:6088-6150 SetupEnemyRoom; Banks0123.asm:6358-6402 SetupActor; Banks0123.asm:12612-12648 EnemiesLogic; Banks0123.asm:12657-12739 RunEnemyLogic; Banks0123.asm:13192-13241 KillActor

**Extractors:** tools/extractors/extract.py; tools/extractors/export_room_data.py

**Dados canônicos locais:** rooms/

**Godot relacionado:** godot/scripts/systems/enemy.gd; godot/scripts/systems/room_manager.gd; godot/scripts/systems/bullet.gd; godot/scripts/systems/prisoner.gd

**Integração inspecionada:** godot/scripts/scenes/sandbox_gameplay.gd::_spawn_room_enemies

**Testes existentes:** tests/test_extractors.py; godot-combat-health; godot-room-transition

**Documentação:** docs/reverse_engineering/enemies.md; docs/reverse_engineering/stage-12b-actors-and-items-evidence.md

**Histórico consultado:** docs/progress/2026-09.md::2026-09-20 — Etapa 12b concluída: Spawn de Inimigos, Itens e Portas Canônicas da ROM

**Implementado:** Extração de ID/Y/X, criação de nós especializados, atualização e remoção de entidades portadas.

**Faltante / não comprovado:** Não há dispatcher completo dos IDs nem equivalência geral de limite/ordem dos 16 slots, dano e morte por tipo.

**Notas de evidência:** A tabela de vida original por ID não é substituída por um único contador de socos.


<a id="guard-senses"></a>
### Percepção de atores e obstrução por tiles

`guard-senses` · **PARTIAL**

**Original:** Contato, faixas direcionais, obstáculos e exceções por postura/tipo.

**Classificação:** Há testes de visibilidade, mas não uma matriz completa das condições originais.

**Assembly:** logic/actors/chkdiscover.asm:7-71 ChkActSeePlayer; logic/actors/chkdiscover.asm:447-491 ChkViewVertical

**Extractors:** tools/extractors/extract.py; tools/extractors/export_room_data.py

**Dados canônicos locais:** rooms/

**Godot relacionado:** godot/scripts/systems/enemy.gd; godot/scripts/systems/security_camera.gd

**Integração inspecionada:** godot/scripts/scenes/sandbox_gameplay.gd::_spawn_room_enemies

**Testes existentes:** godot-enemy-patrol; godot-cameras-and-lasers

**Documentação:** docs/reverse_engineering/enemies.md; docs/reverse_engineering/stage-12b-actors-and-items-evidence.md

**Histórico consultado:** docs/progress/2026-09.md::2026-09-20 — Etapa 12b concluída: Spawn de Inimigos, Itens e Portas Canônicas da ROM

**Implementado:** Visão direcional, tiles bloqueadores e caixa imóvel em guardas/câmeras.

**Faltante / não comprovado:** Equivalência de todas as exceções de água profunda, tipos e aritmética de byte não comprovada pelos testes atuais.

**Notas de evidência:** Auditoria estática; não inferir cobertura total a partir dos testes de linha de visão.


<a id="guard-alert"></a>
### Guardas em alerta e vermelho

`guard-alert` · **PARTIAL**

**Original:** Perseguição, desvio, tiro/recuo, descarte em água/caminhões e reforços.

**Classificação:** Fluxo especializado parcial; armas e velocidades genéricas não demonstram a máquina completa.

**Assembly:** logic/actors/guardalert.asm:7-38 InitGuardAlert; logic/actors/guardalert.asm:91-101 GuardAlertLogic; Banks0123.asm:6559-6628 ChkRespawnEnemy

**Extractors:** tools/extractors/extract.py; tools/extractors/export_room_data.py; tools/extractors/extract_respawn_info.py

**Dados canônicos locais:** respawn_info.json

**Godot relacionado:** godot/scripts/systems/enemy.gd; godot/scripts/systems/alert_system.gd; godot/scripts/systems/bullet.gd

**Integração inspecionada:** godot/scripts/scenes/sandbox_gameplay.gd::_on_reinforcement_requested; godot/scripts/scenes/sandbox_gameplay.gd::_trigger_alarm

**Testes existentes:** godot-alert-system; godot-combat-health

**Documentação:** docs/reverse_engineering/stage-17-alert-evasion-reinforcements.md

**Histórico consultado:** docs/progress/2026-09.md::2026-09-20 — Etapa 17 concluída: Máquina de Estados de Alerta Global, Evasão e Reforços Militares

**Implementado:** Estados de perseguição/espera/recuo e integração de reforços.

**Faltante / não comprovado:** Tiro usa cooldown comum 48; ChkGuardWater e todas as transições específicas ainda não demonstradas.

**Notas de evidência:** try_shoot cria Bullet com parâmetros comuns, não tabela específica de cada ID.


<a id="guard-sleep"></a>
### Sono e despertar de guardas

`guard-sleep` · **PARTIAL**

**Original:** Tempos de sono, fala, despertar e transição para alerta em salas específicas.

**Classificação:** Comportamento específico coberto em cenários locais; apresentação e integração original incompletas.

**Assembly:** logic/actors/guard.asm:187-260 ChkSleepyGuard

**Extractors:** tools/extractors/extract.py; tools/extractors/export_room_data.py

**Dados canônicos locais:** rooms/

**Godot relacionado:** godot/scripts/systems/enemy.gd

**Integração inspecionada:** godot/scripts/scenes/sandbox_gameplay.gd::_on_guard_sleepy_dialog

**Testes existentes:** godot-sleepy-guard

**Documentação:** docs/reverse_engineering/enemies.md; docs/reverse_engineering/stage-12b-actors-and-items-evidence.md

**Histórico consultado:** docs/progress/2026-09.md::[Implementação Canônica] - Guarda Sonolento (Sleepy Guard) na Sala 138 (Gas Mask Room) e Salas 26/85

**Implementado:** Estados acordado/dormindo e despertar por ações; teste dedicado.

**Faltante / não comprovado:** Fala usa banner e Zzz procedural; sincronismo de todos os contadores globais não validado.

**Notas de evidência:** Não confundir sono temporário com os sentinelas permanentes da sala 140.


<a id="guard-entry-hiding"></a>
### Ocultação de guardas conforme entrada na sala

`guard-entry-hiding` · **PARTIAL**

**Original:** Ocultar atores selecionados segundo sala, direção de entrada e sala anterior.

**Classificação:** Portado, mas não promovido a completo por testes de apenas alguns caminhos.

**Assembly:** logic/actors/hideguards.asm:10-172 HideGuardRoom1

**Extractors:** tools/extractors/extract.py; tools/extractors/export_room_data.py

**Dados canônicos locais:** rooms/

**Godot relacionado:** godot/scripts/systems/enemy.gd

**Integração inspecionada:** godot/scripts/scenes/sandbox_gameplay.gd::_should_hide_guard

**Testes existentes:** godot-room-007-patrol; godot-floor3-review

**Documentação:** docs/reverse_engineering/enemies.md; docs/reverse_engineering/stage-12b-actors-and-items-evidence.md

**Histórico consultado:** docs/progress/2026-09.md::[Correção Canônica] - Alternância de Patrulha na Sala 001 por Direção de Entrada (HideGuardRoom1)

**Implementado:** Regras explícitas para salas 1/13/15/17/18/19/22/35/39.

**Faltante / não comprovado:** Cobertura dos testes não demonstra todas as combinações; atalhos por previous_room_id precisam de comparação individual.

**Notas de evidência:** A função inclui condições OR por sala anterior além da direção. Não foram alteradas.


<a id="guard-lorry"></a>
### Guardas que saem e entram em caminhões

`guard-lorry` · **PARTIAL**

**Original:** Espera escondido, saída/rota/retorno, flags por caminhão e transformação em alerta.

**Classificação:** Implementação específica e testes de sala, sem comprovação integral do fluxo original.

**Assembly:** logic/actors/guardlorry.asm:8-55 InitGuardLorry; logic/actors/guardlorry.asm:67-113 GuardLorryLogic

**Extractors:** tools/extractors/extract.py; tools/extractors/export_room_data.py

**Dados canônicos locais:** rooms/

**Godot relacionado:** godot/scripts/systems/enemy.gd

**Integração inspecionada:** godot/scripts/scenes/sandbox_gameplay.gd::_spawn_room_enemies

**Testes existentes:** godot-room-007-patrol

**Documentação:** docs/reverse_engineering/enemies.md; docs/reverse_engineering/stage-12b-actors-and-items-evidence.md

**Histórico consultado:** docs/progress/2026-09.md::[v0.1.26] - Ciclo Canônico de Patrulha e Entrada/Saída na Carroceria (GuardLorry Sala 005)

**Implementado:** Ciclo e sprites ocultos, rotas das salas 5/7 e estado de saída relacionado aos interiores.

**Faltante / não comprovado:** Tempos e todas as variantes de alerta/entrada não comparados integralmente; áudio não portado.

**Notas de evidência:** O histórico descreve correções reais; não se adota sua afirmação de 100% como evidência de cobertura total.


<a id="shooter-guards"></a>
### Atiradores que andam, disparam e se escondem

`shooter-guards` · **PROVISIONAL**

**Original:** Ciclo wait/walk/shot/hide e transformação por proximidade/contador.

**Classificação:** Existe entidade visível substituta, mas o caminho inspecionado usa comportamento genérico sem a máquina original.

**Assembly:** logic/actors/shooter.asm:111-138 ShooterLogic

**Extractors:** tools/extractors/extract.py; tools/extractors/export_room_data.py

**Dados canônicos locais:** rooms/

**Godot relacionado:** godot/scripts/systems/enemy.gd

**Integração inspecionada:** godot/scripts/scenes/sandbox_gameplay.gd::_spawn_room_enemies

**Testes existentes:** tests/test_extractors.py

**Documentação:** docs/reverse_engineering/enemies.md; docs/reverse_engineering/stage-12b-actors-and-items-evidence.md

**Histórico consultado:** docs/progress/2026-09.md::2026-09-20 — Etapa 12b concluída: Spawn de Inimigos, Itens e Portas Canônicas da ROM

**Implementado:** ID aceito por valid_enemy_types e instanciado como EnemyGuard.

**Faltante / não comprovado:** Máquina ShooterWait/Walk/Shot/Hide e parâmetros por sala.

**Notas de evidência:** Extrator preserva ID/posição; teste de contrato não verifica esta variante. _ready/step_tick não despacham máquina própria para este ID.


<a id="switch-guards"></a>
### Guarda que corre para o interruptor

`switch-guards` · **PROVISIONAL**

**Original:** Patrulha, ida ao interruptor, espera e tiro.

**Classificação:** Existe entidade visível substituta, mas o caminho inspecionado usa comportamento genérico sem a máquina original.

**Assembly:** logic/actors/guardswitch.asm:29-62 GuardSwitchLogic

**Extractors:** tools/extractors/extract.py; tools/extractors/export_room_data.py

**Dados canônicos locais:** rooms/

**Godot relacionado:** godot/scripts/systems/enemy.gd

**Integração inspecionada:** godot/scripts/scenes/sandbox_gameplay.gd::_spawn_room_enemies

**Testes existentes:** tests/test_extractors.py

**Documentação:** docs/reverse_engineering/enemies.md; docs/reverse_engineering/stage-12b-actors-and-items-evidence.md

**Histórico consultado:** docs/progress/2026-09.md::2026-09-20 — Etapa 12b concluída: Spawn de Inimigos, Itens e Portas Canônicas da ROM

**Implementado:** ID aceito por valid_enemy_types e instanciado como EnemyGuard.

**Faltante / não comprovado:** Estados de acionamento do interruptor e relação com alarme.

**Notas de evidência:** Extrator preserva ID/posição; teste de contrato não verifica esta variante. _ready/step_tick não despacham máquina própria para este ID.


<a id="lorry-shooters"></a>
### Atiradores nos caminhões do deserto

`lorry-shooters` · **PROVISIONAL**

**Original:** Decidir tiro oculto, aparecer, sair, esperar e reentrar.

**Classificação:** Existe entidade visível substituta, mas o caminho inspecionado usa comportamento genérico sem a máquina original.

**Assembly:** logic/actors/lorryshooter.asm:41-88 LorryShooterLogic

**Extractors:** tools/extractors/extract.py; tools/extractors/export_room_data.py

**Dados canônicos locais:** rooms/

**Godot relacionado:** godot/scripts/systems/enemy.gd

**Integração inspecionada:** godot/scripts/scenes/sandbox_gameplay.gd::_spawn_room_enemies

**Testes existentes:** tests/test_extractors.py

**Documentação:** docs/reverse_engineering/enemies.md; docs/reverse_engineering/stage-12b-actors-and-items-evidence.md

**Histórico consultado:** docs/progress/2026-09.md::2026-09-20 — Etapa 12b concluída: Spawn de Inimigos, Itens e Portas Canônicas da ROM

**Implementado:** ID aceito por valid_enemy_types e instanciado como EnemyGuard.

**Faltante / não comprovado:** Ciclo LorryShooter de cinco estados e tiros próprios.

**Notas de evidência:** Extrator preserva ID/posição; teste de contrato não verifica esta variante. _ready/step_tick não despacham máquina própria para este ID.


<a id="scorpions"></a>
### Escorpiões

`scorpions` · **PROVISIONAL**

**Original:** Vagar, aproximar-se para ataque e esperar.

**Classificação:** Existe entidade visível substituta, mas o caminho inspecionado usa comportamento genérico sem a máquina original.

**Assembly:** logic/actors/scorpion.asm:26-74 ScorpionLogic

**Extractors:** tools/extractors/extract.py; tools/extractors/export_room_data.py

**Dados canônicos locais:** rooms/

**Godot relacionado:** godot/scripts/systems/enemy.gd

**Integração inspecionada:** godot/scripts/scenes/sandbox_gameplay.gd::_spawn_room_enemies

**Testes existentes:** tests/test_extractors.py

**Documentação:** docs/reverse_engineering/enemies.md; docs/reverse_engineering/stage-12b-actors-and-items-evidence.md

**Histórico consultado:** docs/progress/2026-09.md::2026-09-20 — Etapa 12b concluída: Spawn de Inimigos, Itens e Portas Canônicas da ROM

**Implementado:** ID aceito por valid_enemy_types e instanciado como EnemyGuard.

**Faltante / não comprovado:** Máquina, sprites e ataque de escorpião.

**Notas de evidência:** Extrator preserva ID/posição; teste de contrato não verifica esta variante. _ready/step_tick não despacham máquina própria para este ID.


<a id="desert-security"></a>
### Segurança do acesso ao edifício 2

`desert-security` · **PROVISIONAL**

**Original:** Inspecionar uniforme e liberar passagem ou disparar alerta.

**Classificação:** Existe entidade visível substituta, mas o caminho inspecionado usa comportamento genérico sem a máquina original.

**Assembly:** logic/actors/desertsecurity.asm:29-73 DesertSecurityLogic

**Extractors:** tools/extractors/extract.py; tools/extractors/export_room_data.py

**Dados canônicos locais:** rooms/

**Godot relacionado:** godot/scripts/systems/enemy.gd

**Integração inspecionada:** godot/scripts/scenes/sandbox_gameplay.gd::_spawn_room_enemies

**Testes existentes:** tests/test_extractors.py

**Documentação:** docs/reverse_engineering/enemies.md; docs/reverse_engineering/stage-12b-actors-and-items-evidence.md

**Histórico consultado:** docs/progress/2026-09.md::2026-09-20 — Etapa 12b concluída: Spawn de Inimigos, Itens e Portas Canônicas da ROM

**Implementado:** ID aceito por valid_enemy_types e instanciado como EnemyGuard.

**Faltante / não comprovado:** Inspeção de uniforme, fala e desaparecimento do controlador.

**Notas de evidência:** Extrator preserva ID/posição; teste de contrato não verifica esta variante. _ready/step_tick não despacham máquina própria para este ID.


<a id="sentinels"></a>
### Sentinelas com lista de direções

`sentinels` · **PROVISIONAL**

**Original:** Olhar conforme lista de direções, sono específico e transformação em alerta.

**Classificação:** Existe entidade visível substituta, mas o caminho inspecionado usa comportamento genérico sem a máquina original.

**Assembly:** logic/actors/sentinel.asm:58-94 SentinelLogic

**Extractors:** tools/extractors/extract.py; tools/extractors/export_room_data.py

**Dados canônicos locais:** rooms/

**Godot relacionado:** godot/scripts/systems/enemy.gd

**Integração inspecionada:** godot/scripts/scenes/sandbox_gameplay.gd::_spawn_room_enemies

**Testes existentes:** tests/test_extractors.py

**Documentação:** docs/reverse_engineering/enemies.md; docs/reverse_engineering/stage-12b-actors-and-items-evidence.md

**Histórico consultado:** docs/progress/2026-09.md::2026-09-20 — Etapa 12b concluída: Spawn de Inimigos, Itens e Portas Canônicas da ROM

**Implementado:** ID aceito por valid_enemy_types e instanciado como EnemyGuard.

**Faltante / não comprovado:** Direções e esperas próprias por sala, exceções da sala 69/140.

**Notas de evidência:** Extrator preserva ID/posição; teste de contrato não verifica esta variante. _ready/step_tick não despacham máquina própria para este ID.


<a id="silencer-guards"></a>
### Guardas da sala do silenciador

`silencer-guards` · **PARTIAL**

**Original:** Grupo de guardas com movimento/tiros próprios e obtenção do silenciador após derrota.

**Classificação:** Evento de recompensa integrado, mas IA específica incompleta.

**Assembly:** logic/actors/guardsupressor.asm:47-79 GuardSilencerLogic

**Extractors:** tools/extractors/extract.py; tools/extractors/export_room_data.py

**Dados canônicos locais:** rooms/

**Godot relacionado:** godot/scripts/systems/enemy.gd; godot/scripts/systems/item_box.gd

**Integração inspecionada:** godot/scripts/scenes/sandbox_gameplay.gd::_spawn_room_enemies

**Testes existentes:** godot-weapon-combat; godot-basement-and-plastic-bomb

**Documentação:** docs/reverse_engineering/enemies.md; docs/reverse_engineering/stage-12b-actors-and-items-evidence.md

**Histórico consultado:** docs/progress/2026-09.md::2026-09-20 — Etapa 12b concluída: Spawn de Inimigos, Itens e Portas Canônicas da ROM

**Implementado:** Grupo hostil/tiros e drop de silenciador após eliminar os guardas.

**Faltante / não comprovado:** Estados Idle/MovShot/Turn/Walk substituídos por patrulha/tiro genéricos.

**Notas de evidência:** A presença de is_shooter não equivale a GuardSilencerLogic.


<a id="basement-dogs"></a>
### Cães do subsolo

`basement-dogs` · **PROVISIONAL**

**Original:** Sono/corrida/perseguição e limites próprios do subsolo.

**Classificação:** init_dog sobrescreve actor_type_id para 25; não preserva a variante 27.

**Assembly:** logic/actors/dogbasement.asm:83-114 DogBasementLogic

**Extractors:** tools/extractors/extract.py; tools/extractors/export_room_data.py

**Dados canônicos locais:** rooms/

**Godot relacionado:** godot/scripts/systems/enemy.gd

**Integração inspecionada:** godot/scripts/scenes/sandbox_gameplay.gd::_spawn_room_enemies

**Testes existentes:** godot-dogs

**Documentação:** docs/reverse_engineering/enemies.md; docs/reverse_engineering/stage-12b-actors-and-items-evidence.md

**Histórico consultado:** docs/progress/2026-09.md::2026-09-20 — Etapa 12b concluída: Spawn de Inimigos, Itens e Portas Canônicas da ROM

**Implementado:** Spawn aceita 27, chama init_dog e usa sprite canino.

**Faltante / não comprovado:** DogBaseSleep/Run/Chase e migração entre salas.

**Notas de evidência:** Suíte godot-dogs cobre o cão comum, não a máquina do subsolo.


<a id="dog-spawner"></a>
### Gerador de cães entre salas

`dog-spawner` · **NOT_STARTED**

**Original:** Transportar NumBasementDogs e gerar cães com atraso na próxima sala.

**Classificação:** Rotina original identificada; IDs sem criação específica no dispatcher/geradores Godot inspecionados e nenhum sistema de comportamento correspondente no conjunto atual.

**Assembly:** logic/actors/dogspawner.asm:30-45 SpawnDogLogic

**Extractors:** tools/extractors/extract.py; tools/extractors/export_room_data.py

**Dados canônicos locais:** rooms/

**Godot relacionado:** godot/scripts/scenes/sandbox_gameplay.gd

**Integração inspecionada:** godot/scripts/scenes/sandbox_gameplay.gd::_spawn_room_enemies

**Testes existentes:** tests/test_extractors.py

**Documentação:** docs/reverse_engineering/enemies.md; docs/reverse_engineering/stage-12b-actors-and-items-evidence.md

**Histórico consultado:** docs/progress/2026-09.md::2026-09-20 — Etapa 12b concluída: Spawn de Inimigos, Itens e Portas Canônicas da ROM

**Implementado:** Nenhum localizado neste recorte.

**Faltante / não comprovado:** Transportar NumBasementDogs e gerar cães com atraso na próxima sala.

**Notas de evidência:** Somente metadados genéricos do ator são exportáveis; tests/test_extractors.py cobre o contrato de dados, não este comportamento. Busca cruzada em scripts/sistemas, cenas, testes, extractors e histórico de spawn: sem implementação específica; o filtro do sandbox descarta estes IDs.


<a id="jetpack-guards"></a>
### Soldados com jetpack e decolagem

`jetpack-guards` · **PROVISIONAL**

**Original:** Decolagem, ativação, voo orientado e disparos.

**Classificação:** Reforço 22 possui substituto genérico em execução, não comportamento aéreo.

**Assembly:** logic/actors/jetpack.asm:7-65 InitJetpackTakeoff; logic/actors/jetpack.asm:174-192 JetpackLogic

**Extractors:** tools/extractors/extract.py; tools/extractors/export_room_data.py; tools/extractors/extract_respawn_info.py

**Dados canônicos locais:** respawn_info.json

**Godot relacionado:** godot/scripts/systems/enemy.gd; godot/scripts/systems/alert_system.gd

**Integração inspecionada:** godot/scripts/scenes/sandbox_gameplay.gd::_on_reinforcement_requested

**Testes existentes:** godot-alert-system

**Documentação:** docs/reverse_engineering/stage-17-alert-evasion-reinforcements.md

**Histórico consultado:** docs/progress/2026-09.md::2026-09-20 — Etapa 17 concluída: Máquina de Estados de Alerta Global, Evasão e Reforços Militares

**Implementado:** RespawnInfo identifica ID 22; gerador produz EnemyGuard em ALERT para qualquer ID solicitado.

**Faltante / não comprovado:** Decolagem/voo/sprites/colisões/tiros específicos; tipos 20/21 ignorados no spawn de sala.

**Notas de evidência:** Teste do ID na tabela ou sinal de reforço não comprova implementação do voo.


<a id="bridges"></a>
### Pontes e controlador de trechos

`bridges` · **NOT_STARTED**

**Original:** Controlar trechos da ponte e sua progressão de estados.

**Classificação:** Rotina original identificada; IDs sem criação específica no dispatcher/geradores Godot inspecionados e nenhum sistema de comportamento correspondente no conjunto atual.

**Assembly:** logic/actors/bridge.asm:8-48 BridgeLogic

**Extractors:** tools/extractors/extract.py; tools/extractors/export_room_data.py

**Dados canônicos locais:** rooms/

**Godot relacionado:** godot/scripts/scenes/sandbox_gameplay.gd

**Integração inspecionada:** godot/scripts/scenes/sandbox_gameplay.gd::_spawn_room_enemies

**Testes existentes:** tests/test_extractors.py

**Documentação:** docs/reverse_engineering/enemies.md; docs/reverse_engineering/stage-12b-actors-and-items-evidence.md

**Histórico consultado:** docs/progress/2026-09.md::2026-09-20 — Etapa 12b concluída: Spawn de Inimigos, Itens e Portas Canônicas da ROM

**Implementado:** Nenhum localizado neste recorte.

**Faltante / não comprovado:** Controlar trechos da ponte e sua progressão de estados.

**Notas de evidência:** Somente metadados genéricos do ator são exportáveis; tests/test_extractors.py cobre o contrato de dados, não este comportamento. Busca cruzada em scripts/sistemas, cenas, testes, extractors e histórico de spawn: sem implementação específica; o filtro do sandbox descarta estes IDs.


<a id="enemy-mines"></a>
### Minas do cenário

`enemy-mines` · **NOT_STARTED**

**Original:** Minas de ator, detecção/visibilidade, contato e restauração de fundo; distinto da arma de minas no inventário.

**Classificação:** Rotina original identificada; IDs sem criação específica no dispatcher/geradores Godot inspecionados e nenhum sistema de comportamento correspondente no conjunto atual.

**Assembly:** logic/actors/mine.asm:7-27 InitMines

**Extractors:** tools/extractors/extract.py; tools/extractors/export_room_data.py

**Dados canônicos locais:** rooms/

**Godot relacionado:** godot/scripts/scenes/sandbox_gameplay.gd

**Integração inspecionada:** godot/scripts/scenes/sandbox_gameplay.gd::_spawn_room_enemies

**Testes existentes:** tests/test_extractors.py

**Documentação:** docs/reverse_engineering/enemies.md; docs/reverse_engineering/stage-12b-actors-and-items-evidence.md

**Histórico consultado:** docs/progress/2026-09.md::2026-09-20 — Etapa 12b concluída: Spawn de Inimigos, Itens e Portas Canônicas da ROM

**Implementado:** Nenhum localizado neste recorte.

**Faltante / não comprovado:** Minas de ator, detecção/visibilidade, contato e restauração de fundo; distinto da arma de minas no inventário.

**Notas de evidência:** Somente metadados genéricos do ator são exportáveis; tests/test_extractors.py cobre o contrato de dados, não este comportamento. Busca cruzada em scripts/sistemas, cenas, testes, extractors e histórico de spawn: sem implementação específica; o filtro do sandbox descarta estes IDs.


<a id="rolling-barrels"></a>
### Barris rolantes

`rolling-barrels` · **NOT_STARTED**

**Original:** Rolagem, animação, aceleração e ricochete em paredes.

**Classificação:** Rotina original identificada; IDs sem criação específica no dispatcher/geradores Godot inspecionados e nenhum sistema de comportamento correspondente no conjunto atual.

**Assembly:** logic/actors/rollingbarrels.asm:8-37 RollingBarrelLogic

**Extractors:** tools/extractors/extract.py; tools/extractors/export_room_data.py

**Dados canônicos locais:** rooms/

**Godot relacionado:** godot/scripts/scenes/sandbox_gameplay.gd

**Integração inspecionada:** godot/scripts/scenes/sandbox_gameplay.gd::_spawn_room_enemies

**Testes existentes:** tests/test_extractors.py

**Documentação:** docs/reverse_engineering/enemies.md; docs/reverse_engineering/stage-12b-actors-and-items-evidence.md

**Histórico consultado:** docs/progress/2026-09.md::2026-09-20 — Etapa 12b concluída: Spawn de Inimigos, Itens e Portas Canônicas da ROM

**Implementado:** Nenhum localizado neste recorte.

**Faltante / não comprovado:** Rolagem, animação, aceleração e ricochete em paredes.

**Notas de evidência:** Somente metadados genéricos do ator são exportáveis; tests/test_extractors.py cobre o contrato de dados, não este comportamento. Busca cruzada em scripts/sistemas, cenas, testes, extractors e histórico de spawn: sem implementação específica; o filtro do sandbox descarta estes IDs.


<a id="pitfalls"></a>
### Alçapões de ator

`pitfalls` · **NOT_STARTED**

**Original:** Contato abre progressivamente o buraco e participa da queda do jogador.

**Classificação:** Rotina original identificada; IDs sem criação específica no dispatcher/geradores Godot inspecionados e nenhum sistema de comportamento correspondente no conjunto atual.

**Assembly:** logic/actors/pitfall.asm:7-51 PitfallLogic

**Extractors:** tools/extractors/extract.py; tools/extractors/export_room_data.py

**Dados canônicos locais:** rooms/

**Godot relacionado:** godot/scripts/scenes/sandbox_gameplay.gd

**Integração inspecionada:** godot/scripts/scenes/sandbox_gameplay.gd::_spawn_room_enemies

**Testes existentes:** tests/test_extractors.py

**Documentação:** docs/reverse_engineering/enemies.md; docs/reverse_engineering/stage-12b-actors-and-items-evidence.md

**Histórico consultado:** docs/progress/2026-09.md::2026-09-20 — Etapa 12b concluída: Spawn de Inimigos, Itens e Portas Canônicas da ROM

**Implementado:** Nenhum localizado neste recorte.

**Faltante / não comprovado:** Contato abre progressivamente o buraco e participa da queda do jogador.

**Notas de evidência:** Somente metadados genéricos do ator são exportáveis; tests/test_extractors.py cobre o contrato de dados, não este comportamento. Busca cruzada em scripts/sistemas, cenas, testes, extractors e histórico de spawn: sem implementação específica; o filtro do sandbox descarta estes IDs.


<a id="shell-barrage"></a>
### Bombardeio e gerador de projéteis aéreos

`shell-barrage` · **NOT_STARTED**

**Original:** Gerar projéteis cadenciados que caem no deserto, com fase de som e explosão.

**Classificação:** Rotina original identificada; IDs sem criação específica no dispatcher/geradores Godot inspecionados e nenhum sistema de comportamento correspondente no conjunto atual.

**Assembly:** logic/actors/tankshell.asm:9-26 InitTankShell; logic/actors/shellspawner.asm:28-55 SpawnTankShell

**Extractors:** tools/extractors/extract.py; tools/extractors/export_room_data.py

**Dados canônicos locais:** rooms/

**Godot relacionado:** godot/scripts/scenes/sandbox_gameplay.gd

**Integração inspecionada:** godot/scripts/scenes/sandbox_gameplay.gd::_spawn_room_enemies

**Testes existentes:** tests/test_extractors.py

**Documentação:** docs/reverse_engineering/enemies.md; docs/reverse_engineering/stage-12b-actors-and-items-evidence.md

**Histórico consultado:** docs/progress/2026-09.md::2026-09-20 — Etapa 12b concluída: Spawn de Inimigos, Itens e Portas Canônicas da ROM

**Implementado:** Nenhum localizado neste recorte.

**Faltante / não comprovado:** Gerar projéteis cadenciados que caem no deserto, com fase de som e explosão.

**Notas de evidência:** Somente metadados genéricos do ator são exportáveis; tests/test_extractors.py cobre o contrato de dados, não este comportamento. Busca cruzada em scripts/sistemas, cenas, testes, extractors e histórico de spawn: sem implementação específica; o filtro do sandbox descarta estes IDs.


<a id="actor-camera"></a>
### Câmera de vigilância comum

`actor-camera` · **PARTIAL**

**Original:** Movimento por rota, espera, visão e alarme; renderização própria.

**Classificação:** Sensor integrado, sem completar visual e todos os parâmetros da rotina.

**Assembly:** logic/actors/camera.asm:129-186 CameraLogic; logic/actors/rendercameras.asm:8-42 RenderCamera

**Extractors:** tools/extractors/extract.py; tools/extractors/export_room_data.py

**Dados canônicos locais:** rooms/

**Godot relacionado:** godot/scripts/systems/security_camera.gd

**Integração inspecionada:** godot/scripts/scenes/sandbox_gameplay.gd::_spawn_room_enemies; godot/scripts/scenes/sandbox_gameplay.gd::_on_camera_detected

**Testes existentes:** godot-cameras-and-lasers

**Documentação:** docs/reverse_engineering/enemies.md; docs/reverse_engineering/stage-12b-actors-and-items-evidence.md

**Histórico consultado:** docs/progress/2026-09.md::[Recalibração Canônica] - Velocidade das Câmeras de Vigilância (Security Cameras) na Sala 031 e Complexo

**Implementado:** SecurityCamera com movimento, visão, caixa e alerta; teste dedicado.

**Faltante / não comprovado:** Desenho ainda procedural; espera fixa no Godot e integração visual original incompleta.

**Notas de evidência:** Não cobre câmera armada ID 53.


<a id="laser-cameras"></a>
### Câmeras armadas e seus lasers

`laser-cameras` · **NOT_STARTED**

**Original:** Detecção, parada para disparar, extensão/retração do laser e variante de comprimento da sala 111.

**Classificação:** Rotina original identificada; IDs sem criação específica no dispatcher/geradores Godot inspecionados e nenhum sistema de comportamento correspondente no conjunto atual.

**Assembly:** logic/actors/camera.asm:248-275 LaserCameraLogic; logic/actors/lasershot.asm:7-32 InitLaserShot

**Extractors:** tools/extractors/extract.py; tools/extractors/export_room_data.py

**Dados canônicos locais:** rooms/

**Godot relacionado:** godot/scripts/scenes/sandbox_gameplay.gd

**Integração inspecionada:** godot/scripts/scenes/sandbox_gameplay.gd::_spawn_room_enemies

**Testes existentes:** tests/test_extractors.py

**Documentação:** docs/reverse_engineering/enemies.md; docs/reverse_engineering/stage-12b-actors-and-items-evidence.md

**Histórico consultado:** docs/progress/2026-09.md::2026-09-20 — Etapa 12b concluída: Spawn de Inimigos, Itens e Portas Canônicas da ROM

**Implementado:** Nenhum localizado neste recorte.

**Faltante / não comprovado:** Detecção, parada para disparar, extensão/retração do laser e variante de comprimento da sala 111.

**Notas de evidência:** Somente metadados genéricos do ator são exportáveis; tests/test_extractors.py cobre o contrato de dados, não este comportamento. Busca cruzada em scripts/sistemas, cenas, testes, extractors e histórico de spawn: sem implementação específica; o filtro do sandbox descarta estes IDs.


<a id="actor-lasers"></a>
### Controlador de feixes móveis

`actor-lasers` · **PARTIAL**

**Original:** Controlar feixes móveis da sala, visibilidade e contato/alarme.

**Classificação:** Implementação por sistema de sala pode representar o ator sem classe própria, mas não prova todas as variantes.

**Assembly:** Banks0123.asm:5653-5680 InitLaserRoom; logic/laserbeams.asm:11-68 ChkTouchLaser

**Extractors:** tools/extractors/extract.py; tools/extractors/export_room_data.py

**Dados canônicos locais:** rooms/

**Godot relacionado:** godot/scripts/systems/laser_system.gd

**Integração inspecionada:** godot/scripts/scenes/sandbox_gameplay.gd::_on_laser_triggered; godot/scripts/scenes/sandbox_gameplay.gd::_spawn_room_enemies

**Testes existentes:** godot-cameras-and-lasers

**Documentação:** docs/reverse_engineering/enemies.md; docs/reverse_engineering/stage-12b-actors-and-items-evidence.md

**Histórico consultado:** docs/progress/2026-09.md::2026-09-20 — Etapa 16 concluída: Câmeras de Vigilância e Feixes Laser Infravermelhos

**Implementado:** LaserSystem acionado por sala, contato e óculos; testes.

**Faltante / não comprovado:** Composição e temporização integral das configurações originais ainda não verificadas.

**Notas de evidência:** Escopo restrito ao controlador de ator; câmera que dispara laser é outra família.


<a id="actor-gas"></a>
### Nuvens de gás

`actor-gas` · **PARTIAL**

**Original:** Alternância oculta/visível e animação de dois sprites.

**Classificação:** Ciclo visual parcial; não confundir testes de máscara/dano global com fidelidade do ator visual.

**Assembly:** logic/actors/gas.asm:7-53 InitGas

**Extractors:** tools/extractors/extract.py; tools/extractors/export_room_data.py; tools/extractors/extract_gas_hazard.py

**Dados canônicos locais:** rooms/

**Godot relacionado:** godot/scripts/systems/gas_cloud.gd; godot/scripts/systems/gas_hazard_system.gd

**Integração inspecionada:** godot/scripts/scenes/sandbox_gameplay.gd::_spawn_room_enemies

**Testes existentes:** godot-gas-hazard

**Documentação:** docs/reverse_engineering/stage-19-gas-hazard.md

**Histórico consultado:** docs/progress/2026-09.md::2026-09-20 — Etapa 12b concluída: Spawn de Inimigos, Itens e Portas Canônicas da ROM

**Implementado:** GasCloud alterna fases e quadros; integração nas salas com ID 8.

**Faltante / não comprovado:** Imagem procedural; intervalos randômicos 10–40/20–60 diferem da inicialização via registrador R.

**Notas de evidência:** gas.asm configura colisão zero para o ator visual; dano global é outra mecânica.


<a id="actor-power-switch"></a>
### Painel de força e pulsação da paleta

`actor-power-switch` · **PARTIAL**

**Original:** Painel destrutível e atualização da paleta do piso por brilho.

**Classificação:** Interação implementada, apresentação e paleta original incompletas.

**Assembly:** logic/actors/powerswitch.asm:7-67 InitPowerSwitch

**Extractors:** tools/extractors/extract.py; tools/extractors/export_room_data.py; tools/extractors/extract_electrified_floor_data.py

**Dados canônicos locais:** rooms/

**Godot relacionado:** godot/scripts/systems/power_panel.gd; godot/scripts/systems/electrified_floor_system.gd

**Integração inspecionada:** godot/scripts/scenes/sandbox_gameplay.gd::_spawn_room_power_panel

**Testes existentes:** godot-electrified-floor

**Documentação:** docs/reverse_engineering/enemies.md; docs/reverse_engineering/stage-12b-actors-and-items-evidence.md

**Histórico consultado:** docs/progress/2026-09.md::2026-09-20 — Etapa 12b concluída: Spawn de Inimigos, Itens e Portas Canônicas da ROM

**Implementado:** PowerPanel, dano por míssil e estado desligado integrado ao piso.

**Faltante / não comprovado:** Arte procedural; alteração global da paleta e todos os limites de brilho não demonstrados equivalentes.

**Notas de evidência:** O teste da lógica do piso não equivale a comparação visual do painel original.


<a id="capture-guards"></a>
### Guardas da sequência de captura

`capture-guards` · **PARTIAL**

**Original:** Adicionar guarda B, aproximar de Snake, falar e aguardar a captura.

**Classificação:** Ator representado por cutscene dedicada; cobertura parcial da sequência completa.

**Assembly:** logic/capturescene.asm:141-159 CaptureGuardsLogic

**Extractors:** tools/extractors/extract.py; tools/extractors/export_room_data.py; tools/extractors/extract_capture_prison_data.py

**Dados canônicos locais:** rooms/

**Godot relacionado:** godot/scripts/systems/capture_cutscene.gd; godot/scripts/systems/capture_system.gd

**Integração inspecionada:** godot/scripts/scenes/sandbox_gameplay.gd::_trigger_capture_event

**Testes existentes:** godot-capture-prison

**Documentação:** docs/reverse_engineering/prison-wall.md

**Histórico consultado:** docs/progress/2026-09.md::2026-09-20 — Etapa 12b concluída: Spawn de Inimigos, Itens e Portas Canônicas da ROM

**Implementado:** CaptureCutscene/CaptureSystem coordenam os dois guardas e prisão; testes.

**Faltante / não comprovado:** Comparação de todos os ticks e texto/apresentação com a sequência inglesa ainda pendente; aliases 211/212 conflitam com salas reais.

**Notas de evidência:** Este item audita os guardas da cutscene, não reaudita paredes/bolsa.


<a id="guard-projectiles"></a>
### Projéteis comuns e variantes horizontal/vertical/mirada

`guard-projectiles` · **PARTIAL**

**Original:** Bala de guarda, disparos nos eixos com dispersão e disparo orientado ao jogador.

**Classificação:** Bala genérica existe, mas não representa todas as variantes do despacho.

**Assembly:** logic/actors/guardshot.asm:9-19 InitGuardShot; logic/actors/bullethv.asm:9-45 InitBulletHor; logic/actors/shottoplayer.asm:7-14 InitShotToPlayer

**Extractors:** tools/extractors/extract.py; tools/extractors/export_room_data.py

**Dados canônicos locais:** rooms/

**Godot relacionado:** godot/scripts/systems/bullet.gd; godot/scripts/systems/enemy.gd

**Integração inspecionada:** godot/scripts/scenes/sandbox_gameplay.gd::_spawn_room_enemies

**Testes existentes:** godot-combat-health; godot-weapon-combat

**Documentação:** docs/reverse_engineering/enemies.md; docs/reverse_engineering/stage-12b-actors-and-items-evidence.md

**Histórico consultado:** docs/progress/2026-09.md::2026-09-20 — Etapa 12b concluída: Spawn de Inimigos, Itens e Portas Canônicas da ROM

**Implementado:** Bullet cardinal criado por EnemyGuard, contato, dano e remoção.

**Faltante / não comprovado:** Identidade e trajetórias de 58/59/61 não portadas por seus inicializadores; dispersão e cálculo de mira originais faltam.

**Notas de evidência:** try_shoot define velocidade/duração/dano comuns; testes de arma do jogador não cobrem todos os projéteis inimigos.


<a id="tank"></a>
### Tanque e seus disparos

`tank` · **NOT_STARTED**

**Original:** Canhão alinhado ao jogador, rajadas laterais, tiros de tanque e derrota/persistência.

**Classificação:** Rotina original identificada; IDs sem criação específica no dispatcher/geradores Godot inspecionados e nenhum sistema de comportamento correspondente no conjunto atual.

**Assembly:** logic/actors/tank.asm:45-79 TankLogic; logic/actors/tankshot.asm:7-40 InitTankShellBoss

**Extractors:** tools/extractors/extract.py; tools/extractors/export_room_data.py

**Dados canônicos locais:** rooms/

**Godot relacionado:** godot/scripts/scenes/sandbox_gameplay.gd

**Integração inspecionada:** godot/scripts/scenes/sandbox_gameplay.gd::_spawn_room_enemies

**Testes existentes:** tests/test_extractors.py

**Documentação:** docs/reverse_engineering/enemies.md; docs/reverse_engineering/stage-12b-actors-and-items-evidence.md

**Histórico consultado:** docs/progress/2026-09.md::2026-09-20 — Etapa 12b concluída: Spawn de Inimigos, Itens e Portas Canônicas da ROM

**Implementado:** Nenhum localizado neste recorte.

**Faltante / não comprovado:** Canhão alinhado ao jogador, rajadas laterais, tiros de tanque e derrota/persistência.

**Notas de evidência:** Somente metadados genéricos do ator são exportáveis; tests/test_extractors.py cobre o contrato de dados, não este comportamento. Busca cruzada em scripts/sistemas, cenas, testes, extractors e histórico de spawn: sem implementação específica; o filtro do sandbox descarta estes IDs.


<a id="bulldozer"></a>
### Bulldozer

`bulldozer` · **NOT_STARTED**

**Original:** Avanço, três pausas/velocidades e parada ao alcançar limite.

**Classificação:** Rotina original identificada; IDs sem criação específica no dispatcher/geradores Godot inspecionados e nenhum sistema de comportamento correspondente no conjunto atual.

**Assembly:** logic/actors/bulldozer.asm:8-71 BulldozerLogic

**Extractors:** tools/extractors/extract.py; tools/extractors/export_room_data.py

**Dados canônicos locais:** rooms/

**Godot relacionado:** godot/scripts/scenes/sandbox_gameplay.gd

**Integração inspecionada:** godot/scripts/scenes/sandbox_gameplay.gd::_spawn_room_enemies

**Testes existentes:** tests/test_extractors.py

**Documentação:** docs/reverse_engineering/enemies.md; docs/reverse_engineering/stage-12b-actors-and-items-evidence.md

**Histórico consultado:** docs/progress/2026-09.md::2026-09-20 — Etapa 12b concluída: Spawn de Inimigos, Itens e Portas Canônicas da ROM

**Implementado:** Nenhum localizado neste recorte.

**Faltante / não comprovado:** Avanço, três pausas/velocidades e parada ao alcançar limite.

**Notas de evidência:** Somente metadados genéricos do ator são exportáveis; tests/test_extractors.py cobre o contrato de dados, não este comportamento. Busca cruzada em scripts/sistemas, cenas, testes, extractors e histórico de spawn: sem implementação específica; o filtro do sandbox descarta estes IDs.


<a id="arnold"></a>
### Arnold

`arnold` · **NOT_STARTED**

**Original:** Vigiar, correr ao jogador, retornar e reagir a projéteis.

**Classificação:** Rotina original identificada; IDs sem criação específica no dispatcher/geradores Godot inspecionados e nenhum sistema de comportamento correspondente no conjunto atual.

**Assembly:** logic/actors/arnold.asm:32-71 ArnoldLogic

**Extractors:** tools/extractors/extract.py; tools/extractors/export_room_data.py

**Dados canônicos locais:** rooms/

**Godot relacionado:** godot/scripts/scenes/sandbox_gameplay.gd

**Integração inspecionada:** godot/scripts/scenes/sandbox_gameplay.gd::_spawn_room_enemies

**Testes existentes:** tests/test_extractors.py

**Documentação:** docs/reverse_engineering/enemies.md; docs/reverse_engineering/stage-12b-actors-and-items-evidence.md

**Histórico consultado:** docs/progress/2026-09.md::2026-09-20 — Etapa 12b concluída: Spawn de Inimigos, Itens e Portas Canônicas da ROM

**Implementado:** Nenhum localizado neste recorte.

**Faltante / não comprovado:** Vigiar, correr ao jogador, retornar e reagir a projéteis.

**Notas de evidência:** Somente metadados genéricos do ator são exportáveis; tests/test_extractors.py cobre o contrato de dados, não este comportamento. Busca cruzada em scripts/sistemas, cenas, testes, extractors e histórico de spawn: sem implementação específica; o filtro do sandbox descarta estes IDs.


<a id="big-boss"></a>
### Big Boss em combate

`big-boss` · **NOT_STARTED**

**Original:** Discurso, decisão, corrida, saída da cobertura, tiro e retorno à cobertura.

**Classificação:** Rotina original identificada; IDs sem criação específica no dispatcher/geradores Godot inspecionados e nenhum sistema de comportamento correspondente no conjunto atual.

**Assembly:** logic/actors/bigboss.asm:27-69 BigBossLogic

**Extractors:** tools/extractors/extract.py; tools/extractors/export_room_data.py

**Dados canônicos locais:** rooms/

**Godot relacionado:** godot/scripts/scenes/sandbox_gameplay.gd

**Integração inspecionada:** godot/scripts/scenes/sandbox_gameplay.gd::_spawn_room_enemies

**Testes existentes:** tests/test_extractors.py

**Documentação:** docs/reverse_engineering/enemies.md; docs/reverse_engineering/stage-12b-actors-and-items-evidence.md

**Histórico consultado:** docs/progress/2026-09.md::2026-09-20 — Etapa 12b concluída: Spawn de Inimigos, Itens e Portas Canônicas da ROM

**Implementado:** Nenhum localizado neste recorte.

**Faltante / não comprovado:** Discurso, decisão, corrida, saída da cobertura, tiro e retorno à cobertura.

**Notas de evidência:** Somente metadados genéricos do ator são exportáveis; tests/test_extractors.py cobre o contrato de dados, não este comportamento. Busca cruzada em scripts/sistemas, cenas, testes, extractors e histórico de spawn: sem implementação específica; o filtro do sandbox descarta estes IDs.


<a id="machine-gun-kid"></a>
### Machine Gun Kid e rajadas

`machine-gun-kid` · **NOT_STARTED**

**Original:** Apresentação, escolha de movimento, posição de tiro/abrigo e projétil específico.

**Classificação:** Rotina original identificada; IDs sem criação específica no dispatcher/geradores Godot inspecionados e nenhum sistema de comportamento correspondente no conjunto atual.

**Assembly:** logic/actors/machinegunkid.asm:26-56 MachGunKidLogic; logic/actors/machinegunkid.asm:287-305 InitMGunKidShot

**Extractors:** tools/extractors/extract.py; tools/extractors/export_room_data.py

**Dados canônicos locais:** rooms/

**Godot relacionado:** godot/scripts/scenes/sandbox_gameplay.gd

**Integração inspecionada:** godot/scripts/scenes/sandbox_gameplay.gd::_spawn_room_enemies

**Testes existentes:** tests/test_extractors.py

**Documentação:** docs/reverse_engineering/enemies.md; docs/reverse_engineering/stage-12b-actors-and-items-evidence.md

**Histórico consultado:** docs/progress/2026-09.md::2026-09-20 — Etapa 12b concluída: Spawn de Inimigos, Itens e Portas Canônicas da ROM

**Implementado:** Nenhum localizado neste recorte.

**Faltante / não comprovado:** Apresentação, escolha de movimento, posição de tiro/abrigo e projétil específico.

**Notas de evidência:** Somente metadados genéricos do ator são exportáveis; tests/test_extractors.py cobre o contrato de dados, não este comportamento. Busca cruzada em scripts/sistemas, cenas, testes, extractors e histórico de spawn: sem implementação específica; o filtro do sandbox descarta estes IDs.


<a id="fire-trooper"></a>
### Fire Trooper e chamas

`fire-trooper` · **NOT_STARTED**

**Original:** Introdução, gestão de chamas e movimento/ataque das chamas.

**Classificação:** Rotina original identificada; IDs sem criação específica no dispatcher/geradores Godot inspecionados e nenhum sistema de comportamento correspondente no conjunto atual.

**Assembly:** logic/actors/firetropper.asm:7-48 FireTrooperLoogic; logic/actors/flame.asm:7-39 InitFlame

**Extractors:** tools/extractors/extract.py; tools/extractors/export_room_data.py

**Dados canônicos locais:** rooms/

**Godot relacionado:** godot/scripts/scenes/sandbox_gameplay.gd

**Integração inspecionada:** godot/scripts/scenes/sandbox_gameplay.gd::_spawn_room_enemies

**Testes existentes:** tests/test_extractors.py

**Documentação:** docs/reverse_engineering/enemies.md; docs/reverse_engineering/stage-12b-actors-and-items-evidence.md

**Histórico consultado:** docs/progress/2026-09.md::2026-09-20 — Etapa 12b concluída: Spawn de Inimigos, Itens e Portas Canônicas da ROM

**Implementado:** Nenhum localizado neste recorte.

**Faltante / não comprovado:** Introdução, gestão de chamas e movimento/ataque das chamas.

**Notas de evidência:** Somente metadados genéricos do ator são exportáveis; tests/test_extractors.py cobre o contrato de dados, não este comportamento. Busca cruzada em scripts/sistemas, cenas, testes, extractors e histórico de spawn: sem implementação específica; o filtro do sandbox descarta estes IDs.


<a id="hind-d"></a>
### Hind D

`hind-d` · **NOT_STARTED**

**Original:** Hélice animada, rajadas, pausas e integração de derrota do helicóptero.

**Classificação:** Rotina original identificada; IDs sem criação específica no dispatcher/geradores Godot inspecionados e nenhum sistema de comportamento correspondente no conjunto atual.

**Assembly:** logic/actors/hindd.asm:43-81 HindDLogic

**Extractors:** tools/extractors/extract.py; tools/extractors/export_room_data.py

**Dados canônicos locais:** rooms/

**Godot relacionado:** godot/scripts/scenes/sandbox_gameplay.gd

**Integração inspecionada:** godot/scripts/scenes/sandbox_gameplay.gd::_spawn_room_enemies

**Testes existentes:** tests/test_extractors.py

**Documentação:** docs/reverse_engineering/enemies.md; docs/reverse_engineering/stage-12b-actors-and-items-evidence.md

**Histórico consultado:** docs/progress/2026-09.md::2026-09-20 — Etapa 12b concluída: Spawn de Inimigos, Itens e Portas Canônicas da ROM

**Implementado:** Nenhum localizado neste recorte.

**Faltante / não comprovado:** Hélice animada, rajadas, pausas e integração de derrota do helicóptero.

**Notas de evidência:** Somente metadados genéricos do ator são exportáveis; tests/test_extractors.py cobre o contrato de dados, não este comportamento. Busca cruzada em scripts/sistemas, cenas, testes, extractors e histórico de spawn: sem implementação específica; o filtro do sandbox descarta estes IDs.


<a id="coward-duck"></a>
### Coward Duck e bumerangues

`coward-duck` · **NOT_STARTED**

**Original:** Discurso, deslocamento lateral, lançamento/retorno de bumerangues e luta junto dos reféns.

**Classificação:** Rotina original identificada; IDs sem criação específica no dispatcher/geradores Godot inspecionados e nenhum sistema de comportamento correspondente no conjunto atual.

**Assembly:** logic/actors/cowardduck.asm:12-45 CowardDuckLogic; logic/actors/cowardduck.asm:160-173 InitBoomerang

**Extractors:** tools/extractors/extract.py; tools/extractors/export_room_data.py

**Dados canônicos locais:** rooms/

**Godot relacionado:** godot/scripts/scenes/sandbox_gameplay.gd

**Integração inspecionada:** godot/scripts/scenes/sandbox_gameplay.gd::_spawn_room_enemies

**Testes existentes:** tests/test_extractors.py

**Documentação:** docs/reverse_engineering/enemies.md; docs/reverse_engineering/stage-12b-actors-and-items-evidence.md

**Histórico consultado:** docs/progress/2026-09.md::2026-09-20 — Etapa 12b concluída: Spawn de Inimigos, Itens e Portas Canônicas da ROM

**Implementado:** Nenhum localizado neste recorte.

**Faltante / não comprovado:** Discurso, deslocamento lateral, lançamento/retorno de bumerangues e luta junto dos reféns.

**Notas de evidência:** Somente metadados genéricos do ator são exportáveis; tests/test_extractors.py cobre o contrato de dados, não este comportamento. Busca cruzada em scripts/sistemas, cenas, testes, extractors e histórico de spawn: sem implementação específica; o filtro do sandbox descarta estes IDs.


<a id="metal-gear-boss"></a>
### Metal Gear, sequência de bombas e destruição

`metal-gear-boss` · **NOT_STARTED**

**Original:** Entidade Metal Gear, ordem das bombas, morte das câmeras associadas e destruição.

**Classificação:** Rotina original identificada; IDs sem criação específica no dispatcher/geradores Godot inspecionados e nenhum sistema de comportamento correspondente no conjunto atual.

**Assembly:** BanksABC.asm:36-58 InitMetalGear_; logic/damagetoenemy.asm:189-223 ChkBombOrder

**Extractors:** tools/extractors/extract.py; tools/extractors/export_room_data.py

**Dados canônicos locais:** rooms/

**Godot relacionado:** godot/scripts/scenes/sandbox_gameplay.gd

**Integração inspecionada:** godot/scripts/scenes/sandbox_gameplay.gd::_spawn_room_enemies

**Testes existentes:** tests/test_extractors.py

**Documentação:** docs/reverse_engineering/enemies.md; docs/reverse_engineering/stage-12b-actors-and-items-evidence.md

**Histórico consultado:** docs/progress/2026-09.md::2026-09-20 — Etapa 12b concluída: Spawn de Inimigos, Itens e Portas Canônicas da ROM

**Implementado:** Nenhum localizado neste recorte.

**Faltante / não comprovado:** Entidade Metal Gear, ordem das bombas, morte das câmeras associadas e destruição.

**Notas de evidência:** Somente metadados genéricos do ator são exportáveis; tests/test_extractors.py cobre o contrato de dados, não este comportamento. Busca cruzada em scripts/sistemas, cenas, testes, extractors e histórico de spawn: sem implementação específica; o filtro do sandbox descarta estes IDs.


<a id="ellen"></a>
### Ellen como refém

`ellen` · **PARTIAL**

**Original:** Resgate na sala 167, texto 129 e flag utilizada por Madnar.

**Classificação:** NPC reconhecido, mas a condição narrativa dependente não está implementada.

**Assembly:** logic/actors/prisoner.asm:212-223 PrisonerRescued

**Extractors:** tools/extractors/extract.py; tools/extractors/export_room_data.py; tools/extractors/extract_prisoner_sprites.py

**Dados canônicos locais:** rooms/

**Godot relacionado:** godot/scripts/systems/prisoner.gd; godot/scripts/systems/rank_system.gd

**Integração inspecionada:** godot/scripts/scenes/sandbox_gameplay.gd::_spawn_room_prisoners

**Testes existentes:** godot-rank-and-prisoners; tests/test_prisoner_sprite_extractor.py

**Documentação:** docs/reverse_engineering/enemies.md; docs/reverse_engineering/stage-12b-actors-and-items-evidence.md

**Histórico consultado:** docs/progress/2026-09.md::2026-09-21 — Etapa 19: Sistema de Prisioneiros, Reféns e Patente Militar (Ranks ★1 a ★4)

**Implementado:** Identidade, sprite próprio, resgate e sinalização de morte vital.

**Faltante / não comprovado:** Texto canônico paginado e consumo da flag de Ellen na conversa de Madnar.

**Notas de evidência:** Não declarar a cadeia Ellen→Madnar completa a partir de is_vital.


<a id="ellen-help"></a>
### Pedido de ajuda periódico de Ellen

`ellen-help` · **NOT_STARTED**

**Original:** Ator de mensagem periódica texto 128, com contador próprio.

**Classificação:** Rotina original identificada; IDs sem criação específica no dispatcher/geradores Godot inspecionados e nenhum sistema de comportamento correspondente no conjunto atual.

**Assembly:** logic/actors/prisoner.asm:105-112 ChkSayHelpMe

**Extractors:** tools/extractors/extract.py; tools/extractors/export_room_data.py

**Dados canônicos locais:** rooms/

**Godot relacionado:** godot/scripts/scenes/sandbox_gameplay.gd

**Integração inspecionada:** godot/scripts/scenes/sandbox_gameplay.gd::_spawn_room_enemies

**Testes existentes:** tests/test_extractors.py

**Documentação:** docs/reverse_engineering/enemies.md; docs/reverse_engineering/stage-12b-actors-and-items-evidence.md

**Histórico consultado:** docs/progress/2026-09.md::2026-09-20 — Etapa 12b concluída: Spawn de Inimigos, Itens e Portas Canônicas da ROM

**Implementado:** Nenhum localizado neste recorte.

**Faltante / não comprovado:** Ator de mensagem periódica texto 128, com contador próprio.

**Notas de evidência:** Somente metadados genéricos do ator são exportáveis; tests/test_extractors.py cobre o contrato de dados, não este comportamento. Busca cruzada em scripts/sistemas, cenas, testes, extractors e histórico de spawn: sem implementação específica; o filtro do sandbox descarta estes IDs.


<a id="grey-fox"></a>
### Grey Fox: resgate e diálogo inglês

`grey-fox` · **PARTIAL**

**Original:** Libertação, texto 59, janela modal/páginas, SFX e persistência de resgate.

**Classificação:** Cadeia principal verificada; limitações concretas impedem declarar o ator completo 1:1.

**Assembly:** logic/actors/prisoner.asm:244-277 RescuedLogic3; Banks0123.asm:7952-8043 TW_PrintChar

**Extractors:** tools/extractors/extract.py; tools/extractors/export_room_data.py; tools/extractors/extract_grey_fox_dialogue.py; tools/extractors/extract_prisoner_sprites.py

**Dados canônicos locais:** dialogues/

**Godot relacionado:** godot/scripts/systems/prisoner.gd; godot/scripts/systems/prisoner_dialog.gd; godot/scripts/systems/rank_system.gd

**Integração inspecionada:** godot/scripts/scenes/sandbox_gameplay.gd::_on_prisoner_rescued

**Testes existentes:** godot-prisoner-dialog; tests/test_grey_fox_dialogue.py

**Documentação:** docs/reverse_engineering/grey-fox-dialogue.md; docs/reverse_engineering/en-eu-reextraction.md

**Histórico consultado:** docs/progress/2026-10.md::2026-10-03 — Correções de fidelidade do resgate e da janela de Grey Fox

**Implementado:** Texto inglês extraído da ROM canônica, dez páginas, fonte, modal, atraso do ator e testes de render/integração.

**Faltante / não comprovado:** SFX de digitação e comprovação dinâmica audiovisual; conflito de aliases da prisão permanece.

**Notas de evidência:** A etapa antiga usava só a fonte inglesa; a migração canônica posterior alterou a proveniência.


<a id="madnar"></a>
### Dr. Pettrovich Madnar

`madnar` · **PROVISIONAL**

**Original:** Conversa condicionada ao resgate de Ellen, textos 124/125 e flags específicas.

**Classificação:** A classe não despacha MadnarLogic; apenas personaliza um refém genérico.

**Assembly:** logic/actors/prisoner.asm:151-168 MadnarLogic

**Extractors:** tools/extractors/extract.py; tools/extractors/export_room_data.py; tools/extractors/extract_prisoner_sprites.py

**Dados canônicos locais:** rooms/

**Godot relacionado:** godot/scripts/systems/prisoner.gd; godot/scripts/systems/rank_system.gd

**Integração inspecionada:** godot/scripts/scenes/sandbox_gameplay.gd::_spawn_room_prisoners; godot/scripts/scenes/sandbox_gameplay.gd::_on_prisoner_rescued

**Testes existentes:** godot-rank-and-prisoners

**Documentação:** docs/reverse_engineering/enemies.md; docs/reverse_engineering/stage-12b-actors-and-items-evidence.md

**Histórico consultado:** docs/progress/2026-09.md::2026-09-21 — Etapa 19: Sistema de Prisioneiros, Reféns e Patente Militar (Ranks ★1 a ★4)

**Implementado:** Tipo, nome e sprite de Madnar em Prisoner; resgate genérico.

**Faltante / não comprovado:** Condição de Ellen, textos alternativos e semântica de resgate/repetição.

**Notas de evidência:** Texto hardcoded não comprova o evento original.


<a id="fake-madnar"></a>
### Fake Madnar e armadilha

`fake-madnar` · **PROVISIONAL**

**Original:** Espera pelo toque, fala, cria alçapão e cai/desaparece.

**Classificação:** Ator é tratado como refém comum, sem a armadilha do original.

**Assembly:** logic/actors/fakemadnar.asm:7-65 FakeMadnadLogic

**Extractors:** tools/extractors/extract.py; tools/extractors/export_room_data.py; tools/extractors/extract_prisoner_sprites.py

**Dados canônicos locais:** rooms/

**Godot relacionado:** godot/scripts/systems/prisoner.gd

**Integração inspecionada:** godot/scripts/scenes/sandbox_gameplay.gd::_spawn_room_prisoners

**Testes existentes:** godot-rank-and-prisoners

**Documentação:** docs/reverse_engineering/enemies.md; docs/reverse_engineering/stage-12b-actors-and-items-evidence.md

**Histórico consultado:** docs/progress/2026-09.md::2026-09-21 — Etapa 19: Sistema de Prisioneiros, Reféns e Patente Militar (Ranks ★1 a ★4)

**Implementado:** Tipo/nome/sprite e resgate genérico.

**Faltante / não comprovado:** Máquina FakeMadnarSpeak/Trap/Fall; criação do alçapão e flag específica.

**Notas de evidência:** Código atual incrementa resgate pelo fluxo comum; não alterar durante auditoria.


<a id="jennifer-brother"></a>
### Reféns de Coward Duck e irmão de Jennifer

`jennifer-brother` · **PROVISIONAL**

**Original:** Distinguir irmão de Jennifer pelo Y do ator, texto 140 e demais reféns com texto 131.

**Classificação:** Mapa de textos e rescued_rooms são por sala; não reproduzem a seleção por Y.

**Assembly:** logic/actors/prisoner.asm:181-190 ChkRescJenBro

**Extractors:** tools/extractors/extract.py; tools/extractors/export_room_data.py

**Dados canônicos locais:** rooms/

**Godot relacionado:** godot/scripts/systems/prisoner.gd; godot/scripts/systems/rank_system.gd

**Integração inspecionada:** godot/scripts/scenes/sandbox_gameplay.gd::_spawn_room_prisoners; godot/scripts/scenes/sandbox_gameplay.gd::_on_prisoner_rescued

**Testes existentes:** godot-rank-and-prisoners

**Documentação:** docs/reverse_engineering/enemies.md; docs/reverse_engineering/stage-12b-actors-and-items-evidence.md

**Histórico consultado:** docs/progress/2026-09.md::2026-09-21 — Etapa 19: Sistema de Prisioneiros, Reféns e Patente Militar (Ranks ★1 a ★4)

**Implementado:** Mensagem por room_id 193 e reféns genéricos.

**Faltante / não comprovado:** Distinção por posição/indivíduo e persistência correta de múltiplos reféns da mesma sala.

**Notas de evidência:** Testes de contagem/resgate comum não estabelecem a variante da sala 193.


<a id="prisoner6"></a>
### Slot de prisioneiro ID 56

`prisoner6` · **UNMAPPED**

**Original:** Slot inicializado por InitPrisoner, mas atualizado por EnemyLogicEnd; comentário original questiona seu uso.

**Classificação:** Não é seguro afirmar feature não iniciada: despacho é inerte e o uso real do slot não foi demonstrado.

**Assembly:** constants/Enums.asm:225 ID_PRISONER6; Banks0123.asm:6458-6459; Banks0123.asm:12729-12730

**Extractors:** tools/extractors/extract.py; tools/extractors/export_room_data.py

**Dados canônicos locais:** rooms/

**Godot relacionado:** godot/scripts/scenes/sandbox_gameplay.gd

**Integração inspecionada:** godot/scripts/scenes/sandbox_gameplay.gd::_spawn_room_enemies

**Testes existentes:** Nenhum localizado neste recorte.

**Documentação:** docs/reverse_engineering/enemies.md; docs/reverse_engineering/stage-12b-actors-and-items-evidence.md

**Histórico consultado:** docs/progress/2026-09.md::2026-09-20 — Etapa 12b concluída: Spawn de Inimigos, Itens e Portas Canônicas da ROM

**Implementado:** Nenhum localizado neste recorte.

**Faltante / não comprovado:** Determinar se existe uso alcançável na edição inglesa e qual comportamento efetivamente constitui feature.

**Notas de evidência:** A tabela histórica o nomeia incorretamente como Dr. Pettrovich; ID_MADNAR é 52. Não inferir uso a partir desse documento.


<a id="sleep-sign"></a>
### Ator de indicação de sono

`sleep-sign` · **PROVISIONAL**

**Original:** Animação do Zzz ligada ao ator anterior, remoção em alerta/morte e exceção da sala 140.

**Classificação:** Existe representação visual substituta, não o comportamento completo do ator ID 64.

**Assembly:** logic/actors/snoringsymbol.asm:25-49 SnoringSymbolLogic

**Extractors:** tools/extractors/extract.py; tools/extractors/export_room_data.py

**Dados canônicos locais:** rooms/

**Godot relacionado:** godot/scripts/systems/enemy.gd

**Integração inspecionada:** godot/scripts/scenes/sandbox_gameplay.gd::_spawn_room_enemies

**Testes existentes:** godot-sleepy-guard

**Documentação:** docs/reverse_engineering/enemies.md; docs/reverse_engineering/stage-12b-actors-and-items-evidence.md

**Histórico consultado:** docs/progress/2026-09.md::2026-09-20 — Etapa 12b concluída: Spawn de Inimigos, Itens e Portas Canônicas da ROM

**Implementado:** Zzz desenhado proceduralmente no EnemyGuard.

**Faltante / não comprovado:** Sprite/ator original, dependência do slot anterior e exceções específicas.

**Notas de evidência:** _draw_snoring_symbol e _draw_z_char não equivalem à entidade original.


<a id="big-explosion-actor"></a>
### Explosão grande de ator

`big-explosion-actor` · **UNMAPPED**

**Original:** Efeito temporizado de três quadros, troca de cores e remoção.

**Classificação:** Explosões existentes impedem concluir ausência só por nome/ID; correspondência entre este ator e os efeitos atuais não estabelecida.

**Assembly:** logic/actors/bigexplosion.asm:7-35 BigExplosionLogic; Banks0123.asm:12739

**Extractors:** tools/extractors/extract.py; tools/extractors/export_room_data.py

**Dados canônicos locais:** rooms/

**Godot relacionado:** godot/scripts/systems/plastic_bomb.gd; godot/scripts/systems/remote_missile.gd

**Integração inspecionada:** godot/scripts/scenes/sandbox_gameplay.gd::_spawn_room_enemies

**Testes existentes:** godot-basement-and-plastic-bomb; godot-remote-missile

**Documentação:** docs/reverse_engineering/enemies.md; docs/reverse_engineering/stage-12b-actors-and-items-evidence.md

**Histórico consultado:** docs/progress/2026-09.md::2026-09-20 — Etapa 12b concluída: Spawn de Inimigos, Itens e Portas Canônicas da ROM

**Implementado:** Há efeitos de explosão em armas, sem associação demonstrada ao ID 65.

**Faltante / não comprovado:** Mapear criação dinâmica do ID 65 e verificar se algum efeito Godot é seu equivalente ou apenas efeito da arma.

**Notas de evidência:** Essas suítes testam armas; não comprovam BigExplosionLogic. Pendente mapear produtores/consumidores do efeito, sem classificá-lo como não iniciado.
