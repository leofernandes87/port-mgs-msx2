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
| `Banks456.asm:66` / `:80` | `weaponnames.asm` / `itemnames.asm` | Rótulos inventados nos menus (ver divergências) |
| `BanksABC.asm:24` | `texts.asm` | Textos de rádio escritos à mão em inglês; Grey Fox extraído |
| `BanksDEF.asm:21` | `radiocalls.asm` | Tabela própria incompleta (ver divergências) |
| `Banks0123.asm:5353,7970,7981,8052,8158,8228` | sem `flagTxtItem` | Não implementado = comportamento EN |
| `logic/items.asm:409` | só texto 62 ao pegar o último item | Nenhum texto (ver divergências) |
| `data/musicradioconfig.asm:16` | sala 31 sem chamada | Sala 31 sem chamada = EN |
| `logic/gamedemo.asm:216` | entradas de demo EN | Demo não implementada |
| `gfx/font.asm:29,63` | glifos EN | Fonte EN (`prisoner_dialog.gd`) |
| `logic/regionlock.asm:28` | sem teste de BIOS | Não se aplica |
| `logic/actors/guardalert.asm:174` | bytes não usados | Não se aplica |

## Divergências de comportamento para a próxima etapa (não corrigidas)

1. **Texto ao pegar itens.** EN: `ItemTakeText` (`data/itemtaketextid.asm:7-9`) só é
   exibido se o valor for 62, "I took back the weapon and equipment" (`logic/items.asm:403-414`);
   apenas `BAG` (`Enums.asm:154`, ID 22h → índice 33 = 62) e somente quando é o último
   item da sala (`TempData2`, `:399-401`). JP mostra todas as descrições.
   Godot: `item_box.gd:145-151` restaura o equipamento sem texto algum. Falta o texto 62.
2. **Rádio.** `radio_system.gd` tem `ROOM_CALLS` escrito à mão com 16 salas; a tabela
   EN (`idxRoomRadio`) tem 60. Faltam 45 salas EN (7, 8, 33, 45, 46, 48, 51, 57,
   59–63, 69, 82, 83, 86, 87, 93, 94, 96, 97, 99, 100, 102–104, 108, 111, 115–117,
   119, 123–125, 150, 165, 178, 182, 192, 193, 202, 220, 221). A sala 138 do Godot
   (Schneider, texto 156) não existe na EN (nem na JP, que tem Big Boss 154). Nenhuma
   entrada exclusiva da JP foi usada (JP tem 52 salas extras, chamadas extras nas
   salas 31, 54, 57, 150 e texto 111 em vez de 64 na sala 94). O cabeçalho
   (`radio_system.gd:6`) cita `radiocallsjp.asm` e deve ser corrigido.
3. **Indicador de chamada / música.** Original: bit 3 de `RoomsMusic`
   (`musicradioconfig.asm:9`). EN: salas 0, 29, 37, 53, 69, 99, 104, 108, 111, 115,
   116, 119, 125, 165, 178, 192, 193; JP acrescenta a 31. Godot deriva de
   `is_autoreply`: 0, 5, 29, 37, 53. A sala 5 não tem bit 3 em nenhuma versão;
   faltam 12 salas EN. IDs de música (nibble alto) e bits 0–2 não são usados pelo Godot.
4. **Nomes das armas e itens.** EN: `HAND GUN`, `SMG`, `GRENADE`, `ROCKET`, `P@BOMB`,
   `L@MAIN`, `MISSILE`, `SILENCER`; itens com 5 letras (`GOGGL`, `SCOPE`, `BOX`,
   `RATIO`…) (`data/weaponnames.asm:20-34`, `data/itemnames.asm:37-85`). Godot:
   `item_menu.gd:96-106` usa "CARDBOARD BOX", "INFRARED GOGGLES", "BINOCULARS",
   "RATION (x/y)"; `weapon_menu.gd` usa identificadores internos.
5. **`flagTxtItem`.** Existe só nos ramos JP (pular texto de item com direcional,
   impressão imediata). EN não o tem; Godot também não. Sem ação, salvo registrar.
6. **Demo.** EN usa `DemoGameplay1` com `42h,0,28h` (JP `70h,0,2Ch`), `DemoTutorial`
   com `80h,0` extra e `DemoGameplay2` diferente (`logic/gamedemo.asm:216-238`).
   Godot não implementa demo; quando implementar, usar o ramo `ELSE`.
7. **Outras descobertas.** Textos de rádio hardcoded precisam ser conferidos com
   `texts.asm` decodificado; `RESPAWN` agora com 188 entradas (o Godot já usa o
   arquivo novo); RAM `0xF29C` sem explicação; frequência de captura 50 Hz contra
   Godot 60 Hz (decisão mantida).
