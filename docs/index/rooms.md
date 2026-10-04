# Salas: numeração, faixas e aliases locais

Curado à mão. A tabela entre os marcadores `aliases` é conferida por
`tools/context/build_index.py` contra `ALIASES` em `tools/extractors/export_local_aliases.py`.

## Aliases locais (convenção do laboratório, não dados da ROM)

<!-- aliases -->
| Local | Original | Papel | Evidência |
|---|---|---|---|
| 211 | 165 | cela da captura | `logic/capturescene.asm:87-118` |
| 212 | 164 | sala da bolsa de equipamentos | `data/doors.asm:724-728` |
<!-- aliases -->

- Gerados por `export_local_aliases.py` em `data/extracted/en-eu-rc750/local-aliases/`, que tem
  prioridade sobre `rooms/` (`ROOM_DATA_DIRS` em `room_manager.gd`). Portas cujo destino é
  165/164 são redirecionadas para 211/212 e registradas em `local_door_remap` (inclui a sala 54).
- `RoomManager.get_next_room` devolve `NO_ROOM` para 211/212: a saída é pelas portas 103/12.
- **Conflito conhecido, não resolvido:** na ROM, 211 e 212 também são salas reais do canal de
  água, alcançadas pela sala 106 para cima e pela 107 para baixo (`data/roomsconnections.asm:113-114`,
  comentários `129>211` / `130>212` em `:136-137`). A tabela portada em `room_manager.gd` mantém
  esses destinos, então essas bordas levariam aos aliases da prisão. Pendência em `docs/STATUS.md`.

## Faixas da numeração original (`GetNextRoomNum`, `Banks0123.asm:889-918`)

| Salas | Índice em `RoomConnections` | Observação |
|---|---|---|
| 0–125 | mesmo número | conexões de borda 1:1 |
| 126–207 | — | caminhões e salas isoladas; só por porta |
| 208–227 | sala − 82 (126–145) | canal de água, escadas |
| 227–239 | — | indefinidas (comentário em `:902-903`) |
| 240 | — | primeiro elevador, sem conexões |
| 241–250 | sala − 95 (146–155) | elevadores |

`idxRooms` tem 251 entradas; 235 decodificam como sala (inventário em
`docs/reverse_engineering/maps.md`). Salas isoladas para o binóculo: `ChkIsolatedRoom`
(`Banks0123.asm:1038`), portado em `RoomManager.is_room_isolated`.
