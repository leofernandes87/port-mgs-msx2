# Etapa 18 — Boss Fight Canônica: Shoot Gunner (Sala 57)

## 1. Visão Geral

Implementação fiel do primeiro chefe autêntico de Metal Gear MSX2 RC750: **Shoot Gunner** (`ID_SHOT_GUNNER = 0x21 = 33`).
Ao contrário de concepções populares que o associam à Sala 132, a análise exata das tabelas da ROM comprova que sua localização canônica é a **Sala 57** (`ActorsRoom057`), localizada no Prédio 2. A Sala 132 contém apenas um soldado em alerta (`ID_GUARD_ALERT`).

---

## 2. Evidências da ROM e Engenharia Reversa

### 2.1 Identificadores e Localização
- **ID do Chefe**: `ID_SHOT_GUNNER: equ 21h` (33 decimal) em `constants/Enums.asm:202`.
- **ID do Projétil**: `ID_SGUNNER_SHOT: equ 2Bh` (43 decimal) em `constants/Enums.asm:212`.
- **Sala Canônica**: `data/actorsinrooms.asm:370-372`:
  ```z80
  ActorsRoom057:
      db 1
      db ID_SHOT_GUNNER
      dw 9038h
  ```
  - `dw 9038h` decodifica para coordenadas `X = 144 (0x90)`, `Y = 56 (0x38)` no extrator do projeto.
- **Sala Segura contra Barulho de Tiros**:
  - `logic/checkweaponalert.asm:37-40` (`RoomShotSecure`): A Sala 57 consta na lista de 55 salas onde disparos sem silenciador **não** disparam o alarme geral de reforços militares.

### 2.2 Atributos Físicos e Dano
- **Pontos de Vida (HP)**:
  - Tabela `idxActorLife` em `data/actorspriteattr.asm:127-130`:
  - Entrada para o ator 33 (`ID_SHOT_GUNNER`, índice 32): `0x14` (20 pontos de vida).
- **Dano Causado por Armas do Jogador**:
  - Tabela `BulletDamage` em `data/weapondamage.asm:18`:
  - Entrada para o ator 33: `2` pontos de dano por tiro de pistola.
  - Portanto, são necessários **10 tiros de pistola** para derrotar o Shoot Gunner (\(20 / 2 = 10\)).
- **Dano de Contato com Projétil**:
  - Projétil de escopeta inflige dano severo ao jogador (calibrado em 8 pontos de vida).

### 2.3 Rotina e Máquina de Estados (`logic/actors/shotgunner.asm`)
O comportamento é regido por uma máquina de estados de 3 estágios (`ShotGunnerLogic`):

1. **INTRO (`ShotGunnerIntro`, status 0)**:
   - Delay inicial de refresh: `IntroDelay = 2 ticks`.
   - Discurso canônico (Texto 61, unskippable):
     `"I'M SHOOT GUNNER! NOBODY HAS EVER BEEN ABLE TO ESCAPE FROM HERE."`
   - Transita para `Status = 1` e toca música de chefe (`SetBossMusic`).

2. **ROLAGEM LATERAL (`ShotGunnerRoll`, status 1)**:
   - Desloca-se horizontalmente em direção ao jogador a **\(\pm 4.0\) px/tick** (`SpeedX`).
   - Duração máxima: `Wait = 0x0B` (11 ticks).
   - Animação de rolagem alternando sprites `5Eh, 5Fh, 60h, 5Fh` via `(ANIM_CNT & 6) >> 1`.
   - **Invulnerabilidade**: Durante a rolagem, `COLLISION_CFG = 0`, desativando a detecção de colisões com tiros e com o jogador.
   - Interrupção: Ao colidir contra uma parede sólida da grade (`ChkTileCollision`) ou expirar os 11 ticks, aciona `ShotGunnerStop`.

3. **DISPARO DE ESCOPETA (`SGunnerShotLogic`, status 2)**:
   - Ao parar: `SpeedX = 0`, `Wait = 0x2D` (45 ticks) e `COLLISION_CFG = 3` (vulnerável a tiros).
   - Checagem de cobertura do jogador: Se `PlayerY >= 166` e `PlayerX >= 170`, o jogador está atrás das caixas/barricadas e o chefe cessa fogo temporariamente.
   - Cadência de tiro: Dispara projétil de escopeta (`ID_SGUNNER_SHOT`) a cada **16 ticks** (`(ANIM_CNT & 0x0F) == 0`).
   - Ao zerar `Wait` (45 ticks): executa `SGunnerThinkDir`, reavalia a posição relativa do jogador no eixo X para selecionar a direção (\(\pm 4.0\) px/tick) e retorna ao estado de rolagem (`Status = 1`).

### 2.4 Balística da Escopeta (`ShotGunnerShot`)
- Projétil direcionado com vetor calculado em direção a Snake (`CalcShot2(0x90)`).
- Expansão visual e de hitbox em 4 estágios conforme `Wait` avança:
  - \(0 \le \text{Wait} < 7\): Frame 1, colisor reduzido (Shape 2).
  - \(7 \le \text{Wait} < 14\): Frame 2.
  - \(14 \le \text{Wait} < 21\): Frame 3.
  - \(\text{Wait} \ge 21\): Frame 4, colisor expandido (Shape 1).
- É destruído ao atingir paredes sólidas ou o jogador.

### 2.5 Resolução da Derrota (`DismissActor6` em `Banks0123.asm:12996-13003`)
- Quando `LIFE <= 0`:
  - Flag gravado: `ShotGunnerStat bit 0 = 1` (Dead).
  - Restauração da música de área (`SetAreaMusic`).
  - **Sem drop de item**: O chefe não dropa cartão ou chave diretamente na rotina de dismiss.

---

## 3. Implementação em Godot 4

- `godot/scripts/systems/shot_gunner.gd`: Classe `ShotGunner` encapsulando toda a lógica, estados, colisão lateral e renderização procedural autoral.
- `godot/scripts/systems/shot_gunner_bullet.gd`: Projétil `ShotGunnerBullet` com expansão de 4 frames, colisão e dano.
- `godot/scripts/scenes/sandbox_gameplay.gd`:
  - Detecção e spawn de `actor_type_id == 33` ao carregar a Sala 57.
  - Suporte à tecla de atalho `F` para teleportar diretamente à Sala 57 armado com Handgun.
  - Indicador de Boss Fight e barra de HP do chefe no cabeçalho do HUD.
  - Conexão de colisões entre balas do jogador e o chefe.
- `godot/tests/shot_gunner_test.gd`: Suíte com 7 testes headless cobrindo integridade mecânica.
