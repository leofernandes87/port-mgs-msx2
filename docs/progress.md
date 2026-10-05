# Progresso

Somente as entradas mais recentes. Histórico completo, sem edição, em `docs/progress/`;
índice com arquivo e linha em `docs/progress/INDEX.md`. Rotação: `python3 -m tools.context.build_index`.

## 2026-10-05 — Inventário progressivo: eventos de campanha e progressão global

**Feito:** inventário Z80 da edição inglesa antes do cruzamento com Godot, extrações e testes.
33 features em `progression-events`: PARTIAL 4, PROVISIONAL 5, NOT_STARTED 24; UNMAPPED/INVESTIGATING 0.
Evidência: `logic/checkpoints.asm:10-127`, `logic/capturescene.asm:8-118`, `logic/doors/opendoor.asm:215-319`,
`logic/items.asm:295-325`, `logic/nextroom.asm:204-260`, `logic/lorry.asm:7-105`, `logic/elevatorroom.asm:7-227`,
`logic/destructiontimer.asm:10-39`, `logic/ending.asm:7-60`, `Banks0123.asm:889-918,8301-8325,9580-9653,10410-10500`.
Divergências registradas: buffer de checkpoints ausente, conflito de IDs das salas 211/212, omissão do
transmissor na bolsa, penalidade de refém sem reset de 17 prisioneiros, bosses intermediários ausentes e
inviabilidade de playthrough contínuo. Nenhum arquivo de gameplay alterado.
**Testes:** `python3 tools/validate.py` fora do sandbox: exit 0, 38 etapas PASS, 164 testes Python; `build_index --check`: exit 0.
**Pendências:** implementação da persistência e expansão dos edifícios 2 e 3 reservadas para etapas sob demanda.
**Git:** commit `e1bdddd` a pedido do usuário, sem push e sem tag; `godot/project.godot` preservado fora do commit.

## 2026-10-05 — Inventário progressivo: núcleo do jogador, física e estados de controle

**Feito:** inventário Z80 da edição inglesa antes do cruzamento com Godot, integração e testes.
17 features em `player-core`: PARTIAL 10, PROVISIONAL 3, NOT_STARTED 4; IMPLEMENTED 0, UNMAPPED/INVESTIGATING 0.
Evidência: `Banks0123.asm:5486-5515,8397-8439,8447-8512,8564-8644,8702-8760,8791-8926,8972-9008,9141-9277,9284-9325,9332-9441,9520-9573,9654-9765,9886-9928,12151-12290`, `Variables.asm:79,88-92,105,142-181`, `logic/collisions.asm:15-169`, `logic/nextroom.asm:204-480`, `logic/touchenemy.asm:8-190`, `logic/hud.asm:107-145`, `logic/damagegas.asm:36-47`, `logic/damageelectric.asm:51-61`, `logic/pitfall.asm:10-41`.
Divergências registradas: física float/delta vs aritmética 8.8 (0x0200 = 2.0 px/tick), precedência direcional sem memória Z80, dano com flash vermelho alternado por frame vs invisibilidade, sequência de morte de 128 ticks (DeadTimer = 0x80) com 3 poses antes de Game Over, ausência de knockback físico e timers de recuperação por hazard (32/16/8 ticks). Nenhum arquivo de gameplay alterado.
**Testes:** `python3 tools/validate.py` fora do sandbox: exit 0, 38 etapas PASS, 164 testes Python; `build_index --check`: exit 0.
**Pendências:** convergência de física 8.8 e sequência de morte reservadas para etapas sob demanda.
**Git:** commit a pedido do usuário, sem push e sem tag; `godot/project.godot` preservado fora do commit.

## 2026-10-05 — Inventário progressivo: hazards ambientais e lógica especial de salas

**Feito:** inventário Z80 da edição inglesa antes de qualquer alteração no Godot, dados ou testes.
14 features em `hazards-special-rooms`: PARTIAL 4 (`gas`, `electrified-floor`, `cameras-lasers`, `hazard-breakable-walls`), PROVISIONAL 1 (`hazard-environmental-palette`), NOT_STARTED 9 (`hazard-water-environment`, `hazard-pitfall-trap`, `hazard-dark-rooms`, `hazard-roof-wind`, `hazard-roof-bridge-fall`, `hazard-minefield`, `hazard-roof-freefall`, `hazard-desert-loop`, `hazard-room78-narrow-channel`), UNMAPPED 0, INVESTIGATING 0.
Evidência: `logic/damagegas.asm:9-53`, `logic/damageelectric.asm:8-63`, `data/laserconfig.asm:6-51`, `logic/laserbeams.asm:11-101`, `Banks0123.asm:9141-9277,8999-9008,9284-9325,8587-8603,2937-2974`, `logic/pitfall.asm:10-69`, `logic/actors/pitfall.asm:7-99`, `data/doors.asm:293-305,923-1085`, `logic/doors/drawdoors.asm:233-261`, `logic/doors/opendoor.asm:280-385`, `logic/bridge.asm:8-48`, `logic/actors/mine.asm:7-75`, `logic/nextroom.asm:33-48,204-260`, `powerswitch.asm:37-67`.
Divergências registradas: ausência de esteiras (conveyor belts) e correnteza em MG1 MSX2; paredes ocas e quebráveis unificadas como a mesma mecânica (C4 + soco direcional); conflito estrutural de salas 211/212 (canal de água na ROM vs aliases da prisão no Godot); aproximações por overlay alfa/senoidal no Godot vs alteração de paleta direta do VDP MSX2; sala 204 bloqueada como "o limbo" em vez do pátio de paraquedas; loop do deserto (sala 103) contornado no Godot sem checagem de Compass. Nenhum arquivo de gameplay alterado.
**Testes:** `python3 tools/validate.py` fora do sandbox: exit 0, 38 etapas PASS; `build_index --check`: exit 0.
**Pendências:** implementação/correção de hazards e resolução do conflito de IDs 211/212 sob demanda.
**Git:** commit a pedido do usuário, sem push e sem tag; `godot/project.godot` preservado fora do commit.

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
