# Etapa 9 — Portas Interativas, Caixas de Itens Coletáveis e Inventário

## 1. Visão Geral e Contexto
Na Etapa 8, foi implementado o combate corpo a corpo, a perseguição por soldados em alerta e o sistema de vida e dano.
Na **Etapa 9**, avançamos para o núcleo de progressão e exploração do Metal Gear original do MSX2 RC750:
1. **Caixas de Itens Coletáveis nas Salas (`data/itemsinrooms.asm`)**:
   - Spawning autêntico de caixas com posições $(X, Y)$ exatas da ROM.
   - Suporte a `CARD1`, `RATION` e `BINOCULARS`.
2. **Sistema de Inventário e Seleção (`logic/menuequipment.asm`)**:
   - Adição e contagem de itens possuídos.
   - Alternância de item ativo via tecla `E`.
   - Uso de rações (`RATION`) via tecla `U` para restauração total da barra de energia ($24$ pontos de vida).
3. **Portas Interativas e Trancas por Cartão (`logic/doors/opendoor.asm` e `data/doors.asm`)**:
   - Portas fechadas renderizadas bloqueando a passagem física através de injeção de colisão (`1`) na grade de $768$ tiles.
   - Verificação de proximidade e compatibilidade de chave (`required_card`): ao encostar com o cartão correspondente selecionado, a porta se abre (`is_open = true`) e desativa a colisão (`0`).
   - Transição de entrada: ao passar pela soleira da porta aberta, Snake transiciona para a sala de destino (`destination_room`).

---

## 2. Reversão do Código Z80 da ROM Original

### 2.1 Mapeamento de Itens por Sala (`data/itemsinrooms.asm`)
A tabela `idxRoomItemsIdx` associa cada ID de sala a um ponteiro de itens:
- **Sala 004**: `ItemCard4` $\rightarrow$ `CARD1`, posição `(112, 80)` ($0x70, 0x50$).
- **Sala 005**: `ItemBinoculars` $\rightarrow$ `BINOCULARS`, posição `(112, 64)` ($0x70, 0x40$).
- **Sala 006**: `ItemRation` $\rightarrow$ `RATION`, posição `(96, 64)` ($0x60, 0x40$).

### 2.2 Verificação e Abertura de Portas (`logic/doors/opendoor.asm`)
```z80
ChkCard:
    ld      l, c
    ld      h, b                ; HL = ponteiro para dados da porta
    ld      a, (SelectedItem)
    cp      d                   ; D = cartão exigido pela porta
    jp      nz, DoorLocked      ; Se não for o cartão correto -> Porta trancada!

    ld      a, (PlayerDirection)
    cp      (hl)                ; Snake está virado para a porta?
    jp      nz, DoorLocked

    jp      ChkTouchDoor        ; Verifica se Snake encostou na porta
```
- A rotina `ChkTouchDoor` verifica se a coordenada de Snake está dentro do retângulo de contato da porta.
- Quando o cartão corresponde e Snake encosta virado para a porta, a rotina `DoorUnlocked` é disparada: a porta abre e limpa os tiles de colisão na VRAM.

### 2.3 Entrada e Transição pela Porta (`logic/nextroom.asm:120-155`)
```z80
SetDoorDestination:
    ld      a, 15               ; Offset 15 na estrutura da porta = Destination room
    call    ADD_HL_A
    ld      a, (hl)
    ld      c, a                ; C = sala de destino
    ld      a, (Room)
    ld      (PreviousRoom), a   ; Salva sala anterior
    ld      a, c
    ld      (Room), a           ; Carrega nova sala
```

### 2.4 Consumo de Ração (`logic/menuequipment.asm:228`)
```z80
UseRation:
    ld      a, (MaxLife)
    ld      (Life), a           ; Restaura a energia de Snake ao valor máximo
    dec     (RationsCount)      ; Consome uma unidade de ração
```

---

## 3. Implementação em Godot 4

1. **[`InventoryManager`](file:///Users/leofernandes/Desktop/WorkSpace/projeto-game/godot/scripts/systems/inventory.gd)**:
   - Registro de itens coletados, rações e seleção ativa.
   - Métodos `collect_item()`, `cycle_item()`, `select_item()`, `use_selected_item()`.
2. **[`ItemBox`](file:///Users/leofernandes/Desktop/WorkSpace/projeto-game/godot/scripts/systems/item_box.gd)**:
   - Caixa metálica militar cinza de 12x12 com indicador gráfico de tipo (cartão, cruz de ração ou suprimento).
   - Coleta por proximidade ($\le 12$ px) com persistência por ID para evitar duplicações.
3. **[`RoomDoor`](file:///Users/leofernandes/Desktop/WorkSpace/projeto-game/godot/scripts/systems/door.gd)**:
   - Orientação direcional (North, South, West, East) e injeção dinâmica de colisão nos tiles da grade.
   - Verificação de proximidade, direção e cartão exigido.
   - Abertura com vão escuro de passagem e disparo de transição ao entrar.
4. **[`sandbox_gameplay.gd`](file:///Users/leofernandes/Desktop/WorkSpace/projeto-game/godot/scripts/scenes/sandbox_gameplay.gd)**:
   - Spawners `_spawn_room_items()` e `_spawn_room_doors()`.
   - Atalhos `E` (alternar item) e `U` (consumir ração).
   - Indicador de item ativo no HUD (`ITEM: [CARD1]` / `ITEM: [RAÇÃO x1]`).

---

## 4. Validação Automatizada

- Teste: `godot/tests/doors_and_inventory_test.gd`.
- Integrado na suíte central `tools/validate.py` como `godot-doors-inventory: PASS`.
- Todos os 39 testes unitários Python e 8 testes Godot aprovados com 100% de sucesso.
