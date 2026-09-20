# Etapa 6 — Transição de Salas e Navegação Contínua do Mundo

## 1. Visão Geral e Contexto
Na Etapa 5, foi estabelecida a física discreta de caminhada de Snake (2.0 px/tick) e a amostragem de colisão por pontos de `BoxColliderDat` (Shape 0).
Na **Etapa 6**, revertemos e implementamos os sistemas responsáveis por permitir que Snake **transicione entre telas conectadas**, explorando continuamente o mapa do jogo (da praia inicial até os corredores do Prédio 1) com total paridade ao comportamento da ROM original do MSX2 RC750.

---

## 2. Reversão do Código Z80 da ROM Original

### 2.1 Limites de Disparo de Saída (`ChkExitRoom`)
No disassembly original (`Banks0123.asm:9418`), a rotina `ChkExitRoom` é chamada a cada tick de física do jogador:

```z80
ChkExitRoom:
    call    MovePlayerX         ; Atualiza X do jogador
    ld      a, h                ; Parte inteira de X
    cp      12
    ld      c, 3                ; Left
    jp      c, ExitRoom         ; Se X < 12 -> Saída para a esquerda

    inc     c                   ; 4 = Right
    cp      244
    jp      nc, ExitRoom        ; Se X >= 244 -> Saída para a direita

    call    MovePlayerY         ; Atualiza Y do jogador
    ld      a, h                ; Parte inteira de Y
    cp      16                  ; Up
    ld      c, 1
    jr      c, ExitRoom         ; Se Y < 16 -> Saída para o norte

    inc     c                   ; 2 = Down
    cp      186
    jr      nc, ExitRoom        ; Se Y >= 186 -> Saída para o sul
    ret
```

**Constantes canônicas de saída:**
- `LEFT`: $X < 12.0$
- `RIGHT`: $X \ge 244.0$
- `UP`: $Y < 16.0$
- `DOWN`: $Y \ge 186.0$

> **Nota de Arquitetura**: Essas margens foram calibradas no MSX2 de modo que, no momento em que a saída dispara, todos os pontos de amostragem de `BoxColliderDat` de Snake ainda estejam estritamente dentro da grade de tiles $32 \times 24$, garantindo que colisores válidos em passagens abertas nunca sejam bloqueados prematuramente pela borda da matriz.

### 2.2 Tabela e Resolução de Vizinhos (`GetNextRoomNum` e `RoomConnections`)
A rotina `GetNextRoomNum` (`Banks0123.asm:889`) resolve a vizinhança da sala atual a partir da tabela `RoomConnections` (`data/roomsconnections.asm`):

```z80
GetNextRoomNum:
    call    SetBanks_4_5_6
    ld      c, 0FFh
    ld      a, (Room)
    cp      126                 ; Salas 0 a 125 possuem relação direta 1:1 na tabela
    jr      c, GetNextRoomNum3

    cp      208
    jr      c, GetNextRoomNum4   ; Salas 126 a 207 são isoladas / caminhões (sem saída de borda)

    cp      228
    jr      c, GetNextRoomNum2   ; Salas 208 a 227 usam índice (Room - 82)

    cp      241                 ; Elevadores 241 a 250
    jr      c, GetNextRoomNum4   ; Sala 240 (elevador do Prédio 1) não possui saída de borda

    sub     13                  ; Elevadores: subtrai 13 (241 - 13 - 82 = 146)

GetNextRoomNum2:
    sub     82                  ; Subtrai 82

GetNextRoomNum3:
    ld      de, RoomConnections
    call    HL_4xA              ; HL = index * 4
    add     hl, de
    ld      a, (NextRoomDirect) ; 4=Right, 3=Left, 2=Down, 1=Up
    dec     a
    call    ADD_HL_A
    ld      c, (hl)
GetNextRoomNum4:
    ld      a, c
```

Cada entrada na tabela possui 4 bytes: `[UP, DOWN, LEFT, RIGHT]`. O valor `255` (`0xFF`) indica ausência de conexão.

**Exemplo do percurso inicial de infiltração:**
- **Sala 121** (Praia de infiltração): `[0, 255, 255, 255]` $\rightarrow$ UP vai para Sala 0.
- **Sala 000** (Portão externo do Prédio 1): `[1, 121, 255, 4]` $\rightarrow$ UP vai para Sala 1; DOWN volta para Sala 121; RIGHT vai para Sala 4.
- **Sala 001** (Fachada do Prédio 1 / Caixas): `[2, 0, 255, 5]` $\rightarrow$ UP vai para Sala 2; DOWN volta para Sala 0; RIGHT vai para Sala 5.
- **Sala 002** (Corredor interno de bifurcação): `[3, 1, 255, 6]` $\rightarrow$ UP vai para Sala 3; DOWN volta para Sala 1; RIGHT vai para Sala 6.
- **Sala 003** (Hall do Elevador): `[255, 2, 255, 7]` $\rightarrow$ DOWN volta para Sala 2; RIGHT vai para Sala 7; UP é a parede com a porta do elevador.

### 2.3 Coordenadas de Reentrada na Nova Sala (`SetRoomEntryXY` / `EntryRoomXY`)
Em `logic/nextroom.asm:342`, ao cruzar para a nova sala, Snake tem sua coordenada ortogonal ajustada:

```z80
EntryRoomXY:
    dw 0B800h   ; Vindo de UP: 0xB8 = 184 -> Y = 184.0 (Snake surge no sul da nova sala)
    dw 1200h    ; Vindo de DOWN: 0x12 = 18  -> Y = 18.0 (Snake surge no norte da nova sala)
    dw 0F200h   ; Vindo de LEFT: 0xF2 = 242 -> X = 242.0 (Snake surge no leste da nova sala)
    dw 0C00h    ; Vindo de RIGHT: 0x0C = 12 -> X = 12.0 (Snake surge no oeste da nova sala)
```

O eixo paralelo é conservado (ex: ao subir de Sala 0 para Sala 1 em $X=128$, Snake entra na Sala 1 em $X=128, Y=184$).

---

## 3. Implementação em Godot 4

### 3.1 `RoomManager` (`godot/scripts/systems/room_manager.gd`)
- Classe GDScript com tipagem estática pura, sem dependências de nós de cena.
- Contém a tabela canônica completa de 156 entradas (`CONNECTIONS_TABLE`) extraída da ROM.
- `get_next_room(room_id: int, dir: Direction) -> int`: implementa o mapeamento por faixas (`< 126`, `< 208`, `< 228`, etc.).
- `check_room_exit(pos: Vector2) -> int`: detecta cruzamento dos limites canônicos ($X < 12$, $X \ge 244$, $Y < 16$, $Y \ge 186$).
- `get_entry_position(exit_dir: int, current_pos: Vector2) -> Vector2`: calcula a coordenada exata de reentrada.
- `load_room_snapshot(room_id: int) -> RoomSnapshot`: gerenciador com cache inteligente de snapshots JSON já validados.

### 3.2 Integração na Cena Sandbox (`sandbox_gameplay.gd`)
- A cada deslocamento bem-sucedido em `_physics_process()`, chama `_check_and_handle_room_transition()`.
- Se houver vizinho válido, troca a textura, a grade de colisão e reposiciona Snake instantaneamente.
- Se for borda sem saída (`NO_ROOM`), `_clamp_to_room_bounds()` impede Snake de vazar para fora dos limites jogáveis da tela.

---

## 4. Validação Automatizada

Criado o teste headless `godot/tests/room_transition_test.gd`:
1. Validação estática das conexões de salas de referência (121, 0, 1, 2, 3, 208, 240).
2. Validação da função de limites de saída e conversão de coordenadas de reentrada.
3. Simulação interativa no SceneTree:
   - Sala 1 $\rightarrow$ move UP $\rightarrow$ carrega Sala 2 em $(128, 184)$.
   - Sala 2 $\rightarrow$ move UP pelo corredor direito ($X=144$) $\rightarrow$ carrega Sala 3 em $(144, 184)$.
   - Sala 3 $\rightarrow$ move DOWN $\rightarrow$ retorna para Sala 2 em $(144, 18)$.
   - Sala 2 $\rightarrow$ move DOWN $\rightarrow$ retorna para Sala 1 em $(128, 18)$.
   - Sala 1 $\rightarrow$ move DOWN $\rightarrow$ carrega Sala 0 em $(128, 18)$.
   - Sala 0 $\rightarrow$ move DOWN $\rightarrow$ carrega Sala 121 (praia) em $(128, 18)$.
   - Saída oficial: `ROOM_TRANSITION_OK: room connections, authentic exit bounds, entry XY recalculation, bidirectional room changes`.

Integrado ao `tools/validate.py`:
- `python-tests`: **PASS** (39 testes unitários)
- `godot-import`: **PASS**
- `godot-smoke`: **PASS**
- `godot-room-snapshot`: **PASS**
- `godot-player-movement`: **PASS**
- `godot-room-transition`: **PASS**
- `godot-main`: **PASS**
