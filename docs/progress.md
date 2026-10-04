# Progresso

Somente as entradas mais recentes. Histórico completo, sem edição, em `docs/progress/`;
índice com arquivo e linha em `docs/progress/INDEX.md`. Rotação: `python3 -m tools.context.build_index`.

## 2026-10-04 — Auditoria regional da implementação contra a edição inglesa

**Critério:** ausência de implementação não é bug; só o que já existe e diverge da
edição inglesa foi corrigido. Classificação completa em
`docs/reverse_engineering/en-eu-reextraction.md` ("Auditoria regional").

**Semântica confirmada:** `RADIO_WAITCALL` (4) = Snake precisa pedir resposta;
`RADIO_AUTOREPLY` (8) = auto tune (`UpdateRadio`, `Banks0123.asm:2413-2425`;
`ChkRadioReceiv`, `:10993-11006`); CALL = bit 3 de `RoomsMusic` (`ChkRadioCalls`,
`:1689-1743`). O cabeçalho de `radiocalls.asm` inverte esses nomes.

**Corrigido (`radio_system.gd`):** sala 5 não dispara mais CALL/auto-resposta
(`RADIO_WAITCALL`, sem bit 3); entrada inventada da sala 138 removida (`NoRadio`,
`radiocalls.asm:188`); removida a resposta genérica do Big Boss em salas sem ouvintes
(texto inexistente na ROM; `ChkRadioReceiv` não responde); cabeçalho deixou de citar
`radiocallsjp.asm`.

**Registrado sem correção:** textos hardcoded com redação diferente da ROM (intro texto
2; rádio 3, 60, 64, 88, 92) — corrigir exige extração em runtime para não versionar
texto protegido; decisão pendente. Parciais: 15/60 salas de rádio, condições de
`ChkRadioCalls`, resposta automática ao sintonizar, texto 62 da bolsa, textos de
interface provisórios. Backlog: tela de menu original com `weaponnames`/`itemnames`,
música por sala, demo. Ignorados por serem só JP: `flagTxtItem`, descrições de itens,
sala 31 com CALL, chamadas extras de `radiocallsjp.asm`.

**Testes:** `radio_system_test.gd` ampliado (sala 5, salas 2 e 138 mudas);
`tests/test_region_tools.py::GodotRadioFollowsEnglishEdition` confere cada sala
portada contra `radiocalls.asm` e `RoomsMusic` ingleses (falha na versão anterior nas
salas 5 e 138). `python3 tools/validate.py`: exit 0, 36 etapas PASS, 120 testes Python.

**Git:** sem commit, conforme pedido. `godot/project.godot` preservado.

## 2026-10-04 — Infraestrutura de contexto: regras enxutas, STATUS, progresso arquivado e índices

**Feito:** `AGENTS.md` só com regras permanentes (mapa do repositório e ambiente em
`docs/README.md`); `GEMINI.md` de uma linha; `docs/STATUS.md` substitui o HANDOFF (original
preservado em `docs/history/`). Histórico de `progress.md` movido sem edição para
`docs/progress/AAAA-MM.md` (94 entradas reconstruídas byte a byte; 309 KB → 12 KB) com índice.
`tools/context/`: `build_index` (símbolos asm, RAM, citações reversas, esboço Godot, testes,
rotação do progresso, validação de `mechanics.json`, `rooms.md`, caminhos e skills) e `lookup`.
`validate.py` com tabela `GODOT_TESTS` e etapa `context-indexes`. Skills novas:
`implement-faithful-mechanic`, `rom-extraction`, `godot-testing`, `openmsx-probe`, `delivery`;
`inspect-msx-disassembly` atualizada. Citações ambíguas qualificadas (`logic/actors/camera.asm`,
`logic/items.asm`), só em comentários.
**Achado registrado (não corrigido):** 211/212 são aliases da prisão no Godot e salas reais do
canal de água na ROM (`data/roomsconnections.asm:113-114,136-137`).
**Testes:** `tests/test_context_index.py` (7, fixtures sintéticas). `python3 tools/validate.py`:
exit 0, 37 etapas PASS (nova `context-indexes`), 127 testes Python.
**Git:** commit a pedido do usuário com tag `v0.2.0` (minor: desde `v0.1.48`, ROM canônica
inglesa com dados incompatíveis, auditoria regional `0ffde16` e esta entrega).

## 2026-10-04 — Inventário progressivo: atores e bosses

**Feito:** `docs/index/mechanics.json` ampliado como catálogo único, com 51 features da edição
inglesa, cruzadas com Godot, extractors, testes, documentos e histórico. Base:
`constants/Enums.asm:169-234`, `Banks0123.asm:6358-6468,12657-12739`.
PARTIAL 20, PROVISIONAL 12, NOT_STARTED 17, UNMAPPED 2; demais statuses 0.
`coverage.md` gerado, `lookup mech` ampliado e validação de status, IDs e referências
(incluindo histórico, dados locais e relações). Nenhum gameplay alterado.
**Testes:** índice com 14 testes sintéticos (7 novos). `python3 tools/validate.py` fora do
sandbox: exit 0, 37 etapas PASS, 134 testes Python; importação/boot Godot 4.7.2 aprovados.
**Pendências:** UNMAPPED: uso alcançável do prisioneiro ID 56 e correspondência da explosão
ID 65; demais divergências no catálogo, sem correção nesta entrega.
**Git:** commit `e408782`; entrega registrada na tag anotada `v0.2.1`.
`godot/project.godot` preservado fora do commit; sem push.

## 2026-10-04 — Interface enxuta de contexto para agentes

**Feito:** `lookup domain DOMÍNIO`, `lookup status STATUS` e `lookup unmapped` retornam
somente ID, título e status; `lookup mech ID` expõe os detalhes de uma única feature.
Regras em `AGENTS.md`, skills de inspeção/implementação/entrega e documentação proíbem
leitura integral de arquivos grandes com lookup apropriado. `coverage.md` se identifica
como relatório humano, não contexto padrão de agentes; catálogo e gameplay preservados.
**Testes:** oito novos testes sintéticos de CLI; 22 testes de contexto aprovados.
`python3 tools/validate.py` fora do sandbox: exit 0, 37 etapas PASS, 142 testes Python;
importação/boot Godot 4.7.2 aprovados. Conferência real dos filtros e hashes preservados.
**Pendências:** auditoria não avançou; lacunas anteriores permanecem no catálogo.
**Git:** commit `e408782`; entrega registrada na tag anotada `v0.2.1`.
`godot/project.godot` preservado fora do commit; sem push.

## 2026-10-04 — Inventário progressivo: armas, itens e equipamentos

**Feito:** inventário inglês antes do cruzamento com extração, Godot, integração, testes e histórico.
38 features `weapons-items` no catálogo canônico: IMPLEMENTED 1, PARTIAL 20, PROVISIONAL 8,
NOT_STARTED 9; DEFERRED/UNMAPPED/INVESTIGATING 0. Entradas de outros domínios preservadas.
Evidência: `constants/Enums.asm:4-10,83-108,127-155`, `logic/items.asm:333-356,490-516`,
`logic/weaponuse.asm:8-40`, `logic/maxammo.asm:112-147`; detalhes via `lookup mech ID`.
Gerador/lookup/validação suportam IDs de armas, pickups e equipamentos separados dos atores;
relatório humano regenerado. Limites de escopo e sobreposições documentados no próprio catálogo.
**Testes:** 26 testes focados de contexto; `python3 tools/validate.py` fora do sandbox: exit 0,
37 etapas PASS, 146 testes Python; importação, boot e suítes Godot 4.7.2 aprovados.
**Pendências:** divergências registradas sem correção; próxima tarefa sugerida, após pedido,
priorizar aquisição do foguete/recarga e respectivos testes. Gameplay e configuração local preservados.
**Git:** commit a pedido do usuário, sem push e sem tag; `godot/project.godot` preservado fora do commit.
