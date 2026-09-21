# Engenharia Reversa — Salas de Gás Tóxico e Máscara de Gás (MSX2 RC750)

## 1. Contexto e Fontes

- **Arquivo fonte**: `logic/damagegas.asm`, `logic/actors/gas.asm`, `Banks0123.asm` e `data/actorsinrooms.asm`.
- **Offset na ROM**: `0x4C79` (19.577 bytes, Banco 2).
- **Mecânica**: Verificação contínua no loop de jogo (`ChkGasRooms` chamado em `CommonLogic`). Se o jogador estiver em uma sala com gás, verifica se a Máscara de Gás (`ITEM_GAS_MASK`) está equipada no inventário. Caso não esteja, causa 2 pontos de dano a cada 16 ticks (0x10).

## 2. Desmontagem Comentada

### `logic/damagegas.asm:9-47`
```z80
ChkGasRooms:
    ld      a, (Room)
    ld      b, 9                            ; 9 salas com gás
    ld      hl, GasRooms                    ; Tabela GasRooms no offset 0x4C79

ChkGasRooms2:
    cp      (hl)
    jr      z, ChkGasMask                   ; É uma sala com gás
    inc     hl
    djnz    ChkGasRooms2
    ret

ChkGasMask:
    ld      a, (SelectedItem)
    cp      SELECTED_GAS_MASK               ; ID 5 na ROM = Gas Mask
    ret     z                               ; Máscara equipada -> sem dano

    ld      c, 10h                          ; Intervalo de dano = 16 ticks (0x10)

DecrementLife_C:
    ld      a, (DamageDelayTimer)
    and     a
    ret     nz                              ; Aguarda o delay para não aplicar dano a cada frame

    ld      a, c
    ld      (DamageDelayTimer), a           ; Reinicia o delay de 16 ticks

DecrementLife_2:
    ld      b, 2                            ; Dano = 2 HP
    jp      DecrementLife_B
```

### Tabela Canônica de Salas de Gás (`damagegas.asm:53`)
```z80
GasRooms:
    db 29, 94, 96, 97, 98, 100, 101, 112, 114
```
Bytes na ROM em `0x4C79`:
`1D 5E 60 61 62 64 65 70 72` (9 salas).

### Atores de Nuvens de Gás (`data/actorsinrooms.asm`)
Nas 9 salas, atores com `ID_GAS = 8` são instanciados para gerar as nuvens visuais de gás animadas:
- Sala 29: 4 atores de gás
- Sala 94: 4 atores de gás
- Sala 96: 4 atores de gás
- Sala 97: 4 atores de gás
- Sala 98: 4 atores de gás
- Sala 100: 4 atores de gás
- Sala 101: 4 atores de gás
- Sala 112: 3 atores de gás
- Sala 114: 3 atores de gás

### Obtenção da Máscara de Gás (`data/itemsinrooms.asm:91`)
- **Sala 138** (Prédio 1 - Térreo):
  - Guarda dorminhoco (`SleepyGuardFlag = 1` em `Banks0123.asm:6822`).
  - Caixa de item `GAS_MASK` (ID 13 nos metadados neutros) em `(72, 32)`.
