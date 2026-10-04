# Progresso

Somente as entradas mais recentes. Histórico completo, sem edição, em `docs/progress/`;
índice com arquivo e linha em `docs/progress/INDEX.md`. Rotação: `python3 -m tools.context.build_index`.

## 2026-10-04 — Fase 4: reextração completa da ROM canônica `en-eu-rc750`

**Escopo:** reextrair todos os dados derivados da ROM a partir só de `en-eu-rc750`,
comparar com os dados antigos do dump japonês, classificar as diferenças, trocar o
pipeline para os dados canônicos e remover a aceitação legada. Sem correções de
gameplay. Relatório completo: `docs/reverse_engineering/en-eu-reextraction.md`.

**Dados:** gerados em diretório novo `data/extracted/en-eu-rc750/` (pacote e
repetição idênticos, 235 salas + atores, aliases 211/212/54, cinco JSONs de
mecânica, paredes 12–15, Grey Fox, capturas de emulador demo e gameplay, trace da
introdução, sonda da caixa de texto). Os antigos foram comparados primeiro e depois
apenas movidos para `data/extracted/legacy-jp-rc750-local/` (nada apagado).

**Ferramentas novas:** `tools/reverse_engineering/compare_regions.py` (monta EN e JP
com Sjasm só para símbolos; deslocamento é estrutural somente se igual ao delta do
símbolo), `tools/extractors/export_local_aliases.py` (celas 211/212 como cópias de
165/164 com portas remapeadas), `tools/emulation/run_trace.py` (trace Tcl na ROM
canônica com relocação de endereços e conferência de opcodes). `tools/rom.py`:
`canonical_data_dir()` e `require_canonical_provenance()`; `batch_snapshots`,
`export_room_data`, `compare.py` e os extratores exigem a proveniência canônica.
Schema de snapshot: `rom_profile` obrigatório, `local_alias_of` opcional.

**Relatório antes/depois:** 461 artefatos idênticos, 38 estruturais (173 achados:
relocação −13/−76/−79 bytes entre os ramos `JAPANESE`, `respawn_info` 189→188,
arquivo raiz obsoleto, salas 208–226 nunca exportadas antes, ordem de portas,
50 Hz na captura), 2 achados regionais esperados (glifos 44 e 103,
`gfx/font.asm:29-33,63-67`) e 1 sem explicação (RAM `0xF29C–0xF2D9` da sonda, fora
das variáveis do jogo e do BIOS; hipótese: área do C-BIOS). Nenhuma diferença de
conteúdo de gameplay nos dados extraídos.

**Godot:** `RomProvenance` sem `LEGACY_PENDING_REEXTRACTION` nem hash japonês; exige
o par `rom_profile` + `input_sha256` (canônico ou sintético) e oferece
`load_canonical_json()`. `RoomManager` (local-aliases → rooms), gás, respawn, piso
elétrico, paredes da prisão e diálogo de Grey Fox leem só de `en-eu-rc750` com
verificação de proveniência; os fallbacks `res://data/*.json` foram removidos (os
fallbacks em código continuam). Scripts de mapa `tools/assemble_*.gd` apontam para
`en-eu-rc750/rooms`. Frequência continua 60 Hz; `godot/project.godot` intocado.

**Divergências de gameplay registradas para a próxima etapa (não corrigidas):**
texto 62 ao pegar `BAG` ausente; `ROOM_CALLS` com 16 de 60 salas EN e sala 138
inexistente; indicador de chamada derivado de `is_autoreply` (sala 5 indevida, 12
salas EN faltando) em vez do bit 3 de `RoomsMusic`; nomes de menu inventados em vez de
`weaponnames.asm`/`itemnames.asm`; `flagTxtItem` (só JP, ausente no Godot = EN);
demo não implementada (usar ramo `ELSE`); textos de rádio hardcoded a conferir.

**Validação real:** testes de extractors/emulação/proveniência/regiões: 58 OK.
`tests/test_rom.py`: 13 OK, incluindo espelho Godot sem hash estrangeiro, lint que
proíbe caminhos legados e conferência real de 485 arquivos consumidos (todos
`en-eu-rc750` + SHA canônico). `python3 tools/validate.py`: exit 0, 36 etapas PASS
(119 testes Python); `godot-room-snapshot` carregou as salas 0, 126, 240 e 211 de
`en-eu-rc750` e recusou snapshot japonês, perfil japonês e perfil ausente.

**Git:** commit `ac7cd60` a pedido do usuário (sem push, sem tag);
`godot/project.godot` fora do commit.

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
