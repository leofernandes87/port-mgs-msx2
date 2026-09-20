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

## 5. Estado atual do projeto (HEAD: `356ee1b` + Bloco 12-B pronto)

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

### Dados extraídos disponíveis

| Diretório | Conteúdo |
|-----------|----------|
| `data/extracted/rc750-verified/` | `package.json` (19 MB): 235 salas, tilesets, doors, actors, items, paths |
| `data/extracted/stage4c-validated/` | 8 snapshots validados por emulador (rooms 0–3, 5, 121, 240) |
| `data/extracted/stage4b-validated/` | 6 snapshots validados por emulador |
| `data/extracted/stage4-validated/` | 4 snapshots (rooms 1, 5, 31, 127) |
| `data/extracted/stage5-batch/` | **126 snapshots rooms 0–125** + PNGs + **129 room-NNN-actors.json** (salas 0-128) |

### Snapshots por cobertura de edifício (stage5-batch)

- Prédio 1 (salas 0–15): **16 snapshots**
- Prédio 2 (salas 16–63): **48 snapshots**
- Prédio 3 (salas 64–125): **62 snapshots**
- 7/126 cross-checked pixel-a-pixel contra emulador (rooms 0, 1, 2, 3, 5, 31, 121)
- Salas lorry (126–207) e elevadores (208–250): lorries 126-128 têm atores/itens exportados; snapshot derivado do 127.

### Estado do Godot

O `RoomManager.load_room_snapshot()` busca nas pastas em ordem:
1. `stage5-batch/` (salas 0–125 reais)
2. `stage4c-validated/`
3. `stage4b-validated/`
4. `stage4-validated/`

---

## 6. Próxima tarefa: Etapa 12-C — Spawn dinâmico no sandbox e carregamento de atores

**Status: Bloco 12-A e 12-B prontos; Bloco 12-C a iniciar.**

### Sub-blocos da Etapa 12

- [x] **Bloco 12-A — RoomManager prioriza stage5-batch** (commit `356ee1b`)
- [x] **Bloco 12-B — Ferramenta Python `export_room_data.py`** (commit a seguir)
  - `tools/extractors/export_room_data.py` gerou `room-NNN-actors.json` para 129 salas (0-128).
  - Suíte `ExportRoomDataTests` em `tests/test_extractors.py`.
- [ ] **Bloco 12-C — Integração de atores/itens dinâmicos no RoomManager e sandbox_gameplay.gd**
  - Adicionar método `RoomManager.load_room_actors(room_id: int) -> Dictionary`.
  - Atualizar `sandbox_gameplay.gd` para usar dados do JSON em vez de spawn puramente hardcoded.
  - Manter hardcoded como fallback / compatibilidade garantida para testes existentes.
  - Testar e validar. Commit + HANDOFF.
- Testes Python sintéticos
- Commit + validate + HANDOFF

**Bloco 12-C — Spawn dinâmico no sandbox**
- `_spawn_room_enemies()` e `_spawn_room_items()` leem `room-NNN-actors.json`
- Fallback: hardcode existente para rooms sem arquivo
- Guardas sem path data: patrulha horizontal ±32px ao redor do spawn
- Commit + validate + HANDOFF

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
