# Modelo de Movimento e Colisão de Snake (Etapa 5)

Data: 2026-09-20
Laboratório educacional de engenharia reversa do Metal Gear original MSX2 (RC750).

## 1. Objetivos

Especificar com base em evidências do código desmontado e na execução emulada:
- A física de movimento de Snake (velocidade submétrica, vetores direcionais e taxas de atualização).
- O algoritmo exato de detecção de colisão estática por amostragem de pontos (`BoxColliderDat`).
- O ciclo de animação de passos.
- A fundamentação para a reimplementação do controlador no Godot 4.

## 2. Variáveis de Estado em RAM

Conforme `Variables.asm` e `Banks0123.asm`:

| Endereço RAM | Identificador | Tamanho | Descrição |
| :---: | :--- | :---: | :--- |
| `0xC182` | `PlayerYdec` | 2 bytes | Posição Y em ponto fixo 8.8 (byte baixo = subpixel, byte alto = pixel Y) |
| `0xC184` | `PlayerXdec` | 2 bytes | Posição X em ponto fixo 8.8 (byte baixo = subpixel, byte alto = pixel X) |
| `0xC180` | `StopPlayerFlag` | 1 byte | `0` = em movimento, `1` = parado |
| `0xC181` | `PlayerDirection` | 1 byte | `1` = Cima, `2` = Baixo, `3` = Esquerda, `4` = Direita |
| `0xC105` | `PlayerMovSpeed` | 2 bytes | Velocidade linear em ponto fixo 8.8 |
| `0xC155` | `PlayerSpeedY` | 2 bytes | Componente Y da velocidade em 8.8 |
| `0xC157` | `PlayerSpeedX` | 2 bytes | Componente X da velocidade em 8.8 |
| `0xC186` | `PlayerFrameNum` | 1 byte | Índice do frame de animação (`0` = parado, `1` e `2` = passos) |
| `0xC187` | `PlayerAnimWaitCnt` | 1 byte | Contador de ticks para troca de frame (dispara a cada 6 ticks) |

## 3. Dinâmica de Movimento (`ControlPlayer`)

Em `Banks0123.asm` (linhas 8840–8965):
1. **Velocidade de Caminhada**:
   - `PlayerMovSpeed` é inicializado como `0x0200` (exatamente **2.0 pixels por tick / frame**).
   - Em água profunda (`CONTROL_DEEP_WATER`), `PlayerMovSpeed` cai para `0x0100` (1.0 pixel por tick).
2. **Atualização Vetorial**:
   - **Cima (`Dir 1`)**: `SpeedY = -0x0200` (-2 pixels), `SpeedX = 0`
   - **Baixo (`Dir 2`)**: `SpeedY = +0x0200` (+2 pixels), `SpeedX = 0`
   - **Esquerda (`Dir 3`)**: `SpeedX = -0x0200` (-2 pixels), `SpeedY = 0`
   - **Direita (`Dir 4`)**: `SpeedX = +0x0200` (+2 pixels), `SpeedY = 0`
   - O jogo MSX não permite movimentação diagonal: apenas um eixo é ativo por tick.

## 4. Algoritmo de Colisão de Tiles (`ChkPlayerColl` e `BoxColliderDat`)

Em `logic/collisions.asm` (linhas 15–97):
Antes de aplicar o deslocamento à posição real (`MovePlayerX` e `MovePlayerY`), a rotina `ChkPlayerColl` projeta a próxima posição:
```text
next_x = PlayerX + SpeedX
next_y = PlayerY + SpeedY
```

Para a forma do jogador (`Size/Shape 0`), o jogo lê `BoxColliderDat` que define rigorosamente **2 pontos de teste** por direção:

| Direção | Ponto 1 (Offset X, Offset Y) | Ponto 2 (Offset X, Offset Y) |
| :---: | :---: | :---: |
| **Cima (`Dir 1`)** | `(-6, -5)` | `(+5, -5)` |
| **Baixo (`Dir 2`)** | `(-6, +4)` | `(+5, +4)` |
| **Esquerda (`Dir 3`)** | `(-8, -4)` | `(-8, +3)` |
| **Direita (`Dir 4`)** | `(+7, -4)` | `(+7, +3)` |

Para cada ponto `(px = next_x + ox, py = next_y + oy)`:
1. Converte para coordenadas de tile: `tile_x = px // 8`, `tile_y = py // 8`.
2. Se `tile_x < 0` ou `tile_x >= 32` ou `tile_y < 0` ou `tile_y >= 24`: colisão de borda de tela.
3. Se `static_collision[tile_y * 32 + tile_x] == 1`: **colisão detectada**.
4. Caso haja colisão em qualquer um dos 2 pontos:
   - A rotina `ResetPlayerSpd` zera `PlayerSpeedX` e `PlayerSpeedY`.
   - A posição `(PlayerX, PlayerY)` **não avança**, mantendo Snake exatamente adjacente à barreira.

## 5. Temporização e Ciclo de Passos (`SetSprWalk`)

Em `Banks0123.asm` (linhas 9708–9745):
- Quando parado (`StopPlayerFlag == 1`): `PlayerFrameNum = 0` (posição de descanso/idle).
- Quando em movimento:
  - `PlayerAnimWaitCnt` é incrementado a cada tick (a 60 Hz).
  - Quando atinge 6 (`cp 6`), é zerado e `PlayerFrameNum` é incrementado.
  - O ciclo de caminhada alterna: `1 -> 2 -> 1 -> 2` (3 frames totais: 0 = idle, 1 = perna esquerda, 2 = perna direita).
  - Isso resulta em uma passada a cada 6 frames (~10 passos por segundo).
