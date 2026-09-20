# Etapa 17 — Máquina de Estados de Alerta Global, Evasão e Reforços Militares

## 1. Visão Geral e Contexto
No Metal Gear original MSX2 (RC750), a segurança e vigilância de Outer Heaven é governada por uma máquina de estados de alerta com 3 modos distintos: **NORMAL** (patrulhas calmas e vigilância passiva), **ALERTA** (sirene, perseguição ativa, disparos e respawn contínuo de soldados de reforço pelas bordas da tela) e **EVASÃO** (temporizador regressivo de busca quando Snake sai da linha de visão dos inimigos).

A **Etapa 17** implementa esse ciclo com fidelidade matemática e lógica às rotinas Z80 da ROM original.

---

## 2. Reversão do Código Z80 da ROM Original

### 2.1 Variáveis e Estados Globais (`Variables.asm:272-285`)
- `AlertMode`: modo de alerta atual (0 = Normal, 1 = Alerta, 2 = Evasão).
- `RoomAlert`: sala onde o alerta foi iniciado.
- `AlertRespawnTimer`: temporizador de atraso entre o surgimento de reforços.
- `NumRespawnGuards`: cota total de soldados de reforço a serem gerados.
- `RedAlertFlag`: flag ativada quando o alarme é acionado por câmeras ou feixes laser.

### 2.2 Gatilhos e Cotas de Reforço (`logic/setalert.asm:11-40`)
```z80
SetAlertModeRespawn:
    ld      (AlertRespawnTimer), a

SetAlertMode:
    ld      a, 1
    ld      (AlertMode), a
    ld      (AlertModeCopy), a

    ld      a, (Room)
    ld      (RoomAlert), a          ; Sala de origem do alerta
    cp      216                     ; 4º Caminhão no deserto
    ld      a, 0                    ; Não spawna reforços neste caminhão
    jr      z, SetAlertMode4

    ld      hl, Card8Taken
    ld      b, 8                    ; 8 cartões

SetAlertMode2:
    bit     0, (hl)                 ; Cartão coletado?
    jr      nz, SetAlertMode3
    dec     hl
    djnz    SetAlertMode2

SetAlertMode3:
    ld      a, b
    add     a, 3                    ; Cota mínima de reforços = Cartão + 3

SetAlertMode4:
    ld      (NumRespawnGuards), a
```

A cota canônica de reforços militares é calculada diretamente a partir do cartão de maior nível que Snake possui: `CardLevel + 3`. Um jogador sem cartões enfrentará 3 soldados de reforço; com o Cartão 8, enfrentará até 11 soldados.

### 2.3 Tabela Canônica de Respawn (`RespawnInfo` em `0xC445` no Banco 6 / `data/respawninfo.asm`)
A ROM define uma tabela contínua de 189 salas (0 a 188), com 3 bytes por sala:
- **Byte 0**: ID do soldado (`10` = `ID_GUARD_ALERT`, `11` = `ID_GUARD_REDALERT`, `22` = `ID_JETPACK`, `0` = sem respawn).
- **Byte 1 e 2**: Posições de entrada alternadas 1 e 2:
  - $Y = \text{loc} \ \& \ \text{0xF0}$
  - $X = (\text{loc} \ \& \ \text{0x0F}) \times 16$

Coordenadas reais de spawn conferidas nas primeiras salas:
- Sala 0: ID 10, Ponto 1 $(144, 16)$, Ponto 2 $(240, 160)$
- Sala 1: ID 10, Ponto 1 $(64, 16)$, Ponto 2 $(240, 144)$
- Sala 2: ID 10, Ponto 1 $(192, 80)$, Ponto 2 $(16, 160)$
- Sala 3: ID 11, Ponto 1 $(48, 240)$, Ponto 2 $(160, 240)$

### 2.4 Cadência de Reforços e Limites na Sala (`Banks0123.asm:6559-6628`)
- Intervalo entre spawns: ~20 a 35 ticks (`add a, 14h` -> base de 20 ticks, intervalo canônico de 24 ticks).
- Limite simultâneo: máximo de 3 soldados na tela para Red Alert/Jetpack, ou 4 para guardas de alerta comuns.

### 2.5 Cancelamento e Fuga (`ChkAlarmEnd` e `StopAlert` em `Banks0123.asm:6635-6713`)
- **Elevadores**: entrar em qualquer sala de elevador (salas $\ge 240 / \text{0xF0h}$) executa `StopAlert` imediatamente, restaurando o estado `NORMAL`.
- **Evasão**: quando nenhum soldado ou câmera ativa tiver linha de visão direta sobre Snake (ou quando Snake utilizar a Caixa de Papelão imóvel), o alarme transita para **EVASÃO** com temporizador regressivo de 99 ticks.
- **Re-alerta**: se qualquer guarda avistar Snake durante a contagem de evasão, o temporizador é cancelado e o estado volta imediatamente para **ALERTA**.
- **Término**: ao esgotar o cronômetro sem re-detecção, `StopAlert` encerra o alarme e os soldados restantes voltam à patrulha calma.

---

## 3. Implementação no Motor Godot 4

1. **Extrator Reproduzível (`tools/extractors/extract_respawn_info.py`)**:
   - Extração byte-a-byte dos 567 bytes no offset `0xC445` da ROM original para `data/extracted/respawn_info.json`.
   - Schema neutro em `data/schemas/respawn-info.schema.json`.
2. **Subsistema de Alerta (`AlertSystem` em `godot/scripts/systems/alert_system.gd`)**:
   - Máquina de estados com `NORMAL`, `ALERT` e `EVASION`.
   - Controle de cotas de reforço (`num_respawn_guards`), temporizadores e alternância de spawn points.
   - Sinais `state_changed`, `reinforcement_requested` e `alert_cleared`.
3. **Soldados de Alerta (`EnemyGuard` em `enemy.gd`)**:
   - Suporte aos tipos de alerta da ROM (`ID_GUARD_ALERT = 10` e `ID_GUARD_REDALERT = 11`) com velocidade Fast ($1.5$ px/tick).
   - Métodos `transform_to_alert_guard()` e `reset_to_patrol()`.
4. **Integração no Sandbox (`sandbox_gameplay.gd`)**:
   - Spawning dinâmico de reforços nas bordas da sala em tempo real.
   - HUD dinâmico:
     - `ALERTA! [!] (Reforços: N)` em vermelho vibrante.
     - `EVASÃO [NN]` em laranja com contagem regressiva.
     - `NORMAL` em branco neutro.
   - Furtividade da Caixa de Papelão (`ITEM_BOX`): Snake imóvel na caixa não é avistado por soldados nem câmeras, forçando transição para evasão.
