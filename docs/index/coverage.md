# Cobertura progressiva por domínio

Gerado por `python3 -m tools.context.build_index` a partir de [mechanics.json](mechanics.json). Não editar esta visualização.

**Relatório para leitura humana; não é contexto padrão de agentes.** Agentes não devem ler este arquivo integralmente: use `python3 -m tools.context.lookup domain DOMÍNIO`, `lookup status STATUS` ou `lookup unmapped`; detalhes somente com `lookup mech ID`.

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
| [guards](#guards) — Guardas de patrulha lenta, média e rápida | ator: 4, 5, 30 | `PARTIAL` |
| [dogs](#dogs) — Cães de guarda comuns | ator: 25 | `PARTIAL` |
| [elevator-guards](#elevator-guards) — Sentinelas e revezamento do elevador | ator: 14, 40 | `PARTIAL` |
| [rank-prisoners](#rank-prisoners) — Reféns comuns, resgate, patente e morte | ator: 49 | `PARTIAL` |
| [shot-gunner](#shot-gunner) — Shot Gunner e projétil expansivo | ator: 33, 43 | `PARTIAL` |
| [actor-runtime](#actor-runtime) — Ciclo, criação, dano e remoção de atores | transversal | `PARTIAL` |
| [guard-senses](#guard-senses) — Percepção de atores e obstrução por tiles | transversal | `PARTIAL` |
| [guard-alert](#guard-alert) — Guardas em alerta e vermelho | ator: 10, 11 | `PARTIAL` |
| [guard-sleep](#guard-sleep) — Sono e despertar de guardas | transversal | `PARTIAL` |
| [guard-entry-hiding](#guard-entry-hiding) — Ocultação de guardas conforme entrada na sala | transversal | `PARTIAL` |
| [guard-lorry](#guard-lorry) — Guardas que saem e entram em caminhões | ator: 19 | `PARTIAL` |
| [shooter-guards](#shooter-guards) — Atiradores que andam, disparam e se escondem | ator: 13 | `PROVISIONAL` |
| [switch-guards](#switch-guards) — Guarda que corre para o interruptor | ator: 24 | `PROVISIONAL` |
| [lorry-shooters](#lorry-shooters) — Atiradores nos caminhões do deserto | ator: 28 | `PROVISIONAL` |
| [scorpions](#scorpions) — Escorpiões | ator: 31 | `PROVISIONAL` |
| [desert-security](#desert-security) — Segurança do acesso ao edifício 2 | ator: 46 | `PROVISIONAL` |
| [sentinels](#sentinels) — Sentinelas com lista de direções | ator: 48 | `PROVISIONAL` |
| [silencer-guards](#silencer-guards) — Guardas da sala do silenciador | ator: 57 | `PARTIAL` |
| [basement-dogs](#basement-dogs) — Cães do subsolo | ator: 27 | `PROVISIONAL` |
| [dog-spawner](#dog-spawner) — Gerador de cães entre salas | ator: 29 | `NOT_STARTED` |
| [jetpack-guards](#jetpack-guards) — Soldados com jetpack e decolagem | ator: 20, 21, 22 | `PROVISIONAL` |
| [bridges](#bridges) — Pontes e controlador de trechos | ator: 1, 2 | `NOT_STARTED` |
| [enemy-mines](#enemy-mines) — Minas do cenário | ator: 7 | `NOT_STARTED` |
| [rolling-barrels](#rolling-barrels) — Barris rolantes | ator: 15 | `NOT_STARTED` |
| [pitfalls](#pitfalls) — Alçapões de ator | ator: 16 | `NOT_STARTED` |
| [shell-barrage](#shell-barrage) — Bombardeio e gerador de projéteis aéreos | ator: 12, 39 | `NOT_STARTED` |
| [actor-camera](#actor-camera) — Câmera de vigilância comum | ator: 6 | `PARTIAL` |
| [laser-cameras](#laser-cameras) — Câmeras armadas e seus lasers | ator: 53, 54 | `NOT_STARTED` |
| [actor-lasers](#actor-lasers) — Controlador de feixes móveis | ator: 35 | `PARTIAL` |
| [actor-gas](#actor-gas) — Nuvens de gás | ator: 8 | `PARTIAL` |
| [actor-power-switch](#actor-power-switch) — Painel de força e pulsação da paleta | ator: 44 | `PARTIAL` |
| [capture-guards](#capture-guards) — Guardas da sequência de captura | ator: 45 | `PARTIAL` |
| [guard-projectiles](#guard-projectiles) — Projéteis comuns e variantes horizontal/vertical/mirada | ator: 47, 58, 59, 61 | `PARTIAL` |
| [tank](#tank) — Tanque e seus disparos | ator: 9, 23, 62 | `NOT_STARTED` |
| [bulldozer](#bulldozer) — Bulldozer | ator: 18 | `NOT_STARTED` |
| [arnold](#arnold) — Arnold | ator: 26 | `NOT_STARTED` |
| [big-boss](#big-boss) — Big Boss em combate | ator: 32 | `NOT_STARTED` |
| [machine-gun-kid](#machine-gun-kid) — Machine Gun Kid e rajadas | ator: 34, 60 | `NOT_STARTED` |
| [fire-trooper](#fire-trooper) — Fire Trooper e chamas | ator: 36, 37 | `NOT_STARTED` |
| [hind-d](#hind-d) — Hind D | ator: 38 | `NOT_STARTED` |
| [coward-duck](#coward-duck) — Coward Duck e bumerangues | ator: 41, 63 | `NOT_STARTED` |
| [metal-gear-boss](#metal-gear-boss) — Metal Gear, sequência de bombas e destruição | ator: 17 | `NOT_STARTED` |
| [ellen](#ellen) — Ellen como refém | ator: 50 | `PARTIAL` |
| [ellen-help](#ellen-help) — Pedido de ajuda periódico de Ellen | ator: 3 | `NOT_STARTED` |
| [grey-fox](#grey-fox) — Grey Fox: resgate e diálogo inglês | ator: 51 | `PARTIAL` |
| [madnar](#madnar) — Dr. Pettrovich Madnar | ator: 52 | `PROVISIONAL` |
| [fake-madnar](#fake-madnar) — Fake Madnar e armadilha | ator: 55 | `PROVISIONAL` |
| [jennifer-brother](#jennifer-brother) — Reféns de Coward Duck e irmão de Jennifer | transversal | `PROVISIONAL` |
| [prisoner6](#prisoner6) — Slot de prisioneiro ID 56 | ator: 56 | `UNMAPPED` |
| [sleep-sign](#sleep-sign) — Ator de indicação de sono | ator: 64 | `PROVISIONAL` |
| [big-explosion-actor](#big-explosion-actor) — Explosão grande de ator | ator: 65 | `UNMAPPED` |

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

## Armas do jogador, itens e equipamentos

Auditoria: 2026-10-04; HEAD de partida: `8af26174ac6338949899edc1b6f2356188fffaf5`; referência inglesa: `30d1b940bede10fdabbaf9767ad4f0ad8dd33291`.

Inventário inglês RC750 (JAPANESE equ 0): sete armas, supressor, 25 IDs selecionáveis de equipamento em famílias, bolsa e caixa de munição; soco, regras de ataque, coleta, consumo, reposição e limites por rank. Exclui UI/HUD como domínio, áudio, diálogos, máquinas de bosses e hazards/salas; dependências apenas como consumidores do equipamento.

Primeiro enums e despachos originais (weaponuse/items/menuequipment/maxammo e consumidores de SelectedItem); depois rotinas específicas, package/exports e tabelas extraídas, factory de pickups, sistemas, entradas de uso e consumidores Godot, testes existentes e histórico por índice. Comparação estática de fonte, seguida de validate.py; não houve sonda dinâmica nova no emulador. Ausência de nome isolada nunca fundamenta NOT_STARTED.

- IDs de arma, pickup e equipamento são namespaces distintos. ID 0 é vazio, não uma feature. Cartões 1–8 constituem uma família, enquanto aquisição, efeito e ciclo de consumo têm escopos transversais separados; contagem não é percentual de fidelidade.
- Entradas sem implementação exigem evidência de despachos e consumidores ausentes/rejeitados, além de dados/testes/histórico; PROVISIONAL distingue substitutos executáveis ou itens selecionáveis sem efeito. Nenhuma ausência foi elevada a DEFERRED sem decisão explícita.
- Os IDs legados items, weapons, remote-missile, plastic-bomb e binoculars foram auditados e delimitados; nenhuma entrada de actors-bosses foi modificada. Corpo de combate e progressão herdados não foram consertados.
- Fronteiras potencialmente sobrepostas: gas/gas-mask; doors/access-cards; capture-prison/equipment-bag; cameras-lasers/goggles; actor-runtime/player-hit-resolution; rank-prisoners/rank-capacities. Cadeias legadas de outros domínios foram preservadas e relacionadas, não somadas como novas features deste domínio.
- Inventário original inclui fontes não estáticas: cigarros iniciais, transmissor pela bolsa, supressor e cartões 7/8 por eventos. Nenhum evento de boss foi reauditado como feature de equipamento.
- Divergências de alta relevância: SMG/granada/mina usam Bullet genérico; foguete rejeitado e ID 4 vira RATION; caixa dá +5 RC missiles em lugar de +2 foguetes; C4 96 em vez de 48 ticks; míssil 1.5 em vez de 4 px/tick; handgun 3×32 em vez de 6×16; cartões por posse e pickups renováveis persistentes.
- Testes citados podem cobrir somente aquisição, contrato aproximado ou dependência. evidence_notes distingue isso; validate verde não promove automaticamente nenhuma classificação. Um único IMPLEMENTED pode ter escopo estreito explicitamente separado da coleta/hazard.

| Status | Features |
| --- | ---: |
| `IMPLEMENTED` | 1 |
| `PARTIAL` | 20 |
| `PROVISIONAL` | 8 |
| `NOT_STARTED` | 9 |
| `DEFERRED` | 0 |
| `UNMAPPED` | 0 |
| `INVESTIGATING` | 0 |
| Total | 38 |

### Entradas

| Feature | IDs | Status |
| --- | --- | --- |
| [items](#items) — Coleta de pickups e despacho dos IDs originais | transversal | `PARTIAL` |
| [weapons](#weapons) — Inventário e seleção das sete armas | transversal | `PARTIAL` |
| [remote-missile](#remote-missile) — Míssil teleguiado do jogador | arma: 7; pickup: 7 | `PARTIAL` |
| [plastic-bomb](#plastic-bomb) — Bomba plástica do jogador | arma: 5; pickup: 5 | `PARTIAL` |
| [binoculars](#binoculars) — Binóculos e observação de salas adjacentes | pickup: 17; equipamento: 9 | `PARTIAL` |
| [pickup-persistence](#pickup-persistence) — Disponibilidade e reposição de pickups | transversal | `PARTIAL` |
| [equipment-inventory](#equipment-inventory) — Inventário e seleção de equipamentos | transversal | `PARTIAL` |
| [rank-capacities](#rank-capacities) — Limites de munição e rações por rank | transversal | `PARTIAL` |
| [ammo-crates](#ammo-crates) — Caixas de munição para armas permanentes | pickup: 35 | `PARTIAL` |
| [consumable-lifecycle](#consumable-lifecycle) — Consumo, esgotamento e remoção do inventário | transversal | `PARTIAL` |
| [punch-loot](#punch-loot) — Itens temporários deixados por morte a socos | transversal | `NOT_STARTED` |
| [player-attack-rules](#player-attack-rules) — Restrições de ataque e ciclo de tiros do jogador | transversal | `PARTIAL` |
| [player-hit-resolution](#player-hit-resolution) — Acerto e dano por arma do jogador | transversal | `PARTIAL` |
| [punch](#punch) — Soco e ataque corpo a corpo de Snake | transversal | `PARTIAL` |
| [handgun](#handgun) — Hand Gun | arma: 1; pickup: 1 | `PARTIAL` |
| [smg](#smg) — Sub Machine Gun | arma: 2; pickup: 2 | `PROVISIONAL` |
| [grenade-launcher](#grenade-launcher) — Grenade Launcher | arma: 3; pickup: 3 | `PROVISIONAL` |
| [rocket-launcher](#rocket-launcher) — Rocket Launcher e liberação por progressão | arma: 4; pickup: 4 | `NOT_STARTED` |
| [land-mine](#land-mine) — Minas colocadas pelo jogador | arma: 6; pickup: 6 | `PROVISIONAL` |
| [silencer](#silencer) — Supressor para Hand Gun e SMG | pickup: 8 | `PARTIAL` |
| [body-armor](#body-armor) — Body Armor | pickup: 9; equipamento: 1 | `PROVISIONAL` |
| [bomb-blast-suit](#bomb-blast-suit) — Bomb Blast Suit | pickup: 10; equipamento: 2 | `PROVISIONAL` |
| [flashlight](#flashlight) — Flashlight | pickup: 11; equipamento: 3 | `NOT_STARTED` |
| [cigarettes](#cigarettes) — Cigarros e extensão da contagem final | pickup: 14; equipamento: 6 | `PROVISIONAL` |
| [mine-detector](#mine-detector) — Mine Detector | pickup: 15; equipamento: 7 | `PROVISIONAL` |
| [antenna](#antenna) — Antenna | pickup: 16; equipamento: 8 | `NOT_STARTED` |
| [oxygen-tank](#oxygen-tank) — Oxygen Tank | pickup: 18; equipamento: 10 | `NOT_STARTED` |
| [compass](#compass) — Compass | pickup: 19; equipamento: 11 | `NOT_STARTED` |
| [parachute](#parachute) — Parachute | pickup: 20; equipamento: 12 | `NOT_STARTED` |
| [antidote](#antidote) — Antidote reutilizável | pickup: 21; equipamento: 13 | `NOT_STARTED` |
| [transmitter](#transmitter) — Transmissor recuperado e descarte | pickup: 31; equipamento: 23 | `NOT_STARTED` |
| [uniform](#uniform) — Uniform | pickup: 32; equipamento: 24 | `PROVISIONAL` |
| [goggles](#goggles) — Goggles: visibilidade dos lasers e paleta | pickup: 12; equipamento: 4 | `PARTIAL` |
| [gas-mask](#gas-mask) — Gas Mask: proteção por seleção | pickup: 13; equipamento: 5 | `IMPLEMENTED` |
| [access-cards](#access-cards) — Cartões 1 a 8 e uso por seleção exata | pickup: 22, 23, 24, 25, 26, 27, 28, 29; equipamento: 14, 15, 16, 17, 18, 19, 20, 21 | `PARTIAL` |
| [ration](#ration) — Rações: uso manual e cura | pickup: 30; equipamento: 22 | `PARTIAL` |
| [cardboard-box](#cardboard-box) — Caixa de papelão: ocultação e restrições | pickup: 33; equipamento: 25 | `PARTIAL` |
| [equipment-bag](#equipment-bag) — Bolsa recuperável e restituição de equipamentos | pickup: 34 | `PARTIAL` |

### UNMAPPED

Nenhuma entrada.

<a id="items"></a>
### Coleta de pickups e despacho dos IDs originais

`items` · **PARTIAL**

**Original:** Até três slots de item; toque usa tamanho original, offsets e limites estritos; despacha IDs 1–35 para arma, equipamento, supressor, bolsa ou munição. Esta entrada cobre aquisição, não os efeitos individuais.

**Classificação:** Há comportamento específico integrado, mas as divergências abaixo impedem equivalência ao recorte original.

**Assembly:** logic/items.asm:7-129; logic/addroomitems.asm:8-75; constants/Enums.asm:127-155

**Extractors:** tools/extractors/extract.py; tools/extractors/export_room_data.py

**Dados canônicos locais:** package/package.json; rooms/room-183-actors.json

**Godot relacionado:** godot/scripts/systems/item_box.gd; godot/scripts/systems/inventory.gd; godot/scripts/systems/weapon_system.gd; godot/scripts/scenes/sandbox_gameplay.gd

**Integração inspecionada:** godot/scripts/scenes/sandbox_gameplay.gd::_spawn_room_items; godot/scripts/systems/item_box.gd::step_tick

**Testes existentes:** godot-doors-inventory; godot-item-box-sprites; tests/test_extractors.py

**Documentação:** docs/reverse_engineering/inventory-and-events.md; docs/reverse_engineering/stage-10-lorries-and-canonical-items.md

**Histórico consultado:** docs/progress/2026-09.md::2026-09-20 — Etapa 9: Portas Interativas, Caixas de Itens e Inventário

**Implementado:** Exportação por sala de tipo e coordenadas; ItemBox encaminha diversos IDs a inventário/arsenal.

**Faltante / não comprovado:** Mapear sem substituição IDs 4, 11, 16, 18–21 e os casos sem pickup estático 14/31; preservar regras de disponibilidade no caminho de exportação/runtime.; Reproduzir colisão por tamanho: X com centro +8/+16 e raio 12/20, Y com centro +16 e raio 16, em vez do quadrado <=20.

**Notas de evidência:** export_room_data.py:79-83 retém apenas ID/Y/X; _spawn_room_items:1253-1317 mapeia desconhecidos para RATION e também ID 21 explicitamente para RATION.; Os testes de proximidade validam a aproximação atual; não cobrem os limites estritos do original. IDs pertencem às entradas específicas; esta é transversal.


<a id="weapons"></a>
### Inventário e seleção das sete armas

`weapons` · **PARTIAL**

**Original:** Arsenal de sete tipos, seleção e WeaponInUse; primeiras armas exceto granada são selecionadas automaticamente; retorno do menu limpa tiros ativos. Exclui apresentação visual dos menus.

**Classificação:** Há comportamento específico integrado, mas as divergências abaixo impedem equivalência ao recorte original.

**Assembly:** logic/items.asm:199-285; Banks0123.asm:11485-11524; logic/shrinkitems.asm:8-28

**Extractors:** tools/extractors/extract.py; tools/extractors/export_room_data.py

**Dados canônicos locais:** package/package.json

**Godot relacionado:** godot/scripts/systems/weapon_system.gd; godot/scripts/systems/weapon_menu.gd; godot/scripts/scenes/sandbox_gameplay.gd

**Integração inspecionada:** godot/scripts/systems/weapon_system.gd::add_weapon; godot/scripts/scenes/sandbox_gameplay.gd::_input; godot/scripts/systems/weapon_menu.gd::_confirm_selection; godot/scripts/scenes/sandbox_gameplay.gd::_on_weapon_menu_selected

**Testes existentes:** godot-weapon-combat; godot-remote-missile

**Documentação:** docs/reverse_engineering/inventory-and-events.md

**Histórico consultado:** docs/progress/2026-09.md::2026-09-20 — Etapa 13 concluída: Sistema de Armas, Silenciador e Balística

**Implementado:** Seis tipos aceitos por WeaponSystem; posse, seleção, munição e menu integrados.

**Faltante / não comprovado:** Sétimo tipo ROCKET_LAUNCHER; não selecionar granada quando primeira arma; reproduzir limpeza de tiros/WeaponInUse na troca.

**Notas de evidência:** add_weapon:88-102 rejeita foguete e o elif seleciona a primeira granada apesar do comentário contrário.; As cadeias legadas weapons/items foram delimitadas para não contar novamente os efeitos específicos; inicialização por arsenal de debug não comprova progressão original.


<a id="remote-missile"></a>
### Míssil teleguiado do jogador

`remote-missile` · **PARTIAL**

**Original:** Consumível ID 7: um míssil, direção controlável, Snake imobilizado, velocidade 4 px/tick, duas verificações verticais de colisão, limites e explosão de 15 ticks. Pacotes de cinco e limites 5/10/15/20.

**Classificação:** Há comportamento específico integrado, mas as divergências abaixo impedem equivalência ao recorte original.

**Assembly:** logic/weapon/missile.asm:8-51; logic/weapon/missile.asm:80-86; logic/weapon/missile.asm:112-172

**Extractors:** tools/extractors/extract.py; tools/extractors/export_room_data.py; tools/extractors/extract_missile_data.py

**Dados canônicos locais:** missile_weapon.json; rooms/room-147-actors.json

**Godot relacionado:** godot/scripts/systems/remote_missile.gd; godot/scripts/systems/weapon_system.gd; godot/scripts/scenes/sandbox_gameplay.gd

**Integração inspecionada:** godot/scripts/systems/remote_missile.gd::step_tick; godot/scripts/scenes/sandbox_gameplay.gd::_input; godot/scripts/scenes/sandbox_gameplay.gd::_on_missile_exploded

**Testes existentes:** godot-remote-missile; tests/test_extractors.py

**Documentação:** docs/reverse_engineering/stage-20-rc-missile.md

**Histórico consultado:** docs/progress/2026-09.md::Calibração e Refinamento do Subsolo, Míssil Teleguiado e Explosivo Plástico (2026-09-28)

**Implementado:** Entidade própria, controle, congelamento de Snake, colisões, explosão e dano; extractor de velocidades/capacidades.

**Faltante / não comprovado:** Runtime usa SPEED=1.5 em vez de 4; não carrega missile_weapon.json para esse parâmetro. Remoção quando acaba e recarga original de pickups.

**Notas de evidência:** Calibração explícita no histórico de 2026-09-28; teste compara velocidade à própria constante do runtime, sem comparar com a tabela extraída.; Uso contra painel está relacionado, mas sua lógica não foi reclassificada.


<a id="plastic-bomb"></a>
### Bomba plástica do jogador

`plastic-bomb` · **PARTIAL**

**Original:** Consumível ID 5 em pacotes de cinco; uma bomba armada, posicionamento conforme direção, espera 48 ticks antes da explosão de 15 ticks e consumo/removal. Interação com paredes e bosses é externa a esta entrada.

**Classificação:** Há comportamento específico integrado, mas as divergências abaixo impedem equivalência ao recorte original.

**Assembly:** logic/weapon/plasticbomb.asm:7-83; logic/weapon/plasticbomb.asm:108-134

**Extractors:** tools/extractors/extract.py; tools/extractors/export_room_data.py

**Dados canônicos locais:** package/package.json; rooms/room-142-actors.json; rooms/room-153-actors.json

**Godot relacionado:** godot/scripts/systems/plastic_bomb.gd; godot/scripts/systems/weapon_system.gd; godot/scripts/scenes/sandbox_gameplay.gd

**Integração inspecionada:** godot/scripts/systems/plastic_bomb.gd::setup; godot/scripts/scenes/sandbox_gameplay.gd::_on_plastic_bomb_exploded; godot/scripts/scenes/sandbox_gameplay.gd::_input

**Testes existentes:** godot-basement-and-plastic-bomb

**Documentação:** docs/reverse_engineering/inventory-and-events.md

**Histórico consultado:** docs/progress/2026-09.md::Calibração e Refinamento do Subsolo, Míssil Teleguiado e Explosivo Plástico (2026-09-28)

**Implementado:** Entidade própria, posicionamento, consumo, explosão e integração com dano/paredes.

**Faltante / não comprovado:** Timer está em 96, não 48; dano/shape e alerta devem seguir resolução original; ciclo de esgotamento/reposição.

**Notas de evidência:** Histórico de 2026-09-28 registra aumento para 96 por conforto; não é inferência baseada em comentário. Testes atuais validam a calibração.; Antiga cadeia plastic-bomb incluía paredes; mantida a relação doors/metal-gear-boss sem reclassificar esses consumidores.


<a id="binoculars"></a>
### Binóculos e observação de salas adjacentes

`binoculars` · **PARTIAL**

**Original:** Selecionar ao sair do menu abre observação se sala não isolada; direção consulta vizinha, timer 128 ticks retorna; mantém Snake seguro e restaura cópia de atores, power switch, flags/timer de rádio e alerta.

**Classificação:** Há comportamento específico integrado, mas as divergências abaixo impedem equivalência ao recorte original.

**Assembly:** logic/menuequipment.asm:299-349 ExitEquipMenu; Banks0123.asm:12402-12528

**Extractors:** tools/extractors/extract.py; tools/extractors/export_room_data.py

**Dados canônicos locais:** package/package.json; rooms/room-128-actors.json

**Godot relacionado:** godot/scripts/systems/binocular_system.gd; godot/scripts/systems/room_manager.gd; godot/scripts/scenes/sandbox_gameplay.gd

**Integração inspecionada:** godot/scripts/scenes/sandbox_gameplay.gd::open_binoculars; godot/scripts/scenes/sandbox_gameplay.gd::_backup_home_enemies; godot/scripts/scenes/sandbox_gameplay.gd::_restore_home_enemies; godot/scripts/scenes/sandbox_gameplay.gd::_process_binoculars

**Testes existentes:** godot-binoculars

**Documentação:** docs/reverse_engineering/inventory-and-events.md

**Histórico consultado:** docs/progress/2026-09.md::[Implementação Canônica] - Binóculo / Modo Telescópio (TELESCOPE MODE)

**Implementado:** Sistema dedicado, bloqueio de salas isoladas, navegação/retorno em 128 ticks, Snake oculto e backup de propriedades de EnemyGuard.

**Faltante / não comprovado:** Backup/restauração integral de todos os atores e flags do original; comprovar efeitos de ida/volta em salas com entidades além de EnemyGuard.

**Notas de evidência:** _backup_home_enemies:1147-1180 armazena subconjunto de campos EnemyGuard; a suíte cobre esse contrato, não cópia de todos os atores/flags. Apresentação do telescópio fica fora.


<a id="pickup-persistence"></a>
### Disponibilidade e reposição de pickups

`pickup-persistence` · **PARTIAL**

**Original:** Persistir itens únicos; não marcar como tomados bombas plásticas, minas, RC missiles, rações e caixas de munição. Disponibilidade depende de flags e do evento de liberação do foguete.

**Classificação:** Há comportamento específico integrado, mas as divergências abaixo impedem equivalência ao recorte original.

**Assembly:** logic/items.asm:490-516 SetItemAsTaken; logic/addroomitems.asm:8-75

**Extractors:** tools/extractors/extract.py; tools/extractors/export_room_data.py

**Dados canônicos locais:** package/package.json

**Godot relacionado:** godot/scripts/systems/item_box.gd; godot/scripts/scenes/sandbox_gameplay.gd

**Integração inspecionada:** godot/scripts/systems/item_box.gd::step_tick; godot/scripts/scenes/sandbox_gameplay.gd::_spawn_room_items

**Testes existentes:** godot-doors-inventory

**Documentação:** docs/reverse_engineering/inventory-and-events.md

**Histórico consultado:** docs/progress/2026-09.md::2026-09-20 — Etapa 9: Portas Interativas, Caixas de Itens e Inventário

**Implementado:** collected_boxes impede reaparecimento de caixas já coletadas na sessão.

**Faltante / não comprovado:** Exceções renováveis dos IDs 5/6/7/30/35 e flags originais por pickup; gate JeniRocketF para foguete.

**Notas de evidência:** A mesma persistência incondicional é usada para todo pickup; não há separação entre item permanente e reposição. Os testes cobrem persistência, não revisita canônica de consumíveis.


<a id="equipment-inventory"></a>
### Inventário e seleção de equipamentos

`equipment-inventory` · **PARTIAL**

**Original:** Vinte e cinco IDs selecionáveis em slots de quatro bytes, uma seleção ativa, compactação ao remover, cigarros iniciais; supressor tem estado separado, fora dos 25 equipamentos.

**Classificação:** Há comportamento específico integrado, mas as divergências abaixo impedem equivalência ao recorte original.

**Assembly:** logic/items.asm:139-189; logic/menuequipment.asm:186-195; logic/shrinkitems.asm:30-58; Banks0123.asm:11775-11780

**Extractors:** tools/extractors/extract.py; tools/extractors/export_room_data.py

**Dados canônicos locais:** package/package.json

**Godot relacionado:** godot/scripts/systems/inventory.gd; godot/scripts/systems/item_menu.gd; godot/scripts/systems/item_box.gd; godot/scripts/scenes/sandbox_gameplay.gd

**Integração inspecionada:** godot/scripts/systems/inventory.gd::collect_item; godot/scripts/systems/inventory.gd::use_selected_item; godot/scripts/scenes/sandbox_gameplay.gd::_spawn_room_items

**Testes existentes:** godot-doors-inventory

**Documentação:** docs/reverse_engineering/inventory-and-events.md

**Histórico consultado:** docs/progress/2026-09.md::2026-09-20 — Etapa 9: Portas Interativas, Caixas de Itens e Inventário

**Implementado:** Lista de equipamentos, seleção/ciclo e cigarros iniciais; contador dedicado de rações.

**Faltante / não comprovado:** Modelar os 25 tipos e suas quantidades/remoção sem substituições; supressor não deve virar equipamento selecionável; preservar seleção vazia após consumo final.

**Notas de evidência:** A lista aceita strings sem contrato dos 25 IDs; use_selected_item só implementa RATION. Há ícones para itens sem efeitos. Quantidade de slots em memória não exige copiar o layout em Godot, mas os resultados de uso precisam coincidir.


<a id="rank-capacities"></a>
### Limites de munição e rações por rank

`rank-capacities` · **PARTIAL**

**Original:** Class 0–3: HG/SMG 50/100/200/300; granadas 15/30/60/90; foguetes 5/10/20/30; bombas/minas/mísseis 5/10/15/20; rações 3/6/9/12. Rebaixamento limita quantidades armazenadas.

**Classificação:** Há comportamento específico integrado, mas as divergências abaixo impedem equivalência ao recorte original.

**Assembly:** logic/maxammo.asm:10-147

**Extractors:** tools/extractors/extract_missile_data.py

**Dados canônicos locais:** missile_weapon.json

**Godot relacionado:** godot/scripts/systems/weapon_system.gd; godot/scripts/systems/inventory.gd; godot/scripts/systems/rank_system.gd; godot/scripts/scenes/sandbox_gameplay.gd

**Integração inspecionada:** godot/scripts/systems/weapon_system.gd::update_rank_capacities; godot/scripts/systems/inventory.gd::update_rank_capacities

**Testes existentes:** godot-rank-and-prisoners; godot-remote-missile

**Documentação:** docs/reverse_engineering/inventory-and-events.md

**Histórico consultado:** docs/progress/2026-09.md::2026-09-20 — Etapa 13 concluída: Sistema de Armas, Silenciador e Balística

**Implementado:** Tabelas dos seis tipos aceitos e rações, ajuste por rank e clamp de munição/rações.

**Faltante / não comprovado:** Limites de foguetes e cobertura de teste de todas as colunas; progressão que aciona as tabelas herda divergência de rank-prisoners.

**Notas de evidência:** Suítes citadas exercitam HG, míssil e rações por rank; a suíte weapon-combat também verifica o teto básico da SMG. Não cobrem todas as armas/ranks, em particular o foguete ausente.; Resgate/rebaixamento de reféns pertence a rank-prisoners: não foi reclassificado. Passwords e flags de cheat da rotina ficam fora do domínio de equipamento.


<a id="ammo-crates"></a>
### Caixas de munição para armas permanentes

`ammo-crates` · **PARTIAL**

**Original:** Pickup 35 soma 20 HG, 20 SMG, 6 granadas e 2 foguetes, apenas às armas possuídas e até o limite por rank; não recarrega RC missile.

**Classificação:** Há comportamento específico integrado, mas as divergências abaixo impedem equivalência ao recorte original.

**Assembly:** logic/items.asm:333-356 PickAmmoCrate; logic/items.asm:445-479

**Extractors:** tools/extractors/extract.py; tools/extractors/export_room_data.py

**Dados canônicos locais:** package/package.json; rooms/room-122-actors.json; rooms/room-142-actors.json

**Godot relacionado:** godot/scripts/systems/item_box.gd; godot/scripts/systems/weapon_system.gd

**Integração inspecionada:** godot/scripts/systems/item_box.gd::step_tick; godot/scripts/systems/weapon_system.gd::add_ammo_crate

**Testes existentes:** godot-weapon-combat; godot-remote-missile

**Documentação:** docs/reverse_engineering/inventory-and-events.md

**Histórico consultado:** docs/progress/2026-09.md::2026-09-20 — Etapa 13 concluída: Sistema de Armas, Silenciador e Balística

**Implementado:** Recarga e clamp de HG/SMG/granada já possuídas.

**Faltante / não comprovado:** Trocar a recarga indevida de 5 mísseis pela recarga original de 2 foguetes; reposição da caixa é tratada em pickup-persistence.

**Notas de evidência:** remote_missile_test.gd:181-187 exige explicitamente +5 mísseis, uma divergência do original; aprovação da suíte não atesta fidelidade desta recarga.


<a id="consumable-lifecycle"></a>
### Consumo, esgotamento e remoção do inventário

`consumable-lifecycle` · **PARTIAL**

**Original:** DecItemUnits distingue munição permanente, armas consumíveis (5/6/7) e itens usados no menu. Ao esgotar consumível, remove slot e zera seleção; equipamentos persistentes não são consumidos por seleção.

**Classificação:** Há comportamento específico integrado, mas as divergências abaixo impedem equivalência ao recorte original.

**Assembly:** Banks0123.asm:1824-1913 DecItemUnits; logic/shrinkitems.asm:8-58

**Extractors:** Nenhum localizado neste recorte.

**Dados canônicos locais:** Nenhum localizado neste recorte.

**Godot relacionado:** godot/scripts/systems/weapon_system.gd; godot/scripts/systems/inventory.gd

**Integração inspecionada:** godot/scripts/systems/weapon_system.gd::consume_ammo; godot/scripts/systems/inventory.gd::use_selected_item

**Testes existentes:** godot-weapon-combat; godot-remote-missile; godot-doors-inventory

**Documentação:** docs/reverse_engineering/inventory-and-events.md

**Histórico consultado:** docs/progress/2026-09.md::2026-09-20 — Etapa 13 concluída: Sistema de Armas, Silenciador e Balística

**Implementado:** Tiros decrementam munição; rações decrementam quantidade e são removidas ao zerar.

**Faltante / não comprovado:** Remover bomba/mina/míssil e limpar SelectedWeapon ao zerar; limpar seleção de equipamento em vez de selecionar implicitamente outro; uso/remoção de cigarros e transmissor.

**Notas de evidência:** consume_ammo:173-177 nunca remove owned_weapons. Testes verificam decremento, mas não todo o ciclo de esgotar/recoletar/selecionar.


<a id="punch-loot"></a>
### Itens temporários deixados por morte a socos

`punch-loot` · **NOT_STARTED**

**Original:** ChkDropItem filtra efetivamente ID_GUARD_SLOW; valor derivado de R em 0..3 só cria ração (0) ou munição (1). SpawnItem permite um item temporário e exige primeiro slot livre.

**Classificação:** O original está identificado; a cadeia de aquisição, despacho de uso e consumidores inspecionada não inicia este efeito. Ícones e metadados não contam como gameplay.

**Assembly:** Banks0123.asm:12832-12865 ChkDropItem; logic/spawnitem.asm:15-75

**Extractors:** tools/extractors/extract.py; tools/extractors/export_room_data.py

**Dados canônicos locais:** Nenhum localizado neste recorte.

**Godot relacionado:** godot/scripts/systems/enemy.gd; godot/scripts/scenes/sandbox_gameplay.gd; godot/scripts/systems/item_box.gd

**Integração inspecionada:** godot/scripts/systems/enemy.gd::receive_punch; godot/scripts/scenes/sandbox_gameplay.gd::_physics_process; godot/scripts/scenes/sandbox_gameplay.gd::_spawn_room_items

**Testes existentes:** godot-combat-health

**Documentação:** docs/reverse_engineering/inventory-and-events.md

**Histórico consultado:** docs/progress/2026-09.md::2026-09-20 — Etapa 8: Combate Corpo a Corpo (Soco), Perseguição em Alerta e Vida/Dano

**Implementado:** Nenhum localizado neste recorte.

**Faltante / não comprovado:** Produzir, posicionar (X-8,Y-4), coletar e limitar loot temporário conforme fluxo de morte a socos.

**Notas de evidência:** receive_punch só marca morto e o sandbox não cria ração/munição nessa transição; instâncias ItemBox são pickups estáticos/fallback e evento explícito do supressor.; Exportação de itens de sala não representa spawn de morte. Histórico de combate e testes de morte não registram nem exercitam loot. Não generalizar pelos comentários a guardas médios/rápidos: o salto NZ filtra esses IDs.


<a id="player-attack-rules"></a>
### Restrições de ataque e ciclo de tiros do jogador

`player-attack-rules` · **PARTIAL**

**Original:** Despacho para sete armas; não disparar em room 204, rooms >=224, água, água profunda ou caixa; pool de seis slots e limites específicos por arma; soco também bloqueado em água/caixa.

**Classificação:** Há comportamento específico integrado, mas as divergências abaixo impedem equivalência ao recorte original.

**Assembly:** logic/weaponuse.asm:8-73; Banks0123.asm:8934-8962 chkPunch; Banks0123.asm:1081-1093 GetWeaponDamages; data/weapondamage.asm:4-58

**Extractors:** Nenhum localizado neste recorte.

**Dados canônicos locais:** Nenhum localizado neste recorte.

**Godot relacionado:** godot/scripts/systems/player.gd; godot/scripts/systems/weapon_system.gd; godot/scripts/scenes/sandbox_gameplay.gd

**Integração inspecionada:** godot/scripts/systems/player.gd::punch; godot/scripts/systems/player.gd::fire_weapon; godot/scripts/scenes/sandbox_gameplay.gd::_input

**Testes existentes:** godot-weapon-combat

**Documentação:** docs/reverse_engineering/inventory-and-events.md

**Histórico consultado:** docs/progress/2026-09.md::2026-09-20 — Etapa 13 concluída: Sistema de Armas, Silenciador e Balística

**Implementado:** Verificação de controle/vida/munição; um míssil e uma bomba ativos; congelamento ao controlar míssil.

**Faltante / não comprovado:** Guards originais de sala/animação; limite de seis slots em armas comuns; entrada contínua para SMG; limpeza/seleção coordenada de tiros.

**Notas de evidência:** Ramo de disparo por evento só separa MISSILE e PLASTIC_BOMB; array de bullets não implementa o pool original. Não há comparação dinâmica em emulador nesta auditoria.


<a id="player-hit-resolution"></a>
### Acerto e dano por arma do jogador

`player-hit-resolution` · **PARTIAL**

**Original:** ChkPlayerShots escolhe shape de projétil ou explosão, respeita KILL_BY_CONTACT e lê dano por tipo de arma/alvo; rocket/mine/missile passam à explosão no contato. Máquinas de bosses permanecem em actors-bosses.

**Classificação:** Há comportamento específico integrado, mas as divergências abaixo impedem equivalência ao recorte original.

**Assembly:** logic/damagetoenemy.asm:7-77; logic/damagetoenemy.asm:92-225; data/weapondamage.asm:4-58; logic/weaponuse.asm:338-375

**Extractors:** tools/extractors/extract_missile_data.py

**Dados canônicos locais:** missile_weapon.json

**Godot relacionado:** godot/scripts/systems/bullet.gd; godot/scripts/systems/enemy.gd; godot/scripts/systems/remote_missile.gd; godot/scripts/systems/plastic_bomb.gd; godot/scripts/scenes/sandbox_gameplay.gd

**Integração inspecionada:** godot/scripts/systems/enemy.gd::take_bullet_hit; godot/scripts/scenes/sandbox_gameplay.gd::_on_plastic_bomb_exploded; godot/scripts/scenes/sandbox_gameplay.gd::_physics_process

**Testes existentes:** godot-weapon-combat; godot-remote-missile; godot-basement-and-plastic-bomb

**Documentação:** docs/reverse_engineering/inventory-and-events.md

**Histórico consultado:** docs/progress/2026-09.md::2026-09-20 — Etapa 13 concluída: Sistema de Armas, Silenciador e Balística

**Implementado:** Colisões com tiles/inimigos, dano genérico de bala, dano 5 de míssil e explosão radial de bomba.

**Faltante / não comprovado:** Shapes e matriz de dano por arma/alvo; estados que permitem dano; limite específico de tiros e interação canônica sem matar todo EnemyGuard com um hit genérico.

**Notas de evidência:** Matriz não é consumida pelo runtime; take_bullet_hit marca EnemyGuard morto, independentemente do parâmetro de dano. Testes de fixtures de guardas não cobrem a matriz.; Limite com actor-runtime: esta entrada é o produtor/acerto da arma; reação, resistência e morte do ator pertencem ao domínio já auditado.


<a id="punch"></a>
### Soco e ataque corpo a corpo de Snake

`punch` · **PARTIAL**

**Original:** Soco de oito ticks com direção e retângulo de alcance, filtro de tipos elegíveis, TOUCH_INFO bit 6; soco proibido em água/caixa. Janelas de novo impacto dependem do estado de stun do alvo.

**Classificação:** Há comportamento específico integrado, mas as divergências abaixo impedem equivalência ao recorte original.

**Assembly:** Banks0123.asm:8934-8962 chkPunch; logic/punchenemy.asm:6-87

**Extractors:** Nenhum localizado neste recorte.

**Dados canônicos locais:** Nenhum localizado neste recorte.

**Godot relacionado:** godot/scripts/systems/player.gd; godot/scripts/systems/enemy.gd; godot/scripts/scenes/sandbox_gameplay.gd

**Integração inspecionada:** godot/scripts/systems/player.gd::punch; godot/scripts/systems/enemy.gd::check_punched; godot/scripts/systems/enemy.gd::receive_punch

**Testes existentes:** godot-combat-health; godot-weapon-combat

**Documentação:** docs/reverse_engineering/inventory-and-events.md

**Histórico consultado:** docs/progress/2026-09.md::2026-09-20 — Etapa 8: Combate Corpo a Corpo (Soco), Perseguição em Alerta e Vida/Dano

**Implementado:** Player.punch, animação/timer e testes de alcance; guardas recebem impactos e morrem no terceiro.

**Faltante / não comprovado:** Filtro original (cães não constam de PunchEnemies), geometria e janela de repetição (original permite stun abaixo de 0x38); bloqueios de água/caixa.

**Notas de evidência:** Godot aceita socos em cães e exige fim completo do stun; isso também consta da fronteira com actors-bosses, cujas entradas permanecem intactas.; Parede quebrável/porta não são reinventariadas aqui; relações indicam consumidores do soco.


<a id="handgun"></a>
### Hand Gun

`handgun` · **PARTIAL**

**Original:** Arma permanente ID 1, uma unidade por disparo, velocidade axial 6 px/tick e 16 ticks de voo; colisões superior/inferior; ruído condicionado pelo supressor.

**Classificação:** Há comportamento específico integrado, mas as divergências abaixo impedem equivalência ao recorte original.

**Assembly:** logic/weapon/handgun.asm:8-89; logic/weaponuse.asm:338-375

**Extractors:** tools/extractors/extract.py; tools/extractors/export_room_data.py

**Dados canônicos locais:** package/package.json; rooms/room-130-actors.json

**Godot relacionado:** godot/scripts/systems/weapon_system.gd; godot/scripts/systems/player.gd; godot/scripts/systems/bullet.gd; godot/scripts/scenes/sandbox_gameplay.gd

**Integração inspecionada:** godot/scripts/systems/player.gd::fire_weapon; godot/scripts/scenes/sandbox_gameplay.gd::_input

**Testes existentes:** godot-weapon-combat

**Documentação:** docs/reverse_engineering/inventory-and-events.md

**Histórico consultado:** docs/progress/2026-09.md::2026-09-20 — Etapa 13 concluída: Sistema de Armas, Silenciador e Balística

**Implementado:** Coleta, seleção, consumo e tiros integrados; protótipo Bullet possui constantes originais.

**Faltante / não comprovado:** player.fire_weapon sobrescreve velocidade para 3 e duração para 32; trajetória/cadência temporal e shape duplo divergem.

**Notas de evidência:** Mesmo alcance nominal de 96 px não torna 3×32 equivalente a 6×16. Teste do Bullet isolado não comprova os overrides do Player.


<a id="smg"></a>
### Sub Machine Gun

`smg` · **PROVISIONAL**

**Original:** Arma permanente ID 2: manter botão gera sequência de oito direções, gate de dois ticks e velocidades fracionárias; cada bala dura 16 ticks e consome munição, com supressor opcional.

**Classificação:** A aquisição ou representação existe, mas o uso corresponde a um substituto ou não possui o efeito específico original.

**Assembly:** logic/weapon/smg.asm:25-128

**Extractors:** tools/extractors/extract.py; tools/extractors/export_room_data.py

**Dados canônicos locais:** package/package.json; rooms/room-137-actors.json

**Godot relacionado:** godot/scripts/systems/weapon_system.gd; godot/scripts/systems/player.gd; godot/scripts/scenes/sandbox_gameplay.gd

**Integração inspecionada:** godot/scripts/systems/weapon_system.gd::add_weapon; godot/scripts/scenes/sandbox_gameplay.gd::_input; godot/scripts/systems/player.gd::fire_weapon

**Testes existentes:** godot-weapon-combat; godot-item-box-sprites

**Documentação:** docs/reverse_engineering/inventory-and-events.md

**Histórico consultado:** docs/progress/2026-09.md::2026-09-20 — Etapa 13 concluída: Sistema de Armas, Silenciador e Balística

**Implementado:** Coleta, seleção e reserva de munição; disparo genérico do Player.

**Faltante / não comprovado:** Autofire ao segurar, sequência angular/frações e cadência específicas de ChkSMGShot.

**Notas de evidência:** Não há ramo SMG no disparo; evento de tecla sem echo produz a mesma bala da pistola. Testes de aquisição/contagem não exercitam rajada original.


<a id="grenade-launcher"></a>
### Grenade Launcher

`grenade-launcher` · **PROVISIONAL**

**Original:** Arma permanente ID 3 com mira, voo de 24 ticks, velocidade 3 e deslocamento parabólico visual; dano na fase de explosão de 15 ticks, não por contato durante voo.

**Classificação:** A aquisição ou representação existe, mas o uso corresponde a um substituto ou não possui o efeito específico original.

**Assembly:** logic/weapon/grenade.asm:8-153; logic/items.asm:253-261

**Extractors:** tools/extractors/extract.py; tools/extractors/export_room_data.py

**Dados canônicos locais:** package/package.json; rooms/room-151-actors.json

**Godot relacionado:** godot/scripts/systems/weapon_system.gd; godot/scripts/systems/player.gd; godot/scripts/scenes/sandbox_gameplay.gd

**Integração inspecionada:** godot/scripts/scenes/sandbox_gameplay.gd::_input; godot/scripts/systems/player.gd::fire_weapon

**Testes existentes:** godot-weapon-combat

**Documentação:** docs/reverse_engineering/inventory-and-events.md

**Histórico consultado:** docs/progress/2026-09.md::2026-09-20 — Etapa 13 concluída: Sistema de Armas, Silenciador e Balística

**Implementado:** Coleta, reserva e seleção; caminho genérico de bullet.

**Faltante / não comprovado:** Mira de lançamento, trajetória/posição lógica, timer e dano por fase; exceção de seleção inicial.

**Notas de evidência:** GRENADE_LAUNCHER é aceito mas não tem entidade/ramo de granada: mata como bala reta. Testes não exercitam voo/explosão canônicos.


<a id="rocket-launcher"></a>
### Rocket Launcher e liberação por progressão

`rocket-launcher` · **NOT_STARTED**

**Original:** Arma permanente ID 4: um foguete, velocidade 5, colisão superior/inferior e explosão de 15 ticks; capacidades 5/10/20/30. Pickup exige JeniRocketF; resposta que libera suprimento exige Class 3.

**Classificação:** O original está identificado; a cadeia de aquisição, despacho de uso e consumidores inspecionada não inicia este efeito. Ícones e metadados não contam como gameplay.

**Assembly:** logic/weapon/rocket.asm:8-142; logic/addroomitems.asm:8-75; Banks0123.asm:11136-11148; logic/maxammo.asm:112-147

**Extractors:** tools/extractors/extract.py; tools/extractors/export_room_data.py

**Dados canônicos locais:** package/package.json; rooms/room-185-actors.json

**Godot relacionado:** godot/scripts/systems/weapon_system.gd; godot/scripts/systems/item_box.gd; godot/scripts/scenes/sandbox_gameplay.gd

**Integração inspecionada:** godot/scripts/systems/weapon_system.gd::add_weapon; godot/scripts/systems/item_box.gd::step_tick; godot/scripts/scenes/sandbox_gameplay.gd::_spawn_room_items

**Testes existentes:** godot-item-box-sprites

**Documentação:** docs/reverse_engineering/inventory-and-events.md

**Histórico consultado:** docs/progress/2026-09.md::2026-09-20 — Etapa 13 concluída: Sistema de Armas, Silenciador e Balística

**Implementado:** Nenhum localizado neste recorte.

**Faltante / não comprovado:** Aceitar/selecionar/municiar arma; gate de liberação; voo/explosão e uso específico. A conversa de Jennifer em si está fora do domínio.

**Notas de evidência:** ID 4 da sala 185 cai no fallback RATION do factory. ItemBox criado manualmente com ROCKET_LAUNCHER marca coleta mesmo quando add_weapon retorna false.; item_box_sprites_test:78-85 verifica touched/collected, não posse; logo esse teste não comprova aquisição. Não há entidade nem ramo de disparo de foguete no fluxo auditado.


<a id="land-mine"></a>
### Minas colocadas pelo jogador

`land-mine` · **PROVISIONAL**

**Original:** Consumível ID 6 em pacotes de cinco, colocado nas coordenadas de Snake em slot livre; fica no chão, explode por contato elegível e percorre estados de explosão.

**Classificação:** A aquisição ou representação existe, mas o uso corresponde a um substituto ou não possui o efeito específico original.

**Assembly:** logic/weapon/mine.asm:7-76; logic/damagetoenemy.asm:129-152

**Extractors:** tools/extractors/extract.py; tools/extractors/export_room_data.py

**Dados canônicos locais:** package/package.json; rooms/room-132-actors.json; rooms/room-140-actors.json

**Godot relacionado:** godot/scripts/systems/weapon_system.gd; godot/scripts/systems/player.gd; godot/scripts/scenes/sandbox_gameplay.gd

**Integração inspecionada:** godot/scripts/scenes/sandbox_gameplay.gd::_input; godot/scripts/systems/player.gd::fire_weapon

**Testes existentes:** godot-weapon-combat

**Documentação:** docs/reverse_engineering/inventory-and-events.md

**Histórico consultado:** docs/progress/2026-09.md::2026-09-20 — Etapa 13 concluída: Sistema de Armas, Silenciador e Balística

**Implementado:** Coleta, munição e seleção; ao usar, segue o bullet genérico.

**Faltante / não comprovado:** Entidade estacionária, múltiplas minas/pool, contato e explosão; esgotamento/reposição.

**Notas de evidência:** Sem ramo LAND_MINE no dispatch; não confundir com minas inimigas ID 9 do domínio actors-bosses. Inventário em string não implementa colocação.


<a id="silencer"></a>
### Supressor para Hand Gun e SMG

`silencer` · **PARTIAL**

**Original:** Pickup 8 grava InvSupressor separado do equipamento selecionável e elimina o ramo de ruído de HG/SMG; não altera explosivos. Drop dos guardas é descrito em silencer-guards.

**Classificação:** Há comportamento específico integrado, mas as divergências abaixo impedem equivalência ao recorte original.

**Assembly:** logic/items.asm:184-189 PickSupressor; logic/weapon/handgun.asm:8-80; logic/weapon/smg.asm:25-128

**Extractors:** Nenhum localizado neste recorte.

**Dados canônicos locais:** Nenhum localizado neste recorte.

**Godot relacionado:** godot/scripts/systems/weapon_system.gd; godot/scripts/systems/inventory.gd; godot/scripts/systems/item_box.gd; godot/scripts/scenes/sandbox_gameplay.gd

**Integração inspecionada:** godot/scripts/systems/item_box.gd::step_tick; godot/scripts/scenes/sandbox_gameplay.gd::_input

**Testes existentes:** godot-weapon-combat

**Documentação:** docs/reverse_engineering/inventory-and-events.md

**Histórico consultado:** docs/progress/2026-09.md::2026-09-20 — Etapa 13 concluída: Sistema de Armas, Silenciador e Balística

**Implementado:** Flag has_silencer, aquisição e gate de alerta acústico no disparo.

**Faltante / não comprovado:** Retirar do inventário selecionável e limitar efeito às armas originais; distinguir comportamento de inimigos que escutam tiros.

**Notas de evidência:** Silenciador suprime todo disparo genérico, inclusive granadas/minas substituídas; como equipamento adicional foge dos 25 IDs. Áudio e máquinas de guardas ficam fora desta auditoria.


<a id="body-armor"></a>
### Body Armor

`body-armor` · **PROVISIONAL**

**Original:** Quando selecionada, reduz à metade o dano de contato em ChkUsingArmor.

**Classificação:** A aquisição ou representação existe, mas o uso corresponde a um substituto ou não possui o efeito específico original.

**Assembly:** logic/touchenemy.asm:181-189 ChkUsingArmor

**Extractors:** tools/extractors/extract.py; tools/extractors/export_room_data.py

**Dados canônicos locais:** package/package.json; rooms/room-171-actors.json

**Godot relacionado:** godot/scripts/systems/item_box.gd; godot/scripts/systems/player.gd; godot/scripts/systems/inventory.gd

**Integração inspecionada:** godot/scripts/scenes/sandbox_gameplay.gd::_spawn_room_items; godot/scripts/systems/player.gd::apply_damage

**Testes existentes:** Nenhum localizado neste recorte.

**Documentação:** docs/reverse_engineering/inventory-and-events.md

**Histórico consultado:** docs/progress/2026-09.md::2026-09-20 — Etapa 9: Portas Interativas, Caixas de Itens e Inventário

**Implementado:** Coletável e selecionável como BODY_ARMOR.

**Faltante / não comprovado:** Aplicar seleção e SRL ao dano recebido no caminho apropriado.

**Notas de evidência:** Factory de itens, inventário e consumidores de uso/dano/navegação foram cruzados: há apenas representação/posse, sem o efeito descrito.; Busca por nomes/IDs foi cruzada com despacho e dados; atlas/HUD isolados não contam como efeito. Nenhum teste específico nem entrega desse efeito localizado no índice/histórico de inventário.


<a id="bomb-blast-suit"></a>
### Bomb Blast Suit

`bomb-blast-suit` · **PROVISIONAL**

**Original:** Seleção impede arrasto pela corrente de ar do terraço; não significa imunidade geral a explosões.

**Classificação:** A aquisição ou representação existe, mas o uso corresponde a um substituto ou não possui o efeito específico original.

**Assembly:** Banks0123.asm:9280-9295 ChkRoofAirFlow

**Extractors:** tools/extractors/extract.py; tools/extractors/export_room_data.py

**Dados canônicos locais:** package/package.json; rooms/room-170-actors.json

**Godot relacionado:** godot/scripts/systems/item_box.gd; godot/scripts/systems/player.gd; godot/scripts/systems/inventory.gd

**Integração inspecionada:** godot/scripts/scenes/sandbox_gameplay.gd::_spawn_room_items; godot/scripts/systems/player.gd::step_tick

**Testes existentes:** Nenhum localizado neste recorte.

**Documentação:** docs/reverse_engineering/inventory-and-events.md

**Histórico consultado:** docs/progress/2026-09.md::2026-09-20 — Etapa 9: Portas Interativas, Caixas de Itens e Inventário

**Implementado:** ID 10 é coletado como BOMB_BLAST_SUIT.

**Faltante / não comprovado:** Consumidor da seleção para proteção contra vento.

**Notas de evidência:** Factory de itens, inventário e consumidores de uso/dano/navegação foram cruzados: há apenas representação/posse, sem o efeito descrito.; Busca por nomes/IDs foi cruzada com despacho e dados; atlas/HUD isolados não contam como efeito. Nenhum teste específico nem entrega desse efeito localizado no índice/histórico de inventário.


<a id="flashlight"></a>
### Flashlight

`flashlight` · **NOT_STARTED**

**Original:** Selecionar lanterna permite paleta normal nos ambientes escuros 123–125 e 220–221.

**Classificação:** O original está identificado; a cadeia de aquisição, despacho de uso e consumidores inspecionada não inicia este efeito. Ícones e metadados não contam como gameplay.

**Assembly:** Banks0123.asm:2936-2965

**Extractors:** tools/extractors/extract.py; tools/extractors/export_room_data.py

**Dados canônicos locais:** package/package.json; rooms/room-176-actors.json

**Godot relacionado:** godot/scripts/systems/item_box.gd; godot/scripts/systems/inventory.gd; godot/scripts/scenes/sandbox_gameplay.gd

**Integração inspecionada:** godot/scripts/scenes/sandbox_gameplay.gd::_spawn_room_items

**Testes existentes:** Nenhum localizado neste recorte.

**Documentação:** docs/reverse_engineering/inventory-and-events.md

**Histórico consultado:** docs/progress/2026-09.md::2026-09-20 — Etapa 9: Portas Interativas, Caixas de Itens e Inventário

**Implementado:** Nenhum localizado neste recorte.

**Faltante / não comprovado:** Aquisição fiel de ID 11 e uso da seleção ao definir visibilidade/paleta.

**Notas de evidência:** Factory de itens, inventário e consumidores de uso/dano/navegação foram cruzados: não há caminho funcional para este item; IDs estáticos não mapeados caem em RATION.; Busca por nomes/IDs foi cruzada com despacho e dados; atlas/HUD isolados não contam como efeito. Nenhum teste específico nem entrega desse efeito localizado no índice/histórico de inventário.


<a id="cigarettes"></a>
### Cigarros e extensão da contagem final

`cigarettes` · **PROVISIONAL**

**Original:** Cigarros iniciais; uso apenas com contagem final ativa consome unidade e soma 2000 unidades BCD. Não é cura.

**Classificação:** A aquisição ou representação existe, mas o uso corresponde a um substituto ou não possui o efeito específico original.

**Assembly:** Banks0123.asm:11775-11780; logic/menuequipment.asm:268-284 ChkUseCigarettes

**Extractors:** Nenhum localizado neste recorte.

**Dados canônicos locais:** Nenhum localizado neste recorte.

**Godot relacionado:** godot/scripts/systems/item_box.gd; godot/scripts/systems/inventory.gd; godot/scripts/scenes/sandbox_gameplay.gd

**Integração inspecionada:** godot/scripts/scenes/sandbox_gameplay.gd::_spawn_room_items; godot/scripts/systems/inventory.gd::use_selected_item

**Testes existentes:** Nenhum localizado neste recorte.

**Documentação:** docs/reverse_engineering/inventory-and-events.md

**Histórico consultado:** docs/progress/2026-09.md::2026-09-20 — Etapa 9: Portas Interativas, Caixas de Itens e Inventário

**Implementado:** Cigarros adicionados na inicialização e recuperados na bolsa.

**Faltante / não comprovado:** Handler de uso/consumo condicionado à contagem final.

**Notas de evidência:** Factory de itens, inventário e consumidores de uso/dano/navegação foram cruzados: há apenas representação/posse, sem o efeito descrito.; Busca por nomes/IDs foi cruzada com despacho e dados; atlas/HUD isolados não contam como efeito. Nenhum teste específico nem entrega desse efeito localizado no índice/histórico de inventário.


<a id="mine-detector"></a>
### Mine Detector

`mine-detector` · **PROVISIONAL**

**Original:** Selecionado, revela minas do cenário ao inicializar e redesenhar; as rotinas inspecionadas não concedem recuperação dessas minas como munição.

**Classificação:** A aquisição ou representação existe, mas o uso corresponde a um substituto ou não possui o efeito específico original.

**Assembly:** logic/actors/mine.asm:7-39 InitMines; logic/actors/mine.asm:75-103 DrawMines

**Extractors:** tools/extractors/extract.py; tools/extractors/export_room_data.py

**Dados canônicos locais:** package/package.json; rooms/room-160-actors.json

**Godot relacionado:** godot/scripts/systems/item_box.gd; godot/scripts/systems/inventory.gd; godot/scripts/scenes/sandbox_gameplay.gd

**Integração inspecionada:** godot/scripts/scenes/sandbox_gameplay.gd::_spawn_room_items

**Testes existentes:** Nenhum localizado neste recorte.

**Documentação:** docs/reverse_engineering/inventory-and-events.md

**Histórico consultado:** docs/progress/2026-09.md::2026-09-20 — Etapa 9: Portas Interativas, Caixas de Itens e Inventário

**Implementado:** Coleta/seleção de MINE_DETECTOR.

**Faltante / não comprovado:** Consumidor que revele minas conforme seleção; depende do ator de mina.

**Notas de evidência:** Factory de itens, inventário e consumidores de uso/dano/navegação foram cruzados: há apenas representação/posse, sem o efeito descrito.; Busca por nomes/IDs foi cruzada com despacho e dados; atlas/HUD isolados não contam como efeito. Nenhum teste específico nem entrega desse efeito localizado no índice/histórico de inventário.


<a id="antenna"></a>
### Antenna

`antenna` · **NOT_STARTED**

**Original:** Posse libera resposta de rádio em MapZone >=5; aquisição ajusta estado da chamada. É efeito por posse, não por seleção. Diálogos/rádio não são auditados.

**Classificação:** O original está identificado; a cadeia de aquisição, despacho de uso e consumidores inspecionada não inicia este efeito. Ícones e metadados não contam como gameplay.

**Assembly:** logic/items.asm:159-170; Banks0123.asm:11043-11056 ChkRadioReply

**Extractors:** tools/extractors/extract.py; tools/extractors/export_room_data.py

**Dados canônicos locais:** package/package.json; rooms/room-178-actors.json

**Godot relacionado:** godot/scripts/systems/item_box.gd; godot/scripts/systems/inventory.gd; godot/scripts/scenes/sandbox_gameplay.gd; godot/scripts/systems/radio_system.gd

**Integração inspecionada:** godot/scripts/scenes/sandbox_gameplay.gd::_spawn_room_items; godot/scripts/systems/radio_system.gd::get_transmission_result

**Testes existentes:** Nenhum localizado neste recorte.

**Documentação:** docs/reverse_engineering/inventory-and-events.md

**Histórico consultado:** docs/progress/2026-09.md::2026-09-20 — Etapa 9: Portas Interativas, Caixas de Itens e Inventário

**Implementado:** Nenhum localizado neste recorte.

**Faltante / não comprovado:** Aquisição ID 16 e flag de elegibilidade por posse para consumidor do rádio.

**Notas de evidência:** Factory de itens, inventário e consumidores de uso/dano/navegação foram cruzados: não há caminho funcional para este item; IDs estáticos não mapeados caem em RATION. radio_system.get_transmission_result recebe sala/frequência, sem flag de posse da antena.; Busca por nomes/IDs foi cruzada com despacho e dados; atlas/HUD isolados não contam como efeito. Nenhum teste específico nem entrega desse efeito localizado no índice/histórico de inventário.


<a id="oxygen-tank"></a>
### Oxygen Tank

`oxygen-tank` · **NOT_STARTED**

**Original:** Seleção evita perda de 2 de vida a cada oito ticks em água profunda. Movimento/salas de água não entram neste recorte.

**Classificação:** O original está identificado; a cadeia de aquisição, despacho de uso e consumidores inspecionada não inicia este efeito. Ícones e metadados não contam como gameplay.

**Assembly:** Banks0123.asm:9248-9260 SetInWaterMode3; logic/damagegas.asm:36-46 DecrementLife_C

**Extractors:** tools/extractors/extract.py; tools/extractors/export_room_data.py

**Dados canônicos locais:** package/package.json; rooms/room-200-actors.json

**Godot relacionado:** godot/scripts/systems/item_box.gd; godot/scripts/systems/inventory.gd; godot/scripts/systems/player.gd; godot/scripts/scenes/sandbox_gameplay.gd

**Integração inspecionada:** godot/scripts/scenes/sandbox_gameplay.gd::_spawn_room_items; godot/scripts/systems/player.gd::apply_damage

**Testes existentes:** Nenhum localizado neste recorte.

**Documentação:** docs/reverse_engineering/inventory-and-events.md

**Histórico consultado:** docs/progress/2026-09.md::2026-09-20 — Etapa 9: Portas Interativas, Caixas de Itens e Inventário

**Implementado:** Nenhum localizado neste recorte.

**Faltante / não comprovado:** Aquisição ID 18 e proteção seletiva no caminho de dano em água.

**Notas de evidência:** Factory de itens, inventário e consumidores de uso/dano/navegação foram cruzados: não há caminho funcional para este item; IDs estáticos não mapeados caem em RATION.; Busca por nomes/IDs foi cruzada com despacho e dados; atlas/HUD isolados não contam como efeito. Nenhum teste específico nem entrega desse efeito localizado no índice/histórico de inventário.


<a id="compass"></a>
### Compass

`compass` · **NOT_STARTED**

**Original:** Na sala 103, seleção permite saída sem o redirecionamento do deserto; direção Down é exceção sem bússola.

**Classificação:** O original está identificado; a cadeia de aquisição, despacho de uso e consumidores inspecionada não inicia este efeito. Ícones e metadados não contam como gameplay.

**Assembly:** logic/nextroom.asm:12-51 SetNextRoom

**Extractors:** tools/extractors/extract.py; tools/extractors/export_room_data.py

**Dados canônicos locais:** package/package.json; rooms/room-184-actors.json

**Godot relacionado:** godot/scripts/systems/item_box.gd; godot/scripts/systems/inventory.gd; godot/scripts/systems/room_manager.gd; godot/scripts/scenes/sandbox_gameplay.gd

**Integração inspecionada:** godot/scripts/scenes/sandbox_gameplay.gd::_spawn_room_items

**Testes existentes:** Nenhum localizado neste recorte.

**Documentação:** docs/reverse_engineering/inventory-and-events.md

**Histórico consultado:** docs/progress/2026-09.md::2026-09-20 — Etapa 9: Portas Interativas, Caixas de Itens e Inventário

**Implementado:** Nenhum localizado neste recorte.

**Faltante / não comprovado:** Aquisição ID 19 e seleção como entrada da regra de navegação.

**Notas de evidência:** Factory de itens, inventário e consumidores de uso/dano/navegação foram cruzados: não há caminho funcional para este item; IDs estáticos não mapeados caem em RATION.; Busca por nomes/IDs foi cruzada com despacho e dados; atlas/HUD isolados não contam como efeito. Nenhum teste específico nem entrega desse efeito localizado no índice/histórico de inventário.


<a id="parachute"></a>
### Parachute

`parachute` · **NOT_STARTED**

**Original:** Seleção converte a saída do terraço em descida por room 204; sem ela há queda livre fatal. A regra de seleção é o recorte, não as salas da queda.

**Classificação:** O original está identificado; a cadeia de aquisição, despacho de uso e consumidores inspecionada não inicia este efeito. Ícones e metadados não contam como gameplay.

**Assembly:** logic/nextroom.asm:204-219 ChkParachute

**Extractors:** tools/extractors/extract.py; tools/extractors/export_room_data.py

**Dados canônicos locais:** package/package.json; rooms/room-143-actors.json

**Godot relacionado:** godot/scripts/systems/item_box.gd; godot/scripts/systems/inventory.gd; godot/scripts/systems/player.gd; godot/scripts/scenes/sandbox_gameplay.gd

**Integração inspecionada:** godot/scripts/scenes/sandbox_gameplay.gd::_spawn_room_items

**Testes existentes:** Nenhum localizado neste recorte.

**Documentação:** docs/reverse_engineering/inventory-and-events.md

**Histórico consultado:** docs/progress/2026-09.md::2026-09-20 — Etapa 9: Portas Interativas, Caixas de Itens e Inventário

**Implementado:** Nenhum localizado neste recorte.

**Faltante / não comprovado:** Aquisição ID 20 e gate que distingue queda com paraquedas.

**Notas de evidência:** Factory de itens, inventário e consumidores de uso/dano/navegação foram cruzados: não há caminho funcional para este item; IDs estáticos não mapeados caem em RATION.; Busca por nomes/IDs foi cruzada com despacho e dados; atlas/HUD isolados não contam como efeito. Nenhum teste específico nem entrega desse efeito localizado no índice/histórico de inventário.


<a id="antidote"></a>
### Antidote reutilizável

`antidote` · **NOT_STARTED**

**Original:** Uso manual limpa Poisoned sem decrementar ou remover o antídoto. Selecionar por si só não executa cura.

**Classificação:** O original está identificado; a cadeia de aquisição, despacho de uso e consumidores inspecionada não inicia este efeito. Ícones e metadados não contam como gameplay.

**Assembly:** logic/menuequipment.asm:255-261 ChkUseAntidote

**Extractors:** tools/extractors/extract.py; tools/extractors/export_room_data.py

**Dados canônicos locais:** package/package.json; rooms/room-183-actors.json

**Godot relacionado:** godot/scripts/systems/item_box.gd; godot/scripts/systems/inventory.gd; godot/scripts/scenes/sandbox_gameplay.gd

**Integração inspecionada:** godot/scripts/scenes/sandbox_gameplay.gd::_spawn_room_items; godot/scripts/systems/inventory.gd::use_selected_item

**Testes existentes:** Nenhum localizado neste recorte.

**Documentação:** docs/reverse_engineering/inventory-and-events.md

**Histórico consultado:** docs/progress/2026-09.md::2026-09-20 — Etapa 9: Portas Interativas, Caixas de Itens e Inventário

**Implementado:** Nenhum localizado neste recorte.

**Faltante / não comprovado:** ID 21 não virar ração; handler que limpa envenenamento e mantém o item.

**Notas de evidência:** Factory de itens, inventário e consumidores de uso/dano/navegação foram cruzados: não há caminho funcional para este item; IDs estáticos não mapeados caem em RATION.; Busca por nomes/IDs foi cruzada com despacho e dados; atlas/HUD isolados não contam como efeito. Nenhum teste específico nem entrega desse efeito localizado no índice/histórico de inventário.


<a id="transmitter"></a>
### Transmissor recuperado e descarte

`transmitter` · **NOT_STARTED**

**Original:** Bolsa insere transmissor; posse marcada por TransmiTaken causa/sustenta alerta, e uso remove o item e apaga a flag.

**Classificação:** O original está identificado; a cadeia de aquisição, despacho de uso e consumidores inspecionada não inicia este efeito. Ícones e metadados não contam como gameplay.

**Assembly:** logic/items.asm:295-320; logic/menuequipment.asm:238-248 ChkDropTransmitter; Banks0123.asm:1590-1603; Banks0123.asm:6635-6640

**Extractors:** Nenhum localizado neste recorte.

**Dados canônicos locais:** Nenhum localizado neste recorte.

**Godot relacionado:** godot/scripts/systems/item_box.gd; godot/scripts/systems/inventory.gd; godot/scripts/systems/capture_system.gd; godot/scripts/systems/alert_system.gd

**Integração inspecionada:** godot/scripts/scenes/sandbox_gameplay.gd::_spawn_room_items; godot/scripts/systems/capture_system.gd::restore_equipment; godot/scripts/systems/inventory.gd::use_selected_item

**Testes existentes:** Nenhum localizado neste recorte.

**Documentação:** docs/reverse_engineering/inventory-and-events.md

**Histórico consultado:** docs/progress/2026-09.md::2026-09-20 — Etapa 9: Portas Interativas, Caixas de Itens e Inventário

**Implementado:** Nenhum localizado neste recorte.

**Faltante / não comprovado:** Inserção ao recuperar bolsa, efeito por posse e descarte manual.

**Notas de evidência:** restore_equipment restaura arrays, mas não injeta transmissor; use_selected_item só trata ração e alert_system não consulta TransmiTaken. Não há teste específico de posse/descarte.; Busca por nomes/IDs foi cruzada com despacho e dados; atlas/HUD isolados não contam como efeito. Nenhum teste específico nem entrega desse efeito localizado no índice/histórico de inventário.


<a id="uniform"></a>
### Uniform

`uniform` · **PROVISIONAL**

**Original:** Seleção evita o alerta imediato da segurança do acesso ao edifício 2; não basta possuir uniforme. Máquina da segurança é externa.

**Classificação:** A aquisição ou representação existe, mas o uso corresponde a um substituto ou não possui o efeito específico original.

**Assembly:** logic/actors/desertsecurity.asm:65-74 DesertSecurity2

**Extractors:** tools/extractors/extract.py; tools/extractors/export_room_data.py

**Dados canônicos locais:** package/package.json; rooms/room-169-actors.json; rooms/room-177-actors.json

**Godot relacionado:** godot/scripts/systems/item_box.gd; godot/scripts/systems/inventory.gd; godot/scripts/scenes/sandbox_gameplay.gd

**Integração inspecionada:** godot/scripts/scenes/sandbox_gameplay.gd::_spawn_room_items

**Testes existentes:** Nenhum localizado neste recorte.

**Documentação:** docs/reverse_engineering/inventory-and-events.md

**Histórico consultado:** docs/progress/2026-09.md::2026-09-20 — Etapa 9: Portas Interativas, Caixas de Itens e Inventário

**Implementado:** IDs 32 viram UNIFORM coletável.

**Faltante / não comprovado:** Consumidor da seleção no acesso do deserto.

**Notas de evidência:** Factory de itens, inventário e consumidores de uso/dano/navegação foram cruzados: há apenas representação/posse, sem o efeito descrito.; Busca por nomes/IDs foi cruzada com despacho e dados; atlas/HUD isolados não contam como efeito. Nenhum teste específico nem entrega desse efeito localizado no índice/histórico de inventário.


<a id="goggles"></a>
### Goggles: visibilidade dos lasers e paleta

`goggles` · **PARTIAL**

**Original:** Selecionar goggles revela feixes quando fora do alerta e altera a paleta para tons de cinza; não torna Snake imune a laser.

**Classificação:** Há comportamento específico integrado, mas as divergências abaixo impedem equivalência ao recorte original.

**Assembly:** logic/drawlaserbeams.asm:7-24 DrawLaserBeams; Banks0123.asm:2967-2975 ChkGogglesPal

**Extractors:** tools/extractors/extract.py; tools/extractors/export_room_data.py

**Dados canônicos locais:** package/package.json; rooms/room-139-actors.json

**Godot relacionado:** godot/scripts/systems/inventory.gd; godot/scripts/systems/laser_system.gd; godot/scripts/scenes/sandbox_gameplay.gd

**Integração inspecionada:** godot/scripts/systems/laser_system.gd::tick; godot/scripts/systems/laser_system.gd::_draw; godot/scripts/scenes/sandbox_gameplay.gd::_physics_process

**Testes existentes:** godot-cameras-and-lasers

**Documentação:** docs/reverse_engineering/inventory-and-events.md

**Histórico consultado:** docs/progress/2026-09.md::2026-09-20 — Etapa 9: Portas Interativas, Caixas de Itens e Inventário

**Implementado:** Seleção alimenta LaserSystem; _draw oculta feixes sem goggles e no alerta.

**Faltante / não comprovado:** Reproduzir efeito de paleta; validação integrada do efeito de seleção, além de fixtures de laser.

**Notas de evidência:** Não há consumidor da seleção que aplique paleta cinza. Feixes e alarmes permanecem em cameras-lasers/actor-lasers, sem reclassificação.


<a id="gas-mask"></a>
### Gas Mask: proteção por seleção

`gas-mask` · **IMPLEMENTED**

**Original:** Quando SelectedItem é GAS_MASK, o teste de gás não decrementa vida; mera posse sem seleção não protege. Esta feature é só o efeito de equipamento, não geração de nuvens/salas ou apresentação.

**Classificação:** O efeito declarado é específico, integrado e coberto por testes pertinentes; coleta e sistemas ambientais são auditados separadamente.

**Assembly:** logic/damagegas.asm:29-46 ChkGasMask

**Extractors:** tools/extractors/extract.py; tools/extractors/export_room_data.py; tools/extractors/extract_gas_hazard.py

**Dados canônicos locais:** gas_hazard.json; rooms/room-138-actors.json

**Godot relacionado:** godot/scripts/systems/inventory.gd; godot/scripts/systems/gas_hazard_system.gd; godot/scripts/scenes/sandbox_gameplay.gd

**Integração inspecionada:** godot/scripts/systems/gas_hazard_system.gd::is_player_protected; godot/scripts/systems/gas_hazard_system.gd::tick; godot/scripts/scenes/sandbox_gameplay.gd::_physics_process

**Testes existentes:** godot-gas-hazard

**Documentação:** docs/reverse_engineering/inventory-and-events.md; docs/reverse_engineering/stage-19-gas-hazard.md

**Histórico consultado:** docs/progress/2026-09.md::2026-09-20 — Etapa 9: Portas Interativas, Caixas de Itens e Inventário

**Implementado:** is_player_protected exige item selecionado; tick usa a proteção antes de dano e integração recebe o inventário atual; testes verificam selecionada e não selecionada.

**Faltante / não comprovado:** Nenhum localizado neste recorte.

**Notas de evidência:** gas_hazard_test.gd:98-136 cobre proteção e ausência de proteção. Coleta/persistência e fidelidade global dos hazards não são inferidas deste status.


<a id="access-cards"></a>
### Cartões 1 a 8 e uso por seleção exata

`access-cards` · **PARTIAL**

**Original:** Oito cartões independentes: pickups 22–29, selected IDs 14–21. ChkCard exige exatamente o cartão selecionado e direção correspondente, sem chave universal por rank ou cartão superior.

**Classificação:** Há comportamento específico integrado, mas as divergências abaixo impedem equivalência ao recorte original.

**Assembly:** constants/Enums.asm:96-103; logic/doors/opendoor.asm:121-134 ChkCard; logic/spawnitem.asm:71-75

**Extractors:** tools/extractors/extract.py; tools/extractors/export_room_data.py

**Dados canônicos locais:** package/package.json; rooms/room-122-actors.json; rooms/room-127-actors.json

**Godot relacionado:** godot/scripts/systems/inventory.gd; godot/scripts/systems/door.gd; godot/scripts/scenes/sandbox_gameplay.gd

**Integração inspecionada:** godot/scripts/systems/door.gd::check_interaction; godot/scripts/scenes/sandbox_gameplay.gd::_spawn_room_items

**Testes existentes:** godot-doors-inventory; godot-building-doors

**Documentação:** docs/reverse_engineering/inventory-and-events.md

**Histórico consultado:** docs/progress/2026-09.md::2026-09-20 — Etapa 9: Portas Interativas, Caixas de Itens e Inventário

**Implementado:** Strings CARD1..8 e posse por inventário; portas verificam cartão exigido.

**Faltante / não comprovado:** Exigir seleção exata em vez de has_item; provar aquisição por eventos dos cartões 7/8 sem presumir pickups estáticos.

**Notas de evidência:** door.gd:373-454 aceita posse, divergindo do assembly e da documentação de inventário. Teste coleta CARD1 como primeira seleção e não distingue posse de seleção.; 6 cartões têm registros estáticos; 7/8 dependem de produtores de eventos/bosses (fora desta auditoria). Não criar oito features idênticas nem reclassificar bosses por essa dependência.


<a id="ration"></a>
### Rações: uso manual e cura

`ration` · **PARTIAL**

**Original:** Pickup 30 adiciona uma ração; uso manual no menu restaura MaxLife, consome unidade e remove ao esgotar, exceto em água profunda. Capacidade 3/6/9/12 conforme Class.

**Classificação:** Há comportamento específico integrado, mas as divergências abaixo impedem equivalência ao recorte original.

**Assembly:** logic/menuequipment.asm:208-231 ChkUseItem; logic/items.asm:425-442; logic/maxammo.asm:10-103; Banks0123.asm:1858-1896

**Extractors:** tools/extractors/extract.py; tools/extractors/export_room_data.py

**Dados canônicos locais:** package/package.json; rooms/room-126-actors.json; rooms/room-158-actors.json

**Godot relacionado:** godot/scripts/systems/inventory.gd; godot/scripts/systems/player.gd; godot/scripts/scenes/sandbox_gameplay.gd

**Integração inspecionada:** godot/scripts/systems/inventory.gd::use_selected_item; godot/scripts/scenes/sandbox_gameplay.gd::_input

**Testes existentes:** godot-doors-inventory; godot-rank-and-prisoners

**Documentação:** docs/reverse_engineering/inventory-and-events.md

**Histórico consultado:** docs/progress/2026-09.md::2026-09-20 — Etapa 9: Portas Interativas, Caixas de Itens e Inventário

**Implementado:** Quantidade, limites, cura total e remoção da ração vazia; uso rápido integrado.

**Faltante / não comprovado:** Proibição de uso em água profunda e semântica de seleção ao consumir última unidade; comportamento renovável separado.

**Notas de evidência:** Não classificar cura automática como faltante: nas rotinas de vida e usos consultadas não há resgate automático por ração. O original confirmado aqui é uso manual.


<a id="cardboard-box"></a>
### Caixa de papelão: ocultação e restrições

`cardboard-box` · **PARTIAL**

**Original:** Seleção ativa animação de caixa, invisibilidade a guardas/câmeras fora do alerta apenas enquanto parada e bloqueia soco/disparo. Mira da granada é escondida.

**Classificação:** Há comportamento específico integrado, mas as divergências abaixo impedem equivalência ao recorte original.

**Assembly:** Banks0123.asm:8499-8511; logic/actors/chkdiscover.asm:12-47 ChkSeePlayer; logic/weaponuse.asm:8-30; Banks0123.asm:8934-8962; Banks0123.asm:12193-12195

**Extractors:** tools/extractors/extract.py; tools/extractors/export_room_data.py

**Dados canônicos locais:** package/package.json; rooms/room-156-actors.json

**Godot relacionado:** godot/scripts/systems/inventory.gd; godot/scripts/systems/player.gd; godot/scripts/scenes/sandbox_gameplay.gd

**Integração inspecionada:** godot/scripts/systems/player.gd::punch; godot/scripts/systems/player.gd::fire_weapon; godot/scripts/scenes/sandbox_gameplay.gd::_physics_process

**Testes existentes:** godot-cameras-and-lasers

**Documentação:** docs/reverse_engineering/inventory-and-events.md

**Histórico consultado:** docs/progress/2026-09.md::2026-09-20 — Etapa 9: Portas Interativas, Caixas de Itens e Inventário

**Implementado:** Seleção, estado is_in_box e gate de visão quando parada; representação de caixa.

**Faltante / não comprovado:** Bloquear ataques em caixa e sincronizar estados/efeitos com regras do original.

**Notas de evidência:** Bloqueio visual em sandbox não bloqueia fire_weapon/punch. Teste de câmera/ocultação não comprova restrições de uso de armas.


<a id="equipment-bag"></a>
### Bolsa recuperável e restituição de equipamentos

`equipment-bag` · **PARTIAL**

**Original:** Pickup 34 termina remoção de equipamento, marca bolsa recuperada e adiciona transmissor ao primeiro slot livre. Captura, paredes e fala associada não integram este domínio.

**Classificação:** Há comportamento específico integrado, mas as divergências abaixo impedem equivalência ao recorte original.

**Assembly:** logic/items.asm:295-320 RecoverEquipment

**Extractors:** tools/extractors/extract.py; tools/extractors/export_room_data.py

**Dados canônicos locais:** package/package.json; rooms/room-168-actors.json

**Godot relacionado:** godot/scripts/systems/capture_system.gd; godot/scripts/systems/item_box.gd; godot/scripts/systems/inventory.gd; godot/scripts/systems/weapon_system.gd

**Integração inspecionada:** godot/scripts/systems/capture_system.gd::restore_equipment; godot/scripts/systems/item_box.gd::step_tick

**Testes existentes:** godot-capture-prison

**Documentação:** docs/reverse_engineering/inventory-and-events.md

**Histórico consultado:** docs/progress/2026-09.md::2026-09-21 — Etapa 21: Evento de Captura na Sala 8, Cela 211, Parede Oca e Restituição de Inventário

**Implementado:** Captura salva/restaura arsenal, munições, itens e seleção; pickup BAG invoca restauração.

**Faltante / não comprovado:** Adicionar transmissor original; distinguir restauração de equipamento real do fallback inventado quando não há snapshot anterior.

**Notas de evidência:** restore_equipment:146-184 não inclui transmissor; caminho sem captura anterior concede loadout fixo (cartões/cigarros/ração/HG), não uma restauração comprovada. Suíte não exige transmissor.
