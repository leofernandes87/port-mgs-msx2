# Etapa 10 — Engenharia Reversa: Portas de Caminhões (Lorries) e Posicionamento Canônico

Este documento formaliza as estruturas e rotinas da ROM original de Metal Gear (MSX2 RC750) relativas às portas de caminhões estacionados, mecânica de embarque/desembarque e posicionamento de itens no pátio e nas salas internas.

---

## 1. Mapeamento de Portas e Caminhões da Sala 005

No pátio inicial (Sala 005, pátio a leste da Sala 001), existem 3 caminhões de transporte estacionados. Cada caminhão funciona como um portal para uma sala interna independente de caminhão (`Rooms 126, 127, 128`):

Fonte: `external/MetalGear/data/doors.asm:311-316`

```z80
DoorsRoom005:
    db  65h,   1, 44h, 24h, 7Eh    ; Caminhão 1 (Esquerda) -> Sala 126 (0x7E)
    db  6Dh,   1, 64h, 64h, 7Fh    ; Caminhão 2 (Centro)   -> Sala 127 (0x7F)
    db  71h,   1, 44h,0A4h, 80h    ; Caminhão 3 (Direita)  -> Sala 128 (0x80)
    db  75h,   1, 44h, 24h,0C7h    ; Fake door usada para realocar o jogador
    db  6Ch,   2, 20h, 60h,0CCh
    db 0FFh
```

### Decodificação da Estrutura (5 bytes por porta):
- **Byte 0**: `Door ID` (ex: `65h` = 101, `6Dh` = 109, `71h` = 113).
- **Byte 1**: `Render Type ID` (1 = Entrada norte/sul padrão).
- **Byte 2**: `Draw Y` (posição vertical na tela em pixels).
- **Byte 3**: `Draw X` (posição horizontal na tela em pixels).
- **Byte 4**: `Destination Room` (ID da sala de destino).

Coordenadas físicas no pátio da Sala 5:
- **Caminhão 1 (Esquerda)**: $X = 36$ (`0x24`), $Y = 68$ (`0x44`) $\rightarrow$ Destino: Sala 126.
- **Caminhão 2 (Centro)**: $X = 100$ (`0x64`), $Y = 100$ (`0x64`) $\rightarrow$ Destino: Sala 127 (o caminhão central fica 32 pixels abaixo dos outros).
- **Caminhão 3 (Direita)**: $X = 164$ (`0xA4`), $Y = 68$ (`0x44`) $\rightarrow$ Destino: Sala 128.

---

## 2. Lógica de Portas de Caminhão (`ChkDoorLorry`)

Diferente das portas metálicas de edifícios, as portas de caminhão são abertas por padrão e não possuem tranca de cartão:

Fonte: `external/MetalGear/Banks0123.asm:1009-1026` e `external/MetalGear/data/doors.asm:917-918`

```z80
SetDefaultDoorLock2:
    ld      a, (de)
    and     0C0h        ; Mascara bits 7-6
    sub     80h         ; Se bit 7 estiver setado (#80), porta aberta
    jr      z, SetDefaultDoorLock3
    ld      a, 1        ; Fechada
SetDefaultDoorLock3:
    ld      (hl), a
```

Na tabela `IdDoorsLogic`:
- Porta 101: `8Ah` (Bit 7 setado $\rightarrow$ Aberta por padrão).
- Porta 109: `8Bh` (Bit 7 setado $\rightarrow$ Aberta por padrão).
- Porta 113: `8Bh` (Bit 7 setado $\rightarrow$ Aberta por padrão).

Portanto, portas de caminhão:
1. Começam em estado aberto (`is_open = true`).
2. Não injetam obstáculos de colisão nos tiles.
3. Não desenham sprite com leitor de cartão (os gráficos do caminhão já fazem parte dos metatiles de fundo).

---

## 3. Saída de Dentro dos Caminhões (`DoorsRoom126-128`)

As salas 126, 127 e 128 representam a caçamba interna do caminhão (renderizadas a partir do mesmo conjunto de metatiles da Sala 127). Na parte traseira (à direita), há a abertura por onde Snake sai de volta para o pátio:

Fonte: `external/MetalGear/data/doors.asm:634-638`

```z80
DoorsRoom126: db 65h, 4, 40h, 0D0h, 5, 0FFh
DoorsRoom127: db 6Dh, 4, 40h, 0D0h, 5, 0FFh
DoorsRoom128: db 71h, 4, 40h, 0D0h, 5, 0FFh
```

- **Render Type**: `4` (abertura voltada para a direita).
- **Coordenadas**: `DrawY = 40h` (64), `DrawX = 0D0h` (208).
- **Destino**: Sala 5 (pátio dos caminhões).

---

## 4. Posicionamento de Snake ao Atravessar (`PlayerInDoorDat`)

Ao mudar de sala através de uma porta, a rotina `SetPlayerInDoor4` em `logic/nextroom.asm:418-453` calcula a nova posição de Snake e sua direção usando `PlayerInDoorDat` (`logic/nextroom.asm:463-482`):

Para **Render Type 4** (Entrada no caminhão):
- `OffsetY`: `30h` ($+48$ px)
- `OffsetX`: `0F6h` ($-10$ px)
- `Direction`: `3` (`LEFT`)
- Posição resultante: $Y = 64 + 48 = 112$, $X = 208 - 10 = 198$, virado para a ESQUERDA.

Para **Render Type 1** (Saída do caminhão para a Sala 5):
- `OffsetY`: `28h` ($+40$ px)
- `OffsetX`: `0Ch` ($+12$ px)
- `Direction`: `2` (`DOWN`)
- Posições de saída:
  - Do Caminhão 1: $X = 36 + 12 = 48, Y = 68 + 40 = 108$, virado para BAIXO.
  - Do Caminhão 2: $X = 100 + 12 = 112, Y = 100 + 40 = 140$, virado para BAIXO.
  - Do Caminhão 3: $X = 164 + 12 = 176, Y = 68 + 40 = 108$, virado para BAIXO.

---

## 5. Posicionamento Canônico de Itens e Inimigos

Fonte: `external/MetalGear/data/itemsinrooms.asm` e `external/MetalGear/logic/addroomitems.asm:19-35`

Em salas $< 122$, não existem caixas de itens soltas (`ret c`). Todos os itens de suprimento ficam em salas $\ge 122$:

Tabela `idxRoomItemsIdx` (offset por `Room - 122`):
- Índice $126 - 122 = 4 \rightarrow$ Entrada 1: `ItemRation`
  - Coordenadas: `dw 5050h` $\rightarrow Y=80, X=80$.
- Índice $127 - 122 = 5 \rightarrow$ Entrada 2: `ItemCard1`
  - Coordenadas: `dw 7050h` $\rightarrow Y=80, X=112$.
  - Inimigo: `ActorsRoom127: db 1, db ID_GUARD_ALERT, dw 4870h` $\rightarrow X=72, Y=112$ (soldado de guarda em alerta!).
- Índice $128 - 122 = 6 \rightarrow$ Entrada 3: `ItemBinoculars`
  - Coordenadas: `dw 7040h` $\rightarrow Y=64, X=112$.

E no pátio externo (Sala 005):
- Inimigo: `ActorsRoom005: db 1, db ID_GUARD_EXIT_LORRY, dw 7078h` $\rightarrow X=112, Y=120$.
