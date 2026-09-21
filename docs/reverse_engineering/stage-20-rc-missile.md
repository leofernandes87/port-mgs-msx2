# Engenharia Reversa — Etapa 20: Míssil Teleguiado (Remote-Controlled Missile — WEAPON_MISSILE)

## 1. Evidências da ROM MSX2 RC750 e Desmontagem

A rotina de controle e disparo do míssil teleguiado foi revertida de `logic/weapon/missile.asm`, `logic/weaponuse.asm` e `logic/damagetoenemy.asm`.

### 1.1 Offset da Tabela de Velocidades (`MissileIniSpeed`)
* **Offset na ROM**: `0x48DE` (Banco 2).
* **Bytes**: `FC 00 04 00 00 FC 00 04`.
* **Mapeamento Direcional**:
  * Direção 1 (UP): `speedY = -4`, `speedX = 0`
  * Direção 2 (DOWN): `speedY = +4`, `speedX = 0`
  * Direção 3 (LEFT): `speedY = 0`, `speedX = -4`
  * Direção 4 (RIGHT): `speedY = 0`, `speedX = +4`
* Velocidade escalar constante: **4 pixels por tick** (~240 px/s a 60 ticks/s).

### 1.2 Regra de Ouro: Tiro Único Simultâneo (`PlayerShotsList`)
Em `missile.asm:23-25`:
```asm
ld a, (PlayerShotsList)
and a
ret nz ; Only one missile each time
```
Apenas 1 míssil pode existir em voo por vez. Enquanto ativo, o jogador não pode disparar outro.

### 1.3 Supressão do Controle do Jogador (`Banks0123.asm:8468-8470`)
```asm
NormalCtrl:
    ld a, (PlayerShotsList)
    cp 7 ; ID 7 = MISSILE
    ret z ; Too many shots / missile active. Ignore player controls.
```
Quando o míssil está em voo (`PlayerShotsList == 7`), a rotina `NormalCtrl` do Snake retorna imediatamente (`ret z`). Isso congela a movimentação dos pés do Snake, transferindo as entradas direcionais (WASD / Setas) para a rotina `ControlMissile`.

### 1.4 Manobrabilidade / Controle Remoto em Tempo Real (`missile.asm:112-133`)
A rotina `ControlMissile` lê `ControlsTrigger` a cada tick de física:
* Bit 0: UP
* Bit 1: DOWN
* Bit 2: LEFT
* Bit 3: RIGHT
Ao detectar mudança direcional, atualiza imediatamente a velocidade e o sprite do míssil (`SetMissileSpr`).

### 1.5 Colisões e Limites de Tela (`weaponuse.asm:365-375`)
* **Colisão com Paredes (`ChkShotCollision`)**:
  * Testa o grid de blocos sólidos 32×24. Caso atinja uma parede sólida, transita para `MissileExplode`.
* **Limites de Tela (`ChkShotBoundaries`)**:
  * $X \in [9, 248]$, $Y \in [0, 184]$. Se sair destes limites, o míssil é removido (`RemoveShot`) sem dano.

### 1.6 Dano e Explosão (`weapondamage.asm:58` e `plasticbomb.asm:144-164`)
* **Dano (`MissileDamage`)**: **5 pontos de dano** por impacto (suficiente para eliminar soldados com 2 ou 3 HP com 1 único míssil).
* **Explosão Média (`MedExplosionLogic`)**:
  * Temporizador de **15 ticks** (`0x0F`).
  * 3 fases visuais expansivas (frames 1, 2 e 3).
  * Ao zerar o timer, `RemoveShot` limpa `PlayerShotsList` e os controles do Snake são imediatamente devolvidos.

### 1.7 Capacidade de Munição por Patente (`MaxAmmoLv1..4` em `0x51D6`)
Offset `0x51D6` na ROM:
* **Rank ★1**: 5 mísseis
* **Rank ★2**: 10 mísseis
* **Rank ★3**: 15 mísseis
* **Rank ★4**: 20 mísseis

---

## 2. Dados Extraídos
Exportados para `data/extracted/missile_weapon.json` e validados pelo schema `data/schemas/missile_weapon.schema.json`.
Localização primária da arma: **Sala 149** em `(160, 32)` com 5 mísseis iniciais.
