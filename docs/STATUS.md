# Estado atual

Atualizado em 2026-10-08. Curto por regra (skill `delivery`); histórico em `docs/progress/`.
Confirme sempre com `git log --oneline -3` e `git status --short`.

## Onde estamos

- Última tag: `v0.2.5` (CORE-002: movimento cardinal fiel), branch feature/core-002-player-movement.
- Último commit: `feat(player)` (confira com `git log --oneline -1`).
- Implementação recente: CORE-002, movimento cardinal fiel. `PlayerControls` porta
  StoreControls/GetPlayerDir/DisableControls; `step_control` move 200h em 8.8 por tick com parada imediata.
- Anterior: CORE-001, relógio `GameClock` (60 Hz, jogo a cada 2 interrupções; máquina europeia é 50 Hz).
- ROM canônica `en-eu-rc750` por SHA-256 (`tools/rom.py`); o Godot só aceita dados de
  `data/extracted/en-eu-rc750/` com essa proveniência.
- Sandbox jogável a partir da sala 121; catálogo progressivo e cadeias em
  `python3 -m tools.context.lookup mech` (`docs/index/mechanics.json`).
- Validação atual: `python3 tools/validate.py` fora do sandbox, exit 0; 40 etapas PASS,
  165 testes Python; importação/boot Godot 4.7.2 e suítes existentes aprovados.
- `godot/project.godot` versionado sem `[physics]` nem `resizable` (60 Hz definido por `GameClock`).

## Auditoria atual

- `actors-bosses`: 51 features (1 IMPLEMENTED, 20 PARTIAL, 12 PROVISIONAL, 16 NOT_STARTED, 2 UNMAPPED).
- `weapons-items`: 38 features (1 IMPLEMENTED, 20 PARTIAL, 8 PROVISIONAL, 9 NOT_STARTED).
- `radio-dialogue`: 32 features (7 IMPLEMENTED, 19 PARTIAL, 3 PROVISIONAL, 2 NOT_STARTED, 1 UNMAPPED).
- `progression-events`: 33 features (IMPLEMENTED 0, PARTIAL 4, PROVISIONAL 5, NOT_STARTED 24).
- `player-core`: 18 features (IMPLEMENTED 0, PARTIAL 11, PROVISIONAL 3, NOT_STARTED 4; UNMAPPED 0).
- `hazards-special-rooms`: 14 features (IMPLEMENTED 0, PARTIAL 4, PROVISIONAL 1, NOT_STARTED 9).
- `world-rooms-navigation`: 10 features (IMPLEMENTED 0, PARTIAL 6, PROVISIONAL 0, NOT_STARTED 4).
- Catálogo: 201 features normalizadas, ownership consolidado e 0 erros de integridade.
- Próxima tarefa sugerida, só após pedido: CORE-003 (facing e animação) de docs/IMPLEMENTATION_PLAN.md.

## Decisões pendentes do usuário

- Texto 2 da intro ainda hardcoded com redação diferente da ROM; os textos do rádio já vêm da
  extração local do rádio, que pode servir à intro se autorizado.

## Próximas tarefas registradas (não iniciar sem pedido)

- Conflito de IDs: 211/212 são aliases da prisão no Godot, mas salas reais do canal de água na ROM.
- `RESCUED_PER_RANK = 4` em `rank_system.gd` versus `cp 5` em `IncRescued`
  (`Banks0123.asm:9634-9641`; `docs/reverse_engineering/grey-fox-dialogue.md`).
- Rádio: produtores das flags de evento (texto 138, bolsa com transmissor, sala 111) e texto 62 da `BAG`.
- Grey Fox: SFX e captura dinâmica do diálogo.
- Tick: `RadioDialog`/typewriter ainda em tempo real; cadência de rádio/menus/binóculos/captura não
  medida; `game_tick` não segue rotina a rotina `PlayModeLogic` (`game-loop`).
- Movimento: wrap de 16 bits; `DisableControls` em elevador/paraquedas/escada;
  velocidade 100h em água sem evidência no asm (`player-movement`).
- Fora do escopo até pedido: modo 50 Hz opcional; bloco de RAM 0xF29C–0xF2D9.

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
