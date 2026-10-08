# Reextração da ROM canônica `en-eu-rc750` (fase 4)

Data: 2026-10-04. ROM: `en-eu-rc750`, 131072 bytes, CRC32 `E85C5731`, SHA-256
`d16fff4a59ce26b570851c7200f67e05f385978598dcad91c83bf9c671a295ae`, resolvida por
`tools/rom.py`. Referência: `external/MetalGear` revisão `30d1b940`. Montagem Sjasm
`JAPANESE equ 0` idêntica byte a byte à ROM canônica; `JAPANESE equ 1` usada só para
tabelas de símbolos (deslocamentos), nunca como dado.

## Onde estão os dados

| Conteúdo | Caminho (ignorado pelo Git) |
| --- | --- |
| Dados canônicos consumidos | `data/extracted/en-eu-rc750/` |
| Dados antigos do dump japonês, preservados para comparação | `data/extracted/legacy-jp-rc750-local/` |
| Relatório máquina/humano | `data/extracted/en-eu-rc750/region-diff.json`, `region-diff.md` |

Nada antigo foi sobrescrito: a reextração escreveu em diretório novo; depois do
relatório os dados antigos foram apenas movidos para `legacy-jp-rc750-local/`.

Conteúdo canônico gerado: pacote (`package/`, repetição idêntica em `package-repeat/`,
`package_sha256 ad068b77…`), 235 salas + 235 arquivos de atores (`rooms/`; 155, 222,
223 e 227–239 não definidas), aliases locais 211/212/54 (`local-aliases/`), cinco
JSONs de mecânica, paredes 12–15, diálogo de Grey Fox, capturas de emulador
(demo: salas 1, 5, 31, 127; gameplay: 0, 1, 2, 3, 121, 240 — 49152 pixels e portas
iguais ao pacote), trace da introdução e sonda da caixa de texto.

Comandos:

```sh
python3 tools/extractors/extract.py --output data/extracted/en-eu-rc750/package
python3 tools/extractors/batch_snapshots.py --package data/extracted/en-eu-rc750/package/package.json --output data/extracted/en-eu-rc750/rooms --rooms all
python3 tools/extractors/export_room_data.py --package data/extracted/en-eu-rc750/package/package.json --output data/extracted/en-eu-rc750/rooms --rooms all
python3 tools/extractors/export_local_aliases.py   # 211/212 = 165/164, portas remapeadas
python3 tools/extractors/extract_gas_hazard.py     # idem respawn, missile, capture_prison, electrified, prison_wall, grey_fox
python3 tools/reverse_engineering/compare_regions.py --sjasm <sjasm> --json <novo.json> --markdown <novo.md>
```

## Relatório antes/depois

`compare_regions.py` compara cada artefato antigo com o novo. Campos de proveniência
(`rom_profile`, `input_sha256`, evidências) são ignorados; deslocamentos só são aceitos
como estruturais quando a mudança é exatamente o delta do símbolo entre as montagens
EN e JP.

| Categoria | Artefatos (pior achado) | Achados |
| --- | ---: | ---: |
| Idêntico | 461 | — |
| Diferença estrutural | 38 | 173 |
| Diferença regional esperada | 0 | 2 |
| Ainda sem explicação | 1 | 1 |

- **Idênticos (461):** 218 salas, todos os atores fora dos aliases, aliases 211/212/54
  (salvo ordem de portas), paredes 12–15, diálogo de Grey Fox, `capture_prison`,
  capturas de emulador.
- **Estruturais:**
  - pacote: 121 endereços deslocados −13 bytes (60 itens × `rom_offset`/`cpu_address`
    e o offset do segmento; tabelas de nomes regionais
    antes de `itemsinrooms`, `Banks456.asm:66-84`); segmento `itemsinrooms` com hash
    diferente por conter ponteiros `dw` absolutos;
  - `gas_hazard` `0x4C79→0x4C2A`, `electrified_floor` `0x4C0D→0x4BBE`, velocidade do
    míssil `0x48DE→0x488F` (−79, código do banco 0), munição máxima `0x51D6→0x518A`
    (−76, depois de `AddItemAmount`, `logic/items.asm:409-413`);
  - `respawn_info`: 189→188 entradas; o extrator antigo lia uma entrada além de
    `RespawnInfo` (`data/respawninfo.asm:13`, 564 bytes); as 188 primeiras são iguais;
  - `capture_prison.json` da raiz antiga: formato obsoleto;
  - salas 208–221 e 224–226: só existem no export novo (nunca exportadas antes);
  - `room-212-actors`: mesmas portas em outra ordem;
  - trace da introdução: mesma sequência de 457 atualizações; período 0,06804 s
    (máquina JP, 60 Hz) contra 0,08233 s (`C-BIOS_MSX2_EU`, 50 Hz). Godot segue em 60 Hz;
  - sonda da caixa de texto: fase de música/`TickCounter`, pilha abaixo de
    `Stack=0xF0F0` (`Banks0123.asm:554`) e área do BIOS (`RG9SAV`, bit PAL).
- **Regionais esperadas (2):** 12 bytes de VRAM = glifos 44 e 103 de `gfx/font.asm:29-33,63-67`.
- **Sem explicação (1):** RAM `0xF29C–0xF2D9` (57 bytes) na sonda. Fica entre as
  variáveis do jogo (última: `FKeysHoldMenu`, `0xF0F9`) e a área do BIOS (`0xF380`);
  nenhum símbolo ou literal do jogo a referencia (as ocorrências de `0F2xxh` são
  endereços de VRAM ou coordenadas). Hipótese não confirmada: área de trabalho do
  C-BIOS. Não afeta dados consumidos.

Os aliases 211/212 e as portas da sala 54 eram cópias locais feitas à mão das salas
165/164 (`prison-wall.md:7`); regenerá-los do pacote japonês dá o mesmo resultado
que do europeu, logo a diferença não é regional.

## Ramos `JAPANESE` da referência (17)

| Local | Efeito EN | Estado no Godot |
| --- | --- | --- |
| `Banks456.asm:66` / `:80` | `weaponnames.asm` / `itemnames.asm` | Rótulos inventados nos menus (ver auditoria) |
| `BanksABC.asm:24` | `texts.asm` | Textos de rádio escritos à mão em inglês; Grey Fox extraído |
| `BanksDEF.asm:21` | `radiocalls.asm` | Tabela própria incompleta (ver auditoria) |
| `Banks0123.asm:5353,7970,7981,8052,8158,8228` | sem `flagTxtItem` | Não implementado = comportamento EN |
| `logic/items.asm:409` | só texto 62 ao pegar o último item | Nenhum texto (ver auditoria) |
| `data/musicradioconfig.asm:16` | sala 31 sem chamada | Sala 31 sem chamada = EN |
| `logic/gamedemo.asm:216` | entradas de demo EN | Demo não implementada |
| `gfx/font.asm:29,63` | glifos EN | Fonte EN (`prisoner_dialog.gd`) |
| `logic/regionlock.asm:28` | sem teste de BIOS | Não se aplica |
| `logic/actors/guardalert.asm:174` | bytes não usados | Não se aplica |

## Auditoria regional da implementação (2026-10-04)

Ausência de implementação não conta como bug: o projeto é incremental. Cada achado foi
classificado contra a edição inglesa, com o assembly como evidência.

Semântica do rádio confirmada no código (o cabeçalho de `data/radiocalls.asm:5-10`
inverte os nomes): `UpdateRadio` copia os bits 3-2 (`Banks0123.asm:2413-2425`);
`RADIO_WAITCALL` (4) exige que Snake peça resposta, sem ele a resposta é automática ao
sintonizar (`ChkRadioReceiv`, `:10993-11006`); `RADIO_AUTOREPLY` (8) só faz auto tune.
O indicador CALL vem do bit 3 de `RoomsMusic` (`ChkRadioCalls`, `:1689-1743`).

### 1. Implementado e divergente — corrigido

| Achado | Evidência inglesa | Correção |
| --- | --- | --- |
| Sala 5 disparava CALL e auto-resposta | `RadioRoom_005` = `RADIO_BIGBOSS \| RADIO_WAITCALL`; `RoomsMusic[5]` sem bit 3 (`ChkRadioCalls4`, `Banks0123.asm:1729-1733`) | `is_autoreply = false`; Big Boss responde só ao SEND |
| Sala 138 tinha Schneider/texto 156 | `idxRoomRadio[138]` = `NoRadio` (`data/radiocalls.asm:188`); texto 156 é de Diane na sala 150 | Entrada removida |
| Big Boss respondia em qualquer sala sem dados, com texto inventado | `ChkRadioReceiv` retorna sem resposta se `NumRadioPersons = 0` ou sem frequência igual (`Banks0123.asm:10971-10990`); texto ausente de `texts.asm` | Fallback removido |
| Cabeçalho citava `radiocallsjp.asm` | `BanksDEF.asm:21` (ramo `ELSE`) | Comentário corrigido |

Testes: `godot/tests/radio_system_test.gd` (sala 5 sem CALL e com resposta ao SEND;
salas 2 e 138 mudas) e `tests/test_region_tools.py::GodotRadioFollowsEnglishEdition`
(cada sala portada deve existir na tabela inglesa com os mesmos contatos/frequências/
textos, e o CALL deve seguir o bit 3 de `RoomsMusic`; falha na versão anterior nas
salas 5 e 138).

### 1. Implementado e divergente — registrado, não corrigido

- **Textos hardcoded com redação diferente da ROM inglesa:** briefing da introdução
  (texto 2: `DESTOROY`, `12085 FROM NOW ON. ...OVER`) e rádio, textos 3 (`MISION`),
  60, 64, 88 e 92 (paráfrases). Textos 4, 6, 7, 20, 25 e 38 são idênticos; 10, 23, 26,
  39, 42, 51 e 80 diferem só em espaços/pontuação. A paginação inglesa usa quebras
  explícitas `FE`/`FD`, enquanto o Godot pagina automaticamente. Corrigir exige copiar
  texto protegido para scripts versionados (regra 4); a correção fiel é extrair os textos
  em runtime como no diálogo de Grey Fox. Decisão pendente do usuário.

### 2. Implementado parcialmente (parte existente correta após as correções)

- `ROOM_CALLS`: 15 das 60 salas inglesas; contatos, frequências e textos conferem.
- Indicador CALL: só via entradas portadas; faltam as condições de `ChkRadioCalls`
  (Schneider nunca chama, Jennifer com 4 estrelas e irmão vivo, antena a partir de
  `MapZone` 5, espera de 32 iterações) e a repetição ao reentrar na sala.
- Resposta automática ao sintonizar (entradas sem `RADIO_WAITCALL`, ex.: Schneider nas
  salas 1, 30, 31) ainda exige SEND no Godot; `AutoReplyDone` não portado.
- Textos de interface do rádio sem equivalente na ROM ("TRANSCEIVER ONLINE...",
  "TUNING...", "RECEIVER MODE...", `TXT_NO_RESPONSE`): substitutos provisórios da tela
  de rádio.
- Coleta de itens: funciona e não mostra descrições (= inglês); falta o texto 62
  ao pegar `BAG` como último item da sala
  (`logic/items.asm:399-414`, `data/itemtaketextid.asm:9`). Mensagem ainda não portada.

### 3. Ainda não implementado (backlog)

- Tela de menu de armas/equipamentos original (`DrawWeaponMenu`/`DrawItemMenu`,
  `Banks0123.asm:2025,2209`) com `data/weaponnames.asm`/`itemnames.asm`. Os menus
  atuais (`weapon_menu.gd`, `item_menu.gd`) são painéis Godot provisórios; seus rótulos
  não são divergência regional. O HUD só desenha ícones, como o original.
- Música por sala (nibble alto de `RoomsMusic`, `SetAreaMusic`) e bits 0–2.
- 45 salas de rádio inglesas e os contatos do prédio 2 (frequências 13, 26, 91).
- Demo (`logic/gamedemo.asm:216-238`, usar o ramo `ELSE`).

### 4. Exclusivo da versão japonesa — corretamente ignorado

- `flagTxtItem` (`Banks0123.asm:5353,7970,7981,8052,8158,8228`).
- Descrições de todos os itens na coleta (`logic/items.asm:409-413`).
- Chamada na sala 31 (`musicradioconfig.asm:16`), 52 salas de rádio extras e as
  variações das salas 31, 54, 57, 94 e 150 (`radiocallsjp.asm`).
- Nomes em katakana (`*namesjp.asm`), `textsjp.asm`, glifos JP da fonte, `RegionLock`
  (`logic/regionlock.asm:28`) e bytes não usados de `guardalert.asm:174`.

### 5. Diferença regional legítima — Godot segue o ramo inglês

- Fonte (glifos 44 e 103), texto 62 como única descrição de coleta, sala 31 sem CALL,
  tabela de rádio inglesa, demo inglesa (quando implementada).
