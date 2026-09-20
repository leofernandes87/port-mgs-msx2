# Etapa 7 — Inimigos, Guardas, Rotas de Patrulha e Linha de Visão (Furtividade)

## 1. Visão Geral e Contexto
Na Etapa 5 e 6, implementamos a movimentação física discreta de Snake e o sistema de navegação e transição bidirecional contínua de salas (`RoomManager`).
Na **Etapa 7**, revertemos da ROM original do MSX2 RC750 a lógica que rege os soldados inimigos:
1. Spawning autêntico de guardas e seus tipos por sala (`data/actorsinrooms.asm`).
2. Rotas de patrulha e waypoints com ciclo e inversão ("vai-e-vem") (`data/paths.asm`).
3. Algoritmo canônico de detecção visual e tolerâncias direcionais (`logic/actors/chkdiscover.asm`).
4. Bloqueio de linha de visão por obstáculos da grade de colisão (`ChkViewObstacles`).
5. Disparo do estado de alerta e exibição do clássico balão com exclamação (`!`) sobre a cabeça do guarda.

---

## 2. Reversão do Código Z80 da ROM Original

### 2.1 Tipos de Inimigos e Velocidades Canônicas
No código do MSX2, os soldados guardas regulares são identificados pelos IDs lógicos:
- `ID_GUARD_SLOW = 4`: Velocidade de 0.5 px/tick (avança 1 pixel a cada 2 ticks).
- `ID_GUARD_MEDIUM = 5`: Velocidade de 1.0 px/tick (avança 1 pixel por tick).
- `ID_GUARD_FAST = 6`: Velocidade de 1.5 px/tick.

### 2.2 Tabela de Inimigos por Sala (`ActorsInRooms`)
Em `data/actorsinrooms.asm`, cada sala mapeia os atores que devem ser gerados ao entrar nela:
- **Sala 001** (Fachada do Prédio 1 com caixas):
  - Guarda 0: Tipo `ID_GUARD_MEDIUM` (5), Spawn `(64, 176)`, Rota `Path_000_01`.
  - Guarda 1: Tipo `ID_GUARD_SLOW` (4), Spawn `(80, 80)`, Rota `Path_000_02`.
  - Guarda 2: Tipo `ID_GUARD_MEDIUM` (5), Spawn `(192, 24)`, Rota `Path_000_03`.
- **Sala 002** (Corredor interno de entrada):
  - Guarda 0: Tipo `ID_GUARD_SLOW` (4), Spawn `(64, 48)`, Rota `Path_002_01`.
  - Guarda 1: Tipo `ID_GUARD_MEDIUM` (5), Spawn `(168, 112)`, Rota `Path_002_02`.

### 2.3 Rotas e Waypoints (`Paths`)
Em `data/paths.asm`, as coordenadas são sequências de pares $(Y, X)$:
- `Path_000_01` (Guarda inferior Sala 1):
  - Ponto 1: `(176, 200)`
  - Ponto 2: `(176, 56)`
  - Modo: Vai-e-vem horizontal inferior.
- `Path_000_02` (Guarda central Sala 1):
  - Rota de 8 pontos contornando o complexo de caixas centrais:
    `[(80, 56), (116, 56), (116, 200), (80, 200), (80, 168), (104, 168), (104, 88), (80, 88)]`.
- `Path_000_03` (Guarda superior Sala 1):
  - Ponto 1: `(24, 56)`
  - Ponto 2: `(24, 200)`
  - Modo: Vai-e-vem horizontal superior.
- `Path_002_01` e `Path_002_02` (Guardas Sala 2):
  - Patrulhas horizontais nos corredores da Sala 2.

### 2.4 Linha de Visão e Tolerâncias (`logic/actors/chkdiscover.asm`)
A rotina de detecção de visão do guarda contra Snake possui tolerâncias estritas dependendo da orientação:

#### Visão Vertical (`UP` / `DOWN`):
```z80
ChkViewVertical:
    ; Subtrai PlayerX - EnemyX
    ; Se |PlayerX - EnemyX| > 8 -> Snake fora da linha de visão
    ld      a, (PlayerX)
    sub     (ix+EnemyX)
    jr      nc, ChkViewV_Pos
    neg
ChkViewV_Pos:
    cp      8
    ret     nc                  ; Fora do cone vertical (|diff_x| >= 8)
```
- Condição de alcance: $|PlayerX - EnemyX| \le 8$ pixels.
- Para `UP`: $PlayerY < EnemyY$.
- Para `DOWN`: $PlayerY > EnemyY$.

#### Visão Horizontal (`LEFT` / `RIGHT`):
```z80
ChkViewHorizontal:
    ; Subtrai PlayerY - EnemyY
    ; Se |PlayerY - EnemyY| > 6 -> Snake fora da linha de visão
    ld      a, (PlayerY)
    sub     (ix+EnemyY)
    jr      nc, ChkViewH_Pos
    neg
ChkViewH_Pos:
    cp      6
    ret     nc                  ; Fora do cone horizontal (|diff_y| >= 6)
```
- Condição de alcance: $|PlayerY - EnemyY| \le 6$ pixels.
- Para `LEFT`: $PlayerX < EnemyX$.
- Para `RIGHT`: $PlayerX > EnemyX$.

#### Alcance Máximo e Bloqueio por Obstáculos (`ChkViewObstacles`):
- Alcance máximo do feixe visual: 160 pixels (20 tiles).
- A linha de visão é amostrada passo a passo em intervalos de 8 pixels ($1$ tile):
  - Se qualquer tile amostrado ao longo do feixe contiver valor de colisão `1` (obstáculo sólido), a visão é bloqueada e o alerta não é disparado.

---

## 3. Implementação em Godot 4

### 3.1 Classe `EnemyGuard` (`godot/scripts/systems/enemy.gd`)
- Tipagem estática integral (`class_name EnemyGuard extends Node2D`).
- Enum `GuardType { SLOW = 4, MEDIUM = 5, FAST = 6 }`.
- Função `step_tick(collision_grid, player_pos)`:
  - Movimenta o guarda ao longo de sua rota de waypoints com a velocidade nominal.
  - Testa `check_line_of_sight(player_pos, collision_grid)`.
  - Dispara `trigger_alert()` quando avistado.
  - Renderiza o sprite autêntico do soldado (capacete escuro, uniforme azul acinzentado, rifle e animação de passos) e o balão vermelho com exclamação branca (`!`).
  - Suporta visualização de depuração do cone de visão (`show_debug_vision`) ativada pela tecla `B`.

### 3.2 Integração no Sandbox (`godot/scripts/scenes/sandbox_gameplay.gd`)
- Limpa e instancia dinamicamente os guardas da sala ao entrar (`_spawn_room_enemies(snapshot.room_id)`).
- Atualiza cada guarda em `_physics_process()`.
- Se algum guarda avistar Snake:
  - O guarda exibe o balão `!`.
  - O cabeçalho de status da tela fica vermelho e exibe:
    `"ALERTA! Snake foi detectado por um soldado inimigo!"`.
- Adicionado botão de interface e atalho `B` para visualizar as zonas de detecção visual dos guardas.

---

## 4. Verificação Automatizada
- Teste criado: `godot/tests/enemy_patrol_test.gd`.
- Verificações executadas:
  1. Velocidades canônicas de cada `GuardType` (0.5, 1.0, 1.5).
  2. Patrulha de waypoints e transição de pontos.
  3. Tolerâncias exatas de visão vertical ($|X| \le 8$) e horizontal ($|Y| \le 6$).
  4. Bloqueio e oclusão de visão por obstáculos sólidos (`colisão = 1`).
  5. Disparo de alerta (`is_alert`, `alert_timer`).
- Integrado na suíte central `tools/validate.py` como `godot-enemy-patrol: PASS`.
