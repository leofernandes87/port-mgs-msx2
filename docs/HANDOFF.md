# Transferência — Handoff Atualizado 2026-09-21

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

## 5. Estado atual do projeto (Tag v0.1.0 — 20 Etapas Concluídas)

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
| `5e3b34d` | 15 | Sistema de Rádio Transceptor / Codec (RadioSystem, frequências BCD, UI militar, chamadas autoreply) |
| `3bb9410` | 16 | Câmeras de Vigilância e Feixes Laser Infravermelhos (SecurityCamera, LaserSystem, Goggles) |
| `1aef8a2` | fix | Sandbox: spawn seguro contra colisão no reset e toggle de vida infinita (God Mode) |
| `a43f6f7` | 17 | Máquina de Estados de Alerta Global, Evasão e Reforços Militares (AlertSystem, RespawnInfo) |
| `c3c0803` | 18 | Boss Shoot Gunner, Patentes e Reféns, Menus de Inventário/Armas, Controles Modernos e Ajustes de Portas |
| `6572503` | Doors | Desobstrução de vãos de portas, eliminação de blocos flutuantes e extração de item rooms 129-207 |
| `2fda07a` | Init | Inicialização canônica na Sala 121 (infiltração na água MSX2) |
| `4981fcc` | Spawn | Posicionamento de Snake em terra firme transitável no cais da Sala 121 (128.0, 80.0) |
| `d185e76` | Combat | Game Over punitivo clássico MSX2 com bloqueio imediato de inputs e reset absoluto de estado |
| `d3c8b64` | 19 | Perigo Ambiental de Gás Tóxico e Máscara de Gás (GasHazardSystem, GasCloud, 9 salas canônicas) |
| `8cc41f5` | 20 | Míssil Teleguiado / Remote-Controlled Missile (RemoteMissile, WeaponSystem, esterçamento e dano 5 HP) |
| `d7048f1` | fix | Transição contínua vertical de elevadores multi-telas (Salas 241 <-> 242, RoomConnections) |
| `b27a2c5` | docs | Atualização de documentação e preparação de release |
| `v0.1.0` | **Release** | **Primeiro Marco Oficial Consolidado (20 Etapas, 218 salas, 100% PASS)** |
| `562699b` | 21 | Evento de Captura na Sala 8, Cela 211, Parede Oca e Restituição (CaptureSystem, ItemBag, 4 socos) |
| `85255a2` | fix | Correção de socos na cela 211, abertura física de 24 tiles e bolsa BAG |
| `v0.1.1` | **Release** | **Tag do Marco da Prisão e Restituição (Etapa 21)** |
| `6a6d1c8` | 22 | Pisos Eletrificados & Painéis de Força (ElectrifiedFloorSystem, PowerPanel, Míssil vs Painel) |


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
| `data/extracted/stage5-item-rooms/` | Snapshots das salas de itens e celas (incluindo salas 211 e 212 da prisão) |
| `data/extracted/respawn_info.json` | **189 salas (0-188)** extraídas da ROM (0xC445) com IDs e pontos de spawn de reforços |
| `data/extracted/gas_hazard.json` | **9 salas canônicas com gás tóxico** extraídas da ROM (0x4C79) com danos e temporizadores |
| `data/extracted/missile_weapon.json` | **Constantes do Míssil Teleguiado** extraídas da ROM (velocidade 4 px/tick, 15 ticks explosão, limites por rank) |
| `data/extracted/capture_prison.json` | **Dados canônicos do evento de captura e prisão** (Door 103 0x1EE8E, ItemBag 0xDB0D, cela 211, restituição 212) |
| `data/extracted/electrified_floor.json` | **5 salas canônicas com piso eletrificado e painéis** extraídas da ROM (0x4C0D, dano 2 HP, delay 8 ticks) |


### Cobertura de salas disponíveis

- Prédio 1 (salas 0–15): **16 snapshots** com atores, portas e colisão reais
- Prédio 2 (salas 16–63): **48 snapshots** com atores, portas e colisão reais
- Prédio 3 (salas 64–125): **62 snapshots** com atores, portas e colisão reais
- Caminhões e Interiores (salas 126–207): **81 snapshots** reais com atores e portas (sala 155 indefinida na ROM)
- Cela e Prisão (salas 211 e 212): **2 snapshots** reais com quebra de parede e bolsa de equipamentos
- Elevadores (salas 240–250): **11 snapshots** com atores, portas dummy e colisão reais
- Total de salas reais com background, colisão e atores: **220 salas** (0 a 207, 211, 212 e 240 a 250)!

### Estado do Godot

- `CaptureSystem` (`godot/scripts/systems/capture_system.gd`): gerenciamento do ciclo canônico de captura e prisão da Sala 8 (`logic/common.asm:26-47`). Detecta emboscada em $X \in [192, 208]$, confisca e salva itens/armas/munição em vetores de backup, força transição para as coordenadas internas da cela na Sala 211 (`(128.0, 80.0)`), restringe ações do jogador exclusivamente ao soco básico, usa a porta 103 com bloco original de tiles e resistência de 40 iterações válidas de soco para abrir fuga rumo à Sala 212; a parede sul dessa sala (porta 12) tem resistência independente de 40 iterações e libera a passagem à Sala 54 (correção em `docs/reverse_engineering/prison-wall.md`; substitui a hipótese anterior de quatro socos), e restaura integralmente o inventário ao tocar na bolsa de equipamentos (`ITEM_BAG`).
- `RemoteMissile` (`godot/scripts/systems/remote_missile.gd`): míssil teleguiado com controle em tempo real nas 4 direções (`steer`), velocidade canônica de 4 px/tick (`MissileIniSpeed`), teste de colisão contra matriz de tiles 32×24, limites de tela (`ChkShotBoundaries`), animação de explosão de 15 ticks (`0x0F`), dano de 5 HP instantâneo em guardas e chefes, supressão total da movimentação do Snake enquanto o míssil estiver ativo (`Banks0123.asm:8468`), e recarga de +5 mísseis por caixa de munição.
- `GasHazardSystem` (`godot/scripts/systems/gas_hazard_system.gd`): gerenciamento de perigo de gás tóxico e proteção por máscara de gás (`ITEM_GAS_MASK`), 9 salas canônicas da ROM (`GasRooms`: 29, 94, 96, 97, 98, 100, 101, 112, 114), dano contínuo de 2 HP a cada 16 ticks (`0x10`) desprotegido, 100% de anulação quando equipada e sinais de dano/proteção.
- `GasCloud` (`godot/scripts/systems/gas_cloud.gd`): ator de nuvem de gás (ID_GAS = 8, `gas.asm`), ciclo visual de 32 ticks visíveis e intervalo oculto aleatório, avanço a cada 8 ticks e cores MSX autênticas.
- `RankSystem` (`godot/scripts/systems/rank_system.gd`): gerenciamento de patentes militares (Class / Ranks ★1 a ★4), cotas de 4 reféns por estrela, limites progressivos de vida (24, 32, 40, 48 HP), limites progressivos de munição (Handgun/SMG 50 a 300, Grenade Launcher 15 a 90) e rações (3 a 12), cura total na promoção e penalidade `DowngradeRank` por baixa de refém.
- `Prisoner` (`godot/scripts/systems/prisoner.gd`): entidade autêntica de refém com renderização procedural fiel à paleta MSX2 (amarrado vs libertado/agradecendo), tipos canônicos (ID 49 Comum, 50 Ellen Madnar, 51 Grey Fox, 52 Pettrovich Madnar, 55 Falso Madnar), catálogo completo de 23 diálogos da ROM, banner de diálogo e detecção de tiros/socos.
- `ShotGunner` (`godot/scripts/systems/shot_gunner.gd`): primeiro chefe autêntico do jogo (`ID_SHOT_GUNNER = 33`, Sala 57), máquina de 3 estados (INTRO, ROLAGEM, TIRO), HP inicial de 20 (`idxActorLife[32]`), invulnerabilidade durante rolagem a 4 px/tick, disparo de escopeta a cada 16 ticks ao parar, verificação de abrigo atrás das caixas e derrota limpa (`ShotGunnerStat bit0 = 1`).
- `ShotGunnerBullet` (`godot/scripts/systems/shot_gunner_bullet.gd`): projétil de escopeta `ID_SGUNNER_SHOT` (43) com velocidade orientada a Snake, expansão em 4 frames de animação e colisão progressiva de shape, infligindo 8 pontos de dano.
- `AlertSystem` (`godot/scripts/systems/alert_system.gd`): máquina de estados de 3 modos (NORMAL, ALERT, EVASION), cotas de reforço baseadas no nível de cartão de Snake (`NumRespawnGuards = CardLevel + 3`), temporizador de spawn a cada 24 ticks, tabela `RespawnInfo` da ROM, temporizador regressivo de evasão de 99 ticks, reativação imediata ao ser visto e cancelamento por elevadores.
- `SecurityCamera` (`godot/scripts/systems/security_camera.gd`): ID 6 da ROM, orientações canônicas por sala (`RoomCamTypes`), patrulha a 1 px/tick em waypoints, visada direcional com offset focal (`CameraDrawOffsets`), oclusão por obstáculos sólidos da grade 32×24, furtividade na caixa de papelão e alerta com LED piscante sem ícone '!'.
- `LaserSystem` (`godot/scripts/systems/laser_system.gd`): ID 35 da ROM, tabelas exatas de `laserconfig.asm` (Salas 24, 25 e 72), teste de toque físico `ChkTouchLaser`, alternância dinâmica da Sala 72 (5 sequências a cada 192 ticks) e visibilidade condicionada aos Óculos Infravermelhos (`ITEM_GOGGLES`, item ID 12).
- `RadioSystem` (`godot/scripts/systems/radio_system.gd`): frequências canônicas BCD da ROM (Big Boss 120.85/120.13, Schneider 120.79/120.26, Diane 120.33/120.91, Jennifer 120.48), sintonia BCD, envio SEND ("THIS IS SOLID SNAKE..."), banco canônico de diálogos de salas (0, 1, 4, 5, 20, 28, 29, 30, 31, 37, 50, 53, 54, 58, 67, 138), chamadas automáticas de entrada (`check_incoming_call`), autotune e 12 LEDs de sinal.
- `RadioDialog` (`godot/scripts/systems/radio_dialog.gd`): interface visual militar autêntica MSX2 com visor numérico grande, retratos em pixel art (Snake, Big Boss, Schneider, Diane), typewriter e controle via teclado (atalhos T / F4). Congelamento total de física durante comunicação.
- `RoomDoor` (`godot/scripts/systems/door.gd`): suporte canônico a `PlayerInDoorDat` (5 renders) e emparelhamento por `IdDoorEnter` para trânsito bidirecional perfeito entre corredores e depósitos/arsenais.
- `WeaponSystem` (`godot/scripts/systems/weapon_system.gd`): arsenal com Handgun, SMG e Grenade Launcher, contadores de munição respeitando limite de Rank 1 a 4 e suporte a silenciador.
- `Bullet` (`godot/scripts/systems/bullet.gd`): balística discreta a 6 px/tick, alcance de 16 ticks (96 px), colisão com grid de tiles e letalidade de 1 tiro fatal em soldados comuns.
- `EnemyGuard`: suporte a guardas atiradores (`ID_SHOOTER` = 13, `ID_GUARD_SILENCER` = 57, `ID_GUARD_REDALERT` = 11) e disparo de projéteis em perseguição/alerta.
- Acústica do Silenciador: disparo sem silenciador dispara alerta da sala (exceto nas 55 salas seguras `ROOMS_SHOT_SECURE`); disparo com silenciador é silencioso.
- Sala 150: evento de drop do silenciador ao derrotar os 4 guardas silenciadores em (36, 98).
- `ElevatorSystem` & `ElevatorCabin`: limites e paradas dos 11 elevadores, movimentação vertical a 1 px/tick.
- `RoomManager`: carrega snapshots e metadados de atores de `stage5-batch/`, `stage5-lorries/`, `stage5-elevators/` e `stage5-item-rooms/` (incluindo salas de itens e celas da prisão).
- Sistema de Portas & Desobstrução de Vãos (`door.gd`): suporte a `clearance_tile_indices` para eliminação de blocos de colisão flutuantes em vãos abertos, triggers laterais (WEST/EAST) alinhados ao chão, saída limpa de caminhões (`LORRY_EXIT`) e bloqueio rigoroso de saídas de borda por portas trancadas (ex: Sala 7 -> Sala 11 requer CARD4).
- Inicialização Canônica na Sala 121: `sandbox_gameplay.tscn` configurada como cena principal em `project.godot`; Snake inicia na Sala 121 em terra firme/cais navegável após a infiltração nas coordenadas `(128.0, 80.0)` com direção `UP` e `CIGARETTES` equipados.
- Game Over Punitivo MSX2 & Reset Absoluto de Estado: morte com vida zerada bloqueia imediatamente ações do jogador (`is_dead`, `can_control = false`), limpa totalmente inventário, armas, cartões, rank e alerta, recarregando a cena de forma segura na Sala 121 com vida total e controles liberados.
- Validação contínua: `python3 tools/validate.py` executa 48 testes Python + 20 suítes Godot (100% PASS).

---

## 6. Próximas opções de trabalho

Marco `v0.1.0` atingido com 20 etapas concluídas e validadas. Candidatos para a próxima etapa do projeto:

1. **Obstáculos Especiais e Armadilhas (Pisos Eletrificados & Pitfalls)**:
   - Painéis de força (`ID_SWITCH`) destruíveis por Míssil Teleguiado para desligar a alta-voltagem dos pisos (ex: Salas 8, 20).
   - Alçapões dinâmicos que se abrem sob os passos de Snake (`ID_PITFALL`, `pitfall.asm`).

2. **Boss Fight Canônica 2: Machine Gun Kid (Sala 145 / Subsolo do Prédio 1)**:
   - Segundo chefe do jogo (`ID_MACH_GUN_KID = 34` na ROM), movimentação e rajadas contínuas de metralhadora com dano pesado e resgate de refém.

3. **Mecânica da Caixa de Papelão e Disfarces no Sandbox**:
   - Sprites autênticos da Cardboard Box (`ITEM_BOX`), movimentação lenta e uso de uniforme inimigo (`ITEM_UNIFORM`) no Prédio 2.

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
