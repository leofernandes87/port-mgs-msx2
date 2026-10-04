# Progresso

Somente as entradas mais recentes. Histórico completo, sem edição, em `docs/progress/`;
índice com arquivo e linha em `docs/progress/INDEX.md`. Rotação: `python3 -m tools.context.build_index`.

## 2026-10-04 — Registro do diálogo de Grey Fox

Commit e tag autorizados pelo usuário: diálogo inglês paginado de Grey Fox,
correção da fonte extraída e correções de fidelidade do resgate/janela, tag anotada
`v0.1.48`. Validação reaproveitada da entrega anterior (validador completo, testes
Grey Fox headless e gráfico). Arquivos candidatos revisados; texto, atlas, extrações
e ROMs permanecem ignorados. A alteração local preexistente em `godot/project.godot`
ficou fora do commit e continua preservada. Sem push.

## 2026-10-04 — ROM inglesa oficial como única canônica (fases 1–3)

**Decisões do usuário:** ROM inglesa oficial (europeia, CRC32 `E85C5731`) é a única
canônica; capturas com `C-BIOS_MSX2_EU`; Godot permanece em 60 Hz; ROM
`[English] [6873]` movida para `../metal-gear-roms-fora-do-pipeline/`; nada
reextraído nesta entrega.

**Evidência:** montagem Sjasm 0.39j da referência `30d1b940` com `JAPANESE equ 0`
(`MetalGear.asm:38`) idêntica byte a byte a `en-eu-rc750`
(`python3 -m tools.rom --verify-build` → `build=identical`).

**Fase 1:** `data/rom-profiles.json` (só metadados: hashes, máquina openMSX,
endereços de debugger) e `tools/rom.py`: resolução por SHA-256 (`--rom` >
`$MG_ROM` > busca por conteúdo em `roms/`), recusa nominal dos perfis
`jp-rc750-local`, `en-nekura-hoka-1.995c`, `en-6873-bitflip`, sem fallback;
`--check` e `--verify-build`.

**Fase 2:** removidos `DEFAULT_ROM`, `PRIMARY_SHA256`, constantes `*_ROM_OFFSET`
e o fallback silencioso do piso eletrificado. Extratores localizam offsets por
símbolo na referência (`Reference.literal/table/signature`) e gravam
`rom_profile` + `input_sha256`. `extract.py` aceita só a canônica (schema:
`input_role` = `canonical`, `rom_profile` obrigatório). `capture.py` usa a máquina
do perfil e breakpoints conferidos por âncoras únicas (EU: 0x4935, 0x4CF0,
0x7710, 0x4EDB), passados ao Tcl por `config.tcl`. `analyze.py` analisa só a
canônica; `--inventory-all` lista todas rotuladas por perfil. `verify.py` e
`extract_prison_wall.py` exigem o hash.

**Correção encontrada:** `extract_respawn_info.py` lia 189 entradas; a tabela
`RespawnInfo` (`data/respawninfo.asm:13`) tem 564 bytes = 188 entradas de 3 bytes.
A contagem agora deriva da fonte; a 189ª leitura caía fora da tabela.

**Fase 3:** `tests/test_rom.py` (resolvedor com bytes sintéticos, independência
de nome/ordem, recusas, `MG_ROM`, guarda de alteração, perfil real, âncoras de
captura, espelho Godot do hash e lint de política em `tools/` e
`godot/scripts/`). Godot: `RomProvenance` + guarda em `RoomSnapshot.decode()`:
aceita canônica e sintética (`0`×64), recusa outras; o hash japonês é aceito só
como `LEGACY_PENDING_REEXTRACTION`, com aviso único, até a reextração.
`tools/validate.py` ganhou a etapa `rom-profile` (SKIP sem ROM privada).

**Validação real:** `python3 -m unittest discover -s tests`: 109 testes OK.
`python3 tools/validate.py`: exit 0, 36 etapas PASS, incluindo `rom-profile`
(`ROM_CHECK_OK: en-eu-rc750`) e `godot-room-snapshot` com os casos
canônico/sintético/legado/estrangeiro. Falha intermediária: o lint novo
apontou READMEs e dois comentários Godot com nome/offsets do dump japonês;
corrigidos.

**Pendências:** fase 4 (reextração de todos os dados a partir da ROM canônica e
remoção da exceção legada) aguarda aprovação; depois revalidar diferenças EN×JP
(`logic/items.asm:409`, `musicradioconfig.asm:16-20`, nomes de armas,
`flagTxtItem`, demo).

**Git:** commit `7904020` a pedido do usuário (sem push, sem tag). Alteração
preexistente em `godot/project.godot` preservada fora do commit.

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
