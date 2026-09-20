# Etapa 8 — Combate Corpo a Corpo (Soco), Perseguição em Alerta e Vida/Dano de Snake

## 1. Visão Geral e Contexto
Após o estabelecimento da navegação por salas e a patrulha/visão dos guardas (Etapas 6 e 7), a **Etapa 8** implementa o ciclo completo de combate corpo a corpo, perseguição e sistema de vida/dano baseado na engenharia reversa do código Z80 do Metal Gear MSX2 RC750.

---

## 2. Reversão do Código Z80 da ROM Original

### 2.1 Soco de Snake (`chkPunch` em `Banks0123.asm:8934`)
```z80
chkPunch:
    ld      a, (ControlsTrigger)    ; Bit 5 = Fire2 / Tecla M / Espaço
    and     20h
    ret     z                       ; Tecla não pressionada

    ld      a, (PlayerAnimation)    ; 0=Normal, 1=Punch, 2=Water, 4=Deep water, 7=Box
    cp      2                       ; Na água?
    ret     z
    cp      7                       ; Dentro da caixa de papelão?
    ret     z

    ld      a, 8
    ld      (PunchCnt), a           ; Duração do soco = 8 ticks
    ld      a, 1
    ld      (PlayerAnimation), a    ; Ativa animação de soco
    ld      (PlayerControlMod), a   ; Imobiliza movimentação (Speed = 0)
    ret
```

### 2.2 Caixas de Impacto Direcional do Soco (`logic/punchenemy.asm:46-87`)
O soco de Snake possui alcance e semidimensões específicos dependendo da direção que ele está olhando:
```z80
PunchUpDat:     dw 0C0Ch ; Offset Y = +12, Raio Y = 12, Offset X = 0, Raio X = 12
PunchLeftDat:   dw 0C00h ; Offset Y = 0, Raio Y = 12, Offset X = +12, Raio X = 12
PunchDownDat:   dw 0CF4h ; Offset Y = -12, Raio Y = 12, Offset X = 0, Raio X = 12
PunchRightDat:  dw 0C00h ; Offset Y = 0, Raio Y = 12, Offset X = -12, Raio X = 12
```
A verificação é realizada via `ChkArea`:
- $|EnemyY + OffsetY - PlayerY| < RaioY$
- $|EnemyX + OffsetX - PlayerX| < RaioX$

### 2.3 Atordoamento e Derrota do Guarda (`Banks0123.asm:12815`)
```z80
ChkKillPunching:
    inc     (ix+ACTOR.PunchesCnt)   ; Incrementa contador de socos recebidos
    ld      a, (ix+ACTOR.PunchesCnt)
    cp      3
    jr      z, ChkDropItem          ; Com 3 socos, o guarda morre!

    ld      (ix+ACTOR.StunnedCnt), 40h ; 0x40 = 64 ticks de atordoamento
    ret
```
- Ao ser atingido pelo 1º ou 2º soco: o guarda é atordoado por 64 ticks ($0x40$), fica imóvel e não ataca nem acumula novo soco antes de recuperar a consciência.
- Ao ser atingido pelo 3º soco: o guarda morre (`is_dead = true`), cai no chão e para de agir.

### 2.4 Vida Inicial e Níveis de Snake (`Banks0123.asm:9672`)
```z80
UpdateLevels:
    ld      a, 24                   ; Rank 1 (início do jogo) = 24 pontos
    ld      (MaxLife), a
    ld      (Life), a
```
- A barra de vida inicial de Snake possui $24$ pontos de energia.

### 2.5 Dano por Contato Físico e Invulnerabilidade (`logic/touchenemy.asm:137-189`)
- Tabela `ActorTouchDamage` (`data/shapes.asm:36`):
  - `ID_GUARD_SLOW = 4` $\rightarrow$ **$2$ pontos** de dano por hit.
  - `ID_GUARD_MEDIUM = 5` $\rightarrow$ **$2$ pontos** de dano por hit.
- Timer de invulnerabilidade (`DamageDelayTimer`):
  - Definido para **$32$ ticks** ($0x20$).
  - Impede que Snake sofra dano contínuo quadro a quadro ao colidir com o soldado, concedendo a janela clássica para reação e fuga enquanto pisca.

---

## 3. Implementação no Godot 4

1. **[`godot/scripts/systems/player.gd`](file:///Users/leofernandes/Desktop/WorkSpace/projeto-game/godot/scripts/systems/player.gd)**:
   - Variáveis `life = 24`, `max_life = 24`, `invulnerable_timer`, `punch_timer`, `is_punching`.
   - Método `punch()`: inicia $8$ ticks de imobilização e punho estendido.
   - Método `apply_damage(amount)`: desconta vida e ativa $32$ ticks de invulnerabilidade.
   - Renderização: punho direcional no soco e piscar intermitente no dano.
2. **[`godot/scripts/systems/enemy.gd`](file:///Users/leofernandes/Desktop/WorkSpace/projeto-game/godot/scripts/systems/enemy.gd)**:
   - Variáveis `punches_received`, `stunned_timer`, `is_dead`.
   - Método `check_punched(player_pos, player_dir)` com as caixas exatas da ROM.
   - Método `receive_punch()` com atordoamento de $64$ ticks e morte ao 3º soco.
   - Rotina `_chase_player()`: perseguição em alerta contornando obstáculos no grid.
   - Dano por contato de $2$ pontos via `player.apply_damage(touch_damage)`.
   - Renderização: estrelas giratórias durante atordoamento e silhueta caída na derrota.
3. **[`godot/scripts/scenes/sandbox_gameplay.gd`](file:///Users/leofernandes/Desktop/WorkSpace/projeto-game/godot/scripts/scenes/sandbox_gameplay.gd)**:
   - Teclas `KEY_SPACE` e `KEY_J` disparam o soco.
   - Exibição da barra de vida gráfica (`VIDA: [■■■■■■■■] 24/24`) e contador de guardas derrotados.

---

## 4. Validação Automatizada
- Teste: `godot/tests/combat_and_health_test.gd`.
- Integrado e aprovado em `tools/validate.py` (`godot-combat-health: PASS`).
