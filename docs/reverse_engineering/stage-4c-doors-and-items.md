# Evidência e Validação da Composição de Portas e Itens (Etapa 4C)

Data: 2026-09-20
Laboratório educacional de engenharia reversa do Metal Gear original MSX2 (RC750).

## 1. Objetivos e Escopo

Comprovar e modelar empiricamente a composição dinâmica de portas (`DrawDoors`) e itens (`DrawRoomItems`) sobre o fundo estabilizado de tela (SCREEN 5, VRAM Página 0) gerado por `RenderRoom`, eliminando lacunas entre o fundo estático de metatiles e a imagem visível no jogo.

## 2. Descobertas da Desmontagem e Análise de Instruções

A rotina de renderização de tela `RenderScreen` no Banco 0 (ROM `0x2CE0` / CPU `0x6CE0`) estabelece o pipeline determinístico de inicialização gráfica de sala:

```z80
RenderScreen:
    ...
    call    RenderRoom          ; 0x4CF0: Desenha o fundo base estático dos metatiles
    call    SetRoomPal          ; 0x4ACB: Define a paleta de cores da sala
    call    SetSprPal           ; 0x4AB5: Define a paleta de cores dos sprites
    call    DrawDoors           ; 0x775F: Compõe portas fechadas sobre o fundo
    ld      a, (IntroSceneStatus)
    cp      0Ch                 ; Intro terminada?
    jr      c, RenderScreen3    ; Se ainda em intro, pula desenho de itens
    call    SetBankInA0_6
    call    DrawRoomItems       ; 0xBC54: Desenha itens presentes na sala
```

### Âncoras de Instrução Verificadas na ROM Principal (SHA-256: `254ffcd...`)
- `RenderRoom`: ROM `0x0CF0`, CPU `0x4CF0`.
- `WaitVdpCmd`: ROM `0x0ED2`, CPU `0x4ED2`, RET em `0x4EDB`.
- `LoadRoomTiles`: ROM `0x0935`, CPU `0x4935`.
- `DrawDoors`: ROM `0x375F`, CPU `0x775F` (assinatura `\x3a\xff\xc4\xa7\xc8\x47\x21\xd0\xc3`).
- Sequência de chamada `RenderScreen`: ROM `0x2CE5`, CPU `0x6CE5` (`\xcd\xf0\x4c\xcd\xcb\x4a\xcd\xb5\x4a\xcd\x5f\x77`).

### Lógica da Rotina `DrawDoors` (ROM `0x375F` / CPU `0x775F`)
1. **Verificação de Portas**:
   - Lê `DoorsInRoom` (`RAM 0xC4FF`). Se `0`, retorna imediatamente (`ret z`).
   - Se $> 0$, itera sobre o array `DoorsList` (`RAM 0xC3D0`, 16 bytes por registro).
2. **Estado Aberto vs Fechado**:
   - Byte offset +1: `Open` (`0 = Aberto, 1 = Fechado`).
   - Se `Open == 0`, a porta **não é desenhada** (`jr z, DrawDoors3`), pois os metatiles base de fundo já representam a abertura da porta.
   - Se `Open != 0`, a porta é desenhada sobre a abertura pelo tipo em `DrawDoorType`.
3. **Tipos de Renderização (`DrawDoorType`)**:
   - **Tipo 1 (North)**: Copia bloco de 24×32 pixels da VRAM Página 1 (`SX=196, SY=160`) para `(DrawX, DrawY)` na Página 0 com comando VDP `LMMM TIMP` (`a = 0x48`, onde cor 0 é transparente). Atualiza `RoomTileBuffer` com 4×4 tiles `DoorClosedTiles` (`0x02`).
   - **Tipo 2 (South)**: Copia bloco de 32×8 pixels da Página 1 (`SX=224, SY=192`) para `(DrawX, DrawY)` com `LMMM TIMP`. Atualiza 4×1 tiles `DoorClosedTiles` (`0x02`).
   - **Tipos 3 e 4 (West e East)**: Desenho com inclinação de perspectiva através de 8 fatias verticais de 1×32 a partir de `0xE0A0` e `0xE8A0`.
   - **Tipo 5 (Elevator)**: Copia bloco de 24×32 pixels da Página 1 (`SX=196, SY=192`) para `(DrawX, DrawY)` com `LMMM TIMP`. Atualiza 4×4 tiles `DoorClosedTiles` (`0x02`).
   - **Tipo 6 (Dummy)**: Retorna imediatamente (`ret`), nenhum pixel é desenhado.
   - **Tipos 7..19 (Paredes destrutíveis)**: Desenha blocos de tiles das paredes fechadas (`TilesBasemWall...`) e salva tiles de fundo.

### Regra de Itens em Salas (`AddRoomItems`)
- A rotina `AddRoomItems` (ROM Banco 4/5/6) verifica o ID da sala:
  - Salas 0 a 121: Salas externas / abertas — `cp 122; ret c` (não possuem itens de chão).
  - Salas 122 a 217: Salas isoladas / internas — possuem itens indexados em `idxRoomItemsIdx`.
  - Salas $\ge 218$: Elevadores / especiais — `cp 218; ret nc` (não possuem itens de chão).

## 3. Metodologia de Captura e Validação no openMSX

Foi adicionado hook em `0x775F` (`DrawDoors`) no `capture.tcl` para capturar o retorno do comando (`doors_return`), aguardando a estabilização do VDP (`WaitVdpCmd` RET `0x4EDB` se `VDP status 2 bit 0 == 1`) e despejando:
- `$prefix-doors-vram.bin`: VRAM completa de 64 KiB com a composição pós-portas.
- `$prefix-doors-ram.bin`: RAM completa de 16 KiB refletindo as colisões atualizadas em `RoomTileBuffer` (`0xE000`).

Em seguida, o script `compare.py` implementa `reconstruct_doors_overlay`:
- Reconstitui analiticamente a sobreposição exata esperada a partir dos gráficos da Página 1 da VRAM e dos registros de portas da extração.
- Compara a tela da VRAM pós-`DrawDoors` capturada no emulador contra a reconstrução analítica.

## 4. Resultados Medidos

Execução determinística em `--mode gameplay` nas 6 salas percorridas:

| Sala | Descrição | Portas Fechadas | Pixels Alterados | Bounding Box Delta | Validação Reconstrução |
| :---: | :--- | :---: | :---: | :---: | :---: |
| 121 | Praia (início) | 0 | 0 | N/A (100% idêntico) | 49.152 / 49.152 (100%) |
| 0 | Portão externo | 0 | 0 | N/A (100% idêntico) | 49.152 / 49.152 (100%) |
| 1 | Fachada Prédio 1 | 0 | 0 | N/A (100% idêntico) | 49.152 / 49.152 (100%) |
| 2 | Corredor Prédio 1 | 0 | 0 | N/A (100% idêntico) | 49.152 / 49.152 (100%) |
| 3 | Hall do Elevador | 1 (Porta 2, Elevador) | 737 | X: [100..123], Y: [0..31] (24×32) | 49.152 / 49.152 (100%) |
| 240 | Elevador (interior) | 0 (Tipo 6 Dummy) | 0 | N/A (100% idêntico) | 49.152 / 49.152 (100%) |

### Análise Específica da Sala 3
- Na Sala 3, a porta do elevador (Porta ID 2, `render_type 5`) inicia fechada (`Open = 1`).
- Dimensões do bloco da porta: 24×32 pixels = 768 pixels totais.
- Exatamente 737 pixels foram sobrepostos no VRAM Página 0, e 31 pixels eram da cor 0 (transparente), mantendo o fundo preservado.
- Todos os 737 pixels caíram estritamente dentro da caixa delimitadora `X: 100..123` e `Y: 0..31`. Zero pixels vazaram para fora da área da porta.
- A reconstrução analítica em Python conferiu 100% dos 49.152 pixels contra o dump do emulador.

## 5. Artefatos e Testes

- `data/extracted/emulator-stage4c-settled/`: 55 arquivos privados de execução (prior-vram, ram, vram, settled-vram, doors-vram, doors-ram, palette, state, manifest, config, script).
- `data/extracted/stage4c-validated/`: 6 snapshots validados com contrato de schema, 6 PNGs de fundo base, 6 PNGs pós-portas (`room-003-doors.png`), `comparison.json` e `checksums.json`.
- Testes unitários sintéticos (`test_reconstruct_doors_overlay` e `test_compare_room_with_doors_vram`) aprovados com `unittest`.
- `tools/validate.py`: 39 testes Python OK, importação Godot OK, smoke e room snapshot OK.
