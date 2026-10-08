# Progresso

Somente as entradas mais recentes. Histórico completo, sem edição, em `docs/progress/`;
índice com arquivo e linha em `docs/progress/INDEX.md`. Rotação: `python3 -m tools.context.build_index`.

## 2026-10-05 — Inventário progressivo: topologia de salas, conexões espaciais e navegação

**Feito:** inventário Z80 da edição inglesa antes de qualquer alteração no Godot, dados ou testes.
10 features em `world-rooms-navigation`: PARTIAL 6 (`world-room-identity-mapping`, `world-cardinal-connections`, `world-entry-coordinates`, `world-buildings-zones`, `world-elevator-topology`, `world-desert-navigation`), NOT_STARTED 4 (`world-lorry-navigation`, `world-parachute-courtyard-204`, `world-water-channel-topology`, `world-escape-ladder-topology`); IMPLEMENTED 0, PROVISIONAL 0, UNMAPPED 0, INVESTIGATING 0.
Evidência: `data/rooms.asm:7-267`, `data/roomsconnections.asm:7-162`, `logic/nextroom.asm:11-285`, `data/musicradioconfig.asm:58-74`, `data/elevatorrooms.asm:6-93`, `logic/lorry.asm:7-105`, `data/doors.asm:724-728`, `logic/capturescene.asm:87-118`.
Divergências registradas: salas 211/212 mascaradas por `local-aliases/` no Godot (aliases da cela 165 e sala de equipamento 164 com saídas bloqueadas, em vez do canal de água que conecta Prédio 2 ao Prédio 3); sala 204 tratada como "o limbo" e bloqueada no Godot em vez da descida de paraquedas para os pátios 5/6/10; caminhões com trânsito dinâmico não implementados; loop do deserto (sala 103) contornado no Godot sem checagem de Compass; comando `lookup room` adicionado a `tools/context/lookup.py`. Nenhum arquivo de gameplay alterado.
**Testes:** `python3 tools/validate.py` fora do sandbox: exit 0, 38 etapas PASS, 165 testes Python; `build_index --check`: exit 0.
**Pendências:** resolução estrutural dos IDs 211/212 e implementação da navegação de caminhões, canal e paraquedas sob demanda.
**Git:** commit a pedido do usuário, sem push e sem tag; `godot/project.godot` preservado fora do commit.

## 2026-10-05 — Normalização de consistência e ownership do catálogo canônico

**Feito:** auditoria global de consistência em `docs/index/mechanics.json`. Fatos canônicos corrigidos contra a desmontagem Z80: antena por posse (`AntennaTaken != 0`), paraquedas com origem nas salas 45/46/117 e pouso nos pátios 5/6/10, canal de água profunda nas salas 105/106/211/212, vento da sala 53 empurrando para o norte (Y -= 3), Falso Madnar na cela 189 com ator 55 e Texto 109 (`txtTrap`), deserto com loop na sala 103, escadas de fuga concluindo na sala 226 com gatilho `SetLeavedOuterH`. Features legadas saneadas: `rooms` absorvido/estreitado para apontar para `world-room-identity-mapping` e conexões (com migração de 8 referências); `doors`, `game-loop`, `alert`, `hud` e `intro-title` delimitados; sobreposições de `rank-prisoners` e `elevators` estreitadas; nota histórica em `audits["radio-dialogue"]` contextualizada; dezenas de arestas bidirecionais adicionadas. Nenhum arquivo de gameplay alterado.
**Testes:** `python3 tools/validate.py`: exit 0, 38 etapas PASS, 165 testes Python; `build_index --check`: exit 0.
**Pendências:** expansão de `scenes-flow` adotando `game-loop` e `intro-title`.
**Git:** commit a pedido do usuário, sem push e sem tag; `godot/project.godot` preservado fora do commit.

## 2026-10-06 — Plano mestre de implementação e resolução de milestones

**Feito:** validação e estruturação de `docs/IMPLEMENTATION_PLAN.md` organizando os 9 milestones de transição para o port completo (Runtime canônico, Mundo canônico, Estado persistente, Infraestrutura compartilhada, Edifícios 1, 2, 3 e Fechamento de fidelidade). Todos os 121 IDs de mechanics conferidos contra `docs/index/mechanics.json`; 8 pendências de IDs resolvidas com identificadores canônicos exatos (`progression-boss-shotgunner`, `mine-detector`, `progression-boss-tank`, `progression-building2-entrance-door`, `progression-boss-bulldozer`, `progression-boss-firetrooper`, `progression-jennifer-rocket-launcher`, `progression-metalgear-destruction`). Nenhum arquivo de gameplay alterado.
**Testes:** `python3 tools/validate.py`: exit 0, 38 etapas PASS, 165 testes Python; `build_index --check`: exit 0.
**Pendências:** início da execução por CORE-001 conforme demanda.
**Git:** commit a pedido do usuário, sem push e sem tag; `godot/project.godot` preservado fora do commit.

## 2026-10-06 — CORE-001: relógio de jogo determinístico e cadência medida

**Feito:** `GameClock` é a única base temporal: `_physics_process` do sandbox = interrupção de 60 Hz,
`game_tick()` = uma iteração (`InterruptTick`/`TickInProgress`, `Banks0123.asm:440-471,10058-10060`),
`TickCounter` de 8 bits e `TICK_DELTA` fixo para os contadores portados. Sonda openMSX
`tools/emulation/tick_rate.tcl` (`C-BIOS_MSX2_EU`): R#9 = 82h, 50,1 Hz; em jogo 1 iteração a cada 2
interrupções, janela de texto a cada 1; a ROM inglesa não força frequência. Por decisão do usuário, mesma
estratégia a 60 Hz (jogo a 30 it/s). Prisioneiros, captura e CALL do HUD saíram do tempo real; intro
deriva a cadência do relógio. Ordem de `PlayModeLogic` em `architecture.md`.
**Testes:** `game_clock_test.gd` (novo, registrado no `validate.py`); `prisoner_dialog_test` usa
`game_tick()` (também room_transition, elevator_guard, room_007_patrol, doors_and_inventory e
rolling_barrel) e `capture_prison_test` usa `step_tick`. `validate.py`: exit 0, 39 etapas, 165 testes Python.
**Pendências:** máquina europeia é 50 Hz; cadência de rádio/menus/binóculos/captura não medida;
overrun variável não modelado; `RadioDialog`/typewriter em tempo real; ordem fina de `PlayModeLogic`.
**Git:** commit desta entrega na branch feature/core-001-game-clock, tag `v0.2.4`.

## 2026-10-08 — CORE-002: movimento cardinal fiel (GetPlayerDir e 8.8)

**Feito:** `PlayerControls` porta `StoreControls` (logic/controls.asm:23-30), `GetPlayerDir` com
`DirectionMask`/`DirectionMaskOld` e `IdsDirection` (Banks0123.asm:8702-8782) e `DisableControls`.
`PlayerController.step_control` aplica `ChkControlPlayer` (8825-8917): direção nova vence a mantida,
duas mantidas conservam a direção, soltar a nova volta à antiga, parada imediata. Velocidade 200h em
8.8 inteiro por tick (`MovePlayerX/Y`, 9549-9573), sem `delta`. O sandbox grava os controles no início
de cada `game_tick` e chama `GetPlayerDir` só na caminhada fora do soco.
**Testes:** `player_controls_test.gd` (novo, registrado); movimento, combate, transição e relógio
sem regressão. `validate.py`: exit 0, 40 etapas, 165 testes Python.
**Pendências:** wrap de 16 bits; `DisableControls` em
elevador/paraquedas/escada; 100h em água sem evidência (feature de água). **Git:** commit desta entrega na branch feature/core-002-player-movement, tag `v0.2.5`.
