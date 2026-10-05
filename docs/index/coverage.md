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
| `IMPLEMENTED` | 1 |
| `PARTIAL` | 20 |
| `PROVISIONAL` | 12 |
| `NOT_STARTED` | 16 |
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
| [rolling-barrels](#rolling-barrels) — Barris rolantes | ator: 15 | `IMPLEMENTED` |
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

`rolling-barrels` · **IMPLEMENTED**

**Original:** Coluna de 9 barris (18 sprites, SpriteId 36h/37h) que rola horizontalmente com aceleração, ricocheteia nas paredes X=200/56, mata por toque e absorve tiros e explosivos sem ser destruída.

**Classificação:** RollingBarrel reproduz InitRollingBarrel, RollingBarrelLogic, MoveActor, ChkActorExitRoom, ChkTouchEnemy e ChkEneHitByShot com aritmética de 8/16 bits; o sandbox usa o spritesheet extraído da ROM canônica e a suíte compara constantes e áreas com o JSON extraído.

**Assembly:** logic/actors/rollingbarrels.asm:8-132 RollingBarrelLogic; Banks0123.asm:6358-6402 SetupActor; Banks0123.asm:12612-12672 EnemiesLogic; Banks0123.asm:12875-12919 MoveActor; logic/touchenemy.asm:54-189 ChkTouchEnemy; logic/damagetoenemy.asm:92-228 ChkEneHitByShot

**Extractors:** tools/extractors/extract_rolling_barrel.py; tools/extractors/extract.py; tools/extractors/export_room_data.py

**Dados canônicos locais:** rolling-barrel/; rooms/

**Godot relacionado:** godot/scripts/systems/rolling_barrel.gd; godot/scripts/scenes/sandbox_gameplay.gd

**Integração inspecionada:** godot/scripts/scenes/sandbox_gameplay.gd::_spawn_room_enemies; godot/scripts/scenes/sandbox_gameplay.gd::_physics_process; godot/scripts/scenes/sandbox_gameplay.gd::_on_plastic_bomb_exploded

**Testes existentes:** godot-rolling-barrels; tests/test_rolling_barrel_extractor.py; tests/test_extractors.py

**Documentação:** docs/reverse_engineering/enemies.md; docs/reverse_engineering/stage-12b-actors-and-items-evidence.md

**Histórico consultado:** docs/progress/2026-09.md::2026-09-20 — Etapa 12b concluída: Spawn de Inimigos, Itens e Portas Canônicas da ROM

**Implementado:** Init: velocidade ±80h por PlayerX, Direction 0 herdada da EnemyList zerada, SpriteId 36h, MOVING=1.; RollingBarrelLogic: Anim2FramesActor máscara 3, ChkBarrelBounce (X=199/57 preservando Xdec, DIR_DOWN/DIR_LEFT, SFX 1Dh) e RB_IncrementSpeed ±8 por bit 0 de Direction.; MoveActor 8.8 em 16 bits e ChkActorExitRoom na ordem de EnemiesLogic.; ChkArea de toque na coluna inteira (ImpactAreasInfo linha 10h = 48h,48h,0,0Ch) com dano FFh; tiro e explosivos na linha 11h (48h,48h,0,10h); dano 0/FFh de todas as armas; não socável; Snake desenhado à frente (plano 0).; Sprites canônicos extraídos da ROM (SprRollingBarrel, RollBarrels1/2, SprOffsets7, ActorSprColors3 com Color Compare, SprsetPal19 sobre a paleta das salas 141, 153, 191 e 205).

**Faltante / não comprovado:** Nenhum localizado neste recorte.

**Notas de evidência:** Revisão de 2026-10-04 corrigiu a versão anterior: hitbox 16x16 e destruição por tiro/bomba contrariavam data/weapondamage.asm:18-58 (índice 14 = 0, granada FFh) e ImpactAreasInfo linha 11h (48h,48h,0,10h); direção inicial pelo jogador contrariava SetupActor/InitRollingBarrel.; Extrator localiza todas as tabelas como segmentos binary_verified e confere 6 assinaturas Z80 únicas de rollingbarrels.asm; spawn (128,8) em data/actorsinrooms.asm:860-866; spriteset 19 em SpritesetRooms.; Salas: idxActorsRooms reutiliza ActorsRoom141 nas salas 153 e 191 (data/actorsinrooms.asm:1167, 1179, 1217, 1231; indexada por Room em Banks0123.asm:6141-6147); as quatro salas usam spriteset 19 e têm spritesheet extraído. touchenemy.asm:87-93 e damagetoenemy.asm:98-102 fazem inc a antes de GetShapeInfo (DEC_A_HL_4xA), logo a linha de ImpactAreasInfo é o próprio valor de shape; a leitura shape-1 anterior deixava o toque restrito ao barril superior e Snake nunca era atingido. Snake usa SprAttRAM (plano 0, Banks0123.asm:5414-5424) e fica à frente da coluna.; SFX 1Dh é emitido pelo sinal sfx_requested; o projeto ainda não tem subsistema de áudio. Paleta cinza dos óculos (SetRoomPal/ChkGogglesPal) não foi aplicada ao sprite.


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

**Integração inspecionada:** godot/scripts/scenes/sandbox_gameplay.gd::_spawn_room_items; godot/scripts/systems/radio_system.gd::_reply_allowed

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

## Sistema de rádio/transceptor, chamadas, mensagens e diálogos

Auditoria: 2026-10-04; HEAD de partida: `b68b8f7`; referência inglesa: `30d1b940bede10fdabbaf9767ad4f0ad8dd33291`.

Inventário do sistema de rádio/transceptor (GAME_MODE_RADIO), sintonia, contatos e frequências da edição inglesa RC750 (JAPANESE equ 0), modos SEND/RECV, WAITCALL vs AUTOREPLY, chamadas automáticas/indicador CALL no HUD, despacho de chamadas por sala (idxRoomRadio), regras e condições de contato (antena, rank, mortes, grampos, MSX switch off), sistema unificado de caixas de texto (TextBoxLogic, geometrias, animação de abertura, modos de controle de avanço skippable/unskippable, typewriter, ícone enter, métricas de caracteres), decodificação de textos da ROM (DecodeText e dicionário), diálogos de prisioneiros/reféns, diálogos de chefes/inimigos, briefing da introdução e mensagens contextuais. Exclui lógica física de combate já coberta em actors-bosses, inventário/armas/itens já cobertos em weapons-items, áudio/música como domínio separado e cutscenes completas.

Inventário original primeiro a partir da desmontagem canônica inglesa (Banks0123.asm, logic/incomingcall.asm, data/radiocalls.asm, data/texts.asm, logic/textboxappear.asm, logic/capturescene.asm, logic/introscene.asm, logic/actors/prisoner.asm, logic/actors/*.asm, Variables.asm, constants/Enums.asm). Cruzamento estático com extratores existentes (extract_grey_fox_dialogue.py, extract_transceiver_sprites.py), sistemas Godot (radio_system.gd, radio_dialog.gd, prisoner_dialog.gd, capture_cutscene.gd, hud.gd, sandbox_gameplay.gd, prisoner.gd), testes automatizados (radio_system_test.gd, prisoner_dialog_test.gd, capture_prison_test.gd, intro_cutscene_test.gd), documentação e histórico. Classificação segundo os 7 statuses formais sem promover a IMPLEMENTED suítes verdes com divergências de fidelidade. Sem alterações de código de gameplay nesta tarefa.

- Domínio estritamente focado no sistema de comunicação por rádio, seleção/despacho de mensagens e motor de caixas de texto.
- Não possui IDs numéricos de entidade (actor_ids, weapon_ids, etc.); cada feature cobre uma mecânica ou subsistema funcional transversal.
- Nenhuma feature foi promovida a IMPLEMENTED porque todos os sistemas de diálogo e rádio atuais possuem pendências concretas: strings hardcoded parafraseadas, ausência de motor unificado de caixas de texto ou ausência de condições canônicas do Z80.
- Features legadas 'radio' e 'text-window' foram integradas ao domínio radio-dialogue para manter referências cruzadas existentes de outros domínios intactas.
- Status UNMAPPED atribuído à verificação de Text ID 15 e MadnarMoved em ChkReplyMadnar por ser código anômalo/morto sem correspondência em radiocalls.asm.

| Status | Features |
| --- | ---: |
| `IMPLEMENTED` | 7 |
| `PARTIAL` | 19 |
| `PROVISIONAL` | 3 |
| `NOT_STARTED` | 2 |
| `DEFERRED` | 0 |
| `UNMAPPED` | 1 |
| `INVESTIGATING` | 0 |
| Total | 32 |

### Entradas

| Feature | IDs | Status |
| --- | --- | --- |
| [radio](#radio) — Transceptor: tela, modo de jogo e interface central | transversal | `PARTIAL` |
| [text-window](#text-window) — Motor de janela de texto: TextBoxLogic e despacho central | transversal | `PROVISIONAL` |
| [radio-tuning-frequency](#radio-tuning-frequency) — Sintonia de frequências e display digital BCD | transversal | `IMPLEMENTED` |
| [radio-contacts-frequencies](#radio-contacts-frequencies) — Contatos e frequências canônicas da edição inglesa | transversal | `PARTIAL` |
| [radio-transmission-modes](#radio-transmission-modes) — Modos de transmissão: envio (SEND) vs escuta (RECV) | transversal | `PARTIAL` |
| [radio-auto-reply-waitcall](#radio-auto-reply-waitcall) — Despacho de resposta: AUTO-REPLY vs WAIT-CALL | transversal | `IMPLEMENTED` |
| [radio-auto-tune](#radio-auto-tune) — Sintonia automática ao atender chamadas (Auto-Tune) | transversal | `IMPLEMENTED` |
| [radio-signal-led-bars](#radio-signal-led-bars) — Animação e temporização das 12 barras de sinal LED | transversal | `IMPLEMENTED` |
| [radio-incoming-call-detection](#radio-incoming-call-detection) — Detecção e ciclo de vida de chamadas recebidas (Incoming Calls) | transversal | `IMPLEMENTED` |
| [radio-hud-call-indicator](#radio-hud-call-indicator) — Indicador CALL no HUD e sinal sonoro do buzzer | transversal | `PARTIAL` |
| [radio-room-dispatch-table](#radio-room-dispatch-table) — Tabela canônica de despachos de rádio por sala (idxRoomRadio) | transversal | `IMPLEMENTED` |
| [radio-cond-antenna](#radio-cond-antenna) — Condição de rádio: exigência da antena no Edifício 2 | transversal | `IMPLEMENTED` |
| [radio-cond-schneider](#radio-cond-schneider) — Condições de rádio: Schneider (chamadas ativas e captura) | transversal | `PARTIAL` |
| [radio-cond-jennifer](#radio-cond-jennifer) — Condições de rádio: Jennifer (Rank 4 e vingança pelo irmão) | transversal | `PARTIAL` |
| [radio-cond-bigboss-bug](#radio-cond-bigboss-bug) — Condição de rádio: aviso de grampo/transmissor por Big Boss | transversal | `PARTIAL` |
| [radio-cond-bigboss-switch-off](#radio-cond-bigboss-switch-off) — Condição de rádio: ordem de desligar o MSX por Big Boss | transversal | `PARTIAL` |
| [radio-chk-reply-madnar-text15](#radio-chk-reply-madnar-text15) — Checagem anômala de Text ID 15 e MadnarMoved no rádio | transversal | `UNMAPPED` |
| [text-box-geometry-types](#text-box-geometry-types) — Tipos e geometrias de caixas de texto (TextBoxType) | transversal | `PARTIAL` |
| [text-appearance-animation](#text-appearance-animation) — Animação de abertura e fechamento da caixa de texto | transversal | `PARTIAL` |
| [text-skip-control-modes](#text-skip-control-modes) — Controle de avanço e pulo de texto: skippable vs unskippable | transversal | `PARTIAL` |
| [text-typewriter-audio](#text-typewriter-audio) — Efeito de digitação (Typewriter) e áudio de fala | transversal | `PARTIAL` |
| [text-prompt-enter-blink](#text-prompt-enter-blink) — Ícone de ENTER piscante no fim da página | transversal | `PARTIAL` |
| [text-char-metrics-widths](#text-char-metrics-widths) — Métricas de caracteres e espaçamento proporcional | transversal | `PARTIAL` |
| [text-decoder-rom-dictionary](#text-decoder-rom-dictionary) — Decodificador de texto da ROM e dicionário de tokens | transversal | `PARTIAL` |
| [text-event-triggers](#text-event-triggers) — Disparo de eventos e flags ao término do diálogo | transversal | `NOT_STARTED` |
| [radio-portrait-snake-animation](#radio-portrait-snake-animation) — Animação do retrato de Solid Snake durante a fala | transversal | `PARTIAL` |
| [hostage-dialogue-system](#hostage-dialogue-system) — Diálogos de reféns e prisioneiros (Hostages/Prisoners) | transversal | `PARTIAL` |
| [boss-enemy-speech-dialogue](#boss-enemy-speech-dialogue) — Diálogos e falas de chefes e inimigos | transversal | `PARTIAL` |
| [intro-mission-briefing](#intro-mission-briefing) — Briefing da missão na introdução (Operação Intrude N313) | transversal | `PARTIAL` |
| [gameplay-contextual-messages](#gameplay-contextual-messages) — Mensagens contextuais de gameplay e avisos de perigo | transversal | `PROVISIONAL` |
| [ending-broadcast-dialogue](#ending-broadcast-dialogue) — Diálogo final e transmissão de notícias do encerramento | transversal | `NOT_STARTED` |
| [fake-madnar-trap-dialogue](#fake-madnar-trap-dialogue) — Diálogo do Falso Madnar e armadilha de alçapão | transversal | `PROVISIONAL` |

### UNMAPPED

- **radio-chk-reply-madnar-text15**: Classificado como UNMAPPED porque a rotina original testa um Text ID que o despachador de rádio nunca gera, tratando-se de código anômalo ou resquício de desenvolvimento.

<a id="radio"></a>
### Transceptor: tela, modo de jogo e interface central

`radio` · **PARTIAL**

**Original:** GAME_MODE_RADIO (0x04) em Enums.asm:51. DrawRadio (Banks0123.asm:10695-10731): limpa tela e sprites, define paleta do rádio Screen 5, renderiza blocos de tiles do chassi (RadioTilesMap 18x9 tiles) e retrato de Snake (SnakeTilesMap 4x4 tiles), imprime TRANSCEIVER e RECV, renderiza HUD inferior, toca ruído estático SFX 50h, para flag de chamada pendente (RadioCallFlag = 2). Pausa o gameplay e retorna via ExitRadio (Banks0123.asm:11343-11350).

**Classificação:** Interface visual e ciclo de pausa existem e funcionam, mas com máquina de estados simplificada, textos provisórios inexistentes na ROM e ausência do modo formal da engine.

**Assembly:** Banks0123.asm:10695-10731 DrawRadio; Banks0123.asm:11343-11350 ExitRadio; constants/Enums.asm:51 GAME_MODE_RADIO

**Extractors:** tools/extractors/extract_transceiver_sprites.py

**Dados canônicos locais:** Nenhum localizado neste recorte.

**Godot relacionado:** godot/scripts/systems/radio_dialog.gd; godot/scripts/scenes/sandbox_gameplay.gd

**Integração inspecionada:** godot/scripts/scenes/sandbox_gameplay.gd::_on_radio_closed; godot/scripts/systems/radio_dialog.gd::open_radio; godot/scripts/systems/radio_dialog.gd::close_radio

**Testes existentes:** godot-radio-system; tests/test_region_tools.py

**Documentação:** docs/reverse_engineering/en-eu-reextraction.md

**Histórico consultado:** docs/progress/2026-09.md::2026-09-20 — Etapa 15 concluída: Sistema de Rádio Transceptor (Transceiver / Codec); docs/progress.md::2026-10-04 — Sistema de rádio: tabela canônica, chamadas e AUTO-REPLY/WAIT-CALL

**Implementado:** RadioDialog dirigido por radio_tick a cada physics tick (estados DrawRadio/RadioIdle/RadioSignalUp/SetupRadioReply/RadioSignalOFF); textos extraídos da ROM; janela de texto suspende o RadioLogic; F4/T só saem fora da janela de texto. Textos inventados removidos.

**Faltante / não comprovado:** Ruído contínuo SFX 50h só como sinal; não usa GAME_MODE_RADIO formal; animação do retrato e geometria da caixa seguem em features próprias.

**Notas de evidência:** Substituto provisório da tela de rádio inclui textos 'TRANSCEIVER ONLINE...' não presentes na ROM; SFX 50h e 5Ch não acionados; ausência de modo formal GAME_MODE_RADIO.


<a id="text-window"></a>
### Motor de janela de texto: TextBoxLogic e despacho central

`text-window` · **PROVISIONAL**

**Original:** Modo de jogo central GAME_MODE_TEXT_BOX (0x0A) acionado por SetText/SetTextUnskippable (Banks0123.asm:7808-7829). TextBoxLogic (Banks0123.asm:7837-7860) despacha a máquina de estados: TW_Init, TextBoxAppear, TW_PrintChar, TW_Wait, TW_GetTextPage, TextBox_End. Ao terminar, restaura PrevGameMode.

**Classificação:** As implementações locais funcionam para seus casos específicos, mas constituem substitutos provisórios em vez da arquitetura centralizada do motor original.

**Assembly:** Banks0123.asm:7798-7816 SetTextUnskippable; Banks0123.asm:7808-7860 SetText; Banks0123.asm:8301-8304 TextBoxExit

**Extractors:** tools/extractors/extract_grey_fox_dialogue.py

**Dados canônicos locais:** dialogues/

**Godot relacionado:** godot/scripts/systems/prisoner_dialog.gd; godot/scripts/systems/radio_dialog.gd; godot/scripts/systems/capture_cutscene.gd; godot/scripts/scenes/sandbox_gameplay.gd

**Integração inspecionada:** godot/scripts/scenes/sandbox_gameplay.gd::show_dialog_message

**Testes existentes:** godot-prisoner-dialog; tests/test_grey_fox_dialogue.py

**Documentação:** docs/reverse_engineering/grey-fox-dialogue.md

**Histórico consultado:** docs/progress/2026-10.md::2026-10-04 — Registro do diálogo de Grey Fox

**Implementado:** Implementações locais desconectadas: PrisonerDialog para Grey Fox, CaptureCutscene para sala 8, RadioDialog para transceptor, dialog_banner_label e boss_dialog_label para gameplay.

**Faltante / não comprovado:** Não existe um motor de texto unificado no Godot; a lógica está duplicada e fragmentada entre múltiplos scripts sem compartilhar a máquina de estados canônica do Z80.

**Notas de evidência:** PrisonerDialog implementa os estados TW_* para caixa tipo 1 com fidelidade, mas permanece restrito a Grey Fox; o restante do jogo usa banners e labels.


<a id="radio-tuning-frequency"></a>
### Sintonia de frequências e display digital BCD

`radio-tuning-frequency` · **IMPLEMENTED**

**Original:** Sintonia com botões esquerda/direita via ChgRadioFreq (Banks0123.asm:10906-10957): decremento/incremento de frequência com aritmética BCD pura (add 1; daa / sub 1; daa), limites 120.00 a 120.99. Renderização dos dígitos em 7 segmentos vermelhos em (120, 33) via DrawRadioFreq (Banks0123.asm:11180-11270). A cada alteração de frequência, chama ChkRadioReceiv para checagem contínua de contatos.

**Classificação:** Sintonia portada tick a tick.

**Assembly:** Banks0123.asm:10906-10957 ChgRadioFreq; Banks0123.asm:11180-11270 DrawRadioFreq

**Extractors:** Nenhum localizado neste recorte.

**Dados canônicos locais:** Nenhum localizado neste recorte.

**Godot relacionado:** godot/scripts/systems/radio_system.gd; godot/scripts/systems/radio_dialog.gd

**Integração inspecionada:** godot/scripts/systems/radio_dialog.gd::_physics_process

**Testes existentes:** godot-radio-system

**Documentação:** Nenhum localizado neste recorte.

**Histórico consultado:** docs/progress/2026-09.md::2026-09-20 — Etapa 15 concluída: Sistema de Rádio Transceptor (Transceiver / Codec); docs/progress.md::2026-10-04 — Sistema de rádio: tabela canônica, chamadas e AUTO-REPLY/WAIT-CALL

**Implementado:** Frequência em BCD (bcd_increment/bcd_decrement = add/sub 1; daa) com limites 00h e 99h; _change_frequency porta ChgRadioFreq (atraso 8 ao pressionar, repetição a cada 2 ticks, esquerda com prioridade); ChkRadioReceiv avaliado a cada tick ocioso.; radio_dialog.gd desenha os dígitos pelos nibbles BCD.

**Faltante / não comprovado:** Nenhum localizado neste recorte.

**Notas de evidência:** radio_system_test.gd confere 89h→90h, limites e temporização de repetição.


<a id="radio-contacts-frequencies"></a>
### Contatos e frequências canônicas da edição inglesa

`radio-contacts-frequencies` · **PARTIAL**

**Original:** 8 frequências canônicas da edição inglesa RC750 (constants/Enums.asm:14-23, Banks0123.asm:2455-2462): Big Boss Edifício 1 (120.85 / 0x85), Big Boss Edifício 2 (120.13 / 0x13), Schneider Edifício 1 (120.79 / 0x79), Schneider Edifício 2 (120.26 / 0x26), Diane Edifício 1 (120.33 / 0x33), Diane Edifício 2 (120.91 / 0x91), Jennifer (120.48 / 0x48) e Rádio de Notícias do final (120.77 / 0x77).

**Classificação:** As frequências estão declaradas como constantes nominais, mas sem integração com as salas e eventos posteriores do jogo.

**Assembly:** constants/Enums.asm:14-23; constants/Enums.asm:27-36; Banks0123.asm:11043-11175 ChkRadioReply

**Extractors:** Nenhum localizado neste recorte.

**Dados canônicos locais:** Nenhum localizado neste recorte.

**Godot relacionado:** godot/scripts/systems/radio_system.gd

**Integração inspecionada:** Nenhum localizado neste recorte.

**Testes existentes:** godot-radio-system; tests/test_radio_dialogue_extractor.py

**Documentação:** Nenhum localizado neste recorte.

**Histórico consultado:** docs/progress/2026-09.md::2026-09-20 — Etapa 15 concluída: Sistema de Rádio Transceptor (Transceiver / Codec); docs/progress.md::2026-10-04 — Sistema de rádio: tabela canônica, chamadas e AUTO-REPLY/WAIT-CALL

**Implementado:** RadioFreqs (7 pessoas) extraída e conferida; PERSON_CONTACTS mapeia as pessoas 1-7; todas as salas com rádio vêm da ROM.

**Faltante / não comprovado:** Frequência 120.77 (FREQ_NEWS) só usada pelo final, não portada.

**Notas de evidência:** Constantes conferem com a tabela RadioFreqs de Banks0123.asm; ausência de consumidores para as frequências do Edifício 2 e notícias.


<a id="radio-transmission-modes"></a>
### Modos de transmissão: envio (SEND) vs escuta (RECV)

`radio-transmission-modes` · **PARTIAL**

**Original:** Alternância entre RECV e SEND ao pressionar cima (ControlsTrigger bit 0, Banks0123.asm:10757-10779): apaga RECV e imprime SEND (ErasePrintTxt), silencia ruído estático (SFX 5Ch), envia texto fixo de Snake ID 10 ('THIS IS SOLID SNAKE... YOUR REPLY, PLEASE.') via SetText, e seta ReplyRequested = 1 para aguardar resposta em frequências com WAITCALL.

**Classificação:** O mecanismo de alternância de modo existe no Godot, mas sua semântica foi invertida ao exigir SEND para quem tem auto-reply.

**Assembly:** Banks0123.asm:10742-10779; Banks0123.asm:10993-11020 ChkRadioReceiv4

**Extractors:** Nenhum localizado neste recorte.

**Dados canônicos locais:** Nenhum localizado neste recorte.

**Godot relacionado:** godot/scripts/systems/radio_system.gd; godot/scripts/systems/radio_dialog.gd

**Integração inspecionada:** Nenhum localizado neste recorte.

**Testes existentes:** godot-radio-system

**Documentação:** Nenhum localizado neste recorte.

**Histórico consultado:** docs/progress/2026-09.md::2026-09-20 — Etapa 15 concluída: Sistema de Rádio Transceptor (Transceiver / Codec); docs/progress.md::2026-10-04 — Sistema de rádio: tabela canônica, chamadas e AUTO-REPLY/WAIT-CALL

**Implementado:** SEND por gatilho cima: is_send_mode (RadioCmd), ReplyRequested = 1 e texto 0Ah da ROM; volta a RECV no tick seguinte ao texto; indicador RECV/SEND desenhado conforme RadioCmd.

**Faltante / não comprovado:** SFX 50h/5Ch emitidos só como sinal (sem subsistema de áudio).

**Notas de evidência:** Texto ID 10 confere com texts.asm:191; divergência de comportamento ao exigir SEND para contatos de auto-resposta.


<a id="radio-auto-reply-waitcall"></a>
### Despacho de resposta: AUTO-REPLY vs WAIT-CALL

`radio-auto-reply-waitcall` · **IMPLEMENTED**

**Original:** Diferença formal entre RADIO_AUTOREPLY (bit 3 da tabela / bit 0 invertido em RAM) e RADIO_WAITCALL (bit 2 da tabela / bit 0 em RAM) em Banks0123.asm:10993-11020: contatos com auto-reply respondem assim que a frequência é sintonizada; contatos com wait-call exigem que Snake envie chamada (ReplyRequested = 1). Flag AutoReplyDone (Variables.asm:351, Banks0123.asm:10842, 10924-10925) previne disparo repetido na mesma frequência até que a sintonia mude.

**Classificação:** Flags WAITCALL/AUTOTUNE lidas da tabela extraída e despacho tick a tick como no Z80.

**Assembly:** Banks0123.asm:10993-11020 ChkRadioReceiv4; data/radiocalls.asm:1-11; Variables.asm:351 AutoReplyDone; Banks0123.asm:10965-11039 ChkRadioReceiv

**Extractors:** Nenhum localizado neste recorte.

**Dados canônicos locais:** Nenhum localizado neste recorte.

**Godot relacionado:** godot/scripts/systems/radio_system.gd; godot/scripts/systems/radio_dialog.gd; godot/scripts/scenes/sandbox_gameplay.gd

**Integração inspecionada:** Nenhum localizado neste recorte.

**Testes existentes:** godot-radio-system; tests/test_region_tools.py; tests/test_radio_dialogue_extractor.py

**Documentação:** docs/reverse_engineering/en-eu-reextraction.md

**Histórico consultado:** docs/progress/2026-10.md::2026-10-04 — Auditoria regional da implementação contra a edição inglesa; docs/progress.md::2026-10-04 — Sistema de rádio: tabela canônica, chamadas e AUTO-REPLY/WAIT-CALL

**Implementado:** radio_system.gd::_check_receive porta ChkRadioReceiv: sem WAITCALL responde ao sintonizar salvo AutoReplyDone; com WAITCALL exige ReplyRequested (SEND).; auto_reply_done é ligado em RadioSignalOFF e limpo por DrawRadio e por nova sintonia (ChgRadioFreq2).

**Faltante / não comprovado:** Nenhum localizado neste recorte.

**Notas de evidência:** radio_system_test.gd verifica resposta sem SEND, não repetição, reabilitação ao ressintonizar e WAIT-CALL só após SEND.


<a id="radio-auto-tune"></a>
### Sintonia automática ao atender chamadas (Auto-Tune)

`radio-auto-tune` · **IMPLEMENTED**

**Original:** Flag RADIO_AUTOTUNE (bit 2 da tabela em data/radiocalls.asm:9 / bit 1 em RAM RadioPersonsDat em Banks0123.asm:2421-2426): ao inicializar o rádio com chamada recebida ou sintonizar chamada do jogo, ajusta imediatamente RadioFreq para a frequência do interlocutor.

**Classificação:** Flag canônica lida da tabela idxRoomRadio extraída.

**Assembly:** Banks0123.asm:2427-2435 UpdateRadio3; data/radiocalls.asm:9; Banks0123.asm:2379-2448 UpdateRadio

**Extractors:** Nenhum localizado neste recorte.

**Dados canônicos locais:** Nenhum localizado neste recorte.

**Godot relacionado:** godot/scripts/systems/radio_system.gd

**Integração inspecionada:** Nenhum localizado neste recorte.

**Testes existentes:** godot-radio-system; tests/test_radio_dialogue_extractor.py

**Documentação:** Nenhum localizado neste recorte.

**Histórico consultado:** docs/progress/2026-09.md::2026-09-20 — Etapa 15 concluída: Sistema de Rádio Transceptor (Transceiver / Codec); docs/progress.md::2026-10-04 — Sistema de rádio: tabela canônica, chamadas e AUTO-REPLY/WAIT-CALL

**Implementado:** update_radio porta UpdateRadio: cada contato com flag auto-tune da tabela extraída define current_freq ao entrar na sala.

**Faltante / não comprovado:** Nenhum localizado neste recorte.

**Notas de evidência:** Teste cruzado: sala 0 auto-sintoniza 120.85 a partir de radio_dialogue.json.


<a id="radio-signal-led-bars"></a>
### Animação e temporização das 12 barras de sinal LED

`radio-signal-led-bars` · **IMPLEMENTED**

**Original:** Animação de intensidade de sinal do transceptor (Banks0123.asm:10787-10809 RadioSignalUp e 11271-11340 DrawRadioLeds): atraso inicial de 16 ticks (RadioLedDelay = 10h), seguido pelo acendimento de 1 LED a cada 2 ticks até totalizar 12 barras ligadas, avançando para o estado SetupRadioReply; apagamento de todos os LEDs em RadioSignalOFF (Banks0123.asm:10837-10850).

**Classificação:** Temporização original por tick.

**Assembly:** Banks0123.asm:10787-10809 RadioSignalUp; Banks0123.asm:10837-10850 RadioSignalOFF; Banks0123.asm:11271-11340 DrawRadioLeds

**Extractors:** Nenhum localizado neste recorte.

**Dados canônicos locais:** Nenhum localizado neste recorte.

**Godot relacionado:** godot/scripts/systems/radio_dialog.gd; godot/scripts/systems/radio_system.gd

**Integração inspecionada:** Nenhum localizado neste recorte.

**Testes existentes:** godot-radio-system

**Documentação:** Nenhum localizado neste recorte.

**Histórico consultado:** docs/progress/2026-09.md::2026-09-20 — Etapa 15 concluída: Sistema de Rádio Transceptor (Transceiver / Codec); docs/progress.md::2026-10-04 — Sistema de rádio: tabela canônica, chamadas e AUTO-REPLY/WAIT-CALL

**Implementado:** State.SIGNAL_UP porta RadioSignalUp: atraso inicial 10h, +1 LED a cada 2 ticks até 12, depois SetupRadioReply; RadioSignalOFF zera os LEDs. radio_dialog.gd lê signal_leds a cada tick.

**Faltante / não comprovado:** Nenhum localizado neste recorte.

**Notas de evidência:** radio_system_test.gd confere primeiro LED após 16 ticks e 12 LEDs 22 ticks depois.


<a id="radio-incoming-call-detection"></a>
### Detecção e ciclo de vida de chamadas recebidas (Incoming Calls)

`radio-incoming-call-detection` · **IMPLEMENTED**

**Original:** Gatilho de chamada pelo bit 3 de RoomsMusic (and 8 em ChkRadioCalls, Banks0123.asm:1729-1743); temporizador pré-chamada de 32 ticks (IncomingCallTimer = 32); disparo de RadioCallFlag = 1 com duração de 88 ticks (58h) em logic/incomingcall.asm:10-36; expiração da chamada com RadioCallFlag = 2 se não atendida a tempo.

**Classificação:** Ciclo de vida portado com os temporizadores originais.

**Assembly:** Banks0123.asm:1729-1743 ChkRadioCalls4; logic/incomingcall.asm:10-36 ChkIncomingCall; Banks0123.asm:1688-1745 ChkRadioCalls; logic/items.asm:159-170 AddItemInventory3

**Extractors:** Nenhum localizado neste recorte.

**Dados canônicos locais:** Nenhum localizado neste recorte.

**Godot relacionado:** godot/scripts/systems/radio_system.gd; godot/scripts/scenes/sandbox_gameplay.gd

**Integração inspecionada:** Nenhum localizado neste recorte.

**Testes existentes:** godot-radio-system; tests/test_radio_dialogue_extractor.py

**Documentação:** Nenhum localizado neste recorte.

**Histórico consultado:** docs/progress/2026-09.md::2026-09-20 — Etapa 15 concluída: Sistema de Rádio Transceptor (Transceiver / Codec); docs/progress.md::2026-10-04 — Sistema de rádio: tabela canônica, chamadas e AUTO-REPLY/WAIT-CALL

**Implementado:** check_radio_calls porta ChkRadioCalls (bit 3 de RoomsMusic extraído, bloqueios Schneider capturado, Jennifer e antena); tick_incoming_call porta ChkIncomingCall (32 ticks de atraso, CALL de 58h ticks, expiração).; enter_room roda em toda troca de sala e tick_incoming_call a cada tick de jogo fora de modais; abrir o rádio para o CALL; coletar a antena força chamada pendente (10h).

**Faltante / não comprovado:** Nenhum localizado neste recorte.

**Notas de evidência:** radio_system_test.gd confere flag 0 por 32 ticks, CALL dos ticks 32 a 118 e parada no 119; sala 0 arma o CALL no sandbox.; Salvamento do CALL em menus (menuequipment.asm:326-327) é equivalente porque o Godot não avança o CALL com menus abertos.


<a id="radio-hud-call-indicator"></a>
### Indicador CALL no HUD e sinal sonoro do buzzer

`radio-hud-call-indicator` · **PARTIAL**

**Original:** Quando RadioCallFlag == 1, o letreiro CALL pisca no HUD em ciclos de 8 ticks (TickCounter bit 3, logic/hud.asm:25-56) e toca o buzzer SFX 22h a cada 8 ticks; suprimido quando menus de armas/itens estão abertos; sobreposto pelo cronômetro de autodestruição (DestructionTimerOn); limpo ao abrir o rádio (RadioCallFlag = 2).

**Classificação:** A alternância gráfica do letreiro CALL funciona fielmente a 8 frames no HUD, mas falta a camada de áudio e as prioridades com outras camadas de HUD.

**Assembly:** logic/hud.asm:25-56 DrawCallTimer; Banks0123.asm:10701-10702

**Extractors:** Nenhum localizado neste recorte.

**Dados canônicos locais:** Nenhum localizado neste recorte.

**Godot relacionado:** godot/scripts/systems/hud.gd; godot/scripts/systems/radio_system.gd

**Integração inspecionada:** Nenhum localizado neste recorte.

**Testes existentes:** godot-hud; godot-radio-system

**Documentação:** Nenhum localizado neste recorte.

**Histórico consultado:** docs/progress/2026-09.md::2026-09-20 — Etapa 15 concluída: Sistema de Rádio Transceptor (Transceiver / Codec)

**Implementado:** hud.gd (_draw_call_signal) renderiza 'CALL' piscando em ciclos de 8 frames de engine, sincronizado com o estado has_incoming_call de radio_system.gd.

**Faltante / não comprovado:** Sinal sonoro contínuo do buzzer SFX 22h não é tocado; sobreposição pelo cronômetro de destruição não implementada; supressão por menus de inventário divergente.

**Notas de evidência:** hud_test.gd valida alternância de 8 frames do sinal CALL; áudio do buzzer SFX 22h pendente.


<a id="radio-room-dispatch-table"></a>
### Tabela canônica de despachos de rádio por sala (idxRoomRadio)

`radio-room-dispatch-table` · **IMPLEMENTED**

**Original:** Tabela de 256 ponteiros idxRoomRadio (data/radiocalls.asm:195-447) mapeando cada sala para um dos 41 blocos RadioRoom_XXX ou NoRadio; rotina UpdateRadio em Banks0123.asm:2380-2448 preenche RadioPersonsDat e NumRadioPersons para a sala atual.

**Classificação:** Tabela integral lida da ROM em vez de dicionário local.

**Assembly:** data/radiocalls.asm:195-447 idxRoomRadio; Banks0123.asm:2379-2448 UpdateRadio

**Extractors:** Nenhum localizado neste recorte.

**Dados canônicos locais:** Nenhum localizado neste recorte.

**Godot relacionado:** godot/scripts/systems/radio_system.gd

**Integração inspecionada:** Nenhum localizado neste recorte.

**Testes existentes:** godot-radio-system; tests/test_region_tools.py; tests/test_radio_dialogue_extractor.py

**Documentação:** docs/reverse_engineering/en-eu-reextraction.md

**Histórico consultado:** docs/progress/2026-10.md::2026-10-04 — Auditoria regional da implementação contra a edição inglesa; docs/progress.md::2026-10-04 — Sistema de rádio: tabela canônica, chamadas e AUTO-REPLY/WAIT-CALL

**Implementado:** extract_radio_dialogue.py lê idxRoomRadio/RadioRoom_* da ROM canônica (segmentos binary_verified) e gera a tabela das 251 salas (60 com rádio), zonas de mapa e salas com chamada; radio_system.gd não tem mais tabela local.

**Faltante / não comprovado:** Nenhum localizado neste recorte.

**Notas de evidência:** Textos ingleses dos 45 IDs usados pelo rádio extraídos localmente com quebras FD/FE; nenhum texto versionado.


<a id="radio-cond-antenna"></a>
### Condição de rádio: exigência da antena no Edifício 2

`radio-cond-antenna` · **IMPLEMENTED**

**Original:** A partir do Edifício 2 (MapZone >= 5), qualquer comunicação de rádio requer a Antena (AntennaTaken != 0): sem ela, chamadas recebidas não tocam (ChkRadioCalls3, Banks0123.asm:1720-1727) e chamadas do jogador falham com NoRadioReply (Banks0123.asm:11049-11055).

**Classificação:** Condição portada.

**Assembly:** Banks0123.asm:1720-1727 ChkRadioCalls3; Banks0123.asm:11043-11055 ChkRadioReply

**Extractors:** Nenhum localizado neste recorte.

**Dados canônicos locais:** Nenhum localizado neste recorte.

**Godot relacionado:** godot/scripts/systems/radio_system.gd; godot/scripts/scenes/sandbox_gameplay.gd

**Integração inspecionada:** Nenhum localizado neste recorte.

**Testes existentes:** tests/test_region_tools.py; godot-radio-system

**Documentação:** Nenhum localizado neste recorte.

**Histórico consultado:** docs/progress/2026-10.md::2026-10-04 — Auditoria regional da implementação contra a edição inglesa; docs/progress.md::2026-10-04 — Sistema de rádio: tabela canônica, chamadas e AUTO-REPLY/WAIT-CALL

**Implementado:** map_zone vem do nibble de idxMapZones extraído (SetRadioArea); antenna_taken sincronizado com o inventário; ChkRadioCalls e ChkRadioReply bloqueiam zona >= 5 sem antena; coletar a antena força chamada pendente.

**Faltante / não comprovado:** Nenhum localizado neste recorte.

**Notas de evidência:** radio_system_test.gd: zona 5 sem antena não responde; com antena responde.


<a id="radio-cond-schneider"></a>
### Condições de rádio: Schneider (chamadas ativas e captura)

`radio-cond-schneider` · **PARTIAL**

**Original:** Schneider nunca emite chamadas recebidas ativas (ChkRadioCalls suprime FREQ_SCHNEIDER e FREQ_SCHNEIDER_BUILDING2, Banks0123.asm:1696-1701); quando capturado (SchneiderCaptured != 0), qualquer tentativa de contato falha com NoRadioReply (Banks0123.asm:1692-1694, 11124-11128).

**Classificação:** A ausência de chamadas ativas de Schneider está correta nas salas existentes, mas a condição de supressão pós-captura não foi implementada.

**Assembly:** Banks0123.asm:1689-1701 ChkRadioCalls; Banks0123.asm:11115-11130 ChkReplySchneider

**Extractors:** Nenhum localizado neste recorte.

**Dados canônicos locais:** Nenhum localizado neste recorte.

**Godot relacionado:** godot/scripts/systems/radio_system.gd

**Integração inspecionada:** Nenhum localizado neste recorte.

**Testes existentes:** godot-radio-system

**Documentação:** Nenhum localizado neste recorte.

**Histórico consultado:** docs/progress/2026-09.md::2026-09-20 — Etapa 15 concluída: Sistema de Rádio Transceptor (Transceiver / Codec); docs/progress.md::2026-10-04 — Sistema de rádio: tabela canônica, chamadas e AUTO-REPLY/WAIT-CALL

**Implementado:** schneider_captured bloqueia a chamada recebida quando o primeiro contato é Schneider (ChkRadioCalls só testa isso com SchneiderCaptured != 0) e a resposta em ChkRadioReply.

**Faltante / não comprovado:** Flag SchneiderCaptured nunca é ligada no Godot (evento do texto 138, text-event-triggers).

**Notas de evidência:** Correção da descrição: ChkRadioCalls (Banks0123.asm:1692-1701) só suprime Schneider quando SchneiderCaptured != 0.


<a id="radio-cond-jennifer"></a>
### Condições de rádio: Jennifer (Rank 4 e vingança pelo irmão)

`radio-cond-jennifer` · **PARTIAL**

**Original:** Jennifer só estabelece contato se Snake tiver patente de 4 estrelas (Class == 3, Banks0123.asm:1708-1710, 11140-11142); se Snake tiver menos de 4 estrelas, ela não chama e não responde. Se o irmão de Jennifer for morto pelo jogador (JennifBrotherDead != 0, Banks0123.asm:1712-1714, 11144-11146), Jennifer se recusa terminantemente a responder até o fim do jogo.

**Classificação:** Condição canônica essencial da trama onde o suporte de Jennifer depende de mérito militar (Rank 4) e moral (não matar seu irmão refém).

**Assembly:** Banks0123.asm:1703-1715 ChkRadioCalls2; Banks0123.asm:11135-11149 ChkReplyJeniffer

**Extractors:** Nenhum localizado neste recorte.

**Dados canônicos locais:** Nenhum localizado neste recorte.

**Godot relacionado:** godot/scripts/systems/radio_system.gd

**Integração inspecionada:** Nenhum localizado neste recorte.

**Testes existentes:** godot-radio-system

**Documentação:** Nenhum localizado neste recorte.

**Histórico consultado:** docs/progress.md::2026-10-04 — Sistema de rádio: tabela canônica, chamadas e AUTO-REPLY/WAIT-CALL

**Implementado:** Checagem Class == 3 (class_rank sincronizado com rank_system) e JennifBrotherDead em ChkRadioCalls e ChkRadioReply.

**Faltante / não comprovado:** Flag JennifBrotherDead nunca é ligada no Godot.

**Notas de evidência:** radio_system_test.gd: Jennifer só responde com 4 estrelas.


<a id="radio-cond-bigboss-bug"></a>
### Condição de rádio: aviso de grampo/transmissor por Big Boss

`radio-cond-bigboss-bug` · **PARTIAL**

**Original:** Se o jogador coletar a bolsa com o transmissor/grampo (TransmiTaken != 0) e estiver fora de MapZone == 4, qualquer contato com Big Boss substitui sua fala pelo Texto ID 50: 'THIS IS BIG BOSS... CHECK YOUR EQUIPMENTS! CHECK IF YOU HAVE BEEN BUGGED BY THE ENEMY. ...OVER' (Banks0123.asm:11095-11108).

**Classificação:** Comportamento canônico de narrativa que revela ao jogador por que os guardas o estão perseguindo continuamente.

**Assembly:** Banks0123.asm:11095-11108 ChkReplyBigBoss4

**Extractors:** Nenhum localizado neste recorte.

**Dados canônicos locais:** Nenhum localizado neste recorte.

**Godot relacionado:** godot/scripts/systems/radio_system.gd

**Integração inspecionada:** Nenhum localizado neste recorte.

**Testes existentes:** godot-radio-system

**Documentação:** Nenhum localizado neste recorte.

**Histórico consultado:** docs/progress.md::2026-10-04 — Sistema de rádio: tabela canônica, chamadas e AUTO-REPLY/WAIT-CALL

**Implementado:** ChkRadioReply substitui o texto de Big Boss por 50 com transmitter_taken fora da zona 4.

**Faltante / não comprovado:** TransmiTaken não é sincronizado (bolsa com transmissor não portada); transmitter_taken fica falso no jogo.

**Notas de evidência:** radio_system_test.gd confere a substituição pelo texto 50.


<a id="radio-cond-bigboss-switch-off"></a>
### Condição de rádio: ordem de desligar o MSX por Big Boss

`radio-cond-bigboss-switch-off` · **PARTIAL**

**Original:** Quando a flag SwitchOffMSXF é ativada no porão do Edifício 3 (sala 111), qualquer chamada a Big Boss nas frequências 120.85 ou 120.13 substitui sua fala pelo Texto ID 136: 'Stop operation. Switch off your MSX' (Banks0123.asm:11071-11080).

**Classificação:** Momento icônico da quebra de quarta parede do jogo original MSX2; mecânica ainda não iniciada.

**Assembly:** Banks0123.asm:11071-11080 ChkReplyBigBoss2

**Extractors:** Nenhum localizado neste recorte.

**Dados canônicos locais:** Nenhum localizado neste recorte.

**Godot relacionado:** godot/scripts/systems/radio_system.gd

**Integração inspecionada:** Nenhum localizado neste recorte.

**Testes existentes:** godot-radio-system

**Documentação:** Nenhum localizado neste recorte.

**Histórico consultado:** docs/progress.md::2026-10-04 — Sistema de rádio: tabela canônica, chamadas e AUTO-REPLY/WAIT-CALL

**Implementado:** ChkRadioReply substitui o texto de Big Boss por 136 com switch_off_msx, com prioridade sobre o aviso do transmissor.

**Faltante / não comprovado:** SwitchOffMSXF nunca é ligada (sala 111/evento não portados).

**Notas de evidência:** radio_system_test.gd confere a prioridade do texto 136.


<a id="radio-chk-reply-madnar-text15"></a>
### Checagem anômala de Text ID 15 e MadnarMoved no rádio

`radio-chk-reply-madnar-text15` · **UNMAPPED**

**Original:** Em ChkReplyMadnar (Banks0123.asm:11156-11164), o código compara o Text ID a ser exibido com 15 ('LISTEN! SOLID SNAKE... I'LL NEVER DIE...') e verifica se MadnarMoved está setada para silenciar o rádio com NoRadioReply. No entanto, o Texto 15 nunca é atribuído a nenhuma sala de rádio em data/radiocalls.asm.

**Classificação:** Classificado como UNMAPPED porque a rotina original testa um Text ID que o despachador de rádio nunca gera, tratando-se de código anômalo ou resquício de desenvolvimento.

**Assembly:** Banks0123.asm:11156-11164 ChkReplyMadnar; data/radiocalls.asm:188 NoRadio

**Extractors:** Nenhum localizado neste recorte.

**Dados canônicos locais:** Nenhum localizado neste recorte.

**Godot relacionado:** godot/scripts/systems/radio_system.gd

**Integração inspecionada:** Nenhum localizado neste recorte.

**Testes existentes:** godot-radio-system

**Documentação:** Nenhum localizado neste recorte.

**Histórico consultado:** docs/progress.md::2026-10-04 — Sistema de rádio: tabela canônica, chamadas e AUTO-REPLY/WAIT-CALL

**Implementado:** ChkReplyMadnar portado literalmente: texto 15 sem resposta com madnar_moved (flag não ligada no jogo).

**Faltante / não comprovado:** Código morto/anômalo no Z80 original; o propósito exato (se era protótipo de chamada com Dr. Madnar antes de sua transferência para o prédio 2) não está mapeado no catálogo.

**Notas de evidência:** Anotação na desmontagem: '(!?) Why is this text checked? It is not a radio reply.' Texto 15 é txtFinalThread (texts.asm:15), fala final de Big Boss.


<a id="text-box-geometry-types"></a>
### Tipos e geometrias de caixas de texto (TextBoxType)

`text-box-geometry-types` · **PARTIAL**

**Original:** 5 geometrias canônicas de caixas de texto (TextBoxType nibble inferior, Banks0123.asm:8338-8387): Tipo 0 (1 linha x 7 caracteres 'RELIEVE'), Tipo 1 (3 linhas x 19 caracteres, reféns, 160x41 px em 48, 8), Tipo 2 (5 linhas x 16 caracteres), Tipo 3 (5 linhas x 23 caracteres, exclusivo do transceptor), Tipo 4 (2 linhas x 17 caracteres, 160x41 px, guardas da sala 8).

**Classificação:** Alguns tipos foram implementados com fidelidade milimétrica em subsistemas isolados, mas a tabela completa de geometrias não foi unificada.

**Assembly:** Banks0123.asm:8338-8387 GetTextBoxXYSize

**Extractors:** Nenhum localizado neste recorte.

**Dados canônicos locais:** Nenhum localizado neste recorte.

**Godot relacionado:** godot/scripts/systems/prisoner_dialog.gd; godot/scripts/systems/capture_cutscene.gd; godot/scripts/systems/radio_dialog.gd

**Integração inspecionada:** Nenhum localizado neste recorte.

**Testes existentes:** godot-prisoner-dialog; godot-capture-prison

**Documentação:** Nenhum localizado neste recorte.

**Histórico consultado:** docs/progress/2026-10.md::2026-10-04 — Registro do diálogo de Grey Fox

**Implementado:** PrisonerDialog implementa Tipo 1 (160x41 px em 48, 8); CaptureCutscene implementa Tipo 4 (160x41 px em 48, 8); RadioDialog usa layout aproximado de 5 linhas.

**Faltante / não comprovado:** Tabela de geometrias TextBoxXYSize não centralizada; Tipos 0 e 2 não implementados; caixas de outros reféns e chefes usam banners arbitrários.

**Notas de evidência:** Tabela original define caixas de 1 a 5 linhas em Screen 5; no Godot cada cena calcula suas próprias coordenadas.


<a id="text-appearance-animation"></a>
### Animação de abertura e fechamento da caixa de texto

`text-appearance-animation` · **PARTIAL**

**Original:** Animação de crescimento da moldura da caixa de texto de dentro para fora antes de iniciar a digitação (TextBoxAppear e DrawTextBoxIn em logic/textboxappear.asm:10-70, 19 passos de expansão); salvamento do fundo via cópia VDP entre páginas 0 e 1 (VDP_Copy_Byte, Banks0123.asm:7915-7920) e restauração no encerramento (Banks0123.asm:8286-8289); redesenho de pitfalls abertos após fechar (DrawOpenPitfalls, Banks0123.asm:8290).

**Classificação:** Fielmente implementado e testado em PrisonerDialog, mas ausente no restante dos pontos de exibição de texto do jogo.

**Assembly:** logic/textboxappear.asm:10-70 DrawTextBoxIn; Banks0123.asm:7932-7945 TextBoxAppear; Banks0123.asm:8271-8304 TextBox_End

**Extractors:** Nenhum localizado neste recorte.

**Dados canônicos locais:** Nenhum localizado neste recorte.

**Godot relacionado:** godot/scripts/systems/prisoner_dialog.gd

**Integração inspecionada:** Nenhum localizado neste recorte.

**Testes existentes:** godot-prisoner-dialog

**Documentação:** Nenhum localizado neste recorte.

**Histórico consultado:** docs/progress/2026-10.md::2026-10-04 — Registro do diálogo de Grey Fox

**Implementado:** PrisonerDialog reproduz a expansão exata de 19 passos (APPEAR com _appear_remaining = 19) e o retângulo inicial (120, 26, 16, 5) até 160x41 px.

**Faltante / não comprovado:** Efeito de expansão ausente em RadioDialog, CaptureCutscene e nos banners do sandbox (abrem instantaneamente); cópia de VDP não necessária em engine moderna, mas o timing correspondente não é compartilhado.

**Notas de evidência:** prisoner_dialog_test.gd testa 18 growth steps e estado APPEAR; ausente em outras caixas de diálogo.


<a id="text-skip-control-modes"></a>
### Controle de avanço e pulo de texto: skippable vs unskippable

`text-skip-control-modes` · **PARTIAL**

**Original:** Três modos formais de avanço em SkipTextMode (Banks0123.asm:7813-7816): Modo 0 (SetText): skippable — teclas M/N e Enter pulam a digitação e avançam páginas; Modo 1 (SetTextUnskip2): unskippable com espera de tecla — não permite pular digitação, mas aguarda comando para virar página; Modo 2 (SetTextUnskippable): unskippable temporizado — não aceita pulo e avança automaticamente após pausa fixa de 96 ticks (1.6s, WaitTextCnt = 60h) sem exigir tecla.

**Classificação:** Diferentes scripts reimplementaram subconjuntos de avanço/espera de tecla, mas sem os 3 modos canônicos da rotina Z80.

**Assembly:** Banks0123.asm:7798-7816 SetTextUnskippable; Banks0123.asm:7952-7969 TW_PrintChar; Banks0123.asm:8143-8174 TW_Wait

**Extractors:** Nenhum localizado neste recorte.

**Dados canônicos locais:** Nenhum localizado neste recorte.

**Godot relacionado:** godot/scripts/systems/prisoner_dialog.gd; godot/scripts/systems/capture_cutscene.gd; godot/scripts/systems/radio_dialog.gd

**Integração inspecionada:** Nenhum localizado neste recorte.

**Testes existentes:** godot-prisoner-dialog; godot-capture-prison

**Documentação:** Nenhum localizado neste recorte.

**Histórico consultado:** docs/progress/2026-10.md::2026-10-04 — Registro do diálogo de Grey Fox

**Implementado:** PrisonerDialog implementa modo 0 com avanço de página; CaptureCutscene implementa avanço temporizado fixo; RadioDialog implementa avanço por tecla e trava durante cutscene.

**Faltante / não comprovado:** Os 3 modos de SkipTextMode não existem como despachador formal; teclas M/N do MSX2 não são mapeadas de forma uniforme; temporizador de 96 ticks não é generalizado.

**Notas de evidência:** Modo 2 (WaitTextCnt = 60h) usado nas capturas e bosses; no Godot cada sistema inventou seus próprios timers.


<a id="text-typewriter-audio"></a>
### Efeito de digitação (Typewriter) e áudio de fala

`text-typewriter-audio` · **PARTIAL**

**Original:** Digitação de caracteres a cada 8 ticks (TickCounter and 7) no modo normal e a cada 4 ticks (TickCounter and 3) no modo rápido (Banks0123.asm:7988-7997). Emissão do som de clique de texto SFX 23h para cada caractere impresso que não seja espaço (Banks0123.asm:8037-8044), suprimido durante a equipe de encerramento.

**Classificação:** O efeito visual de máquina de escrever foi portado em partes, mas o componente auditivo SFX 23h e a cadência de 8 ticks estão incompletos.

**Assembly:** Banks0123.asm:7994-8045 TW_PrintChar3

**Extractors:** Nenhum localizado neste recorte.

**Dados canônicos locais:** Nenhum localizado neste recorte.

**Godot relacionado:** godot/scripts/systems/prisoner_dialog.gd; godot/scripts/systems/radio_dialog.gd

**Integração inspecionada:** Nenhum localizado neste recorte.

**Testes existentes:** godot-prisoner-dialog

**Documentação:** Nenhum localizado neste recorte.

**Histórico consultado:** docs/progress/2026-10.md::2026-10-04 — Registro do diálogo de Grey Fox

**Implementado:** Digitação progressiva de texto existe em PrisonerDialog (baseada em ticks) e RadioDialog (timer float 0.045s).

**Faltante / não comprovado:** O áudio SFX 23h de caractere não é tocado em nenhum sistema de texto do Godot; velocidade de digitação em RadioDialog diverge da máscara de 8 ticks do MSX2; banners exibem texto instantâneo.

**Notas de evidência:** SFX 23h disparado via SetSoundEntry em Banks0123.asm:8043; nenhum script Godot toca esse efeito.


<a id="text-prompt-enter-blink"></a>
### Ícone de ENTER piscante no fim da página

`text-prompt-enter-blink` · **PARTIAL**

**Original:** Ao término da impressão de uma página que aguarda comando do jogador (TW_Wait), exibe o caractere especial de seta/enter (código 0x3F) na coordenada PromptXY, alternando visibilidade a cada 16 ticks (TickCounter bit 4, Banks0123.asm:8207-8219 DrawEnterIcon).

**Classificação:** Implementado e validado em testes unitários para PrisonerDialog e RadioDialog, mas ausente nas demais caixas do sandbox.

**Assembly:** Banks0123.asm:8183-8186; Banks0123.asm:8207-8220 DrawEnterIcon

**Extractors:** Nenhum localizado neste recorte.

**Dados canônicos locais:** Nenhum localizado neste recorte.

**Godot relacionado:** godot/scripts/systems/prisoner_dialog.gd; godot/scripts/systems/radio_dialog.gd

**Integração inspecionada:** Nenhum localizado neste recorte.

**Testes existentes:** godot-prisoner-dialog

**Documentação:** Nenhum localizado neste recorte.

**Histórico consultado:** docs/progress/2026-10.md::2026-10-04 — Registro do diálogo de Grey Fox

**Implementado:** PrisonerDialog desenha o prompt piscante em PROMPT_ORIGIN (196, 36); RadioDialog desenha bitmap equivalente de 8x8 pixels em (212, 168).

**Faltante / não comprovado:** Ausente nas mensagens de reféns e chefes exibidas via banners no gameplay; não integrado a um despachador geral de caixas.

**Notas de evidência:** Código 0x3F desenhado quando TextBoxType tem bit alto de prompt icon; prisoner_dialog_test.gd testa o ciclo do prompt.


<a id="text-char-metrics-widths"></a>
### Métricas de caracteres e espaçamento proporcional

`text-char-metrics-widths` · **PARTIAL**

**Original:** Glifos de fonte MSX2 com largura nominal de 8 pixels, exceto apóstrofo (0x97) e dakuten (0x98) que possuem avanço de 4 pixels (Banks0123.asm:8024-8035); quebra de linha com avanço vertical de 12 pixels e retorno à margem esquerda (Banks0123.asm:8117-8125 TW_PrintNewLine).

**Classificação:** Métrica perfeitamente fiel em PrisonerDialog, mas ausente nos outros três renderizadores de texto do projeto.

**Assembly:** Banks0123.asm:8024-8036 TW_PrintChar5; Banks0123.asm:8113-8125 TW_PrintNewLine

**Extractors:** Nenhum localizado neste recorte.

**Dados canônicos locais:** Nenhum localizado neste recorte.

**Godot relacionado:** godot/scripts/systems/prisoner_dialog.gd

**Integração inspecionada:** Nenhum localizado neste recorte.

**Testes existentes:** godot-prisoner-dialog

**Documentação:** Nenhum localizado neste recorte.

**Histórico consultado:** docs/progress/2026-10.md::2026-10-04 — Registro do diálogo de Grey Fox

**Implementado:** PrisonerDialog implementa o avanço de 4 pixels para apóstrofo (código 0x97) e 12 pixels para nova linha, com asserções exatas em testes headless.

**Faltante / não comprovado:** RadioDialog, CaptureCutscene e banners de gameplay utilizam avanço fixo de 8 pixels ou fontes de sistema sem a métrica de 4px do apóstrofo.

**Notas de evidência:** prisoner_dialog_test.gd verifica: 'Apostrophe advances four pixels' e 'Explicit newline advances twelve pixels'.


<a id="text-decoder-rom-dictionary"></a>
### Decodificador de texto da ROM e dicionário de tokens

`text-decoder-rom-dictionary` · **PARTIAL**

**Original:** Descompressão dos textos indexados em idxTexts (158 textos da edição inglesa) através do dicionário de palavras e tokens em data/texts.asm (Banks0123.asm:5305-5345 DecodeText); suporte a marcadores de controle 0xFF (fim), 0xFE (nova linha) e 0xFD (nova página).

**Classificação:** O decodificador canônico foi implementado em Python e comprovado contra a ROM canônica, mas seu pipeline ainda não foi estendido aos outros textos do jogo.

**Assembly:** Banks0123.asm:5305-5345 DecodeText; data/texts.asm idxTexts

**Extractors:** tools/extractors/extract_grey_fox_dialogue.py

**Dados canônicos locais:** Nenhum localizado neste recorte.

**Godot relacionado:** godot/scripts/systems/prisoner_dialog.gd

**Integração inspecionada:** Nenhum localizado neste recorte.

**Testes existentes:** godot-prisoner-dialog; tests/test_grey_fox_dialogue.py

**Documentação:** Nenhum localizado neste recorte.

**Histórico consultado:** docs/progress/2026-10.md::2026-10-04 — Registro do diálogo de Grey Fox; docs/progress.md::2026-10-04 — Sistema de rádio: tabela canônica, chamadas e AUTO-REPLY/WAIT-CALL

**Implementado:** Extractor tools/extractors/extract_grey_fox_dialogue.py implementa decodificação fiel com dicionário da ROM para o Texto 59; PrisonerDialog consome o JSON resultante.

**Faltante / não comprovado:** No runtime do Godot são consumidos o Texto 59 e os 45 textos do rádio (radio_dialogue.json); os demais textos da ROM seguem não extraídos ou hardcoded.

**Notas de evidência:** extract_grey_fox_dialogue.py valida segmento completo de texts.asm byte a byte contra a ROM canônica; runtime só carrega grey-fox-en.json.


<a id="text-event-triggers"></a>
### Disparo de eventos e flags ao término do diálogo

`text-event-triggers` · **NOT_STARTED**

**Original:** Ao encerrar a leitura de textos específicos sem pular (SkipTextF == 0 em Banks0123.asm:8305-8324 TextBoxExit): Texto 117 liga JeniRocketF = 1 (disponibiliza rocket launcher); Texto 118 liga JeniOpenDoorF = 1 (abre porta da bússola); Texto 138 liga SchneiderCaptured = 1 (Schneider capturado). Se o texto for pulado, as flags não são ligadas.

**Classificação:** Ponto crítico de acoplamento entre leitura de diálogos e progressão do mapa/equipamentos que ainda não existe no Godot.

**Assembly:** Banks0123.asm:8301-8325 TextBoxExit

**Extractors:** Nenhum localizado neste recorte.

**Dados canônicos locais:** Nenhum localizado neste recorte.

**Godot relacionado:** godot/scripts/systems/radio_system.gd; godot/scripts/scenes/sandbox_gameplay.gd

**Integração inspecionada:** Nenhum localizado neste recorte.

**Testes existentes:** Nenhum localizado neste recorte.

**Documentação:** Nenhum localizado neste recorte.

**Histórico consultado:** Nenhum localizado neste recorte.

**Implementado:** Nenhuma integração em radio_system.gd ou sandbox_gameplay.gd.

**Faltante / não comprovado:** O encerramento de textos no Godot não atualiza flags de eventos nem verifica se a mensagem foi pulada pelo jogador.

**Notas de evidência:** TextBoxExit2 escreve 1 na flag correspondente após comparar TextId com 117, 118 e 138; SkipTextF impede a ativação.


<a id="radio-portrait-snake-animation"></a>
### Animação do retrato de Solid Snake durante a fala

`radio-portrait-snake-animation` · **PARTIAL**

**Original:** Durante a fala de Snake no rádio (exclusivamente nos textos 10 e 155), o retrato de Snake anima boca e olhos sincronizado com TickCounter (DrawSnakeFrame, Banks0123.asm:8058-8097), alternando entre SnakePicture0, 1 e 2; quando outro personagem fala ou o texto termina, a boca permanece fechada (DrawSnakeFrame1).

**Classificação:** O efeito visual foi reproduzido, mas sua regra de ativação está desregulada e ativa para qualquer fala em vez de apenas falas de Snake.

**Assembly:** Banks0123.asm:8058-8097 DrawSnakeFrame; Banks0123.asm:8102-8108 TW_TextEnd

**Extractors:** Nenhum localizado neste recorte.

**Dados canônicos locais:** Nenhum localizado neste recorte.

**Godot relacionado:** godot/scripts/systems/radio_dialog.gd

**Integração inspecionada:** Nenhum localizado neste recorte.

**Testes existentes:** Nenhum localizado neste recorte.

**Documentação:** Nenhum localizado neste recorte.

**Histórico consultado:** docs/progress/2026-09.md::2026-09-20 — Etapa 15 concluída: Sistema de Rádio Transceptor (Transceiver / Codec)

**Implementado:** RadioDialog desenha boca e olhos animados no retrato de Snake via anim_timer.

**Faltante / não comprovado:** Animação roda continuamente por timer delta mesmo quando outros personagens falam; não é restrita aos textos de Snake (10 e 155); não usa a máscara canônica de TickCounter.

**Notas de evidência:** cp 10 e cp 155 condicionam a fala em Banks0123.asm:8059-8064; em radio_dialog.gd anim_timer anima continuamente.


<a id="hostage-dialogue-system"></a>
### Diálogos de reféns e prisioneiros (Hostages/Prisoners)

`hostage-dialogue-system` · **PARTIAL**

**Original:** Sequência de resgate de prisioneiros em logic/actors/prisoner.asm:112-250: exibe primeiro Texto 1 ('RELIEVE') ou Texto 28 ('I'M SAVED!'), seguido pelo texto informativo específico do refém (data/texts.asm); casos essenciais: Grey Fox (Texto 59), Dr. Madnar (Texto 182), Ellen Madnar (Texto 167), Irmão de Jennifer (Texto 193).

**Classificação:** Grey Fox está implementado de forma exemplar, mas os demais 22 reféns utilizam textos provisórios e banner genérico.

**Assembly:** logic/actors/prisoner.asm:112-250; data/texts.asm:1; data/texts.asm:28; data/texts.asm:59; data/texts.asm:167; data/texts.asm:182; data/texts.asm:193

**Extractors:** Nenhum localizado neste recorte.

**Dados canônicos locais:** Nenhum localizado neste recorte.

**Godot relacionado:** godot/scripts/systems/prisoner_dialog.gd; godot/scripts/systems/prisoner.gd; godot/scripts/scenes/sandbox_gameplay.gd

**Integração inspecionada:** Nenhum localizado neste recorte.

**Testes existentes:** godot-prisoner-dialog; godot-rank-and-prisoners

**Documentação:** docs/reverse_engineering/grey-fox-dialogue.md

**Histórico consultado:** docs/progress/2026-10.md::2026-10-04 — Registro do diálogo de Grey Fox

**Implementado:** Grey Fox usa PrisonerDialog autêntico; prisoner.gd possui tabela PRISONER_TEXTS com 22 salas mapeadas e dispara resgates.

**Faltante / não comprovado:** Todos os outros 22 reféns utilizam strings em inglês parafraseadas, exibidas através de banner provisório dialog_banner_label na parte inferior da tela, sem usar a janela de texto oficial MSX2.

**Notas de evidência:** PRISONER_TEXTS em prisoner.gd possui 22 textos hardcoded; dialog_banner_label usa temporizador de 4.0s.


<a id="boss-enemy-speech-dialogue"></a>
### Diálogos e falas de chefes e inimigos

`boss-enemy-speech-dialogue` · **PARTIAL**

**Original:** Falas de inimigos e chefes antes de combates ou eventos especiais: Guardas da Sala 8 (Texto 6 'DON'T MOVE!' e Texto 7 'YOU ARE CAPTURED!'), Shot Gunner (Texto 66), Machinegun Kid (Texto 81), Fire Trooper (Texto 98), Coward Duck (Texto 125), Guardas do Deserto (Texto 35), Big Boss (Textos 149, 150). Exibidos via SetTextUnskippable ou SetTextUnskip2.

**Classificação:** A cutscene de captura possui falas inimigas autênticas, mas os diálogos de bosses utilizam rótulos provisórios ou ainda não foram iniciados.

**Assembly:** logic/capturescene.asm:174; logic/capturescene.asm:259; logic/actors/shotgunner.asm:66; logic/actors/machinegunkid.asm:54; logic/actors/firetropper.asm:32; logic/actors/cowardduck.asm:41; logic/actors/bigboss.asm:59

**Extractors:** Nenhum localizado neste recorte.

**Dados canônicos locais:** Nenhum localizado neste recorte.

**Godot relacionado:** godot/scripts/systems/capture_cutscene.gd; godot/scripts/systems/shot_gunner.gd; godot/scripts/scenes/sandbox_gameplay.gd

**Integração inspecionada:** Nenhum localizado neste recorte.

**Testes existentes:** godot-capture-prison

**Documentação:** Nenhum localizado neste recorte.

**Histórico consultado:** docs/progress/2026-09.md::2026-09-20 — Etapa 18 concluída: Boss Fight Canônica — Shoot Gunner (Sala 57)

**Implementado:** Cutscene da Sala 8 implementa Textos 6 e 7 com caixa Tipo 4 e fonte autêntica; Shot Gunner possui texto em shot_gunner.gd.

**Faltante / não comprovado:** Shot Gunner exibe texto em banner amarelo flutuante boss_dialog_label no topo da tela; chefes Machinegun Kid, Fire Trooper, Coward Duck e Big Boss não possuem caixas de diálogo no Godot.

**Notas de evidência:** boss_dialog_label em sandbox_gameplay.gd é Label amarelo com offset flutuante; diverge da caixa de texto do Z80.


<a id="intro-mission-briefing"></a>
### Briefing da missão na introdução (Operação Intrude N313)

`intro-mission-briefing` · **PARTIAL**

**Original:** Texto ID 2 em data/texts.asm:58, 203-228: briefing em 4 páginas com quebras explícitas FD/FE transmitido por Big Boss ao transceptor de Snake na Sala 121 ('OPERATION INTRUDE N313... SINTONIZE 120.85'); controles de Snake congelados (CONTROL_INTRO) e liberados na conclusão.

**Classificação:** A cena e o briefing funcionam perfeitamente na experiência de jogo, mas com texto hardcoded paráfraseado e sem a paginação binária da ROM.

**Assembly:** data/texts.asm:58; data/texts.asm:203-228; logic/introscene.asm:170-205

**Extractors:** Nenhum localizado neste recorte.

**Dados canônicos locais:** Nenhum localizado neste recorte.

**Godot relacionado:** godot/scripts/systems/intro_cutscene.gd; godot/scripts/systems/radio_dialog.gd

**Integração inspecionada:** Nenhum localizado neste recorte.

**Testes existentes:** godot-intro-cutscene

**Documentação:** docs/reverse_engineering/en-eu-reextraction.md

**Histórico consultado:** docs/progress/2026-09.md::Cutscene de Infiltração Aquática e Escalada da Grade (Abertura Pré-Jogo MSX2) (2026-09-29)

**Implementado:** intro_cutscene.gd aciona start_briefing em radio_dialog.gd, exibindo 4 páginas de briefing transmitidas por Big Boss com avanço por tecla e trava de sintonia.

**Faltante / não comprovado:** O texto inglês está hardcoded em intro_cutscene.gd com paráfrases leves em relação à ROM (corrigindo 'DESTOROY' e espaçamento); a paginação é feita dinamicamente por wrap de pixels em vez de respeitar os bytes FD/FE da ROM.

**Notas de evidência:** Registrado na auditoria regional: intro texto 2 possui diferenças textuais (DESTOROY vs DESTROY); paginação original usa FD.


<a id="gameplay-contextual-messages"></a>
### Mensagens contextuais de gameplay e avisos de perigo

`gameplay-contextual-messages` · **PROVISIONAL**

**Original:** Mensagens disparadas pelo sistema durante eventos ou perigos específicos: aviso de gás sem máscara (Texto 25), aviso de piso eletrificado e painel de força (Texto 38); mensagem de coleta de item (na edição japonesa Texto 62 'Gear taken!!', na edição inglesa suprimida exceto caso do transmissor na BAG).

**Classificação:** Estão cadastradas como entradas estáticas de rádio por sala, mas sem o comportamento reativo a estados de perigo do jogador.

**Assembly:** logic/damagegas.asm; logic/items.asm:399-414; data/radiocalls.asm:45; data/radiocalls.asm:63

**Extractors:** Nenhum localizado neste recorte.

**Dados canônicos locais:** Nenhum localizado neste recorte.

**Godot relacionado:** godot/scripts/systems/radio_system.gd

**Integração inspecionada:** Nenhum localizado neste recorte.

**Testes existentes:** godot-radio-system

**Documentação:** docs/reverse_engineering/en-eu-reextraction.md

**Histórico consultado:** docs/progress/2026-10.md::2026-10-04 — Auditoria regional da implementação contra a edição inglesa

**Implementado:** Textos 25 e 38 estão mapeados no dicionário ROOM_CALLS de radio_system.gd para as salas 29 e 37.

**Faltante / não comprovado:** Não são disparadas contextualmente pela reação do jogador aos perigos (ex: ao tomar dano de gás sem máscara); a mensagem 62 da bolsa com transmissor não foi portada.

**Notas de evidência:** Falta de texto 62 na BAG registrada em en-eu-reextraction.md; mensagens de perigo só existem como salas de rádio estáticas.


<a id="ending-broadcast-dialogue"></a>
### Diálogo final e transmissão de notícias do encerramento

`ending-broadcast-dialogue` · **NOT_STARTED**

**Original:** Sequência final pós-destruição de Metal Gear (logic/ending.asm:170-200, 304): Snake reporta sucesso da missão pelo rádio (Texto 155: 'THIS IS SOLID SNAKE... I DESTROYED METAL GEAR. OPERATION INTRUDE N313 ACCOMPLISHED!'); sintonia automática incrementa até 120.77 (FREQ_NEWS), disparando boletim de notícias pelo rádio (Texto 156), seguido pelos créditos finais.

**Classificação:** Fase final de encerramento do jogo ainda não iniciada.

**Assembly:** logic/ending.asm:170-200; logic/ending.asm:304; Banks0123.asm:8063-8064; data/texts.asm:155; data/texts.asm:156

**Extractors:** Nenhum localizado neste recorte.

**Dados canônicos locais:** Nenhum localizado neste recorte.

**Godot relacionado:** godot/scripts/systems/radio_system.gd

**Integração inspecionada:** Nenhum localizado neste recorte.

**Testes existentes:** Nenhum localizado neste recorte.

**Documentação:** Nenhum localizado neste recorte.

**Histórico consultado:** Nenhum localizado neste recorte.

**Implementado:** Nenhuma implementação no Godot.

**Faltante / não comprovado:** Toda a sequência de rádio do encerramento, o canal 120.77 e os diálogos finais estão ausentes no projeto.

**Notas de evidência:** FREQ_NEWS (77h / 120.77) é sintonizada automaticamente no ending e aciona os leds de sinal (logic/ending.asm:181-189).


<a id="fake-madnar-trap-dialogue"></a>
### Diálogo do Falso Madnar e armadilha de alçapão

`fake-madnar-trap-dialogue` · **PROVISIONAL**

**Original:** Diálogo do impostor (ator ID 55, sala 189) em logic/actors/fakemadnar.asm:30-45: dispara Texto ID 189 ('HEHEHE... I'M AN IMPOSTOR! THE REAL DR. PETTROVICH IS ELSEWHERE!') via SetTextUnskippable, acionando simultaneamente a abertura do alçapão/pitfall sob os pés de Snake.

**Classificação:** A fala está registrada em dicionário de texto, mas o despachador original de diálogo e o gatilho da armadilha não foram implementados.

**Assembly:** logic/actors/fakemadnar.asm:30-45

**Extractors:** Nenhum localizado neste recorte.

**Dados canônicos locais:** Nenhum localizado neste recorte.

**Godot relacionado:** godot/scripts/systems/prisoner.gd; godot/scripts/scenes/sandbox_gameplay.gd

**Integração inspecionada:** Nenhum localizado neste recorte.

**Testes existentes:** Nenhum localizado neste recorte.

**Documentação:** Nenhum localizado neste recorte.

**Histórico consultado:** Nenhum localizado neste recorte.

**Implementado:** String presente em PRISONER_TEXTS[189] dentro de prisoner.gd.

**Faltante / não comprovado:** O ator do Falso Madnar não existe; a fala é exibida como refém comum em dialog_banner_label; não utiliza caixa unskippable nem aciona a armadilha de alçapão sincronizada.

**Notas de evidência:** SetTextUnskippable acionado em fakemadnar.asm:41; abertura de alçapão ocorre durante a fala.

## Progressão global, flags de evento, desbloqueios e transições de campanha

Auditoria: 2026-10-04; HEAD de partida: `13d74a0`; referência inglesa: `30d1b940bede10fdabbaf9767ad4f0ad8dd33291`.

Inventário das rotinas, flags e eventos de progressão global da edição inglesa RC750 (JAPANESE equ 0): buffer de persistência e checkpoints (GameProgressBuffer, SaveStatRooms), ciclo de Game Over e Continue (GS_GameOver, ChkContinueKey), patentes militares (Class/Rank ★1 a ★4) e penalidade por morte de refém (DowngradeRank), cadeia de captura na sala 8 e fuga da prisão (salas 165/164), restituição de equipamentos e transmissor (ITEM_BAG), resgate dos reféns essenciais (Grey Fox, Ellen, Madnar), consequências da derrota de todos os bosses (Shoot Gunner, Machine Gun Kid, Hind-D, Tank, Bulldozer, Fire Trooper, Arnolds com Cartão 7, Metal Gear e Big Boss), portas e passagens dependentes de eventos (porta de entrada do Edifício 2, porta da bússola, porta do Metal Gear e Big Boss), travessias de perigo com requisitos de equipamento (paraquedas no telhado, bússola no deserto, antena no Edifício 2, tanque de oxigênio no canal), traição de Big Boss (sala 111), contagem regressiva de autodestruição (DecNukeTimer), fuga e encerramento (EndingSetup), caminhões móveis (MovingLorries) e rede de 11 elevadores. Exclui combate detalhado coberto em actors-bosses, inventário detalhado coberto em weapons-items e diálogos cobertos em radio-dialogue.

Inventário inicial a partir da desmontagem canônica inglesa (logic/checkpoints.asm, logic/capturescene.asm, logic/doors/opendoor.asm, logic/items.asm, logic/nextroom.asm, logic/lorry.asm, logic/elevatorroom.asm, logic/madnarbigbossevent.asm, logic/destructiontimer.asm, logic/ending.asm, logic/actors/*.asm, Banks0123.asm, Variables.asm). Cruzamento com sistemas Godot (sandbox_gameplay.gd, capture_system.gd, capture_cutscene.gd, prison_wall_door.gd, rank_system.gd, elevator_system.gd, room_manager.gd), extratores, testes automatizados e histórico. Classificação segundo os 7 statuses sem promover a IMPLEMENTED sem suporte à persistência de campanha. Sem alterações de código de gameplay nesta tarefa.

- Domínio focado na amarração macro da campanha, persistência de checkpoints, flags globais, condições de desbloqueio e transições de estado.
- Integrou as mecânicas legadas 'capture-prison' e 'elevators' para manter referências cruzadas existentes intactas.
- Identificado conflito crítico de IDs de salas 211/212 (aliases locais de prisão vs salas reais de canal de água da ROM) que representa risco grave de softlock na progressão para o Edifício 3.
- Zero features IMPLEMENTED: o projeto atual é um sandbox de salas do Edifício 1 com testes de mecânicas isoladas; não possui a máquina de estados contínua necessária para um playthrough do início ao fim.

| Status | Features |
| --- | ---: |
| `IMPLEMENTED` | 0 |
| `PARTIAL` | 4 |
| `PROVISIONAL` | 5 |
| `NOT_STARTED` | 24 |
| `DEFERRED` | 0 |
| `UNMAPPED` | 0 |
| `INVESTIGATING` | 0 |
| Total | 33 |

### Entradas

| Feature | IDs | Status |
| --- | --- | --- |
| [elevators](#elevators) — Rede de 11 eixos de elevadores conectando andares dos 3 edifícios | transversal | `PARTIAL` |
| [capture-prison](#capture-prison) — Captura na Sala 8, encarceramento na cela e fuga da prisão | transversal | `PARTIAL` |
| [progression-flags-buffer](#progression-flags-buffer) — Buffer canônico de persistência e checkpoints (GameProgressBuffer) | transversal | `NOT_STARTED` |
| [progression-game-over-continue](#progression-game-over-continue) — Ciclo de Game Over e Continue com restauração de checkpoint | transversal | `NOT_STARTED` |
| [progression-rank-stars](#progression-rank-stars) — Patente militar (Rank ★1 a ★4) e requisitos de progressão | transversal | `PARTIAL` |
| [progression-hostage-penalty-downgrade](#progression-hostage-penalty-downgrade) — Penalidade por morte de refém, rebaixamento de rank e reset de prisioneiros | transversal | `PROVISIONAL` |
| [progression-grey-fox-rescue](#progression-grey-fox-rescue) — Resgate de Grey Fox na prisão e revelação de Dr. Madnar | transversal | `PROVISIONAL` |
| [progression-equipment-recovery](#progression-equipment-recovery) — Recuperação de equipamentos na bolsa e inserção do transmissor | transversal | `PROVISIONAL` |
| [progression-boss-shotgunner](#progression-boss-shotgunner) — Derrota de Shoot Gunner na Sala 57 e destrancamento do subsolo | transversal | `PROVISIONAL` |
| [progression-boss-machinegunkid](#progression-boss-machinegunkid) — Derrota de Machine Gun Kid na Sala 39 e destrancamento do refém do telhado | transversal | `NOT_STARTED` |
| [progression-boss-hind-d](#progression-boss-hind-d) — Destruição de Hind-D no telhado do Edifício 1 | transversal | `NOT_STARTED` |
| [progression-roof-parachute-jump](#progression-roof-parachute-jump) — Salto de paraquedas do telhado para o pátio vs queda mortal | transversal | `NOT_STARTED` |
| [progression-desert-crossing-compass](#progression-desert-crossing-compass) — Travessia do labirinto do deserto e exigência da bússola | transversal | `NOT_STARTED` |
| [progression-boss-tank](#progression-boss-tank) — Derrota do Tanque no deserto e abertura do caminho para o Edifício 2 | transversal | `NOT_STARTED` |
| [progression-building2-entrance-door](#progression-building2-entrance-door) — Abertura da porta trancada de entrada do Edifício 2 pelos guardas | transversal | `NOT_STARTED` |
| [progression-antenna-requirement](#progression-antenna-requirement) — Requisito da Antena equipada para comunicação no Edifício 2 | transversal | `NOT_STARTED` |
| [progression-boss-bulldozer](#progression-boss-bulldozer) — Derrota do Bulldozer no Edifício 2 e liberação do corredor | transversal | `NOT_STARTED` |
| [progression-jennifer-compass-door](#progression-jennifer-compass-door) — Abertura remota da porta da bússola por Jennifer via rádio | transversal | `NOT_STARTED` |
| [progression-jennifer-rocket-launcher](#progression-jennifer-rocket-launcher) — Concessão do lançador de foguetes por Jennifer | transversal | `NOT_STARTED` |
| [progression-boss-firetrooper](#progression-boss-firetrooper) — Derrota de Fire Trooper no subsolo do Edifício 2 | transversal | `NOT_STARTED` |
| [progression-ellen-rescue](#progression-ellen-rescue) — Resgate de Ellen e pré-requisito de cooperação de Madnar | transversal | `NOT_STARTED` |
| [progression-madnar-rescue-formula](#progression-madnar-rescue-formula) — Resgate de Dr. Madnar e revelação da fórmula de destruição do Metal Gear | transversal | `NOT_STARTED` |
| [progression-fake-madnar-trap](#progression-fake-madnar-trap) — Armadilha do Falso Madnar e acionamento de alçapão | transversal | `PROVISIONAL` |
| [progression-madnar-moved-event](#progression-madnar-moved-event) — Evento da cela vazia na Sala 133 ('Madnar foi transferido') | transversal | `NOT_STARTED` |
| [progression-schneider-captured-event](#progression-schneider-captured-event) — Evento de captura de Schneider durante transmissão de rádio | transversal | `NOT_STARTED` |
| [progression-water-channel-oxygen](#progression-water-channel-oxygen) — Travessia do canal de água e exigência do tanque de oxigênio | transversal | `NOT_STARTED` |
| [progression-boss-arnolds-card7](#progression-boss-arnolds-card7) — Derrota dos ciborgues Arnolds na Sala 104 e obtenção do Cartão 7 | transversal | `NOT_STARTED` |
| [progression-bigboss-betrayal-switchoff](#progression-bigboss-betrayal-switchoff) — Traição de Big Boss na Sala 111 e ordem para desligar o MSX | transversal | `NOT_STARTED` |
| [progression-metalgear-destruction](#progression-metalgear-destruction) — Destruição do Metal Gear com 16 C4 e ativação da autodestruição | transversal | `NOT_STARTED` |
| [progression-boss-bigboss-final](#progression-boss-bigboss-final) — Confronto final com Big Boss na Sala 119 e abertura da escada de fuga | transversal | `NOT_STARTED` |
| [progression-escape-ending](#progression-escape-ending) — Fuga pela escada de escape, evasão de Outer Heaven e créditos finais | transversal | `NOT_STARTED` |
| [progression-moving-lorries-transport](#progression-moving-lorries-transport) — Rede de caminhões móveis e transporte entre setores (Moving Lorries) | transversal | `PARTIAL` |
| [progression-building-transitions](#progression-building-transitions) — Cadeia global de transição entre edifícios (Edifício 1 -> 2 -> 3) | transversal | `NOT_STARTED` |

### UNMAPPED

Nenhuma entrada.

<a id="elevators"></a>
### Rede de 11 eixos de elevadores conectando andares dos 3 edifícios

`elevators` · **PARTIAL**

**Original:** Rede de 11 eixos verticais de elevadores conectando andares dos 3 edifícios (salas 240 a 250, data/elevatorrooms.asm, logic/elevatorroom.asm:7-227, logic/nextroom.asm:74-94). Movimento da cabine a 1 px/tick com direcional cima/baixo, transição contínua entre shafts verticais (ElevatorExitRoom) e parada nos andares autorizados da campanha (1F, 2F, 3F, B1, Telhado).

**Classificação:** Sistema de elevadores bem modelado no Godot, mas com integração e cobertura parciais em relação ao conjunto de edifícios do jogo completo.

**Assembly:** logic/elevatorroom.asm:7-36 ElevatorRoomLogic; logic/elevatorroom.asm:41-70 MoveElevator; logic/nextroom.asm:74-94

**Extractors:** Nenhum localizado neste recorte.

**Dados canônicos locais:** Nenhum localizado neste recorte.

**Godot relacionado:** godot/scripts/systems/elevator_system.gd; godot/scripts/systems/elevator_cabin.gd; godot/scripts/scenes/sandbox_gameplay.gd

**Integração inspecionada:** godot/scripts/scenes/sandbox_gameplay.gd::_transition_elevator_room

**Testes existentes:** godot-elevator

**Documentação:** Nenhum localizado neste recorte.

**Histórico consultado:** docs/progress/2026-09.md::2026-09-21 — Fix: Transição Contínua Vertical de Shafts de Elevadores Multi-Telas (Salas 241 <-> 242)

**Implementado:** elevator_system.gd e elevator_cabin.gd implementam movimentação de cabine, shafts conectados e transição de tela em sandbox_gameplay.gd.

**Faltante / não comprovado:** Nem todos os 11 eixos da ROM estão integrados e validados no fluxo contínuo de campanha; conexão com salas superiores do Edifício 2 e Edifício 3 não coberta nos testes.

**Notas de evidência:** Salas 240 a 250 cobrem todos os eixos de elevador de Outer Heaven.


<a id="capture-prison"></a>
### Captura na Sala 8, encarceramento na cela e fuga da prisão

`capture-prison` · **PARTIAL**

**Original:** Ao cruzar a zona X=[192, 208] na sala 8, dispara CaptureSceneLogic (logic/capturescene.asm:8-118): guarda diz 'DON'T MOVE!', trava inputs, fade-out, confisca armas e itens (EquipRemoved = 1, SelectedWeapon = 0, SelectedItem = 0), teletransporta Snake para a cela na sala 165 em (128, 80). Fuga exige socar a parede oca leste da cela (porta 103, PrisonWall1Life) para alcançar a cela vizinha de Grey Fox (sala 164), e em seguida socar a parede sul (porta 12, PrisonWall2Life) para abrir a passagem para o subsolo (sala 54).

**Classificação:** Cadeia completa e funcional no sandbox, mas com conflito documentado de room IDs (211/212 vs canal da ROM) e aproximações temporais.

**Assembly:** logic/capturescene.asm:8-18 CaptureSceneLogic; logic/capturescene.asm:87-118 PutInPrison; logic/doors/opendoor.asm:285-319 ChkPrisonWalls; logic/doors/drawdoors.asm:262-319 DrawWallPrison2

**Extractors:** tools/extractors/extract_capture_prison_data.py; tools/extractors/extract_prison_wall.py

**Dados canônicos locais:** capture_prison.json; prison-walls/

**Godot relacionado:** godot/scripts/systems/capture_system.gd; godot/scripts/systems/capture_cutscene.gd; godot/scripts/systems/prison_wall_door.gd

**Integração inspecionada:** godot/scripts/scenes/sandbox_gameplay.gd::_trigger_capture_event; godot/scripts/scenes/sandbox_gameplay.gd::break_prison_wall

**Testes existentes:** godot-capture-prison; godot-prison-wall; tests/test_prison_wall_extractor.py

**Documentação:** docs/reverse_engineering/prison-wall.md; docs/index/rooms.md

**Histórico consultado:** docs/progress/2026-10.md::2026-10-01 — Implementação da Animação Canônica de Captura na Sala 8 e Transporte para Cela 211; docs/progress/2026-10.md::2026-10-02 — Parede original da cela de captura

**Implementado:** Implementado em capture_cutscene.gd, capture_system.gd, prison_wall_door.gd e sandbox_gameplay.gd: detecção na sala 8, cutscene com fade, confisco de inventário, teletransporte para cela e mecânica de soco que abre as portas 103 e 12.

**Faltante / não comprovado:** O Godot utiliza salas 211 e 212 como aliases locais da prisão em vez das salas originais 165 e 164, conflitando com salas reais de canal da ROM; temporização da cutscene diverge do Z80; resistência das paredes utiliza constantes desacopladas dos ticks do Z80.

**Notas de evidência:** Na ROM original a prisão é a sala 165 e a cela de Grey Fox é a 164. Aliases locais 211/212 causam colisão com as salas de canal.


<a id="progression-flags-buffer"></a>
### Buffer canônico de persistência e checkpoints (GameProgressBuffer)

`progression-flags-buffer` · **NOT_STARTED**

**Original:** Buffer de 544 bytes (0x220) em GameProgressBuffer (Variables.asm:365) salvo em ChkSaveGameStatus / StoreGameStat (logic/checkpoints.asm:10-127) ao passar entre 31 pares de salas de checkpoint (SaveStatRooms). Persiste vida, classe/rank, munição, status de todas as 216 portas (DoorOpenArray), inventário completo (Equipment), status de todos os 23 reféns (RescuedArray), flags de bosses derrotados (BossHindD_KO, BossTank_KO, Bulldozer_KO, MetalGear_KO, FireTrooper_KO, ShotGunnerStat, MachGunStatus, BigBossStat) e flags de eventos (PowerSwitchOn, DoorBuild2LockedF, JennifBrotherDead, MadnarMoved, JeniRocketF, SchneiderCaptured, JeniOpenDoorF, SwitchOffMSXF). Gravação é permanentemente suspensa após MetalGear_KO.

**Classificação:** O Godot gerencia estados de salas de forma fragmentada e recria entidades em cada troca de sala sem a matriz canônica de 544 bytes do Z80.

**Assembly:** logic/checkpoints.asm:10-36 ChkSaveGameStatus; logic/checkpoints.asm:59-103 StoreGameStat; logic/checkpoints.asm:114-126; logic/checkpoints.asm:134-164

**Extractors:** Nenhum localizado neste recorte.

**Dados canônicos locais:** Nenhum localizado neste recorte.

**Godot relacionado:** godot/scripts/scenes/sandbox_gameplay.gd

**Integração inspecionada:** Nenhum localizado neste recorte.

**Testes existentes:** Nenhum localizado neste recorte.

**Documentação:** Nenhum localizado neste recorte.

**Histórico consultado:** Nenhum localizado neste recorte.

**Implementado:** Não há buffer de persistência unificado nem tabela de checkpoints da ROM.

**Faltante / não comprovado:** GameProgressBuffer, serialização por GameDataAreas, tabela SaveStatRooms com 31 checkpoints e bloqueio pós-Metal Gear não implementados.

**Notas de evidência:** Checkpoints dependem de pares exatos de transição em SaveStatRooms; serialização ldir com 6 blocos de RAM.


<a id="progression-game-over-continue"></a>
### Ciclo de Game Over e Continue com restauração de checkpoint

`progression-game-over-continue` · **NOT_STARTED**

**Original:** Ao esgotar a vida (Life = 0), aciona modo de morte SetDead (Banks0123.asm:10410-10500, GS_GameOver). Exibe mensagem GAME OVER e aguarda tecla F5 (ChkContinueKey). Se confirmado (RestoreGameFlag = 1), chama RestoreGameStat (logic/checkpoints.asm:44-51), desempacotando GameProgressBuffer e restabelecendo o jogador no último checkpoint salvo com vida e inventário persistidos. Se recusado, reinicia a partida do zero na sala 121.

**Classificação:** Fluxo de Game Over existe apenas como rotina simplificada de reinício sem o protocolo de Continue e restauração de checkpoint do Z80.

**Assembly:** Banks0123.asm:10410-10430 GS_GameOver; Banks0123.asm:10435-10455 ChkContinueKey; logic/checkpoints.asm:44-51 RestoreGameStat

**Extractors:** Nenhum localizado neste recorte.

**Dados canônicos locais:** Nenhum localizado neste recorte.

**Godot relacionado:** godot/scripts/scenes/sandbox_gameplay.gd

**Integração inspecionada:** godot/scripts/scenes/sandbox_gameplay.gd::trigger_game_over; godot/scripts/scenes/sandbox_gameplay.gd::_execute_game_restart

**Testes existentes:** Nenhum localizado neste recorte.

**Documentação:** Nenhum localizado neste recorte.

**Histórico consultado:** Nenhum localizado neste recorte.

**Implementado:** sandbox_gameplay.gd possui trigger_game_over e _execute_game_restart, com reinício direto do jogador na sala de spawn.

**Faltante / não comprovado:** Não existe diálogo de Continue via F5 nem restauração do checkpoint a partir do buffer serializado; morte resulta em reinício manual/debug na sala 121 ou reset local sem persistência canônica.

**Notas de evidência:** RestoreGameStat recarrega o estado salvo em GameProgressBuffer e posiciona Snake na sala anterior do checkpoint.


<a id="progression-rank-stars"></a>
### Patente militar (Rank ★1 a ★4) e requisitos de progressão

`progression-rank-stars` · **PARTIAL**

**Original:** Variável Class (Variables.asm:81, 0 a 3 = ★1 a ★4). Incremento ocorre estritamente a cada 5 prisioneiros resgatados em IncRescued (Banks0123.asm:9634-9653, cp 5; inc (hl); SFX 26h). Aumenta barra de vida (24/32/40/48 px via UpdateLevels), limite de munição (Handgun 50/100/200/300) e rações (3/6/9/12). Rank ★4 é requisito indispensável para desbloquear Jennifer no rádio (120.48), permitindo abrir a porta da bússola e obter o lançador de foguetes.

**Classificação:** Estrutura existe e funciona, mas com divergência numérica canônica (4 vs 5 reféns por estrela) e sem a amarração completa de bloqueio de campanha.

**Assembly:** Banks0123.asm:9634-9653 IncRescued

**Extractors:** Nenhum localizado neste recorte.

**Dados canônicos locais:** Nenhum localizado neste recorte.

**Godot relacionado:** godot/scripts/systems/rank_system.gd; godot/scripts/systems/hud.gd

**Integração inspecionada:** godot/scripts/scenes/sandbox_gameplay.gd::_on_prisoner_rescued; godot/scripts/systems/rank_system.gd::register_rescue

**Testes existentes:** godot-rank-and-prisoners

**Documentação:** docs/reverse_engineering/grey-fox-dialogue.md

**Histórico consultado:** docs/progress/2026-09.md::2026-09-21 — Etapa 19: Sistema de Prisioneiros, Reféns e Patente Militar (Ranks ★1 a ★4)

**Implementado:** rank_system.gd implementa patentes 1 a 4, cálculo de vida máxima (24 a 48), capacidade de munição e rações, com sinal rank_changed integrado ao HUD.

**Faltante / não comprovado:** rank_system.gd define RESCUED_PER_RANK = 4 em vez do valor canônico da ROM que é 5 (cp 5 em Banks0123.asm:9638); o rádio no Godot ainda não bloqueia Jennifer por rank de forma reativa estrita.

**Notas de evidência:** cp 5 em Banks0123.asm:9638 define que são necessários 5 reféns por estrela.


<a id="progression-hostage-penalty-downgrade"></a>
### Penalidade por morte de refém, rebaixamento de rank e reset de prisioneiros

`progression-hostage-penalty-downgrade` · **PROVISIONAL**

**Original:** Ao matar um refém com tiros ou socos, DowngradeRank (Banks0123.asm:9580-9625) zera RescuedCnt, reseta o status de resgate dos últimos 17 prisioneiros em RescuedArray (ldir preservando apenas os 6 primeiros e o irmão de Jennifer), decrementa Class (se > 0), reduz a vida máxima e capacidades de munição/rações, e toca SFX 27h. Se o refém assassinado for o irmão de Jennifer (prisioneiro 13 / 0Dh), Jennifer corta contato permanentemente pelo resto da campanha (JennifBrotherDead = 1).

**Classificação:** Implementação provisória apenas reduz um contador local sem reproduzir a lógica de penalidade persistente e consequências narrativas do original.

**Assembly:** Banks0123.asm:9580-9625 DowngradeRank

**Extractors:** Nenhum localizado neste recorte.

**Dados canônicos locais:** Nenhum localizado neste recorte.

**Godot relacionado:** godot/scripts/systems/rank_system.gd

**Integração inspecionada:** godot/scripts/systems/rank_system.gd::downgrade_rank

**Testes existentes:** godot-rank-and-prisoners

**Documentação:** Nenhum localizado neste recorte.

**Histórico consultado:** docs/progress/2026-09.md::2026-09-21 — Etapa 19: Sistema de Prisioneiros, Reféns e Patente Militar (Ranks ★1 a ★4)

**Implementado:** rank_system.gd possui método downgrade_rank() que decrementa current_rank e emite rank_changed.

**Faltante / não comprovado:** Não executa o reset canônico dos 17 prisioneiros em RescuedArray para permitir re-resgate; não detecta a morte do irmão de Jennifer nem seta JennifBrotherDead; não ajusta vida atual para o novo teto.

**Notas de evidência:** Reset de 17 reféns é punição severa do MSX2 que exige resgatar novamente prisioneiros de salas já visitadas.


<a id="progression-grey-fox-rescue"></a>
### Resgate de Grey Fox na prisão e revelação de Dr. Madnar

`progression-grey-fox-rescue` · **PROVISIONAL**

**Original:** Resgate do agente Grey Fox na cela adjacente (sala 164 / alias 212) após quebrar a primeira parede oca (logic/actors/prisoner.asm:95-120, RescuedArray[22]). Grey Fox revela a existência do Metal Gear e que seu criador Dr. Pettrovich Madnar está preso no complexo. Seta a flag de resgate do prisioneiro 22, contribuindo para a contagem de patentes militares e registrando o avanço narrativo.

**Classificação:** O evento ocorre visualmente e o diálogo é fiel à edição inglesa, mas a persistência no estado global da campanha é provisória em nós GDScript.

**Assembly:** logic/actors/prisoner.asm:95-120

**Extractors:** tools/extractors/extract_grey_fox_dialogue.py

**Dados canônicos locais:** dialogues/grey-fox-en.json

**Godot relacionado:** godot/scripts/systems/prisoner_dialog.gd; godot/scripts/scenes/sandbox_gameplay.gd

**Integração inspecionada:** godot/scripts/scenes/sandbox_gameplay.gd::_on_prisoner_rescued

**Testes existentes:** tests/test_grey_fox_dialogue.py; godot-prisoner-dialog

**Documentação:** docs/reverse_engineering/grey-fox-dialogue.md

**Histórico consultado:** docs/progress/2026-10.md::2026-10-04 — Registro do diálogo de Grey Fox

**Implementado:** Diálogo canônico de Grey Fox extraído da ROM e integrado na sala 212 via prisoner_dialog.gd e sandbox_gameplay.gd, com fala e desbloqueio.

**Faltante / não comprovado:** Não persiste o resgate na posição canônica RescuedArray[22]; status é mantido apenas em dicionário de strings em GDScript; não consome o sistema unificado de flags da campanha.

**Notas de evidência:** Grey Fox é o refém índice 22 no array canônico RescuedArray.


<a id="progression-equipment-recovery"></a>
### Recuperação de equipamentos na bolsa e inserção do transmissor

`progression-equipment-recovery` · **PROVISIONAL**

**Original:** Recuperação das armas e itens confiscados ao coletar a bolsa (ITEM_BAG na sala 168 / subsolo, logic/items.asm:295-325, RecoverEquipment). Seta EquipRemoved = 0 e EquipBagTaken = 1. Consequência canônica do Z80: a rotina AddTransmitter (logic/items.asm:314-325) adiciona furtivamente o item TRANSMITTER (SELECTED_TRANSMITTER) ao inventário do jogador (TransmiTaken = 1), atraindo patrulhas até ser descartado.

**Classificação:** Restituição visual e funcional das armas e itens existe, mas a consequência mecânica original de infiltração do transmissor foi ignorada.

**Assembly:** logic/items.asm:295-325 RecoverEquipment

**Extractors:** Nenhum localizado neste recorte.

**Dados canônicos locais:** Nenhum localizado neste recorte.

**Godot relacionado:** godot/scripts/systems/capture_system.gd; godot/scripts/scenes/sandbox_gameplay.gd

**Integração inspecionada:** godot/scripts/scenes/sandbox_gameplay.gd::_on_equipment_restored; godot/scripts/systems/capture_system.gd::restore_equipment

**Testes existentes:** godot-capture-prison

**Documentação:** Nenhum localizado neste recorte.

**Histórico consultado:** docs/progress/2026-09.md::2026-09-21 — Etapa 21: Evento de Captura na Sala 8, Cela 211, Parede Oca e Restituição de Inventário

**Implementado:** capture_system.gd implementa restore_equipment() restaurando backups de armas e itens, acionado ao coletar a bolsa na sala 168.

**Faltante / não comprovado:** A consequência canônica crucial foi omitida: o transmissor (TRANSMITTER) não é adicionado ao inventário, e a flag TransmiTaken não é acionada; o rádio e as patrulhas não reagem à presença do grampo.

**Notas de evidência:** AddTransmitter em logic/items.asm:314 insere SELECTED_TRANSMITTER automaticamente no inventário.


<a id="progression-boss-shotgunner"></a>
### Derrota de Shoot Gunner na Sala 57 e destrancamento do subsolo

`progression-boss-shotgunner` · **PROVISIONAL**

**Original:** Derrota do chefe Shoot Gunner na sala 57 (logic/actors/shotgunner.asm:8, 59, Banks0123.asm:13001). Ao zerar a vida, ShotGunnerStat bit 0 é setado (morto). Consequência: destranca permanentemente as portas da sala 57 (portas de cartão/acesso ao subsolo), impedindo o respawn do chefe ao reentrar na sala.

**Classificação:** Comportamento de combate e destrancamento de porta existe localmente, mas sem a persistência canônica do Z80.

**Assembly:** logic/actors/shotgunner.asm:55-65; Banks0123.asm:13001

**Extractors:** Nenhum localizado neste recorte.

**Dados canônicos locais:** Nenhum localizado neste recorte.

**Godot relacionado:** godot/scripts/scenes/sandbox_gameplay.gd; godot/scripts/systems/shot_gunner.gd

**Integração inspecionada:** godot/scripts/scenes/sandbox_gameplay.gd::_on_boss_defeated

**Testes existentes:** godot-boss-shoot-gunner

**Documentação:** Nenhum localizado neste recorte.

**Histórico consultado:** docs/progress/2026-09.md::2026-09-20 — Etapa 18 concluída: Boss Fight Canônica — Shoot Gunner (Sala 57)

**Implementado:** sandbox_gameplay.gd:2998-3022 registra defeated_bosses[33] = true, destranca portas com LOCKED_BOSS e exibe mensagem de vitória.

**Faltante / não comprovado:** Flag é armazenada em dicionário local do sandbox em vez de ShotGunnerStat / GameDataArea; não persiste em checkpoints ou salvamento de sessão.

**Notas de evidência:** Bit 0 de ShotGunnerStat indica chefe morto; impede reativação do combate.


<a id="progression-boss-machinegunkid"></a>
### Derrota de Machine Gun Kid na Sala 39 e destrancamento do refém do telhado

`progression-boss-machinegunkid` · **NOT_STARTED**

**Original:** Derrota de Machine Gun Kid na sala 39 (Edifício 1, 2º andar) (logic/actors/machinegunkid.asm:9, 48, Banks0123.asm:13017). Ao morrer, seta MachGunStatus bit 0 = 1, destrancando a porta para a sala traseira onde está o prisioneiro que revela a necessidade do paraquedas para descer do telhado.

**Classificação:** Boss e consequências de vitória não iniciados.

**Assembly:** logic/actors/machinegunkid.asm:45-55; Banks0123.asm:13017

**Extractors:** Nenhum localizado neste recorte.

**Dados canônicos locais:** Nenhum localizado neste recorte.

**Godot relacionado:** Nenhum localizado neste recorte.

**Integração inspecionada:** Nenhum localizado neste recorte.

**Testes existentes:** Nenhum localizado neste recorte.

**Documentação:** Nenhum localizado neste recorte.

**Histórico consultado:** Nenhum localizado neste recorte.

**Implementado:** Não implementado no Godot.

**Faltante / não comprovado:** Combate, fala, flag MachGunStatus, destrancamento de porta e refém ausentes.

**Notas de evidência:** MachGunStatus bit 0 = morto, bit 1 = fala feita.


<a id="progression-boss-hind-d"></a>
### Destruição de Hind-D no telhado do Edifício 1

`progression-boss-hind-d` · **NOT_STARTED**

**Original:** Destruição do helicóptero Hind-D na sala 63 (telhado do Edifício 1) via lançador de mísseis teleguiados (logic/actors/hindd.asm:9, 16). Ao ser abatido, seta BossHindD_KO = 1, eliminando o hazard de metralhadora contínua e liberando o tráfego seguro pelo telhado até a borda de salto.

**Classificação:** Chefe e evento de progressão não iniciados.

**Assembly:** logic/actors/hindd.asm:8-25

**Extractors:** Nenhum localizado neste recorte.

**Dados canônicos locais:** Nenhum localizado neste recorte.

**Godot relacionado:** Nenhum localizado neste recorte.

**Integração inspecionada:** Nenhum localizado neste recorte.

**Testes existentes:** Nenhum localizado neste recorte.

**Documentação:** Nenhum localizado neste recorte.

**Histórico consultado:** Nenhum localizado neste recorte.

**Implementado:** Não implementado no Godot.

**Faltante / não comprovado:** Ator do helicóptero, colisão de míssil, flag BossHindD_KO e liberação do telhado ausentes.

**Notas de evidência:** BossHindD_KO elimina o helicóptero nas visitas subsequentes.


<a id="progression-roof-parachute-jump"></a>
### Salto de paraquedas do telhado para o pátio vs queda mortal

`progression-roof-parachute-jump` · **NOT_STARTED**

**Original:** Salto pela borda sul do telhado (sala 63/241) avaliado por ChkParachute (logic/nextroom.asm:204-260). Se SelectedItem == SELECTED_PARACHUTE: Snake abre o paraquedas, cai pela sala 204 por 2 andares (HeightParachuteCnt = 2) e pousa vivo no pátio exterior (sala 10 / Yard), cancelando o alerta. Se não equipado: FreeFall (logic/nextroom.asm:227-238) derruba Snake sem paraquedas, aplicando dano letal imediato (DecrementLife_B com 0FFh) com aterrissagem morto e Game Over.

**Classificação:** Evento mandatório de progressão entre o Edifício 1 e o pátio não iniciado.

**Assembly:** logic/nextroom.asm:204-260 ChkParachute; Banks0123.asm:8564-8575 ParachuteLogic

**Extractors:** Nenhum localizado neste recorte.

**Dados canônicos locais:** Nenhum localizado neste recorte.

**Godot relacionado:** Nenhum localizado neste recorte.

**Integração inspecionada:** Nenhum localizado neste recorte.

**Testes existentes:** Nenhum localizado neste recorte.

**Documentação:** Nenhum localizado neste recorte.

**Histórico consultado:** Nenhum localizado neste recorte.

**Implementado:** O item paraquedas foi inventariado em weapons-items, mas a mecânica de salto, verificação de equipamento e queda livre mortal não existem no Godot.

**Faltante / não comprovado:** Rotinas ChkParachute, FreeFall, contagem HeightParachuteCnt e pouso na sala 10 não implementadas.

**Notas de evidência:** SelectedItem == SELECTED_PARACHUTE é a única condição que evita morte imediata na saída do telhado.


<a id="progression-desert-crossing-compass"></a>
### Travessia do labirinto do deserto e exigência da bússola

`progression-desert-crossing-compass` · **NOT_STARTED**

**Original:** Travessia das salas de deserto entre o Edifício 1 e o Edifício 2 (salas 64-68). Se Snake não estiver com a bússola (COMPASS) no inventário, a transição entre telas entra em loop infinito retornando para a mesma sala ou desviando a rota. Com a bússola no inventário, a navegação direcional é normalizada, permitindo alcançar o campo minado e o Tanque.

**Classificação:** Bloqueio geográfico de progressão não iniciado.

**Assembly:** logic/nextroom.asm:410-435; constants/Enums.asm:102

**Extractors:** Nenhum localizado neste recorte.

**Dados canônicos locais:** Nenhum localizado neste recorte.

**Godot relacionado:** Nenhum localizado neste recorte.

**Integração inspecionada:** Nenhum localizado neste recorte.

**Testes existentes:** Nenhum localizado neste recorte.

**Documentação:** Nenhum localizado neste recorte.

**Histórico consultado:** Nenhum localizado neste recorte.

**Implementado:** Não implementado no Godot.

**Faltante / não comprovado:** Lógica de desvio/loop de deserto sem bússola e normalização com bússola ausentes.

**Notas de evidência:** Exige ITEM_COMPASS no inventário para atravessar o deserto.


<a id="progression-boss-tank"></a>
### Derrota do Tanque no deserto e abertura do caminho para o Edifício 2

`progression-boss-tank` · **NOT_STARTED**

**Original:** Combate contra o Tanque na sala 69 (deserto) bloqueando o avanço norte (logic/actors/tank.asm:8, 26, 238). O Tanque é imune a armas convencionais e deve ser destruído com minas terrestres (LAND_MINE). Ao ser eliminado, seta BossTank_KO = 1, desobstruindo a passagem de areia para a entrada do Edifício 2 (sala 73).

**Classificação:** Boss de transição entre edifícios não iniciado.

**Assembly:** logic/actors/tank.asm:8-35; logic/actors/tank.asm:235-243

**Extractors:** Nenhum localizado neste recorte.

**Dados canônicos locais:** Nenhum localizado neste recorte.

**Godot relacionado:** Nenhum localizado neste recorte.

**Integração inspecionada:** Nenhum localizado neste recorte.

**Testes existentes:** Nenhum localizado neste recorte.

**Documentação:** Nenhum localizado neste recorte.

**Histórico consultado:** Nenhum localizado neste recorte.

**Implementado:** Não implementado no Godot.

**Faltante / não comprovado:** Ator do Tanque, canhão, dano por minas, flag BossTank_KO e desobstrução da rota ausentes.

**Notas de evidência:** BossTank_KO = 1 libera o avanço para a porta do segundo prédio.


<a id="progression-building2-entrance-door"></a>
### Abertura da porta trancada de entrada do Edifício 2 pelos guardas

`progression-building2-entrance-door` · **NOT_STARTED**

**Original:** A porta 14 entre o deserto (sala 69) e o Edifício 2 (sala 73) está trancada por dentro (logic/doors/opendoor.asm:215-236, ChkDesertDoorBuild2_). Ao se aproximar com uniforme ou acionar a segurança do deserto (logic/actors/desertsecurity.asm:114-134), os guardas dizem 'COME IN...' (Text 127) e abrem a porta (DoorBuild2LockedF = 1). Ao Snake entrar na sala 73, a porta tranca de novo atrás dele (DoorBuild2LockedF = 0).

**Classificação:** Evento obrigatório de acesso ao segundo prédio não iniciado.

**Assembly:** logic/doors/opendoor.asm:215-236 ChkDesertDoorBuild2_; logic/actors/desertsecurity.asm:114-134 DesertSecurity3

**Extractors:** Nenhum localizado neste recorte.

**Dados canônicos locais:** Nenhum localizado neste recorte.

**Godot relacionado:** Nenhum localizado neste recorte.

**Integração inspecionada:** Nenhum localizado neste recorte.

**Testes existentes:** Nenhum localizado neste recorte.

**Documentação:** Nenhum localizado neste recorte.

**Histórico consultado:** Nenhum localizado neste recorte.

**Implementado:** Não implementado no Godot.

**Faltante / não comprovado:** Atores desertsecurity, rotina ChkDesertDoorBuild2_, flag DoorBuild2LockedF e ciclo de tranca imediata pós-entrada ausentes.

**Notas de evidência:** DoorBuild2LockedF fecha imediatamente após Snake cruzar a porta.


<a id="progression-antenna-requirement"></a>
### Requisito da Antena equipada para comunicação no Edifício 2

`progression-antenna-requirement` · **NOT_STARTED**

**Original:** Em todas as salas do Edifício 2 e além (MapZone >= 5, Variables.asm:129), ChkRadioReply (Banks0123.asm:11043-11055) verifica se Snake está com a Antena equipada (SelectedItem == SELECTED_ANTENNA). Se não estiver, todas as frequências recebem estática e falham. Sem a antena, o jogador fica impossibilitado de contatar Jennifer ou receber instruções vitais.

**Classificação:** Bloqueio de comunicação essencial da segunda metade da campanha não iniciado.

**Assembly:** Banks0123.asm:11043-11055 ChkRadioReply; Variables.asm:129

**Extractors:** Nenhum localizado neste recorte.

**Dados canônicos locais:** Nenhum localizado neste recorte.

**Godot relacionado:** Nenhum localizado neste recorte.

**Integração inspecionada:** Nenhum localizado neste recorte.

**Testes existentes:** Nenhum localizado neste recorte.

**Documentação:** Nenhum localizado neste recorte.

**Histórico consultado:** Nenhum localizado neste recorte.

**Implementado:** O item antena existe no catálogo de itens, mas a checagem no transceptor não está implementada.

**Faltante / não comprovado:** Validação de MapZone >= 5 e exigência de SelectedItem == SELECTED_ANTENNA no rádio não implementadas.

**Notas de evidência:** MapZone >= 5 bloqueia todo o rádio sem antena.


<a id="progression-boss-bulldozer"></a>
### Derrota do Bulldozer no Edifício 2 e liberação do corredor

`progression-boss-bulldozer` · **NOT_STARTED**

**Original:** Combate contra o Bulldozer na sala 88 (Edifício 2) (logic/actors/bulldozer.asm:95-122). Trator esmagador que avança no corredor estreito; vulnerável apenas a granadas (GRENADE_LAUNCHER). Ao ser destruído, seta Bulldozer_KO = 1, liberando permanentemente o acesso ao elevador oeste do Edifício 2.

**Classificação:** Chefe e consequência de avanço no Edifício 2 não iniciados.

**Assembly:** logic/actors/bulldozer.asm:95-122

**Extractors:** Nenhum localizado neste recorte.

**Dados canônicos locais:** Nenhum localizado neste recorte.

**Godot relacionado:** Nenhum localizado neste recorte.

**Integração inspecionada:** Nenhum localizado neste recorte.

**Testes existentes:** Nenhum localizado neste recorte.

**Documentação:** Nenhum localizado neste recorte.

**Histórico consultado:** Nenhum localizado neste recorte.

**Implementado:** Não implementado no Godot.

**Faltante / não comprovado:** Ator do Bulldozer, colisão frontal letal, dano por granada, flag Bulldozer_KO e desobstrução de corredor ausentes.

**Notas de evidência:** Bulldozer_KO = 1 limpa o corredor para o elevador da sala 88.


<a id="progression-jennifer-compass-door"></a>
### Abertura remota da porta da bússola por Jennifer via rádio

`progression-jennifer-compass-door` · **NOT_STARTED**

**Original:** Desbloqueio da porta da sala 87 (Edifício 2, 2º andar) onde está guardada a bússola (logic/doors/opendoor.asm:245-256, ChkCompassDoor). Snake contata Jennifer (120.48) com Rank ★4; ao término do diálogo (Text 118, TextBoxExit em Banks0123.asm:8301-8324), seta JeniOpenDoorF = 1. A porta da sala 87 destranca, permitindo pegar a COMPASS.

**Classificação:** Evento essencial para obtenção da bússola não iniciado.

**Assembly:** Banks0123.asm:8301-8324 TextBoxExit; logic/doors/opendoor.asm:245-256 ChkCompassDoor

**Extractors:** Nenhum localizado neste recorte.

**Dados canônicos locais:** Nenhum localizado neste recorte.

**Godot relacionado:** Nenhum localizado neste recorte.

**Integração inspecionada:** Nenhum localizado neste recorte.

**Testes existentes:** Nenhum localizado neste recorte.

**Documentação:** Nenhum localizado neste recorte.

**Histórico consultado:** Nenhum localizado neste recorte.

**Implementado:** Não implementado no Godot.

**Faltante / não comprovado:** Trigger TextBoxExit para Text 118, flag JeniOpenDoorF e rotina ChkCompassDoor não existem no Godot.

**Notas de evidência:** JeniOpenDoorF = 1 abre porta 87 sem necessidade de cartão de chave.


<a id="progression-jennifer-rocket-launcher"></a>
### Concessão do lançador de foguetes por Jennifer

`progression-jennifer-rocket-launcher` · **NOT_STARTED**

**Original:** Provisão do lançador de foguetes (ROCKET_LAUNCHER) via suporte de Jennifer (Banks0123.asm:8301-8324, JeniRocketF). Após Snake resgatar o irmão de Jennifer e contatá-la com Rank ★4, Jennifer combina de arranjar a arma (Text 117). O fechamento do diálogo seta JeniRocketF = 1, fazendo o item aparecer na sala de suprimentos. Sem o foguete, os chefes Arnolds são invencíveis, gerando softlock de combate.

**Classificação:** Progressão original concedia o item por evento narrativo condicional; concessão direta no Godot ignora o fluxo do Z80.

**Assembly:** Banks0123.asm:8301-8324 TextBoxExit

**Extractors:** Nenhum localizado neste recorte.

**Dados canônicos locais:** Nenhum localizado neste recorte.

**Godot relacionado:** Nenhum localizado neste recorte.

**Integração inspecionada:** Nenhum localizado neste recorte.

**Testes existentes:** Nenhum localizado neste recorte.

**Documentação:** Nenhum localizado neste recorte.

**Histórico consultado:** Nenhum localizado neste recorte.

**Implementado:** O item lançador de foguetes foi adicionado ao inventário do sandbox de forma estática, mas a cadeia de evento via rádio e flag JeniRocketF não existe.

**Faltante / não comprovado:** Flag JeniRocketF, trigger em TextBoxExit e spawn condicional da arma ausentes.

**Notas de evidência:** JeniRocketF é acionado por Text 117 em TextBoxExit.


<a id="progression-boss-firetrooper"></a>
### Derrota de Fire Trooper no subsolo do Edifício 2

`progression-boss-firetrooper` · **NOT_STARTED**

**Original:** Derrota de Fire Trooper na sala 95 (subsolo do Edifício 2) (logic/actors/firetropper.asm:549, Banks0123.asm:12986). Boss armado com lança-chamas; vulnerável a tiros por trás. Ao ser eliminado, seta FireTrooper_KO = 1, liberando o acesso ao elevador que leva às celas de Ellen e Dr. Madnar.

**Classificação:** Chefe e evento de avanço no subsolo não iniciados.

**Assembly:** logic/actors/firetropper.asm:545-555; Banks0123.asm:12986

**Extractors:** Nenhum localizado neste recorte.

**Dados canônicos locais:** Nenhum localizado neste recorte.

**Godot relacionado:** Nenhum localizado neste recorte.

**Integração inspecionada:** Nenhum localizado neste recorte.

**Testes existentes:** Nenhum localizado neste recorte.

**Documentação:** Nenhum localizado neste recorte.

**Histórico consultado:** Nenhum localizado neste recorte.

**Implementado:** Não implementado no Godot.

**Faltante / não comprovado:** Ator de Fire Trooper, IA de labaredas, flag FireTrooper_KO e desbloqueio de elevador ausentes.

**Notas de evidência:** FireTrooper_KO = 1 desativa o chefe e labaredas no subsolo.


<a id="progression-ellen-rescue"></a>
### Resgate de Ellen e pré-requisito de cooperação de Madnar

`progression-ellen-rescue` · **NOT_STARTED**

**Original:** Resgate de Ellen (filha sequestrada de Dr. Madnar) na cela do subsolo do Edifício 2 (logic/actors/prisoner.asm:152-170, RescuedArray[20]). Condição estrita de progressão da campanha: se Snake falar com Dr. Madnar antes de salvar Ellen, Madnar recusa-se a cooperar. Resgatar Ellen seta RescuedArray[20] = 1, desbloqueando a cooperação de Madnar.

**Classificação:** Pré-requisito narrativo e mecânico mandatório de campanha não iniciado.

**Assembly:** logic/actors/prisoner.asm:152-170

**Extractors:** Nenhum localizado neste recorte.

**Dados canônicos locais:** Nenhum localizado neste recorte.

**Godot relacionado:** Nenhum localizado neste recorte.

**Integração inspecionada:** Nenhum localizado neste recorte.

**Testes existentes:** Nenhum localizado neste recorte.

**Documentação:** Nenhum localizado neste recorte.

**Histórico consultado:** Nenhum localizado neste recorte.

**Implementado:** Não implementado no Godot.

**Faltante / não comprovado:** Refém Ellen, verificação condicional no diálogo de Madnar e flag RescuedArray[20] ausentes.

**Notas de evidência:** RescuedArray[20] é checado por Madnar antes de falar do Metal Gear.


<a id="progression-madnar-rescue-formula"></a>
### Resgate de Dr. Madnar e revelação da fórmula de destruição do Metal Gear

`progression-madnar-rescue-formula` · **NOT_STARTED**

**Original:** Resgate do verdadeiro Dr. Pettrovich Madnar no subsolo do Edifício 2 após libertar Ellen (logic/actors/prisoner.asm:296-317, RescuedArray[21]). Madnar revela a sequência exata de 16 explosivos C4 necessários para destruir as pernas do Metal Gear (R, R, L, R, L, L, R, L, L, R, R, L, R, L, R, R). Seta RescuedArray[21] = 1.

**Classificação:** Evento chave de resolução da missão não iniciado.

**Assembly:** logic/actors/prisoner.asm:296-317

**Extractors:** Nenhum localizado neste recorte.

**Dados canônicos locais:** Nenhum localizado neste recorte.

**Godot relacionado:** Nenhum localizado neste recorte.

**Integração inspecionada:** Nenhum localizado neste recorte.

**Testes existentes:** Nenhum localizado neste recorte.

**Documentação:** Nenhum localizado neste recorte.

**Histórico consultado:** Nenhum localizado neste recorte.

**Implementado:** Não implementado no Godot.

**Faltante / não comprovado:** Entidade de Madnar, validação da flag de Ellen e revelação da sequência de C4 ausentes.

**Notas de evidência:** Sem Ellen salva, Madnar não entrega a sequência de 16 C4.


<a id="progression-fake-madnar-trap"></a>
### Armadilha do Falso Madnar e acionamento de alçapão

`progression-fake-madnar-trap` · **PROVISIONAL**

**Original:** Armadilha na sala 107 (Edifício 2) com impostor disfarçado de Dr. Madnar (logic/actors/prisoner.asm:180-210, data/texts.asm:90). Ao interagir, o impostor revela a farsa ('FOOLED YOU! I'M NOT MADNAR!') e um alçapão (pitfall) abre imediatamente sob Snake, derrubando-o para o subsolo.

**Classificação:** O evento possui apenas representação textual/provisória sem a consequência espacial do Z80.

**Assembly:** logic/actors/prisoner.asm:180-210

**Extractors:** Nenhum localizado neste recorte.

**Dados canônicos locais:** Nenhum localizado neste recorte.

**Godot relacionado:** Nenhum localizado neste recorte.

**Integração inspecionada:** Nenhum localizado neste recorte.

**Testes existentes:** Nenhum localizado neste recorte.

**Documentação:** Nenhum localizado neste recorte.

**Histórico consultado:** Nenhum localizado neste recorte.

**Implementado:** Diálogo do impostor catalogado em radio-dialogue, com mocks parciais.

**Faltante / não comprovado:** A consequência física de progressão (abertura imediata de alçapão com queda forçada para a sala do subsolo) não está implementada no Godot.

**Notas de evidência:** O alçapão abre sob os pés de Snake forçando queda de andar.


<a id="progression-madnar-moved-event"></a>
### Evento da cela vazia na Sala 133 ('Madnar foi transferido')

`progression-madnar-moved-event` · **NOT_STARTED**

**Original:** Ao entrar na sala 133 (primeira cela onde Madnar supostamente estaria), ChkMadnarMsx (logic/madnarbigbossevent.asm:7-22, 40-55) detecta o evento se MadnarMoved == 0. Entra em modo GAME_MODE_MADNAR_MOVED (0x0C), exibe 'IT'S TOO LATE! DR. PETROVICH HAS BEEN MOVED' (Text 89) e seta MadnarMoved = 1, impedindo reativação.

**Classificação:** Ponto de virada narrativo do Edifício 1 para o Edifício 2 não iniciado.

**Assembly:** logic/madnarbigbossevent.asm:7-22 ChkMadnarMsx; logic/madnarbigbossevent.asm:40-55 chkMadnarLate

**Extractors:** Nenhum localizado neste recorte.

**Dados canônicos locais:** Nenhum localizado neste recorte.

**Godot relacionado:** Nenhum localizado neste recorte.

**Integração inspecionada:** Nenhum localizado neste recorte.

**Testes existentes:** Nenhum localizado neste recorte.

**Documentação:** Nenhum localizado neste recorte.

**Histórico consultado:** Nenhum localizado neste recorte.

**Implementado:** Não implementado no Godot.

**Faltante / não comprovado:** Modo de jogo 0x0C, trigger da sala 133 e flag MadnarMoved ausentes.

**Notas de evidência:** MadnarMoved = 1 impede reexecução da mensagem ao reentrar na sala 133.


<a id="progression-schneider-captured-event"></a>
### Evento de captura de Schneider durante transmissão de rádio

`progression-schneider-captured-event` · **NOT_STARTED**

**Original:** Em sala avançada do complexo, Schneider chama Snake no rádio revelando ter descoberto a identidade do chefe de Outer Heaven ('THIS IS MR. SCHNEIDER... I HAVE DISCOVERED WHO THE BOSS OF OUTER HEAVEN IS... OH NO!'). Ao término do diálogo (Text 138, TextBoxExit em Banks0123.asm:8301-8324), seta SchneiderCaptured = 1. A partir deste evento, Schneider nunca mais responde no rádio (retorna apenas estática).

**Classificação:** Evento dramático e alteração permanente de disponibilidade de rádio não iniciados.

**Assembly:** Banks0123.asm:8301-8324 TextBoxExit; Banks0123.asm:11115-11130 ChkReplySchneider

**Extractors:** Nenhum localizado neste recorte.

**Dados canônicos locais:** Nenhum localizado neste recorte.

**Godot relacionado:** Nenhum localizado neste recorte.

**Integração inspecionada:** Nenhum localizado neste recorte.

**Testes existentes:** Nenhum localizado neste recorte.

**Documentação:** Nenhum localizado neste recorte.

**Histórico consultado:** Nenhum localizado neste recorte.

**Implementado:** Não implementado no Godot.

**Faltante / não comprovado:** Despacho de rádio da mensagem 138, trigger em TextBoxExit e flag SchneiderCaptured silenciando o rádio ausentes.

**Notas de evidência:** SchneiderCaptured = 1 zera futuras respostas em 120.79.


<a id="progression-water-channel-oxygen"></a>
### Travessia do canal de água e exigência do tanque de oxigênio

`progression-water-channel-oxygen` · **NOT_STARTED**

**Original:** Travessia subaquática entre o Edifício 2 e o Edifício 3 pelas salas do canal (salas 105, 110, 211, 212 na ROM, logic/nextroom.asm). Se Snake entrar no canal sem o tanque de oxigênio equipado (SelectedItem != SELECTED_OXYGEN_TANK), a barra de vida é esvaziada em alta velocidade por asfixia/afogamento, levando à morte em poucos segundos. Com o tanque equipado, o nado ocorre normalmente.

**Classificação:** Bloqueio fatal de progressão para o Edifício 3 não iniciado, com risco grave de softlock/conflito de salas.

**Assembly:** logic/nextroom.asm:250-280; constants/Enums.asm:103

**Extractors:** Nenhum localizado neste recorte.

**Dados canônicos locais:** Nenhum localizado neste recorte.

**Godot relacionado:** Nenhum localizado neste recorte.

**Integração inspecionada:** Nenhum localizado neste recorte.

**Testes existentes:** Nenhum localizado neste recorte.

**Documentação:** docs/index/rooms.md

**Histórico consultado:** Nenhum localizado neste recorte.

**Implementado:** Não implementado no Godot. Além disso, existe conflito documentado em rooms.md: as salas 211 e 212 do canal colidem com os aliases da prisão adotados no laboratório.

**Faltante / não comprovado:** Dano por falta de oxigênio, mecânica do canal e resolução do conflito de IDs de sala 211/212 não implementados.

**Notas de evidência:** Conflito de ID de sala 211/212 precisa ser resolvido antes de implementar o canal.


<a id="progression-boss-arnolds-card7"></a>
### Derrota dos ciborgues Arnolds na Sala 104 e obtenção do Cartão 7

`progression-boss-arnolds-card7` · **NOT_STARTED**

**Original:** Combate na sala 104 (Edifício 3) contra a dupla de ciborgues Bloody Brad / Arnolds (Banks0123.asm:6112, 12950, ArnoldsCnt). Os chefes são completamente imunes a armas normais e só sofrem dano com foguetes (ROCKET_LAUNCHER). Ao derrotar os dois (ArnoldsCnt = 2), o Cartão 7 (CARD_7) surge no chão da sala. O Cartão 7 é mandatório para abrir as portas finais rumo ao subsolo do Metal Gear.

**Classificação:** Boss mandatório e entrega da chave mestra do Edifício 3 não iniciados.

**Assembly:** Banks0123.asm:6112; Banks0123.asm:12950

**Extractors:** Nenhum localizado neste recorte.

**Dados canônicos locais:** Nenhum localizado neste recorte.

**Godot relacionado:** Nenhum localizado neste recorte.

**Integração inspecionada:** Nenhum localizado neste recorte.

**Testes existentes:** Nenhum localizado neste recorte.

**Documentação:** Nenhum localizado neste recorte.

**Histórico consultado:** Nenhum localizado neste recorte.

**Implementado:** Não implementado no Godot.

**Faltante / não comprovado:** Atores dos ciborgues, imunidade balística, contador ArnoldsCnt e spawn do Cartão 7 ausentes.

**Notas de evidência:** CARD_7 é gerado no chão somente após eliminar ambos os ciborgues.


<a id="progression-bigboss-betrayal-switchoff"></a>
### Traição de Big Boss na Sala 111 e ordem para desligar o MSX

`progression-bigboss-betrayal-switchoff` · **NOT_STARTED**

**Original:** Ao adentrar a sala 111 (subsolo do Edifício 3), ChkSwitchMsxOff (logic/madnarbigbossevent.asm:27-35) detecta a sala e seta SwitchOffMSXF = 1. No rádio, Big Boss entra em desespero ordenando abortar a missão imediatamente e desligar o console ('SNAKE! ABORT MISSION! SWITCH OFF THE MSX AT ONCE!'). Marca a ruptura explícita e definitiva de Big Boss antes da sala do Metal Gear.

**Classificação:** Evento chave de clímax da narrativa não iniciado.

**Assembly:** logic/madnarbigbossevent.asm:27-35 ChkSwitchMsxOff

**Extractors:** Nenhum localizado neste recorte.

**Dados canônicos locais:** Nenhum localizado neste recorte.

**Godot relacionado:** Nenhum localizado neste recorte.

**Integração inspecionada:** Nenhum localizado neste recorte.

**Testes existentes:** Nenhum localizado neste recorte.

**Documentação:** Nenhum localizado neste recorte.

**Histórico consultado:** Nenhum localizado neste recorte.

**Implementado:** Não implementado no Godot.

**Faltante / não comprovado:** Trigger da sala 111, flag SwitchOffMSXF e diálogo especial no rádio ausentes.

**Notas de evidência:** SwitchOffMSXF altera todas as transmissões de Big Boss para pânico/sabotagem.


<a id="progression-metalgear-destruction"></a>
### Destruição do Metal Gear com 16 C4 e ativação da autodestruição

`progression-metalgear-destruction` · **NOT_STARTED**

**Original:** Destruição do robô bípede Metal Gear na sala 118 (Banks0123.asm:11998, 12304, 12309, logic/destructiontimer.asm:10-39). Snake deve plantar 16 explosivos plásticos C4 nas pernas em sequência estrita alternada (R, R, L, R...). Errar a ordem detona C4 com dano em Snake. Ao plantar o 16º C4: MetalGear_KO = 1; alarme de emergência contínuo (RedAlertFlag = 1); abre a porta norte para o confronto final com Big Boss (OpenBigBossDoor = 1); ativa contagem de autodestruição (DestructionTimerOn = 1, DestructTimer = 0C8h); bloqueia novos checkpoints em ChkSaveGameStatus.

**Classificação:** Objetivo principal da missão e gatilho do clímax não iniciados.

**Assembly:** Banks0123.asm:11998; Banks0123.asm:12304-12315; logic/destructiontimer.asm:10-39 DecNukeTimer

**Extractors:** Nenhum localizado neste recorte.

**Dados canônicos locais:** Nenhum localizado neste recorte.

**Godot relacionado:** Nenhum localizado neste recorte.

**Integração inspecionada:** Nenhum localizado neste recorte.

**Testes existentes:** Nenhum localizado neste recorte.

**Documentação:** Nenhum localizado neste recorte.

**Histórico consultado:** Nenhum localizado neste recorte.

**Implementado:** Não implementado no Godot.

**Faltante / não comprovado:** Ator do Metal Gear, máquina de estados dos 16 C4, flag MetalGear_KO, contagem regressiva e portas ausentes.

**Notas de evidência:** Sequência de 16 C4 é mandatória; erro detona o explosivo e causa dano em Snake.


<a id="progression-boss-bigboss-final"></a>
### Confronto final com Big Boss na Sala 119 e abertura da escada de fuga

`progression-boss-bigboss-final` · **NOT_STARTED**

**Original:** Batalha final contra Big Boss na sala 119 (logic/actors/bigboss.asm:8-55, Banks0123.asm:12935, BigBossStat). Big Boss confessa a liderança de Outer Heaven; combate com tiros sob a contagem regressiva do timer de autodestruição. Ao ser derrotado: BigBossStat = 0; a porta para a escada de escape da base é destrancada (OpenBigBossDoor = 1 em logic/doors/opendoor.asm:265-275, ChkBigBossDoor).

**Classificação:** Duelo final de encerramento de gameplay não iniciado.

**Assembly:** logic/actors/bigboss.asm:8-55; Banks0123.asm:12935; logic/doors/opendoor.asm:265-275 ChkBigBossDoor

**Extractors:** Nenhum localizado neste recorte.

**Dados canônicos locais:** Nenhum localizado neste recorte.

**Godot relacionado:** Nenhum localizado neste recorte.

**Integração inspecionada:** Nenhum localizado neste recorte.

**Testes existentes:** Nenhum localizado neste recorte.

**Documentação:** Nenhum localizado neste recorte.

**Histórico consultado:** Nenhum localizado neste recorte.

**Implementado:** Não implementado no Godot.

**Faltante / não comprovado:** Ator de Big Boss, diálogo de confissão, flag BigBossStat e destrancamento da porta de escape ausentes.

**Notas de evidência:** BigBossStat = 0 libera a porta 265 para a escada final.


<a id="progression-escape-ending"></a>
### Fuga pela escada de escape, evasão de Outer Heaven e créditos finais

`progression-escape-ending` · **NOT_STARTED**

**Original:** Subida da escada antes do timer de autodestruição zerar (logic/ending.asm:7-60). Ao alcançar o topo: seta LeavedOuterHeaven = 1 e carrega a cena de encerramento na sala 251. Snake corre pela floresta, a base Outer Heaven explode ao fundo, helicóptero resgata Snake, relatório final de notícias no rádio e mensagem pós-créditos de Big Boss prometendo retorno.

**Classificação:** Conclusão definitiva da campanha não iniciada.

**Assembly:** logic/ending.asm:7-33 EndingSetup; Variables.asm:74

**Extractors:** Nenhum localizado neste recorte.

**Dados canônicos locais:** Nenhum localizado neste recorte.

**Godot relacionado:** Nenhum localizado neste recorte.

**Integração inspecionada:** Nenhum localizado neste recorte.

**Testes existentes:** Nenhum localizado neste recorte.

**Documentação:** Nenhum localizado neste recorte.

**Histórico consultado:** Nenhum localizado neste recorte.

**Implementado:** Não implementado no Godot.

**Faltante / não comprovado:** Escada de escape, validação de tempo, cena 251 e sequência completa de encerramento ausentes.

**Notas de evidência:** LeavedOuterHeaven = 1 conclui o jogo e dispara a sequência de créditos.


<a id="progression-moving-lorries-transport"></a>
### Rede de caminhões móveis e transporte entre setores (Moving Lorries)

`progression-moving-lorries-transport` · **PARTIAL**

**Original:** Mecânica de transporte e armadilha em caminhões móveis (logic/lorry.asm:7-105, ChkLorryMov). Lista de 6 salas de caminhão que se movem: 199, 217, 219, 213, 215, 173 (MovingLorries). Ao entrar, entra em GAME_MODE_LORRY (0x05), Snake exibe 'I GOOFED. THE LORRY STARTED TO MOVE' (Text 91), SFX 1Fh de motor, tremor vertical de tela por scroll e transporte para outro setor da base.

**Classificação:** Transições de caminhão existem como portas normais de salas de itens, mas o sistema de caminhões móveis em trânsito não está implementado.

**Assembly:** logic/lorry.asm:7-24 ChkLorryMov; logic/lorry.asm:34-54 LorryMoving

**Extractors:** Nenhum localizado neste recorte.

**Dados canônicos locais:** Nenhum localizado neste recorte.

**Godot relacionado:** godot/scripts/scenes/sandbox_gameplay.gd

**Integração inspecionada:** godot/scripts/scenes/sandbox_gameplay.gd::_spawn_room_doors

**Testes existentes:** godot-doors-inventory

**Documentação:** Nenhum localizado neste recorte.

**Histórico consultado:** docs/progress/2026-09.md::2026-09-21 — Eliminação de Triggers Radiais Espúrios, Arquitetura de Caminhões Móveis (Moving Lorries) e Pareamento Universal

**Implementado:** O Godot implementa pares de portas de caminhões interiores e transições fixas para salas de baú (salas 128, 130, 131, 132) em sandbox_gameplay.gd.

**Faltante / não comprovado:** As 6 salas originais de caminhões móveis da ROM (MovingLorries), o modo de jogo 0x05, mensagem de erro de Snake e o deslocamento dinâmico de setor não estão reproduzidos.

**Notas de evidência:** MovingLorries define as salas que transportam o jogador dinamicamente.


<a id="progression-building-transitions"></a>
### Cadeia global de transição entre edifícios (Edifício 1 -> 2 -> 3)

`progression-building-transitions` · **NOT_STARTED**

**Original:** Sequenciamento macro de progressão exigido para um playthrough completo: Edifício 1 (infiltração, Shoot Gunner, captura, fuga com Grey Fox, resgate de reféns, Machine Gun Kid, Hind-D, salto de paraquedas para o pátio) -> Deserto 1 (Bússola, campo minado, destruição do Tanque, entrada no Edifício 2) -> Edifício 2 (Antena, Bulldozer, subsolo, Fire Trooper, resgate de Ellen, resgate de Madnar e fórmula do C4) -> Canal de Água (tanque de oxigênio) -> Deserto 2 -> Edifício 3 (Arnolds e Cartão 7, sala 111 traição de Big Boss, sala 118 destruição do Metal Gear, sala 119 confronto com Big Boss, escada de fuga e encerramento).

**Classificação:** O projeto atualmente é um sandbox de salas e subsistemas focados no Edifício 1; a progressão global da campanha do início ao fim não foi iniciada.

**Assembly:** Banks0123.asm:889-918 GetNextRoomNum; data/roomsconnections.asm:1-162

**Extractors:** Nenhum localizado neste recorte.

**Dados canônicos locais:** Nenhum localizado neste recorte.

**Godot relacionado:** godot/scripts/systems/room_manager.gd; godot/scripts/scenes/sandbox_gameplay.gd

**Integração inspecionada:** Nenhum localizado neste recorte.

**Testes existentes:** Nenhum localizado neste recorte.

**Documentação:** docs/index/rooms.md

**Histórico consultado:** Nenhum localizado neste recorte.

**Implementado:** Não existe progressão macro unificada no Godot; o sandbox permite carregar salas avulsas via room_manager, mas o fluxo de transição entre edifícios é impossível de completar de ponta a ponta.

**Faltante / não comprovado:** A campanha inteira além de partes do Edifício 1 é inalcançável em gameplay contínuo; ausência de conexões de mundo, itens condicionais e bosses intermediários.

**Notas de evidência:** Edifícios 2 e 3 estão fora do loop jogável contínuo no Godot.
