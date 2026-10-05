# Estado atual

Atualizado em 2026-10-04. Curto por regra (skill `delivery`); histórico em `docs/progress/`.
Confirme sempre com `git log --oneline -3` e `git status --short`.

## Onde estamos

- Última tag: `v0.2.3` (núcleo do rádio fiel à ROM).
- Último commit: `feat(radio)` (confira com `git log --oneline -1`).
- Implementação recente: núcleo do rádio fiel à ROM. Tabela de salas, zonas e
  textos extraídos por `tools/extractors/extract_radio_dialogue.py`; `radio_system.gd` tick a tick
  (CALL 32/88 ticks, AUTO-REPLY/WAIT-CALL, BCD, LEDs, condições de `ChkRadioReply`).
- Anterior: `rolling-barrels` (ID 15) com sprites extraídos, tag `v0.2.2`.
- ROM canônica `en-eu-rc750` por SHA-256 (`tools/rom.py`); o Godot só aceita dados de
  `data/extracted/en-eu-rc750/` com essa proveniência. Godot em 60 Hz.
- Sandbox jogável a partir da sala 121; catálogo progressivo e cadeias em
  `python3 -m tools.context.lookup mech` (`docs/index/mechanics.json`).
- Validação atual: `python3 tools/validate.py` fora do sandbox, exit 0; 38 etapas PASS,
  164 testes Python; importação/boot Godot 4.7.2 e suítes existentes aprovados.
- `godot/project.godot` tem alteração local do usuário: nunca incluir em commits.

## Auditoria atual

- `actors-bosses`: `rolling-barrels` (ID 15) promovido a IMPLEMENTED (1 IMPLEMENTED,
  20 PARTIAL, 12 PROVISIONAL, 16 NOT_STARTED, 2 UNMAPPED; total 51).
- `weapons-items`: 38 features — IMPLEMENTED 1, PARTIAL 20, PROVISIONAL 8,
  NOT_STARTED 9; DEFERRED/UNMAPPED/INVESTIGATING 0. Catálogo via `lookup domain weapons-items`.
- `radio-dialogue`: 32 features — IMPLEMENTED 7, PARTIAL 19, PROVISIONAL 3,
  NOT_STARTED 2, UNMAPPED 1; DEFERRED/INVESTIGATING 0. Catálogo via `lookup domain radio-dialogue`.
- Rádio: flags de evento sem produtor (Schneider capturado, irmão de Jennifer, transmissor,
  SwitchOffMSX, Madnar), SFX só como sinal, texto 2 da intro hardcoded e TextBoxLogic fragmentado.
- Próxima tarefa sugerida, só após pedido: priorizar `pitfalls` (ID 16) ou `rocket-launcher`.
- Pendências de actors-bosses: uso alcançável do ID 56 e produtores do ID 65.

## Decisões pendentes do usuário

- Texto 2 da intro ainda hardcoded com redação diferente da ROM; os textos do rádio já vêm da
  extração local do rádio, que pode servir à intro se autorizado.

## Próximas tarefas registradas (não iniciar sem pedido)

- Conflito de IDs: 211/212 são aliases da prisão no Godot, mas salas reais do canal de água na
  ROM (`data/roomsconnections.asm:113-114,136-137`); ver `docs/index/rooms.md`.
- `RESCUED_PER_RANK = 4` em `rank_system.gd` versus `cp 5` em `IncRescued`
  (`Banks0123.asm:9634-9641`; `docs/reverse_engineering/grey-fox-dialogue.md`).
- Rádio: produtores das flags de evento (texto 138, bolsa com transmissor, sala 111) e texto 62 da `BAG`.
- Grey Fox: SFX e captura dinâmica do diálogo.
- Fora do escopo até pedido: 50 Hz × 60 Hz; bloco de RAM 0xF29C–0xF2D9.

## Onde procurar

| Preciso de | Use |
|---|---|
| Regras | `AGENTS.md` |
| Features e lacunas | `lookup domain DOMÍNIO`, `lookup status STATUS`, `lookup unmapped`, `lookup mech ID` |
| Rotina, RAM, quem cita | `python3 -m tools.context.lookup asm/ram/cites` |
| Função em .gd grande | `docs/index/godot-outline.md` ou `lookup gd ARQUIVO FUNÇÃO` |
| Testes e marcadores | `docs/index/tests.md` |
| Salas e aliases | `docs/index/rooms.md` |
| Entrega anterior | `lookup progress "título"` (sem título: última entrada) |
| Mapa do repositório e ambiente | `docs/README.md` |
