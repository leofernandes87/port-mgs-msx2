# Estado atual

Atualizado em 2026-10-04. Curto por regra (skill `delivery`); histórico em `docs/progress/`.
Confirme sempre com `git log --oneline -3` e `git status --short`.

## Onde estamos

- Última tag: `v0.2.2` (barris rolantes fiéis à ROM).
- Último commit: `feat(actors)` dos barris rolantes (confira com `git log --oneline -1`).
- Implementação recente: `rolling-barrels` (ID 15) revisado contra a ROM, com sprites extraídos por
  `tools/extractors/extract_rolling_barrel.py`; toque na coluna inteira mata Snake
  (linha de `ImpactAreasInfo` = shape); salas 141, 153, 191 e 205.
- ROM canônica `en-eu-rc750` por SHA-256 (`tools/rom.py`); o Godot só aceita dados de
  `data/extracted/en-eu-rc750/` com essa proveniência. Godot em 60 Hz.
- Sandbox jogável a partir da sala 121; catálogo progressivo e cadeias em
  `python3 -m tools.context.lookup mech` (`docs/index/mechanics.json`).
- Validação atual: `python3 tools/validate.py` fora do sandbox, exit 0; 38 etapas PASS,
  159 testes Python; importação/boot Godot 4.7.2 e suítes existentes aprovados.
- `godot/project.godot` tem alteração local do usuário: nunca incluir em commits.

## Auditoria atual

- `actors-bosses`: `rolling-barrels` (ID 15) promovido a IMPLEMENTED (1 IMPLEMENTED,
  20 PARTIAL, 12 PROVISIONAL, 16 NOT_STARTED, 2 UNMAPPED; total 51).
- `weapons-items`: 38 features — IMPLEMENTED 1, PARTIAL 20, PROVISIONAL 8,
  NOT_STARTED 9; DEFERRED/UNMAPPED/INVESTIGATING 0. Catálogo via `lookup domain weapons-items`.
- Divergências registradas: armas substituídas por bala genérica, foguete recusado, recarga
  indevida de míssil, timers/velocidades, cartões por posse e reposição de consumíveis.
- Próxima tarefa sugerida, só após pedido: priorizar `pitfalls` (ID 16) ou `rocket-launcher`.
- Pendências de actors-bosses: uso alcançável do ID 56 e produtores do ID 65.

## Decisões pendentes do usuário

- Textos hardcoded com redação diferente da ROM inglesa (intro texto 2; rádio 3, 60, 64, 88, 92):
  corrigir exige extração local em runtime, como o diálogo de Grey Fox
  (`docs/reverse_engineering/en-eu-reextraction.md`, "Auditoria regional").

## Próximas tarefas registradas (não iniciar sem pedido)

- Conflito de IDs: 211/212 são aliases da prisão no Godot, mas salas reais do canal de água na
  ROM (`data/roomsconnections.asm:113-114,136-137`); ver `docs/index/rooms.md`.
- `RESCUED_PER_RANK = 4` em `rank_system.gd` versus `cp 5` em `IncRescued`
  (`Banks0123.asm:9634-9641`; `docs/reverse_engineering/grey-fox-dialogue.md`).
- Rádio parcial: 45 salas restantes, condições de `ChkRadioCalls`, resposta automática ao
  sintonizar, texto 62 da `BAG` (lista na auditoria regional).
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
