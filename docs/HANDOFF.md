# Transferência — Handoff Atualizado 2026-09-20

> **Regra de continuidade**: atualizar este arquivo a cada commit, antes de avançar
> para o próximo bloco de trabalho. Assim, qualquer nova sessão retoma exatamente
> do ponto correto, mesmo que o contexto da conversa anterior tenha se esgotado.

---

## 1. Leitura obrigatória antes de agir

1. `AGENTS.md` — regras permanentes compartilhadas
2. `GEMINI.md` — entrada do agente
3. Este documento (`docs/HANDOFF.md`)
4. Última entrada de `docs/progress.md`

Não avançar para nova etapa sem ter lido todos os quatro.

---

## 2. Objetivo do projeto

Engenharia reversa do Metal Gear MSX2 RC750, reimplementação fiel em Godot 4 e,
posteriormente, remake com arte própria e melhorias opcionais. Não existe jogo
completo ainda — apenas motor técnico e extração de dados.

---

## 3. Ambiente

| Item | Valor |
|------|-------|
| macOS | 15.7.7 build 24G720, x86_64, Macmini8,1 Intel i5-8500B |
| Python | 3.9.6, `/usr/bin/python3`, somente stdlib |
| Godot | 4.7.2.stable `/Applications/Godot.app/Contents/MacOS/Godot` |
| openMSX | 21.0 `/Applications/openMSX.app/Contents/MacOS/openmsx` |
| Git | 2.50.1 (Apple Git-155) |

---

## 4. ROM de trabalho

| Arquivo | Bytes | CRC32 | SHA-256 |
|---------|------:|-------|---------|
| `roms/Metal Gear - Konami (1987) [Does not work on Non Japanese systems] [RC-750] [1473].rom` | 131072 | BE84C94F | `254ffcd94d9ba2322c00df88b21b33b338e3238b90962820bbcaa2bb621e18cf` |

A ROM principal (128 KiB) é a candidata de trabalho. CRC diverge da referência
japonesa (FAFE1303), mas 18.176 bytes de salas/metatiles são idênticos e 9
segmentos (45.982 bytes) foram verificados byte-a-byte. **Nunca modificar a ROM.**

---

## 5. Estado atual do projeto (HEAD pós-Etapa 12d)

### Etapas concluídas e commitadas

| Commit | Etapa | Conteúdo |
|--------|-------|----------|
| `fe4c755` | 1–3 | Estrutura, extração Python, análise ROM |
| `d1210d2` | 4 | Captura openMSX, comparação VRAM, visualizador Godot |
| `008ee76` | 5 | Física discreta Snake, BoxColliderDat, Godot |
| `0b766a2` | 6 | RoomManager, 156 conexões, transições de sala |
| `c280c4a` | 7 | EnemyGuard, patrulha, linha de visão |
| `53d487b` | 8 | Combate: soco 8-ticks, stun 64-ticks, 3 socos/morte |
| `6abb608` | 9 | Portas, ItemBox, InventoryManager, trancas Card1 |
| `a7633eb` | 10 | Caminhões (lorries), salas internas, itens canônicos |
| `27a2815` | 11 | Extração em lote: 126 snapshots, `batch_snapshots.py` |
| `356ee1b` | 12-A | RoomManager prioriza stage5-batch; rooms 0-125 reais |
| `d559100` | 12-B | export_room_data.py gera room-NNN-actors.json (0-128) |
| `c061014` | 12-C | Spawn dinâmico de atores e itens no sandbox via RoomManager |
| `7a8e299` | 12b | Documentação 57 atores, tipos canônicos e portas automatizadas |
| `5215f17` | fix | Bloqueio de patrulha por colisão e correção de postura dos cães |
| `cda3bf6` | 12c | Extração e integração das 81 salas lorry e interiores (126-207) |
| `000b622` | 12d | Sistema de elevadores e conexões verticais (salas 240-250) |
| `f13d908` | fix | Física e trânsito canônico do elevador (ControlPlayerH/SprElevatorDat) |
| `062290f` | 13 | Sistema de Armas, Silenciador e Balística (WeaponSystem, Bullet, 1-shot kill) |
| `75586e0` | 14 | Portas e Transições Bidirecionais dos Interiores (Salas 129–207, PlayerInDoorDat) |
| `HEAD` | 15 | Sistema de Rádio Transceptor / Codec (RadioSystem, frequências BCD, UI militar, chamadas autoreply) |

### Dados extraídos disponíveis

| Diretório | Conteúdo |
|-----------|----------|
| `data/extracted/rc750-verified/` | `package.json` (19 MB): 235 salas, tilesets, doors, actors, items, paths |
| `data/extracted/stage4c-validated/` | 8 snapshots validados por emulador (rooms 0–3, 5, 121, 240) |
| `data/extracted/stage4b-validated/` | 6 snapshots validados por emulador |
| `data/extracted/stage4-validated/` | 4 snapshots (rooms 1, 5, 31, 127) |
| `data/extracted/stage5-batch/` | **126 snapshots rooms 0–125** + PNGs + **129 room-NNN-actors.json** (salas 0-128) |
| `data/extracted/stage5-lorries/` | **81 snapshots rooms 126–207** + PNGs + **81 room-NNN-actors.json** (salas 126-207) |
| `data/extracted/stage5-elevators/` | **11 snapshots rooms 240–250** + PNGs + **11 room-NNN-actors.json** (sala 240 validada contra emulador) |

### Cobertura de salas disponíveis

- Prédio 1 (salas 0–15): **16 snapshots** com atores, portas e colisão reais
- Prédio 2 (salas 16–63): **48 snapshots** com atores, portas e colisão reais
- Prédio 3 (salas 64–125): **62 snapshots** com atores, portas e colisão reais
- Caminhões e Interiores (salas 126–207): **81 snapshots** reais com atores e portas (sala 155 indefinida na ROM)
- Elevadores (salas 240–250): **11 snapshots** com atores, portas dummy e colisão reais
- Total de salas reais com background, colisão e atores: **218 salas** (0 a 207 e 240 a 250)!

### Estado do Godot

- `RadioSystem` (`godot/scripts/systems/radio_system.gd`): frequências canônicas BCD da ROM (Big Boss 120.85/120.13, Schneider 120.79/120.26, Diane 120.33/120.91, Jennifer 120.48), sintonia BCD, envio SEND ("THIS IS SOLID SNAKE..."), banco canônico de diálogos de salas (0, 1, 4, 5, 20, 28, 29, 30, 31, 37, 50, 53, 54, 58, 67, 138), chamadas automáticas de entrada (`check_incoming_call`), autotune e 12 LEDs de sinal.
- `RadioDialog` (`godot/scripts/systems/radio_dialog.gd`): interface visual militar autêntica MSX2 com visor numérico grande, retratos em pixel art (Snake, Big Boss, Schneider, Diane), typewriter e controle via teclado (atalhos T / F4). Congelamento total de física durante comunicação.
- `RoomDoor` (`godot/scripts/systems/door.gd`): suporte canônico a `PlayerInDoorDat` (5 renders) e emparelhamento por `IdDoorEnter` para trânsito bidirecional perfeito entre corredores e depósitos/arsenais.
- `WeaponSystem` (`godot/scripts/systems/weapon_system.gd`): arsenal com Handgun, SMG e Grenade Launcher, contadores de munição respeitando limite de Rank 1 (50 balas) e suporte a silenciador.
- `Bullet` (`godot/scripts/systems/bullet.gd`): balística discreta a 6 px/tick, alcance de 16 ticks (96 px), colisão com grid de tiles e letalidade de 1 tiro fatal em soldados comuns.
- `EnemyGuard`: suporte a guardas atiradores (`ID_SHOOTER` = 13, `ID_GUARD_SILENCER` = 57) e disparo de projéteis em perseguição/alerta.
- Acústica do Silenciador: disparo sem silenciador dispara alerta da sala (exceto nas 55 salas seguras `ROOMS_SHOT_SECURE`); disparo com silenciador é silencioso.
- Sala 150: evento de drop do silenciador ao derrotar os 4 guardas silenciadores em (36, 98).
- `ElevatorSystem` & `ElevatorCabin`: limites e paradas dos 11 elevadores, movimentação vertical a 1 px/tick.
- `RoomManager`: carrega snapshots e metadados de atores de `stage5-batch/`, `stage5-lorries/` e `stage5-elevators/`.
- Validação contínua: `python3 tools/validate.py` executa 46 testes Python + 13 suítes Godot (100% PASS).

---

## 6. Próximas opções de trabalho

A Etapa 15 está **concluída e validada**. Candidatos para a próxima etapa:

1. **Câmeras de Vigilância e Feixes Infravermelhos (Infrared Lasers / Surveillance Cameras)**:
   - Câmeras com varredura angular e cone de visão.
   - Feixes laser infravermelhos acionando alarme ao contato, detectáveis com Binóculos/Óculos Infravermelhos (Goggles).

2. **Sistema de Alarme Global, Níveis de Alerta e Reforços**:
   - Estados de alerta (Normal, Alerta, Evasão), spawn de reforços e sirene.

3. **Boss Fights e Atores Especiais**:
   - Shoot Gunner (Sala 132), Machine Gun Kid (Sala 145), Arnold (Sala 151).

---

## 7. Arquitetura de arquivos relevantes

```
projeto-game/
├── AGENTS.md, GEMINI.md           ← Ler primeiro
├── docs/
│   ├── HANDOFF.md                 ← Este arquivo
│   └── progress.md                ← Histórico de entregas
├── tools/
│   ├── validate.py                ← Comando único de validação
│   ├── extractors/
│   │   ├── extract.py             ← Extração da ROM → package.json
│   │   ├── batch_snapshots.py     ← Lote: package.json → room-NNN.json (Etapa 11)
│   │   └── export_room_data.py    ← A CRIAR (Etapa 12-B)
│   └── emulation/
│       ├── capture.py / capture.tcl ← Captura openMSX
│       └── compare.py             ← Comparação VRAM
├── data/
│   ├── extracted/
│   │   ├── rc750-verified/        ← package.json (fonte de verdade)
│   │   ├── stage5-batch/          ← 126 snapshots rooms 0–125 (Etapa 11)
│   │   └── stage4c-validated/     ← 8 snapshots validados por emulador
│   └── schemas/room-snapshot.schema.json
├── godot/
│   ├── scripts/
│   │   ├── systems/
│   │   │   ├── room_snapshot.gd   ← Carrega/valida JSON
│   │   │   ├── room_manager.gd    ← Conexões + load_room_snapshot()
│   │   │   ├── player_controller.gd
│   │   │   ├── enemy_guard.gd
│   │   │   ├── door.gd
│   │   │   └── item_box.gd, inventory.gd
│   │   └── scenes/
│   │       └── sandbox_gameplay.gd ← Cena jogável principal
│   └── tests/                     ← 9 suites Godot headless
└── tests/                         ← Testes Python (unittest)
    ├── test_extractors.py
    ├── test_emulation.py
    └── test_reverse_engineering.py
```

---

## 8. Comandos essenciais

```bash
# Validação completa (obrigatória antes de cada commit)
python3 tools/validate.py

# Testes Python apenas
python3 -m unittest discover -s tests -v

# Testar sala específica no Godot
/Applications/Godot.app/Contents/MacOS/Godot --headless --path godot \
    --quit-after 30 "res://scenes/sandbox_gameplay.tscn" -- --room 5

# Gerar snapshot de uma sala (batch)
python3 tools/extractors/batch_snapshots.py \
    --package data/extracted/rc750-verified/package.json \
    --output data/extracted/stage5-batch-NEW \
    --rooms 0-125

# Verificar HEAD Git
git log --oneline -5
git status --short
git diff --cached --stat
```

---

## 9. Regras de commit

- Executar `python3 tools/validate.py` antes de cada commit (100% PASS obrigatório)
- Revisar `git diff --cached` para confirmar ausência de ROM/assets protegidos
- Não usar `git add -f`
- **Atualizar este HANDOFF.md a cada commit**

---

## 10. Descobertas ROM confirmadas (resumo)

- 251 entradas de sala, 235 decodificadas; layouts 256×192 px (8×6 metatiles de 4×4 tiles de 8×8 px)
- 7 perfis de colisão; tile IDs 0/1/2 = zero-fill pré-carga (confirmado por emulador)
- Conexões de borda: salas 0–125 usam `RoomConnections` (156 entradas); salas 126–207 são lorries/isoladas
- Salas 208–227 e 241–250 usam tabela deslocada
- Atores: `data/actorsinrooms.asm`; itens: `data/itemsinrooms.asm` (salas 122–217)
- Portas: `data/doors.asm`; caminhos de patrulha: `data/paths.asm`
- Referência: `external/MetalGear` revisão `30d1b940bede10fdabbaf9767ad4f0ad8dd33291`

---

## 11. Hipóteses não confirmadas

- Binding exato de patrol paths por ator/tipo em runtime
- Colisão dinâmica (paredes destruídas, estados persistentes)
- Paletas dinâmicas (modo noite, goggles)
- Identidade integral da ROM com a versão japonesa de referência
