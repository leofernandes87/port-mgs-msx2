# Estado atual

Atualizado em 2026-10-04. Curto por regra (skill `delivery`); histórico em `docs/progress/`.
Confirme sempre com `git log --oneline -3` e `git status --short`.

## Onde estamos

- Última tag `v0.2.0` (minor: ROM canônica inglesa com dados incompatíveis com os anteriores,
  auditoria regional e infraestrutura de contexto).
- ROM canônica `en-eu-rc750` por SHA-256 (`tools/rom.py`); o Godot só aceita dados de
  `data/extracted/en-eu-rc750/` com essa proveniência. Godot em 60 Hz.
- Sandbox jogável a partir da sala 121; mecânicas portadas e suas cadeias em
  `python3 -m tools.context.lookup mech` (`docs/index/mechanics.json`).
- Validação: `python3 tools/validate.py` (ROM, índices de contexto, unittest, suítes Godot, boot).
- `godot/project.godot` tem alteração local do usuário: nunca incluir em commits.

## Em andamento

- Nada além das tarefas abaixo. Índices: `python3 -m tools.context.build_index` a cada entrega.

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
| Rotina, RAM, quem cita | `python3 -m tools.context.lookup asm/ram/cites` |
| Função em .gd grande | `docs/index/godot-outline.md` ou `lookup gd ARQUIVO FUNÇÃO` |
| Testes e marcadores | `docs/index/tests.md` |
| Salas e aliases | `docs/index/rooms.md` |
| Entrega anterior | `docs/progress.md` (últimas 5) ou `lookup progress "título"` |
| Mapa do repositório e ambiente | `docs/README.md` |
